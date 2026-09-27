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