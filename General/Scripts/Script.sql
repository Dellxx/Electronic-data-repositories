SELECT 
    device_preference,
    shopping_channel,
    preferred_category_1,
    COUNT(customer_id) AS young_customers_count,
    ROUND(AVG(avg_order_value_usd)::numeric, 2) AS avg_aov,
    ROUND(AVG(conversion_rate)::numeric, 2) AS avg_conversion_rate,
    ROUND(AVG(social_media_presence)::numeric, 2) AS avg_social_presence,
    ROUND(AVG(click_through_rate)::numeric, 2) AS avg_ctr
FROM public.e_commerce_customer_segmentation
WHERE age BETWEEN 18 AND 24 OR age_group = '18-24'
GROUP BY device_preference, shopping_channel, preferred_category_1
ORDER BY young_customers_count DESC;

/*Фильтровал клиентов 18–24 лет и сортировал по общим тратам.
 * Показывает, через какие устройства (Mobile vs Desktop) 
 * и каналы молодая аудитория покупает чаще всего, а также на какой контент (CTR) реагирует. 
 * Это помогает оптимизировать бюджет на соцсети и мобильную рекламу.*/

----------------------

SELECT 
    MIN(avg_order_value_usd) AS min_aov,
    MAX(avg_order_value_usd) AS max_aov,
    AVG(avg_order_value_usd) AS avg_aov,
    STDDEV(avg_order_value_usd) AS stddev_aov,
    MIN(total_spent_usd) AS min_spent,
    MAX(total_spent_usd) AS max_spent
FROM public.e_commerce_customer_segmentation eccs;

/*Запрос общих показателей чека и трат (min_aov, max_aov, avg_aov...)
 * позволяет рассчитать порог для бесплатной доставки или бонусной программы 
 * можно установить минимальную сумму заказа для применения скидочных купонов */
-----------------------

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

/*список пользователей с высоким доходом.
 * Позволяет определить, на каком уровне лояльности (loyalty_tier) 
 * находятся состоятельные клиенты, какие категории товаров они предпочитают и насколько удовлетворены сервисом.*/

-----------------------

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

/*Фильтровал клиентов старше 56 лет и сортировал по количеству покупок.
 * Выявляет предпочтительные способы оплаты (например, наложенный платеж, карты) 
 * и барьеры (высокий уровень жалоб или возвратов), что помогает улучшить UX/UI для старшего поколения.*/

----------------------

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

/*Запрос демографических групп
 * Показывает, какая возрастная группа приносит основную часть выручки (total_revenue). 
 * Если 60% выручки дают Middle Aged, львиная доля бюджета контекстной и таргетированной рекламы должна идти на них.*/
-------------------------

SELECT 
    income_bracket,
    COUNT(customer_id) AS total_customers,
    ROUND(AVG(avg_order_value_usd)::numeric, 2) AS avg_check,
    ROUND(AVG(total_spent_usd)::numeric, 2) AS avg_total_spent
FROM public.e_commerce_customer_segmentation
GROUP BY income_bracket
ORDER BY avg_total_spent DESC;

--Табыс деңгейі (income_bracket) бойынша сегментация талдауы

------------------------

SELECT 
    country,
    COUNT(customer_id) AS total_customers,
    SUM(total_purchases) AS total_orders,
    ROUND(AVG(avg_order_value_usd)::numeric, 2) AS avg_order_value,
    ROUND(SUM(total_spent_usd)::numeric, 2) AS total_revenue
FROM public.e_commerce_customer_segmentation
GROUP BY country
ORDER BY total_revenue DESC
LIMIT 5;

--Tоп-5 стран по общей выручке и среднему чеку

-----------------------

SELECT 
    gender,
    COUNT(customer_id) AS total_customers,
    ROUND(AVG(age)::numeric, 1) AS avg_age,
    ROUND(AVG(total_purchases)::numeric, 1) AS avg_purchases_per_user,
    ROUND(AVG(avg_order_value_usd)::numeric, 2) AS avg_order_value,
    ROUND(SUM(total_spent_usd)::numeric, 2) AS total_revenue
FROM public.e_commerce_customer_segmentation
GROUP BY gender;

--Сравнение поведения мужчин и женщин

------------------------

WITH vip_customers AS (
    SELECT *
    FROM public.e_commerce_customer_segmentation
    WHERE total_spent_usd >= (
        SELECT PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_spent_usd)
        FROM public.e_commerce_customer_segmentation
    )
)
SELECT 
    country,
    income_bracket,
    preferred_category_1,
    COUNT(customer_id) AS vip_count,
    ROUND(AVG(total_spent_usd)::numeric, 2) AS avg_vip_spend,
    ROUND(AVG(customer_profitability_usd)::numeric, 2) AS avg_vip_profit,
    ROUND(AVG(churn_risk_score)::numeric, 2) AS avg_churn_risk
FROM vip_customers
GROUP BY country, income_bracket, preferred_category_1
ORDER BY avg_vip_spend DESC;

/*Поиск ключевых VIP-клиентов (Топ 1% по тратам)
 * Показывает концентрацию VIP-клиентов по странам и категориям доходов, 
 * а главное — отслеживает риск оттока (churn risk) среди самых ценных клиентов компании.*/

-------------------

SELECT 
    customer_segment,
    COUNT(customer_id) AS total_clients,
    ROUND(AVG(age)::numeric, 1) AS avg_age,
    ROUND(AVG(total_purchases)::numeric, 1) AS avg_purchases,
    ROUND(AVG(avg_order_value_usd)::numeric, 2) AS avg_check,
    ROUND(SUM(total_spent_usd)::numeric, 2) AS total_revenue
FROM public.e_commerce_customer_segmentation
GROUP BY customer_segment
ORDER BY total_revenue DESC;

--Сравнение существующих сегментов

-------------------

SELECT 
    CASE 
        WHEN age BETWEEN 18 AND 24 THEN '1. Gen-Z (18-24)'
        WHEN age BETWEEN 25 AND 38 THEN '2. Young Adults (25-38)'
        WHEN age BETWEEN 39 AND 55 THEN '3. Middle Aged (39-55)'
        WHEN age >= 56 THEN '4. Seniors (56+)'
        ELSE '5. Other'
    END AS age_group,
    gender,
    COUNT(customer_id) AS total_customers,
    ROUND(AVG(total_purchases)::numeric, 1) AS avg_purchases,
    ROUND(AVG(avg_order_value_usd)::numeric, 2) AS avg_aov,
    ROUND(SUM(total_spent_usd)::numeric, 2) AS total_revenue,
    ROUND(AVG(email_open_rate)::numeric, 2) AS avg_email_open_rate,
    ROUND(AVG(churn_risk_score)::numeric, 2) AS avg_churn_risk
FROM public.e_commerce_customer_segmentation
GROUP BY 1, gender
ORDER BY age_group, gender;

/*Группировал по возрасту и полу, рассчитывая выручку и средний чек.
 * Помогает точечно настраивать таргетированную рекламу и e-mail рассылки отдельно для мужчин и женщин в разных возрастных категориях.*/

----------------------

SELECT 
    rfm_category,
    COUNT(customer_id) AS total_customers,
    ROUND(COUNT(customer_id) * 100.0 / SUM(COUNT(customer_id)) OVER(), 2) AS customer_share_pct,
    
    -- Финансовые показатели
    ROUND(AVG(total_spent_usd)::numeric, 2) AS avg_total_spent,
    ROUND(AVG(avg_order_value_usd)::numeric, 2) AS avg_aov,
    ROUND(AVG(customer_lifetime_value_usd)::numeric, 2) AS avg_clv,
    ROUND(AVG(customer_acquisition_cost_usd)::numeric, 2) AS avg_cac,
    ROUND(AVG(customer_profitability_usd)::numeric, 2) AS avg_profit,
    
    -- Поведенческие метрики
    ROUND(AVG(days_since_last_purchase)::numeric, 1) AS avg_recency_days,
    ROUND(AVG(total_purchases)::numeric, 1) AS avg_purchases_count,
    
    -- Сервис и риски
    ROUND(AVG(churn_risk_score)::numeric, 2) AS avg_churn_risk,
    ROUND(AVG(return_count)::numeric, 2) AS avg_returns,
    ROUND(AVG(satisfaction_score)::numeric, 2) AS avg_satisfaction,
    
    -- Digital-вовлеченность
    ROUND(AVG(email_open_rate)::numeric, 2) AS avg_email_open_rate,
    ROUND(AVG(click_through_rate)::numeric, 2) AS avg_ctr
FROM public.e_commerce_customer_segmentation
GROUP BY rfm_category
ORDER BY avg_profit DESC;

/*Этот запрос группирует клиентов по RFM-категориям и вычисляет полный финансово-поведенческий профиль: доходность, отток, вовлеченность и удовлетворенность.*/

-----------------------

SELECT 
    income_bracket,
    preferred_category_1,
    shopping_channel,
    device_preference,
    social_media_presence,
    COUNT(customer_id) AS total_customers,
    ROUND(AVG(avg_order_value_usd)::numeric, 2) AS avg_check,
    ROUND(AVG(customer_profitability_usd)::numeric, 2) AS avg_profit,
    ROUND(AVG(conversion_rate)::numeric, 2) AS avg_conversion_rate
FROM public.e_commerce_customer_segmentation
GROUP BY 
    income_bracket, 
    preferred_category_1, 
    shopping_channel, 
    device_preference, 
    social_media_presence
HAVING COUNT(customer_id) >= 10 -- фильтр шума
ORDER BY income_bracket DESC, total_customers DESC;

/*где и что покупают клиенты разных уровней дохода и демографии, а также их предрасположенность к девайсам и социальным сетям.*/

------------------------

SELECT 
    clv_category,
    profitability_category,
    COUNT(customer_id) AS total_customers,
    ROUND(AVG(total_spent_usd)::numeric, 2) AS avg_revenue,
    ROUND(AVG(customer_acquisition_cost_usd)::numeric, 2) AS avg_cac,
    ROUND(AVG(customer_profitability_usd)::numeric, 2) AS avg_net_profit,
    ROUND(AVG(avg_order_value_usd)::numeric, 2) AS avg_aov,
    ROUND(AVG(return_count)::numeric, 1) AS avg_returns,
    ROUND(AVG(complaint_count)::numeric, 2) AS avg_complaints
FROM public.e_commerce_customer_segmentation
GROUP BY clv_category, profitability_category
ORDER BY avg_net_profit DESC;

/*делит клиентов по категории профитабельности (profitability_category) 
 * и категории стоимости (clv_category), выявляя «Охотников за скидками» 
 * (высокая частота, но низкий чек/прибыль из-за CAC) и VIP-клиентов.*/

-----------------------

SELECT 
    churn_risk_category,
    activity_status,
    satisfaction_level,
    COUNT(customer_id) AS customer_count,
    ROUND(AVG(days_since_last_purchase)::numeric, 0) AS days_idle,
    ROUND(AVG(total_spent_usd)::numeric, 2) AS total_revenue_at_risk,
    ROUND(AVG(email_open_rate)::numeric, 2) AS email_open_rate,
    ROUND(AVG(click_through_rate)::numeric, 2) AS ctr
FROM public.e_commerce_customer_segmentation
GROUP BY churn_risk_category, activity_status, satisfaction_level
ORDER BY churn_risk_category DESC, total_revenue_at_risk DESC;

/*помогает выделить клиентов, которых можно потерять, и сопоставляет отток с уровнем удовлетворенности (satisfaction_level) и активностью.*/
