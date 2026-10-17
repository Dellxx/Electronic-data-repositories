-- НЕДОСТАЮЩИЕ СКРИПТЫ (PostgreSQL)
-- Таблица: public.e_commerce_customer_segmentation

----------------------------------------------------------
-- 1. Семейное положение
----------------------------------------------------------
SELECT
    marital_status,
    COUNT(customer_id) AS total_customers,
    ROUND(COUNT(customer_id) * 100.0 / SUM(COUNT(customer_id)) OVER(), 2) AS customer_share_pct,
    ROUND(AVG(total_spent_usd)::numeric, 2)     AS avg_total_spent,
    ROUND(AVG(avg_order_value_usd)::numeric, 2) AS avg_check,
    ROUND(AVG(churn_risk_score)::numeric, 2)    AS avg_churn_risk
FROM public.e_commerce_customer_segmentation
GROUP BY marital_status
ORDER BY avg_total_spent DESC;

----------------------------------------------------------
-- 2. Главная сегментация: возраст + доход + семья
--    (возрастные группы)
----------------------------------------------------------
WITH segments AS (
    SELECT
        customer_id,
        total_spent_usd,
        avg_order_value_usd,
        churn_risk_score,
        CASE
            WHEN age BETWEEN 18 AND 24 THEN '1. Gen-Z (18-24)'
            WHEN age BETWEEN 25 AND 38 THEN '2. Young Adults (25-38)'
            WHEN age BETWEEN 39 AND 55 THEN '3. Middle Aged (39-55)'
            ELSE '4. Seniors (56+)'
        END AS age_group,
        CASE
            WHEN income_bracket IN ('0-25K', '25K-50K')       THEN '1. Низкий'
            WHEN income_bracket IN ('50K-75K', '75K-100K')    THEN '2. Средний'
            ELSE '3. Высокий'
        END AS income_level,
        CASE
            WHEN marital_status = 'Single'  THEN '1. Без пары'
            WHEN marital_status = 'Married' THEN '2. В браке'
            ELSE '3. Был в браке'          -- Divorced + Widowed
        END AS family_type
    FROM public.e_commerce_customer_segmentation
)
SELECT
    age_group, income_level, family_type,
    COUNT(customer_id) AS total_customers,
    ROUND(COUNT(customer_id) * 100.0 / SUM(COUNT(customer_id)) OVER(), 2) AS customer_share_pct,
    ROUND(AVG(total_spent_usd)::numeric, 2)     AS avg_total_spent,
    ROUND(AVG(avg_order_value_usd)::numeric, 2) AS avg_check,
    ROUND(AVG(churn_risk_score)::numeric, 2)    AS avg_churn_risk
FROM segments
GROUP BY age_group, income_level, family_type
ORDER BY age_group, income_level, family_type;

----------------------------------------------------------
-- 3. Маркетинговое предложение для каждой группы
--    Результат: таблица customer_offers (клиент -> группа -> предложение)
----------------------------------------------------------

--CREATE TABLE public.customer_offers AS
--WITH segments AS (
--    SELECT
--        customer_id,
--        CASE
--            WHEN age BETWEEN 18 AND 24 THEN '1. Gen-Z (18-24)'
--            WHEN age BETWEEN 25 AND 38 THEN '2. Young Adults (25-38)'
--            WHEN age BETWEEN 39 AND 55 THEN '3. Middle Aged (39-55)'
--            ELSE '4. Seniors (56+)'
--        END AS age_group,
--        CASE
--            WHEN income_bracket IN ('0-25K', '25K-50K')       THEN '1. Низкий'
--            WHEN income_bracket IN ('50K-75K', '75K-100K')    THEN '2. Средний'
--            ELSE '3. Высокий'
--        END AS income_level,
--        CASE
--            WHEN marital_status = 'Single'  THEN '1. Без пары'
--            WHEN marital_status = 'Married' THEN '2. В браке'
--            ELSE '3. Был в браке'
--        END AS family_type
--    FROM public.e_commerce_customer_segmentation
--)
--SELECT
--    customer_id, age_group, income_level, family_type,
--    CASE
--        WHEN income_level = '3. Высокий' AND age_group IN ('2. Young Adults (25-38)', '3. Middle Aged (39-55)')
--            THEN 'VIP-программа: ранний доступ к новинкам, бесплатная доставка'
--        WHEN age_group = '1. Gen-Z (18-24)' AND income_level = '1. Низкий'
--            THEN 'Студенческая скидка и рассрочка 0%'
--        WHEN age_group = '1. Gen-Z (18-24)'
--            THEN 'Скидка за приведённого друга, промокоды в соцсетях'
--        WHEN family_type = '2. В браке' AND age_group IN ('2. Young Adults (25-38)', '3. Middle Aged (39-55)')
--            THEN 'Семейные наборы: товары для дома и детей, скидка от суммы'
--        WHEN age_group = '4. Seniors (56+)'
--            THEN 'Скидка по понедельникам и помощь по телефону'
--        WHEN income_level = '1. Низкий'
--            THEN 'Купоны на товары первой необходимости'
--        ELSE 'Персональная подборка и бонусы за повторную покупку'
--    END AS marketing_offer
--FROM segments;


-- Проверка: сколько клиентов получило каждое предложение
SELECT marketing_offer, COUNT(*) AS customers
FROM public.customer_offers
GROUP BY marketing_offer
ORDER BY customers DESC;


-- СЦЕНАРИИ ЭФФЕКТА ОТ ПРЕДЛОЖЕНИЙ (PostgreSQL)
-- Запускать после missing_scripts.sql (нужна таблица customer_offers)
-- Проценты ниже - ДОПУЩЕНИЯ, меняйте их в блоке params

----------------------------------------------------------
-- 1. Прибавка по каждому предложению (млн $ в год)
----------------------------------------------------------
WITH params AS (
    SELECT 0.02  AS uplift_low,    -- осторожный: траты +2%
           0.05  AS uplift_mid,    -- средний:    траты +5%
           0.08  AS uplift_high,   -- оптимистичный: траты +8%
           0.015 AS cost_pct       -- расходы на скидки: 1,5% выручки
),
base AS (
    SELECT
        o.marketing_offer,
        e.customer_id,
        -- годовая выручка = траты / месяцев с нами * 12
        e.total_spent_usd / NULLIF(e.tenure_months, 0) * 12 AS annual_revenue
    FROM public.customer_offers o
    JOIN public.e_commerce_customer_segmentation e USING (customer_id)
)
SELECT
    b.marketing_offer,
    COUNT(*) AS customers,
    ROUND(SUM(b.annual_revenue)::numeric / 1000000.0, 2) AS base_revenue_m,
    ROUND((SUM(b.annual_revenue) * (p.uplift_low  - p.cost_pct))::numeric / 1000000.0, 2) AS net_gain_low_m,
    ROUND((SUM(b.annual_revenue) * (p.uplift_mid  - p.cost_pct))::numeric / 1000000.0, 2) AS net_gain_mid_m,
    ROUND((SUM(b.annual_revenue) * (p.uplift_high - p.cost_pct))::numeric / 1000000.0, 2) AS net_gain_high_m
FROM base b
CROSS JOIN params p
GROUP BY b.marketing_offer, p.uplift_low, p.uplift_mid, p.uplift_high, p.cost_pct
ORDER BY base_revenue_m DESC;

----------------------------------------------------------
-- 2. Итого по всем клиентам, с долей к базе
----------------------------------------------------------
WITH params AS (
    SELECT 0.02 AS uplift_low, 0.05 AS uplift_mid, 0.08 AS uplift_high, 0.015 AS cost_pct
),
base AS (
    SELECT e.total_spent_usd / NULLIF(e.tenure_months, 0) * 12 AS annual_revenue
    FROM public.customer_offers o
    JOIN public.e_commerce_customer_segmentation e USING (customer_id)
)
SELECT
    COUNT(*) AS customers,
    ROUND(SUM(annual_revenue)::numeric / 1000000.0, 2) AS base_revenue_m,
    ROUND((SUM(annual_revenue) * (p.uplift_low  - p.cost_pct))::numeric / 1000000.0, 2) AS net_gain_low_m,
    ROUND((SUM(annual_revenue) * (p.uplift_mid  - p.cost_pct))::numeric / 1000000.0, 2) AS net_gain_mid_m,
    ROUND((SUM(annual_revenue) * (p.uplift_high - p.cost_pct))::numeric / 1000000.0, 2) AS net_gain_high_m,
    ROUND(((p.uplift_mid - p.cost_pct) * 100)::numeric, 1) AS mid_gain_pct_of_base
FROM base
CROSS JOIN params p
GROUP BY p.uplift_low, p.uplift_mid, p.uplift_high, p.cost_pct;
-----------
/*список пользователей с высоким доходом.
 * Позволяет определить, на каком уровне лояльности (loyalty_tier) 
 * находятся состоятельные клиенты, какие категории товаров они предпочитают и насколько удовлетворены сервисом.*/
--------------
SELECT 
    income_bracket,
    loyalty_tier,
    preferred_category_1,
    COUNT(customer_id) AS customer_count,
    ROUND(AVG(avg_order_value_usd)::numeric, 2) AS avg_aov,
    ROUND(AVG(total_spent_usd)::numeric, 2) AS avg_lifetime_spent,
    ROUND(AVG(satisfaction_score)::numeric, 2) AS avg_satisfaction
FROM public.e_commerce_customer_segmentation
WHERE income_bracket IN ('75K-100K', '100K-150K', '150K+')
GROUP BY income_bracket, loyalty_tier, preferred_category_1
ORDER BY income_bracket DESC, avg_lifetime_spent DESC;


/*Фильтровал клиентов старше 56 лет и сортировал по количеству покупок.
 * Выявляет предпочтительные способы оплаты (например, наложенный платеж, карты) 
 * и барьеры (высокий уровень жалоб или возвратов), что помогает улучшить UX/UI для старшего поколения.*/

SELECT 
    shopping_channel,
    payment_method,
    COUNT(customer_id) AS senior_customers_count,
    ROUND(AVG(total_purchases)::numeric, 1) AS avg_purchases_count,
    ROUND(AVG(avg_order_value_usd)::numeric, 2) AS avg_aov,
    ROUND(AVG(complaint_count)::numeric, 2) AS avg_complaints,
    ROUND(AVG(return_count)::numeric, 2) AS avg_returns
FROM public.e_commerce_customer_segmentation
WHERE age >= 56
GROUP BY shopping_channel, payment_method
ORDER BY senior_customers_count DESC;


/*Запрос демографических групп
 * Показывает, какая возрастная группа приносит основную часть выручки (total_revenue). 
 * Если 60% выручки дают Middle Aged, львиная доля бюджета контекстной и таргетированной рекламы должна идти на них.*/

SELECT 
    CASE 
        WHEN age BETWEEN 18 AND 24 THEN '1. Gen-Z (18-24)'
        WHEN age BETWEEN 25 AND 38 THEN '2. Young Adults (25-38)'
        WHEN age BETWEEN 39 AND 55 THEN '3. Middle Aged (39-55)'
        WHEN age >= 56 THEN '4. Seniors (56+)'
        ELSE '5. Unknown'
    END AS age_group,
    COUNT(customer_id) AS total_customers,
    ROUND(COUNT(customer_id) * 100.0 / SUM(COUNT(customer_id)) OVER(), 2) AS customer_share_pct,
    ROUND(SUM(total_spent_usd)::numeric, 2) AS total_revenue,
    ROUND(SUM(total_spent_usd) * 100.0 / SUM(SUM(total_spent_usd)) OVER(), 2) AS revenue_share_pct,
    ROUND(AVG(avg_order_value_usd)::numeric, 2) AS avg_order_value,
    ROUND(AVG(churn_risk_score)::numeric, 2) AS avg_churn_risk
FROM public.e_commerce_customer_segmentation
GROUP BY 1
ORDER BY age_group;


--Сравнение поведения мужчин и женщин

SELECT 
    gender,
    COUNT(customer_id) AS total_customers,
    ROUND(AVG(age)::numeric, 1) AS avg_age,
    ROUND(AVG(total_purchases)::numeric, 1) AS avg_purchases_per_user,
    ROUND(AVG(avg_order_value_usd)::numeric, 2) AS avg_order_value,
    ROUND(SUM(total_spent_usd)::numeric, 2) AS total_revenue
FROM public.e_commerce_customer_segmentation
GROUP BY gender;

