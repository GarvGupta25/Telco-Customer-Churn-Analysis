# Telco-Customer-Churn-Analysis
A end-to-end SQL + Power BI project analysing customer retention for a  telecom business
The Business Problem
A telecom company is losing customers at a rate that is costing it over $139,000 in monthly recurring revenue. Leadership knows churn is high — but they don't know who is churning, when in the customer lifecycle it happens, or which product and billing decisions are driving it.
Without answers to these questions, the retention team is spending budget on broad campaigns with no targeting. The product team is investing in features without knowing which ones actually keep customers. Finance cannot model the revenue impact of any intervention.
This project answers three questions a product manager and data team would bring to a quarterly business review:

1. Which customer segments are churning, and by how much?
2. When in the customer lifecycle does churn peak — and is there a point of no return?
3. What is the dollar cost of churn, and what would a 10–20% reduction actually recover?
   
   <img width="593" height="338" alt="dashboardsnapshot" src="https://github.com/user-attachments/assets/4047f96a-0802-4a69-8ac3-d40e353cc2e9" />

   Key Findings
These are not just numbers — each finding maps directly to a product or business decision.
Finding 1 — Contract type is the single strongest predictor of churn

Contract Type     | Customers | Churn Rate | MRR Lost
------------------------------------------------------
Month-to-month    | 3,875     | 42.71%     | ~$100K+/month

One year          | 1,473     | 11.27%     | Moderate

Two year          | 1,695     | 2.83%      | Minimal

What this means: A customer on a month-to-month contract is 15× more likely to churn than a customer on a two-year contract. 
Every month a customer stays on month-to-month is a month they can leave with zero friction. The retention lever here is direct: incentivise annual plan adoption with a discount or added benefit at the 3-month mark.

Finding 2 — Nearly half of all churn happens in the first year

Tenure Cohort   | Churn Rate
-----------------------------
0–12 months     | 47.68%

13–24 months    | 28.66%

25–48 months    | 20.41%

49+ months      | 9.78%

What this means: If a customer survives their first 12 months, their probability of churning drops by more than half. The first year is the critical window. 
This points directly to an onboarding problem — customers are not finding enough value in the product early enough to stay.
A structured 90-day onboarding programme and proactive outreach at month 6 would target this window precisely.

Finding 3 — Fiber optic customers are churning at a premium price

Internet Service | Churn Rate | Avg Monthly Charge
---------------------------------------------------
Fiber optic      | 41.89%     | $91.49

DSL              | 18.96%     | $57.91

No internet      | 7.40%      | $30.72

What this means: The company's most expensive product has the worst retention. Customers paying nearly $92/month are churning at 41.89% — more than twice the rate of DSL customers. 
This is a classic premium dissatisfaction signal: customers expect high quality at a high price, and something is not meeting that expectation. This warrants an urgent product quality and NPS investigation specifically for fiber optic customers.

Finding 4 — The deadliest customer profile: month-to-month + fiber optic + electronic check

Churn rate: 64.41% across 586 customers

This specific combination — the highest-risk contract, highest-risk internet service, and lowest-commitment payment method — churns at nearly two-thirds.
This is not a small segment. These 586 customers represent a concentrated, targetable group. A single retention campaign aimed at this profile (auto-pay incentive + annual plan offer + proactive support call) would have measurable impact within one quarter.

Finding 5 — Add-on services are genuine retention tools

Add-on Services                                | Churn Rate
------------------------------------------------------------
0 add-ons                                      | 37.77%

1 add-on                                       | 25.90%

2 add-ons                                      | 19.74%

3 add-ons (security + backup + support)        | 14.82%

What this means: Each additional service reduces churn by roughly 8 percentage points. Product stickiness is real and measurable in this data.
This is evidence for the product team to prioritise bundle offers — not just as a revenue play, but as a retention mechanism.

Finding 6 — The revenue impact of fixing churn

Scenario               | Monthly MRR Recovered | Annual Impact
----------------------------------------------------------------
Reduce churn by 10%    | +$13,913/month        | +$166,956/year

Reduce churn by 20%    | +$27,826/month        | +$333,912/year

Any retention programme costing less than $166K per year produces positive ROI at a 10% churn reduction. This gives finance a clear threshold for budget approval.

Relational Schema
The raw CSV was normalised from a single flat file (21 columns, 7,043 rows) into a 4-table relational schema. 
Every table links to customers via customer_id as a foreign key.

<img width="565" height="421" alt="relational schema" src="https://github.com/user-attachments/assets/a7e69a5c-fac6-4073-92d5-ff143f54b0d6" />

Key design decisions:

TotalCharges was stored as a string in the source CSV with 11 blank values. 
All 11 had tenure = 0 (brand new customers, not yet billed). These were imputed to $0.00 — documented in 02_load_data.sql.
SeniorCitizen was stored as 0/1 integer in the source while all other binary columns were Yes/No strings. 
Normalised to TINYINT(1) with a CHECK constraint.
A vw_customer_full view joins all 4 tables — all 25 analysis queries run on this view, not on the raw tables.

Dataset

Source: IBM Telco Customer Churn — Kaggle
Size: 7,043 customers, 21 columns
Type: Cross-sectional snapshot — not time-series data
License: Open (Kaggle public dataset)

Why this dataset: The IBM Telco dataset is a well-known industry benchmark for churn analysis. 
It contains enough dimensional richness (demographics, services, billing, contract) to support multi-level segmentation without being so large that it requires infrastructure beyond a standard MySQL installation. 
The findings are directionally realistic for the telecom industry, making the business recommendations credible in a portfolio context


