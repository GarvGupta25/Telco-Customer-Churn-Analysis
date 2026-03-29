/*customer prioritisation*/
use telco_churn;
SELECT
    customer_id,
    contract_type,
    internet_service,
    tenure_months,
    monthly_charges,
    churned,
    -- Risk score: higher charge + lower tenure + month-to-month = more risk
    ROUND(
        (monthly_charges / 10)
      + (1.0 / (NULLIF(tenure_months, 0) + 1)) * 100
      + (CASE WHEN contract_type = 'Month-to-month' THEN 20 ELSE 0 END)
      + (CASE WHEN internet_service = 'Fiber optic'  THEN 10 ELSE 0 END),
    2)                                                  AS risk_score,
    RANK() OVER (ORDER BY
        (monthly_charges / 10)
      + (1.0 / (NULLIF(tenure_months, 0) + 1)) * 100
      + (CASE WHEN contract_type = 'Month-to-month' THEN 20 ELSE 0 END)
      + (CASE WHEN internet_service = 'Fiber optic'  THEN 10 ELSE 0 END)
    DESC)                                               AS risk_rank
FROM vw_customer_full
ORDER BY risk_rank
LIMIT 15;

/*dividing customer into quartiles based on risk optimisation*/
WITH scored AS (
    SELECT
        customer_id, contract_type, internet_service,
        tenure_months, monthly_charges, churned,
        NTILE(4) OVER (ORDER BY monthly_charges DESC) AS spend_quartile
    FROM vw_customer_full
)
SELECT
    spend_quartile,
    CASE spend_quartile
        WHEN 1 THEN 'Q1 — top spenders'
        WHEN 2 THEN 'Q2 — high spenders'
        WHEN 3 THEN 'Q3 — mid spenders'
        WHEN 4 THEN 'Q4 — low spenders'
    END                                             AS quartile_label,
    COUNT(*)                                        AS total_customers,
    SUM(churned)                                    AS churned_count,
    ROUND(AVG(monthly_charges), 2)               AS avg_charge,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2)   AS churn_rate_pct
FROM scored
GROUP BY spend_quartile
ORDER BY spend_quartile;

/*cumulative pct and sum of churned customer till current date*/
WITH monthly_churn AS (
    SELECT
        tenure_months,
        COUNT(*)        AS customers_at_tenure,
        SUM(churned)    AS churned_at_tenure
    FROM vw_customer_full
    GROUP BY tenure_months
)
SELECT
    tenure_months,
    customers_at_tenure,
    churned_at_tenure,
    SUM(churned_at_tenure) OVER (
        ORDER BY tenure_months
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                       AS cumulative_churned,
    ROUND(
        SUM(churned_at_tenure) OVER (ORDER BY tenure_months)
        * 100.0 / SUM(churned_at_tenure) OVER (),
    2)                      AS pct_of_total_churn
FROM monthly_churn
ORDER BY tenure_months
LIMIT 24;

/*Churn rate trend across tenure cohorts by contract type*/
WITH cohorts AS (
    SELECT
        CASE
            WHEN tenure_months BETWEEN 0  AND 12 THEN '0–12m'
            WHEN tenure_months BETWEEN 13 AND 24 THEN '13–24m'
            WHEN tenure_months BETWEEN 25 AND 48 THEN '25–48m'
            ELSE '49m+'
        END          AS tenure_cohort,
        contract_type,
        churned
    FROM vw_customer_full
)
SELECT
    tenure_cohort,
    contract_type,
    COUNT(*)                                      AS total_customers,
    SUM(churned)                                    AS churned_count,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 2)   AS churn_rate_pct
FROM cohorts
GROUP BY tenure_cohort, contract_type
ORDER BY MIN(tenure_months), contract_type;

/*Customer lifetime value — churned vs retained*/
WITH clv_calc AS (
    SELECT
        customer_id,
        churned,
        tenure_months,
        monthly_charges,
        
        ROUND(monthly_charges * tenure_months, 2)    AS estimated_clv,
       
        ROUND(monthly_charges * 12, 2)              AS projected_annual_value
    FROM vw_customer_full
)
SELECT
    CASE WHEN churned = 1 THEN 'Churned' ELSE 'Retained' END  AS status,
    COUNT(*)                                                    AS customers,
    ROUND(AVG(estimated_clv), 2)                              AS avg_clv,
    ROUND(AVG(projected_annual_value), 2)                     AS avg_annual_value,
    ROUND(AVG(tenure_months), 1)                              AS avg_tenure_months,
    ROUND(SUM(estimated_clv), 2)                             AS total_clv_generated
FROM clv_calc
GROUP BY churned
ORDER BY churned;

/*The single worst customer segment — combined risk ranking*/
WITH segments AS (
    SELECT
        contract_type,
        internet_service,
        payment_method,
        COUNT(*)                                      AS total_customers,
        SUM(churned)                                    AS churned_count,
        ROUND(SUM(churned) * 100.0 / COUNT(*), 2)   AS churn_rate_pct,
        ROUND(AVG(monthly_charges), 2)               AS avg_charge,
        ROUND(SUM(monthly_charges * churned), 2)     AS mrr_lost
    FROM vw_customer_full
    GROUP BY contract_type, internet_service, payment_method
    HAVING COUNT(*) >= 30
),
ranked AS (
    SELECT *,
        RANK() OVER (ORDER BY churn_rate_pct DESC)  AS rank_by_churn_rate,
        RANK() OVER (ORDER BY mrr_lost DESC)        AS rank_by_revenue_loss,
        -- Combined rank: worst on both dimensions = smallest sum of ranks
        RANK() OVER (ORDER BY churn_rate_pct DESC) +
        RANK() OVER (ORDER BY mrr_lost DESC)          AS combined_risk_rank
    FROM segments
)
SELECT *
FROM ranked
ORDER BY combined_risk_rank
LIMIT 10;
