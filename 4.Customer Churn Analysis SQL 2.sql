create database Customer_churn;
use Customer_churn;
select * from telco_clean;

-- I. Business KPIS
-- 1.total customers does the company have

select count(customerid) as total_customer
from telco_clean;
-- total customers 7043

-- 2.customers have churned versus stayed

select  churn, 
		count(*) as customercount, 
        round(count(*)*100/ (select count(*) from telco_clean),2) as percentage
from telco_clean
group by churn;

-- customers have churned- 26.54 versus stayed- 73.46

-- 3.overall customer churn rate

select round(sum(case when churn='Yes' then 1 else 0 end) *100/count(churn),2) as churnrate            -- churn rate= (churn customer/total customer) *100
from telco_clean;

-- customer churn rate-27%
       
-- 4.percentage of customers which are senior citizens?

SELECT
    SUM(CASE WHEN SeniorCitizen = 'Yes' THEN 1 ELSE 0 END)AS senior_citizens,
    ROUND(100.0 * SUM(CASE WHEN SeniorCitizen = 'Yes' THEN 1 ELSE 0 END)/ COUNT(*),2) AS senior_citizen_percentage
FROM telco_clean;

-- senior citizens- 16 %
-- 5.measuring the average monthly charges and total charges?

select round(avg(monthlycharges),2) as avg_monthly_charges, round(sum(totalcharges),2) as total_charges
from telco_clean;
-- average monthly charges= 64.76 and total charges= 16056168.7

-- II. Customer Churn Analysis
-- 6.Which contract type has the highest churn rate?

select contract, round(sum(case when churn ='Yes' then 1 else 0 end)*100 /count(*),2) as churn_rate
from telco_clean
group by contract
order by churn_rate desc
limit 1;
-- highest churn rate- month to month

-- 7.churn differ between month-to-month, one-year and two-year contracts?

select contract, 
	   sum(case when churn = 'yes' then 1 else 0 end) as churned_customer,
       round(sum(case when churn = 'yes' then 1 else 0 end)*100/ count(*),2) as churned_rate
from telco_clean
group by contract
order by churned_rate desc;
-- month-to-month= 42.72, one-year=11.27 and two-year=2.83 contracts

-- 8.payment method that has the highest churn rate-

select paymentmethod, 
	   sum(case when churn= 'yes' then 1 else 0 end) as churn_customer,
       round(sum(case when churn= 'yes' then 1 else 0 end)*100/count(*), 2) as Churn_rate
from telco_clean
group by paymentmethod
order by churn_rate desc
limit 1;
-- electronic check

-- 9.Do customers with paperless billing churn more often-

select paperlessbilling,
       count(*) as total_customer,
       sum(case when churn ='yes' then 1 else 0 end) as churn_customer,
       round(sum(case when churn ='Yes' then 1 else 0 end)*100/count(*) ,2) as churn_rate
from telco_clean
group by paperlessbilling
order by churn_rate desc;

-- yes 33.57%

-- 10. internet service type that has the highest churn rate

select internetservice, 
       sum(case when churn = 'yes' then 1 else 0 end) as churned_customer,
       round(sum(case when churn = 'yes' then 1 else 0 end)*100/count(*)) as churn_rate
from telco_clean
group by internetservice
order by churn_rate desc
limit 1;
-- internet service type that has the highest churn rate- 42%


-- III. Tenure and Customer Spending
-- 11. Do newer customers churn more often than long-term customers

SELECT CASE WHEN Tenure BETWEEN 0 AND 12 THEN '0-12 months'
            WHEN Tenure BETWEEN 13 AND 24 THEN '13-24 months'
            WHEN Tenure BETWEEN 25 AND 48 THEN '25-48 months'
            ELSE '49+ months'
            END AS tenure_group,
      COUNT(*) AS total_customers,
      SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END)* 100.0 / COUNT(*), 2) AS churn_rate
FROM telco_clean
GROUP BY CASE WHEN Tenure BETWEEN 0 AND 12 THEN '0-12 months'
              WHEN Tenure BETWEEN 13 AND 24 THEN '13-24 months'
              WHEN Tenure BETWEEN 25 AND 48 THEN '25-48 months'
              ELSE '49+ months' END
ORDER BY MIN(Tenure);

-- 12. average tenure of churned versus retained customers-

SELECT Churn,
       COUNT(*) AS total_customers,
	   ROUND(AVG(Tenure), 2) AS average_tenure_months
FROM telco_clean
GROUP BY Churn
ORDER BY Churn desc;


-- 13. tenure group that has the highest churn rate-

WITH tenure_churn AS ( SELECT CASE WHEN Tenure BETWEEN 0 AND 12 THEN '0-12 months'
                                   WHEN Tenure BETWEEN 13 AND 24 THEN '13-24 months'
                                   WHEN Tenure BETWEEN 25 AND 48 THEN '25-48 months'
								   ELSE '49+ months'
                                   END AS tenure_group,
							  COUNT(*) AS total_customers,
                              SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
						      ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END)* 100.0 / COUNT(*), 2) AS churn_rate
                      FROM telco_clean
                      GROUP BY CASE
            WHEN Tenure BETWEEN 0 AND 12 THEN '0-12 months'
            WHEN Tenure BETWEEN 13 AND 24 THEN '13-24 months'
            WHEN Tenure BETWEEN 25 AND 48 THEN '25-48 months'
            ELSE '49+ months'
        END
)
SELECT
    tenure_group,
    total_customers,
    churned_customers,
    churn_rate,
    DENSE_RANK() OVER (ORDER BY churn_rate DESC) AS churn_rank
FROM tenure_churn
ORDER BY churn_rank;

-- Q14. customers paying higher monthly charges churn more often or not

WITH charge_churn AS (
    SELECT CASE WHEN MonthlyCharges < 35 THEN 'Low charges (<35)'
                WHEN MonthlyCharges < 70 THEN 'Medium charges (35-69.99)'
                ELSE 'High charges (70+)' END AS charge_group,
                COUNT(*) AS total_customers,
                SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
                ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END)* 100.0 / COUNT(*), 2) AS churn_rate
    FROM telco_clean
    GROUP BY CASE WHEN MonthlyCharges < 35 THEN 'Low charges (<35)'
                  WHEN MonthlyCharges < 70 THEN 'Medium charges (35-69.99)'
                  ELSE 'High charges (70+)' END)
SELECT *
FROM charge_churn
ORDER BY churn_rate DESC;

-- 15. average total charge for churned versus retained customers

select churn, 
	   count(*) as total_churn, 
       round(avg(totalcharges) ,2) as avg_total_charges
from telco_clean
group by churn
order by churn;

-- average total charge for churned versus retained customers- 2549.91

-- IV.Services and Customer Behaviour (Business based)
-- 16.Do customers without tech support have a higher churn rate?
  
  SELECT
    TechSupport,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END)
        AS churned_customers,
    ROUND(
        100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS churn_rate
FROM telco_clean
GROUP BY TechSupport
ORDER BY churn_rate DESC;

-- 17.Is churn different for customers with and without online security?

SELECT
    OnlineSecurity,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(
        100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END)
        / COUNT(*), 2
    ) AS churn_rate
FROM telco_clean
GROUP BY OnlineSecurity
ORDER BY churn_rate DESC;
-- 18.Does having multiple lines relate to churn?

 SELECT
    MultipleLines,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(
        100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END)
        / COUNT(*), 2
    ) AS churn_rate
FROM telco_clean
GROUP BY MultipleLines
ORDER BY churn_rate DESC;
-- Yes — customers with multiple phone lines.

-- 19.Which combination of internet service and contract type has the highest churn rate?
 
select internetservice, 
	   contract, 
       count(*) as total_customers,
       sum(case when churn= 'yes' then 1 else 0 end) as churned_customers,
       round(sum(case when churn= 'yes' then 1 else 0 end)*100 /count(*) ,2) as churn_rate
from telco_clean
group by internetservice,
		 contract
order by churn_rate desc;

-- 20.Which customer groups have above-average churn rates?

WITH overall_churn AS (
    SELECT
        AVG(CASE WHEN Churn = 'Yes' THEN 1.0 ELSE 0.0 END)* 100 AS avg_churn_rate
    FROM telco_clean
),
group_churn AS (
    SELECT
        Contract,
        InternetService,
        COUNT(*) AS total_customers,
        SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END)AS churned_customers,
        ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END)* 100.0 / COUNT(*), 2) AS churn_rate
    FROM telco_clean
    GROUP BY Contract, InternetService
)
SELECT
    gc.Contract,
    gc.InternetService,
    gc.total_customers,
    gc.churned_customers,
    gc.churn_rate
FROM group_churn gc
CROSS JOIN overall_churn oc
WHERE gc.churn_rate > oc.avg_churn_rate
ORDER BY gc.churn_rate DESC;

-- 21. Rank contract types by churn rate.

 select * from telco_clean;
 
with contract_churn as (select contract, 
							   count(*) as total_customers,
                               sum(case when churn= 'yes' then 1 else 0 end) as churned_customers,
                               round(sum(case when churn ='yes' then 1 else 0 end)*100/count(*) ,2) as churn_rate
						from telco_clean
                        group by contract)
select contract,
	   total_customers,
       churned_customers,
       churn_rate,
       dense_rank() over(order by churn_rate desc) as churn_rank
from contract_churn
order by churn_rate asc;

-- 22. Find the top three customer segments by churn rate, with a minimum customer count.

WITH segment_churn AS (
    SELECT
        Contract,
        InternetService,
        COUNT(*) AS total_customers,
        SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
        ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END)* 100.0 / COUNT(*),2) AS churn_rate
    FROM telco_clean
    GROUP BY Contract, InternetService
    HAVING COUNT(*) >= 100
),
ranked_segments AS (
    SELECT
        Contract,
        InternetService,
        total_customers,
        churned_customers,
        churn_rate,
        DENSE_RANK() OVER (ORDER BY churn_rate DESC) AS churn_rank
    FROM segment_churn
)
SELECT
    Contract,
    InternetService,
    total_customers,
    churned_customers,
    churn_rate,
    churn_rank
FROM ranked_segments
WHERE churn_rank <= 3
ORDER BY churn_rank;

-- 23.Compare each segment's churn rate with the overall company churn rate.
WITH overall_churn AS (
    SELECT
        AVG(
            CASE WHEN Churn = 'Yes' THEN 1.0 ELSE 0.0 END
        ) * 100 AS overall_churn_rate
    FROM telco_clean
),
contract_churn AS (
    SELECT
        Contract,
        COUNT(*) AS total_customers,
        SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
        SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END)* 100.0 / COUNT(*) AS churn_rate
    FROM telco_clean
    GROUP BY Contract
)
SELECT
    cc.Contract,
    cc.total_customers,
    cc.churned_customers,
    ROUND(cc.churn_rate, 2) AS churn_rate,
    ROUND(oc.overall_churn_rate, 2) AS overall_churn_rate,
    ROUND(cc.churn_rate - oc.overall_churn_rate, 2) AS difference_in_percentage_points,
    ROUND((cc.churn_rate - oc.overall_churn_rate)/ NULLIF(oc.overall_churn_rate, 0) * 100,2) AS relative_difference_percent
FROM contract_churn cc
CROSS JOIN overall_churn oc
ORDER BY cc.churn_rate DESC;

-- 24.Find customer groups with higher-than-average monthly charges and churn rates

WITH company_benchmarks AS (
    SELECT
        AVG(MonthlyCharges) AS avg_monthly_charges,
        AVG(CASE WHEN Churn = 'Yes' THEN 1.0 ELSE 0.0 END) * 100 AS overall_churn_rate
    FROM telco_clean
),
customer_groups AS (
    SELECT
        Contract,
        InternetService,
        COUNT(*) AS total_customers,
        ROUND(AVG(MonthlyCharges), 2) AS avg_monthly_charges,
        SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END)AS churned_customers,
        SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END)* 100.0 / COUNT(*) AS churn_rate
    FROM telco_clean
    GROUP BY Contract, InternetService
)
SELECT
    cg.Contract,
    cg.InternetService,
    cg.total_customers,
    cg.avg_monthly_charges,
    ROUND(cb.avg_monthly_charges, 2) AS company_avg_monthly_charges,
    ROUND(cg.churn_rate, 2) AS churn_rate,
    ROUND(cb.overall_churn_rate, 2) AS overall_churn_rate
FROM customer_groups cg
CROSS JOIN company_benchmarks cb
WHERE cg.avg_monthly_charges > cb.avg_monthly_charges
  AND cg.churn_rate > cb.overall_churn_rate
ORDER BY cg.churn_rate DESC;

-- 25.Identify combinations of customer characteristics associated with high churn

SELECT
    Contract,
    InternetService,
    PaperlessBilling,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END)
        AS churned_customers,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END)* 100.0 / COUNT(*),2) AS churn_rate
FROM telco_clean
GROUP BY
    Contract,
    InternetService,
    PaperlessBilling
HAVING COUNT(*) >= 100
ORDER BY churn_rate DESC
LIMIT 10;

-- 1. Total rows
SELECT COUNT(*) AS total_rows
FROM telco_clean;

-- 2. Unique customers
SELECT COUNT(DISTINCT customerID) AS unique_customers
FROM telco_clean;

-- 3. Check for duplicate customer IDs
SELECT customerID, COUNT(*) AS record_count
FROM telco_clean
GROUP BY customerID
HAVING COUNT(*) > 1;

-- 4. Check churn labels
SELECT Churn, COUNT(*) AS customer_count
FROM telco_clean
GROUP BY Churn;

-- 5. Check important numerical ranges
SELECT
    MIN(Tenure) AS min_tenure,
    MAX(Tenure) AS max_tenure,
    MIN(MonthlyCharges) AS min_monthly_charges,
    MAX(MonthlyCharges) AS max_monthly_charges,
    MIN(TotalCharges) AS min_total_charges,
    MAX(TotalCharges) AS max_total_charges
FROM telco_clean;

-- Duplicate check
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customerID) AS unique_customers
FROM
    telco_clean;

-- Churn labels
SELECT Churn, COUNT(*) AS customer_count
FROM telco_clean
GROUP BY Churn;

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN TotalCharges IS NULL THEN 1 ELSE 0 END) AS null_total_charges,
    SUM(CASE WHEN TotalCharges = 0 THEN 1 ELSE 0 END) AS zero_total_charges,
    SUM(CASE WHEN Tenure = 0 THEN 1 ELSE 0 END) AS zero_tenure_customers,
    SUM(CASE WHEN Tenure = 0 AND TotalCharges = 0 THEN 1 ELSE 0 END)
        AS both_zero
FROM telco_clean;

SELECT customerID, Tenure, MonthlyCharges, TotalCharges
FROM telco_clean
WHERE TotalCharges = 0 AND Tenure > 0;

SELECT customerID, Tenure, MonthlyCharges, TotalCharges
FROM telco_clean
WHERE TotalCharges = 0
  AND Tenure > 0;