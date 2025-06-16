-- 1. Top 10 LTV ranking users

SELECT 
    Customer_ID,
    LTV,
    RANK() OVER (ORDER BY LTV DESC) AS LTV_rank
FROM fintech_users
ORDER BY LTV DESC
LIMIT 10;


-- 2. Calculating and ranking Engagement Score
SELECT 
    Customer_ID,
    Active_Days,
    Last_Transaction_Days_Ago,
    ROUND(1.0 * Active_Days / NULLIF(Last_Transaction_Days_Ago, 0), 2) AS Engagement_Score,
    NTILE(4) OVER (ORDER BY 1.0 * Active_Days / NULLIF(Last_Transaction_Days_Ago, 0)) AS engagement_quartile
FROM fintech_users;


-- 3. Average check, median check and income spread (Income_Level)

SELECT 
    Income_Level,
    ROUND(AVG(Avg_Transaction_Value)::numeric, 2) AS avg_value,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Avg_Transaction_Value) AS median_value,
    MAX(Avg_Transaction_Value) - MIN(Avg_Transaction_Value) AS value_range
FROM fintech_users
GROUP BY Income_Level;

-- 4. Analysis of the number of transactions and cashback for each category of users
SELECT 
    Income_Level,
    COUNT(*) AS users,
    AVG(Total_Transactions) AS avg_transactions,
    AVG(Cashback_Received) AS avg_cashback,
    SUM(Cashback_Received) AS total_cashback
FROM fintech_users
GROUP BY Income_Level
ORDER BY total_cashback DESC;

-- 5. Intragroup ranking by Total_Spent within Location

SELECT 
    Customer_ID,
    Location,
    Total_Spent,
    DENSE_RANK() OVER (PARTITION BY Location ORDER BY Total_Spent DESC) AS location_spending_rank
FROM fintech_users
ORDER BY Location, location_spending_rank;

-- 6. Calculating Churn Based on Days Without Activity (>90 Days)

SELECT 
    COUNT(*) FILTER (WHERE Last_Transaction_Days_Ago > 90) AS churned,
    COUNT(*) FILTER (WHERE Last_Transaction_Days_Ago <= 90) AS active,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE Last_Transaction_Days_Ago > 90) / COUNT(*),
        2
    ) AS churn_rate_percent
FROM fintech_users;

-- 7. Calculating the average time to resolve tickets by payment method

SELECT 
    Preferred_Payment_Method,
    ROUND(AVG(Issue_Resolution_Time), 2) AS avg_resolution_time
FROM fintech_users
GROUP BY Preferred_Payment_Method
ORDER BY avg_resolution_time;

-- 8. Identifying the top 5 engaged users by Location
SELECT *
FROM (
    SELECT 
        Customer_ID,
        Location,
        ROUND(1.0 * Active_Days / NULLIF(Last_Transaction_Days_Ago, 0), 2) AS Engagement_Score,
        ROW_NUMBER() OVER (PARTITION BY Location ORDER BY 1.0 * Active_Days / NULLIF(Last_Transaction_Days_Ago, 0) DESC) AS rank_loc
    FROM fintech_users
) sub
WHERE rank_loc <= 5;


-- 9. Segmentation of users by activity:
SELECT 
  Customer_ID,
  CASE 
    WHEN Active_Days >= 250 THEN 'Highly Active'
    WHEN Active_Days BETWEEN 100 AND 249 THEN 'Moderately Active'
    ELSE 'Low Activity'
  END AS activity_segment
FROM fintech_users;


-- 10. Most spending users

WITH top_users AS (
  SELECT 
    Customer_ID,
    Total_Spent,
    RANK() OVER (ORDER BY Total_Spent DESC) AS rnk
  FROM fintech_users
)
SELECT * FROM top_users WHERE rnk <= 10;