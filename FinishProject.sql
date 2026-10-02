SELECT 
    customer_id,
    age,
    gender,
    country,
    city,
    income_bracket,
    total_purchases,
    avg_order_value_usd,
    total_spent_usd,
    customer_segment
FROM public.e_commerce_customer_segmentation
WHERE age BETWEEN 18 AND 24
   OR age_group = '18-24'
ORDER BY total_spent_usd DESC;

SELECT 
    MIN(avg_order_value_usd) AS min_aov,
    MAX(avg_order_value_usd) AS max_aov,
    AVG(avg_order_value_usd) AS avg_aov,
    STDDEV(avg_order_value_usd) AS stddev_aov,
    MIN(total_spent_usd) AS min_spent,
    MAX(total_spent_usd) AS max_spent
FROM public.e_commerce_customer_segmentation eccs;



SELECT 
    customer_id,
    age,
    gender,
    income_bracket,
    total_purchases,
    avg_order_value_usd,
    total_spent_usd,
    customer_segment
FROM public.e_commerce_customer_segmentation
WHERE income_bracket IN ('75K-100K', '100K-150K', '150K+')
ORDER BY avg_order_value_usd DESC;

--группа возрасных 

SELECT 
    customer_id,
    age,
    gender,
    country,
    income_bracket,
    total_purchases,
    avg_order_value_usd,
    total_spent_usd,
    customer_segment
FROM public.e_commerce_customer_segmentation
WHERE age >= 56
ORDER BY total_purchases DESC;

--Барлық демографиялық жас топтары бойынша жиынтық статистика

SELECT 
    CASE 
        WHEN age BETWEEN 18 AND 24 THEN '1. Gen-Z (18-24)'
        WHEN age BETWEEN 25 AND 38 THEN '2. Young Adults (25-38)'
        WHEN age BETWEEN 39 AND 55 THEN '3. Middle Aged (39-55)'
        WHEN age >= 56 THEN '4. Seniors (56+)'
        ELSE '5. Unknown'
    END AS age_group,
    COUNT(customer_id) AS total_customers,
    ROUND(AVG(total_purchases)::numeric, 2) AS avg_purchases_per_client,
    ROUND(AVG(avg_order_value_usd)::numeric, 2) AS avg_order_value,
    ROUND(SUM(total_spent_usd)::numeric, 2) AS total_revenue
FROM public.e_commerce_customer_segmentation
GROUP BY 1
ORDER BY age_group;


--Табыс деңгейі (income_bracket) бойынша сегментация талдауы

SELECT 
    income_bracket,
    COUNT(customer_id) AS total_customers,
    ROUND(AVG(avg_order_value_usd)::numeric, 2) AS avg_check,
    ROUND(AVG(total_spent_usd)::numeric, 2) AS avg_total_spent
FROM public.e_commerce_customer_segmentation
GROUP BY income_bracket
ORDER BY avg_total_spent DESC;

--Tоп-5 стран по общей выручке и среднему чеку

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

--Поиск ключевых VIP-клиентов (Топ 1% по тратам)

SELECT 
    customer_id,
    age,
    gender,
    country,
    city,
    income_bracket,
    total_purchases,
    avg_order_value_usd,
    total_spent_usd,
    customer_segment
FROM public.e_commerce_customer_segmentation
WHERE total_spent_usd >= (
    SELECT PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_spent_usd)
    FROM public.e_commerce_customer_segmentation
)
ORDER BY total_spent_usd DESC;

--Сравнение существующих сегментов

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

--Сравнение мужчин и женщин внутри возрастных групп

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
    ROUND(AVG(avg_order_value_usd)::numeric, 2) AS avg_order_value,
    ROUND(SUM(total_spent_usd)::numeric, 2) AS total_revenue
FROM public.e_commerce_customer_segmentation
GROUP BY 1, gender
ORDER BY age_group, gender;