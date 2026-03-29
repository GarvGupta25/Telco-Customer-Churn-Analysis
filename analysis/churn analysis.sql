CREATE VIEW vw_customer_full AS
SELECT
    c.customer_id,
    c.gender,
    c.senior_citizen,
    c.partner,
    c.dependents,
    c.tenure_months,
    s.internet_service,
    s.phone_service,
    s.multiple_lines,
    s.online_security,
    s.online_backup,
    s.streaming_tv,
    s.streaming_movies,
    co.contract_type,
    co.payment_method,
    co.paperless_billing,
    co.monthly_charges,
    co.total_charges,
    ch.churned
FROM customers c
INNER JOIN services  s  ON s.customer_id  = c.customer_id
INNER JOIN contracts co ON co.customer_id = c.customer_id
INNER JOIN churn     ch ON ch.customer_id = c.customer_id;
/*first query - calculating churn pct*/
select
    COUNT(*)                                          AS total_customers,
    SUM(churned)                                        AS total_churned,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2)         AS churn_rate_pct,
    ROUND((1 - SUM(churned) / COUNT(*)) * 100.0, 2)  AS retention_rate_pct
FROM vw_customer_full;

/*Churn rate by contract type*/
SELECT
    contract_type,
    COUNT(*)                                      AS total_customers,
    SUM(churned)                                    AS churned_count,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2)   AS churn_rate_pct
FROM vw_customer_full
GROUP BY contract_type
ORDER BY churn_rate_pct DESC;

/*Churn by tenure bucket*/
SELECT
    CASE
        WHEN tenure_months BETWEEN 0  AND 12 THEN '0–12 months'
        WHEN tenure_months BETWEEN 13 AND 24 THEN '13–24 months'
        WHEN tenure_months BETWEEN 25 AND 48 THEN '25–48 months'
        ELSE                                        '49+ months'
    END                                              AS tenure_bucket,
    COUNT(*)                                         AS total_customers,
    SUM(churned)                                     AS churned_count,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2)    AS churn_rate_pct
FROM vw_customer_full
GROUP BY tenure_bucket
ORDER BY MIN(tenure_months);

/*Churn by internet service type*/
SELECT
    internet_service,
    COUNT(*)                                      AS total_customers,
    SUM(churned)                                    AS churned_count,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2)   AS churn_rate_pct,
    ROUND(AVG(monthly_charges), 2)               AS avg_monthly_charge
FROM vw_customer_full
GROUP BY internet_service
ORDER BY churn_rate_pct DESC;

/*Revenue lost to churn (MRR at risk)*/
SELECT
    COUNT(*)                                           AS total_customers,
    SUM(churned)                                         AS churned_customers,
    ROUND(SUM(monthly_charges), 2)                    AS total_mrr,
    ROUND(SUM(CASE WHEN churned = 1
               THEN monthly_charges ELSE 0 END), 2)    AS mrr_lost,
    ROUND(SUM(CASE WHEN churned = 1
               THEN monthly_charges ELSE 0 END)
          * 100.0 / SUM(monthly_charges), 2)          AS pct_mrr_lost
FROM vw_customer_full;

/*Churn by payment method*/
SELECT
    payment_method,
    COUNT(*)                                      AS total_customers,
    SUM(churned)                                    AS churned_count,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2)   AS churn_rate_pct,
    ROUND(AVG(monthly_charges), 2)               AS avg_monthly_charge
FROM vw_customer_full
GROUP BY payment_method
HAVING COUNT(*) > 100          
ORDER BY churn_rate_pct DESC;

/*Churn by senior citizen status + gender cross-segment*/
SELECT
    CASE WHEN senior_citizen = 1 THEN 'Senior' ELSE 'Non-senior' END  AS age_group,
    gender,
    COUNT(*)                                                            AS total_customers,
    SUM(churned)                                                          AS churned_count,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2)                         AS churn_rate_pct,
    ROUND(AVG(monthly_charges), 2)                                       AS avg_charge
FROM vw_customer_full
GROUP BY age_group, gender           
ORDER BY churn_rate_pct DESC;

/*analysis of add on services and how it impacts churn*/
SELECT
        (CASE WHEN online_security   = 'Yes' THEN 1 ELSE 0 END
   + CASE WHEN online_backup     = 'Yes' THEN 1 ELSE 0 END
   + CASE WHEN tech_support      = 'Yes' THEN 1 ELSE 0 END)  AS addon_count,
    COUNT(*)                                                    AS total_customers,
    SUM(churned)                                                  AS churned_count,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2)               AS churn_rate_pct
FROM vw_customer_full
WHERE internet_service != 'No'  
GROUP BY addon_count
ORDER BY addon_count;

/*Highest-risk customer profiles */
SELECT
    contract_type,
    internet_service,
    payment_method,
    COUNT(*)                                      AS total_customers,
    SUM(churned)                                    AS churned_count,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2)   AS churn_rate_pct
FROM vw_customer_full
GROUP BY contract_type, internet_service, payment_method
HAVING
    COUNT(*) >= 30                               
    AND SUM(churned) * 100.0 / COUNT(*) > (
        
        SELECT SUM(churned) * 100.0 / COUNT(*) FROM vw_customer_full
    )
ORDER BY churn_rate_pct DESC
LIMIT 8;


