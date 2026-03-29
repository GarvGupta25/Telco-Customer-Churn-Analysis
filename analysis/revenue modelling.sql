use telco_churn;
/*MRR lost broken down by contract type*/
SELECT
    contract_type,
    COUNT(*)                                                           AS total_customers,
    SUM(churned)                                                         AS churned_customers,
    ROUND(SUM(monthly_charges), 2)                                    AS total_mrr,
    ROUND(SUM(CASE WHEN churned = 1 THEN monthly_charges ELSE 0 END), 2) AS mrr_lost,
    ROUND(SUM(CASE WHEN churned = 1 THEN monthly_charges ELSE 0 END)
          * 100.0 / SUM(monthly_charges), 2)                           AS pct_mrr_lost
FROM vw_customer_full
GROUP BY contract_type
ORDER BY mrr_lost DESC;

/*scenario modelling (1)- cutting the churn rate by 10%*/
WITH baseline AS (
    SELECT
        SUM(monthly_charges)                                              AS total_mrr,
        SUM(CASE WHEN churned = 1 THEN monthly_charges ELSE 0 END)      AS mrr_lost,
        COUNT(*)                                                          AS total_customers,
        SUM(churned)                                                      AS churned_customers
    FROM vw_customer_full
)
SELECT
    ROUND(total_mrr, 2)                                   AS current_mrr,
    ROUND(mrr_lost, 2)                                    AS current_mrr_lost,
    ROUND(mrr_lost * 0.10, 2)                            AS mrr_saved_at_10pct_reduction,
    ROUND(mrr_lost * 0.20, 2)                            AS mrr_saved_at_20pct_reduction,
    ROUND(mrr_lost * 0.10 * 12, 2)                      AS annual_saving_10pct,
    ROUND(mrr_lost * 0.20 * 12, 2)                      AS annual_saving_20pct,
    ROUND(churned_customers * 0.10, 0)                  AS customers_saved_10pct
FROM baseline;

/*ARPU — average revenue per user, churned vs retained*/
SELECT
    CASE WHEN churned = 1 THEN 'Churned' ELSE 'Retained' END  AS status,
    COUNT(*)                                                    AS customers,
    ROUND(AVG(monthly_charges), 2)                           AS arpu_monthly,
    ROUND(AVG(monthly_charges) * 12, 2)                    AS arpu_annual,
    ROUND(MIN(monthly_charges), 2)                           AS min_charge,
    ROUND(MAX(monthly_charges), 2)                           AS max_charge,
    ROUND(SUM(monthly_charges), 2)                           AS total_mrr_contribution
FROM vw_customer_full
GROUP BY churned
ORDER BY churned DESC;

/*parameterised monthly churn report*/
DROP PROCEDURE IF EXISTS generate_churn_report;

DELIMITER //

CREATE PROCEDURE generate_churn_report (
    IN p_contract_type   VARCHAR(20),   -- pass 'Month-to-month', 'One year', 'Two year', or NULL for all
    IN p_min_tenure      INT,            -- minimum tenure months to include
    IN p_max_tenure      INT             -- maximum tenure months to include
)
BEGIN
    SELECT
        contract_type,
        internet_service,
        COUNT(*)                                      AS total_customers,
        SUM(churned)                                    AS churned_count,
        ROUND(SUM(churned) * 100.0 / COUNT(*), 2)   AS churn_rate_pct,
        ROUND(AVG(monthly_charges), 2)               AS avg_monthly_charge,
        ROUND(SUM(CASE WHEN churned = 1
               THEN monthly_charges ELSE 0 END), 2)  AS mrr_lost
    FROM vw_customer_full
    WHERE
        (p_contract_type IS NULL OR contract_type = p_contract_type)
        AND tenure_months BETWEEN p_min_tenure AND p_max_tenure
    GROUP BY contract_type, internet_service
    ORDER BY churn_rate_pct DESC;
END //

DELIMITER ;

-- HOW TO CALL IT:
-- All contract types, first year customers only:
CALL generate_churn_report(NULL, 0, 12);

-- Month-to-month only, all tenures:
CALL generate_churn_report('Month-to-month', 0, 72);

-- Two year contracts, long-tenure customers:
CALL generate_churn_report('Two year', 24, 72);
