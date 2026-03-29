CREATE DATABASE IF NOT EXISTS telco_churn;
USE telco_churn;
CREATE TABLE IF NOT EXISTS customers (
    customer_id     VARCHAR(20)     NOT NULL,
    gender          VARCHAR(10)     NOT NULL,
	senior_citizen  TINYINT(1)     NOT NULL DEFAULT 0,
	partner         VARCHAR(3)     NOT NULL,
	dependents      VARCHAR(3)     NOT NULL,
	tenure_months   INT           NOT NULL DEFAULT 0,
    CONSTRAINT pk_customers PRIMARY KEY (customer_id),
    CONSTRAINT chk_gender CHECK (gender IN ('Male', 'Female')),
    CONSTRAINT chk_senior CHECK (senior_citizen IN (0, 1)),
    CONSTRAINT chk_partner CHECK (partner IN ('Yes', 'No')),
    CONSTRAINT chk_dependents CHECK (dependents IN ('Yes', 'No')),
    CONSTRAINT chk_tenure CHECK (tenure_months >= 0));
    
    CREATE TABLE IF NOT EXISTS services (
    customer_id         VARCHAR(20)     NOT NULL,
    phone_service       VARCHAR(3)      NOT NULL,           
    multiple_lines      VARCHAR(20)     NOT NULL,          
    internet_service    VARCHAR(15)     NOT NULL,           
    online_security     VARCHAR(25)     NOT NULL,           
    online_backup       VARCHAR(25)     NOT NULL,
    device_protection   VARCHAR(25)     NOT NULL,
    tech_support        VARCHAR(25)     NOT NULL,
    streaming_tv        VARCHAR(25)     NOT NULL,
    streaming_movies    VARCHAR(25)     NOT NULL,
 
    CONSTRAINT pk_services PRIMARY KEY (customer_id),
    CONSTRAINT fk_services_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_phone CHECK (phone_service IN ('Yes', 'No')),
    CONSTRAINT chk_internet CHECK (internet_service IN ('DSL', 'Fiber optic', 'No'))
);
    
    CREATE TABLE IF NOT EXISTS contracts (
    customer_id         VARCHAR(20)     NOT NULL,
    contract_type       VARCHAR(20)     NOT NULL,           
    paperless_billing   TINYINT(1)      NOT NULL DEFAULT 0, 
    payment_method      VARCHAR(35)     NOT NULL,           
    monthly_charges     DECIMAL(8, 2)   NOT NULL,
    total_charges       DECIMAL(10, 2)  NULL,               
 
    CONSTRAINT pk_contracts PRIMARY KEY (customer_id),
    CONSTRAINT fk_contracts_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_contract_type CHECK (contract_type IN ('Month-to-month', 'One year', 'Two year')),
    CONSTRAINT chk_monthly_charges CHECK (monthly_charges >= 0),
    CONSTRAINT chk_total_charges CHECK (total_charges IS NULL OR total_charges >= 0)
);

CREATE TABLE IF NOT EXISTS churn (
    customer_id     VARCHAR(20)     NOT NULL,
    churned         TINYINT(1)      NOT NULL DEFAULT 0, 
 
    CONSTRAINT pk_churn PRIMARY KEY (customer_id),
    CONSTRAINT fk_churn_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_churned CHECK (churned IN (0, 1))
);

CREATE TABLE IF NOT EXISTS telco_raw (
    customerID          VARCHAR(20),
    gender              VARCHAR(10),
    SeniorCitizen       VARCHAR(5),
    Partner             VARCHAR(5),
    Dependents          VARCHAR(5),
    tenure              VARCHAR(10),
    PhoneService        VARCHAR(5),
    MultipleLines       VARCHAR(25),
    InternetService     VARCHAR(20),
    OnlineSecurity      VARCHAR(25),
    OnlineBackup        VARCHAR(25),
    DeviceProtection    VARCHAR(25),
    TechSupport         VARCHAR(25),
    StreamingTV         VARCHAR(25),
    StreamingMovies     VARCHAR(25),
    Contract            VARCHAR(25),
    PaperlessBilling    VARCHAR(5),
    PaymentMethod       VARCHAR(40),
    MonthlyCharges      VARCHAR(15),
    TotalCharges        VARCHAR(15),   telco_rawtelco_rawtelco_rawtelco_raw
    Churn               VARCHAR(5)
);
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
 
SELECT CONCAT('customers loaded: ', COUNT(*), ' rows') AS status FROM customers;  