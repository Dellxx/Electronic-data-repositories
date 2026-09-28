SELECT customer_id, customer_segment, segment_category, age, age_group, gender, country, city, income_bracket, education_level, employment_type, marital_status, tenure_months, total_purchases, avg_order_value_usd, total_spent_usd, purchase_frequency, days_since_last_purchase, preferred_category_1, preferred_category_2, preferred_category_3, shopping_channel, device_used, payment_method, return_count, complaint_count, satisfaction_score, satisfaction_level, loyalty_tier, email_open_rate, click_through_rate, conversion_rate, social_media_presence, customer_lifetime_value_usd, customer_acquisition_cost_usd, customer_profitability_usd, recency_score, frequency_score, monetary_score, rfm_score, churn_risk_score, customer_health_score, dataset_year, customer_value_category, activity_status, health_status, churn_risk_category, rfm_category, profitability_category, engagement_level, behavior_segment, device_preference, clv_category
FROM public.e_commerce_customer_segmentation;

SELECT 
    age_group,
    COUNT(customer_id) AS total_customers
FROM public.e_commerce_customer_segmentation
GROUP BY age_group
ORDER BY total_customers DESC;

SELECT 
    gender,
    customer_segment,
    COUNT(customer_id) AS total_customers
FROM public.e_commerce_customer_segmentation
GROUP BY gender, customer_segment
ORDER BY customer_segment, total_customers DESC;

SELECT 
    income_bracket,
    COUNT(customer_id) AS total_customers,
    ROUND(COUNT(customer_id) * 100.0 / (SELECT COUNT(*) FROM public.e_commerce_customer_segmentation), 2) AS share_percentage
FROM public.e_commerce_customer_segmentation
GROUP BY income_bracket
ORDER BY total_customers DESC;

SELECT 
    age_group,
    income_bracket,
    customer_segment,
    COUNT(customer_id) AS customer_count
FROM public.e_commerce_customer_segmentation
GROUP BY age_group, income_bracket, customer_segment
ORDER BY customer_count DESC
LIMIT 10;



