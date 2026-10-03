--негізгі клиенттер жынысы мен жасы бойынша
select 
gender,
age_group,
count(customer_id) as total_customers,
round(count(customer_id) * 100.0 / (select count(*) from demographics), 2) as percentage_share
from demographics 
group by gender, age_group 
order by total_customers desc;

--табыс деңгейі бойынша
select 
income_bracket,
count(customer_id) as customer_count,
round(count(customer_id) * 100.0 / (select count(*) from demographics), 2) as percentage_share
from demographics d 
group by income_bracket 
order by customer_count desc;

--отбасы жағдай  мен табыс бойынша
SELECT 
    marital_status,
    income_bracket,
    COUNT(customer_id) AS customer_count,
    ROUND(AVG(age), 1) AS avg_age
FROM demographics
GROUP BY marital_status, income_bracket
ORDER BY customer_count DESC;

--жас мамандар мен студенттер бойынша
SELECT 
    age_group,
    income_bracket,
    COUNT(customer_id) AS young_budget_users
FROM demographics
WHERE age BETWEEN 18 AND 25
GROUP BY age_group, income_bracket
ORDER BY young_budget_users DESC;

--Барлық жас топтарының жалпы сатылымға қосқан үлесі
SELECT 
    age_group,
    COUNT(customer_id) AS total_users,
    ROUND(COUNT(customer_id) * 100.0 / (SELECT COUNT(*) FROM demographics), 2) AS share_percentage
FROM demographics
GROUP BY age_group
ORDER BY age_group ASC;
