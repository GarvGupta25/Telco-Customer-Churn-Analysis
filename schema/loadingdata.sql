INSERT INTO customers (
    customer_id,
    gender,
    senior_citizen,
    partner,
    dependents,
    tenure_months
)
SELECT
    customerID,
    gender,
    CAST(SeniorCitizen AS UNSIGNED),   
    Partner,
    Dependents,
    CAST(tenure AS UNSIGNED)
FROM telco_raw;
 
INSERT INTO services (
    customer_id,
    phone_service,
    multiple_lines,
    internet_service,
    online_security,
    online_backup,
    device_protection,
    tech_support,
    streaming_tv,
    streaming_movies
)
SELECT
    customerID,
    PhoneService,
    MultipleLines,
    InternetService,
    OnlineSecurity,
    OnlineBackup,
    DeviceProtection,
    TechSupport,
    StreamingTV,
    StreamingMovies
FROM telco_raw;
 
 INSERT INTO contracts (
    customer_id,
    contract_type,
    paperless_billing,
    payment_method,
    monthly_charges,
    total_charges
)
SELECT
    customerID,
    Contract,
    CASE WHEN PaperlessBilling = 'Yes' THEN 1 ELSE 0 END,
    PaymentMethod,
    CAST(MonthlyCharges AS DECIMAL(8,2)),
    COALESCE(NULLIF(TRIM(TotalCharges), ''), '0')
    FROM telco_raw;
 
 INSERT INTO churn (
    customer_id,
    churned
)
SELECT
    customerID,
    CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END
FROM telco_raw;
 




