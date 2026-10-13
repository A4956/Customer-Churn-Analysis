Customer Churn Analysis: From Raw Data to a Retention Dashboard

Tools: Python (pandas, scikit-learn) · MySQL · Power BI (DAX) · Google Colab

One-line summary: I analysed 7,043 telecom customers to find who is leaving and why, built a model that scores every customer's churn risk, and turned the results into a 4-page Power BI dashboard that points the retention team to 666 active high-risk customers worth about 53.5K in monthly revenue.

1. The Story

A telecom company has 7,043 customers on its books, and 1,869 of them (26.5%) have left. Every departure takes monthly revenue with it, and the company must spend again on marketing and sales just to replace the customer. A leak like this quietly slows growth, even when new sign-ups keep arriving.

The business is asking three questions:

How big is the churn problem, and what does it cost?
Which customers leave, and what do they have in common?
Who is likely to leave next, so we can act before they go?

Replacing a customer is generally more expensive than keeping one, so this project answers each question in turn: it measures the problem, finds the drivers behind it, and ends with a ranked list of customers the retention team should contact first.

The project follows the work in the order an analyst would do it:

Raw CSV  ->  Python cleaning  ->  MySQL (25 business queries)  ->  Python EDA + ML model  ->  Power BI dashboard
2. Problem Statement

Business problem: The company is losing customers at a rate that hurts revenue, and it does not know which customers are most at risk or why they leave.

Objectives

Measure churn and the revenue it removes
Identify the customer segments and behaviours linked to churn
Predict churn risk for every customer
Recommend actions the retention team can take, and size the revenue they protect

Definition of churn: a customer is counted as churned when Churn = Yes in the dataset (the customer left within the last month).

3. Data Source
Item	Detail
Dataset	IBM Telco Customer Churn (sample dataset)
Source	Kaggle: Telco Customer Churn
Size	7,043 customers, 21 columns
Grain	One row per customer
Target	Churn (Yes / No)

Column groups

Demographics: gender, SeniorCitizen, Partner, Dependents
Account: tenure, Contract, PaperlessBilling, PaymentMethod
Services: PhoneService, MultipleLines, InternetService, OnlineSecurity, OnlineBackup, DeviceProtection, TechSupport, StreamingTV, StreamingMovies
Charges: MonthlyCharges, TotalCharges
Target: Churn

The dataset does not state a currency, so charges are shown in the dataset's own units.

4. Data Preparation
4.1 Cleaning in Python (Google Colab)
Issue found	Column	Rows	Action	Reason
Blank spaces stored as text, so the column loaded as text and isnull() showed 0 nulls	TotalCharges	11	Converted to numeric and filled with 0	All 11 customers have tenure = 0 and Churn = No: they are new and not yet billed
Duplicate rows	all	0	None needed	Checked with duplicated()
True null values	all	0	None needed	Checked with isnull()
Target stored as text	Churn	all	Added Churn_flag (1 = churned, 0 = retained)	Allows averages and modelling
Inconsistent format (0/1 vs Yes/No)	SeniorCitizen	all	Mapped to No / Yes	Matches the other Yes/No columns

Result: a cleaned file with 7,043 rows and 22 columns (telco_clean.csv).

4.2 Validation in SQL (MySQL)

The cleaned file was loaded into MySQL as telco_clean, and the following checks confirmed the load: 7,043 total rows, 7,043 unique customer IDs, no duplicate IDs, correct Yes/No churn labels, sensible ranges for tenure and charges, and a check that every customer with TotalCharges = 0 also has tenure = 0.

4.3 Feature engineering (Python)
New column	How it is built	Purpose
tenure_band	Groups tenure into 0-12, 13-24, 25-48, 49+ months	Shows how churn changes as customers stay longer
addon_count	Number of the 6 add-on services a customer has (0 to 6)	Measures how deeply a customer uses the services
churn_probability	Predicted chance of leaving, from the model	Ranks customers by risk
risk_segment	Low (up to 0.40), Medium (0.40 to 0.70), High (above 0.70)	Makes the score easy to act on
5. Data Modelling
5.1 Machine learning model
Step	Choice
Features	All customer attributes, with text columns converted to 0/1 (one-hot encoding), plus addon_count
Excluded	customerID (an identifier) and the churn columns (they are the answer)
Split	80% train, 20% test, stratified so both keep the same 26.5% churn share (random_state=42)
Imbalance	class_weight="balanced", because only about 1 in 4 customers churns
Final model	Logistic regression (with standard scaling)
Comparison model	Random forest (300 trees)

Results on the test set

Metric	Logistic regression	Random forest
ROC-AUC	0.843	about 0.84
Recall (churners)	about 0.78	about 0.74
Precision (churners)	about 0.51	about 0.55

Both models performed about the same. Logistic regression was chosen because its results are easier to explain to a business audience, and it catches slightly more of the customers who really leave.

Does the risk score work? Comparing the segments with what really happened:

Risk segment	Customers	Actually churned
Low	3,589	6.7%
Medium	1,670	30.5%
High	1,784	62.7%
5.2 Power BI data model

The model is a single flat table plus a small metrics table, so no relationships are needed.

Table	Rows	Contents
Churn_Dataset	7,043	All 21 original columns, Churn_flag, tenure_band, addon_count, churn_probability, risk_segment (26 columns)
Model metrics	1	ROC_AUC = 0.843
6. Data Analysis
6.1 SQL analysis (MySQL)

25 business questions, grouped into four areas:

Area	Examples
Business KPIs	Total customers, churned vs retained, overall churn rate, senior citizen share, average charges
Churn analysis	Churn by contract, payment method, paperless billing, internet service
Tenure and spending	Churn by tenure group, average tenure of churned vs retained, churn by charge band
Services and segments	Tech support, online security, multiple lines, contract and internet combinations, top segments with a minimum size, above-average groups, comparison with the company average

Techniques used: GROUP BY with CASE WHEN, CTEs, window functions (DENSE_RANK), subqueries, CROSS JOIN against a benchmark, and HAVING to remove small groups.

6.2 DAX measures (Power BI)
DAX
total_customers = COUNTROWS(Churn_Dataset)

Churn Rate = AVERAGE(Churn_Dataset[Churn_flag])

Retention Rate = 1 - [Churn Rate]

Churned Customers = CALCULATE([total_customers], Churn_Dataset[Churn] = "Yes")

Revenue Lost = CALCULATE(SUM(Churn_Dataset[MonthlyCharges]),
                         Churn_Dataset[Churn] = "Yes")

High Risk Customers = CALCULATE(COUNTROWS(Churn_Dataset),
                                Churn_Dataset[Churn] = "No",
                                Churn_Dataset[risk_segment] = "High")

Revenue at Risk = CALCULATE(SUM(Churn_Dataset[MonthlyCharges]),
                            Churn_Dataset[Churn] = "No",
                            Churn_Dataset[risk_segment] = "High")

Average Churn Probability = AVERAGE(Churn_Dataset[churn_probability])
Measure	What it tells the business
Churn Rate	Share of customers who left (works because Churn_flag is 1 or 0)
Revenue Lost	Monthly revenue that left with the churned customers
High Risk Customers	Customers still with the company who look like past churners
Revenue at Risk	Monthly revenue those customers represent

Note that High Risk Customers and Revenue at Risk filter on Churn = "No", so they count only active customers.

7. Data Visualization (Dashboard)

The dashboard has 4 pages, ordered from the big picture to action.

Page	Purpose	Main visuals
Home	Introduces the project and navigates	Project title, short problem summary, page navigator
<img width="1157" height="647" alt="Home" src="https://github.com/user-attachments/assets/c70db7a3-0ccd-454c-af04-fb119e127fcb" />


Overview	How big is the problem?	Cards (total customers, churn rate, revenue lost, revenue at risk, high-risk customers), churned vs retained donut,
revenue lost by contract, churn rate by contract and by tenure band, slicers
The company has 7,043 customers, and 26.5% of them (1,869) have left. Those customers took 30.5% of monthly revenue with them (139K), and 87% of that loss came from month-to-month contracts. Churn is also worst early on, at 47% in the first year. So the problem is large, and it is concentrated in one kind of customer.
<img width="1142" height="657" alt="Over View" src="https://github.com/user-attachments/assets/ac5cd97c-b838-44b7-a954-2b9ce26aa140" />

Customer Churn Analysis:	
Why do customers leave?	Churn rate by payment method, tech support and internet service; customers by contract and churn; segment detail table; slicers for internet service, senior citizen, risk, tenure, payment method, online security.
The same customers share a pattern. They are on month-to-month plans (42.7% churn), pay by electronic check (45.3%), use fiber optic (41.9%), and have no tech support (41.6%) or online security (41.8%). Customers on longer contracts or with support services rarely leave (3% to 15%). So the leavers can be recognised by their profile.
<img width="1147" height="657" alt="Customer Churn analysis" src="https://github.com/user-attachments/assets/fb00c146-1f0a-4afb-819b-da3e587d2e29" />


ML Prediction and Customer Risk Analysis: 
Who is likely to leave next?	Cards (customers scored, high-risk customers, average churn probability, model ROC-AUC), customer risk distribution donut, high-risk customers by contract, and a table of active high-risk customers to contact. 
A model (ROC-AUC 0.843) scores every customer’s risk. About 63% of those marked High-risk really did churn, against 7% of Low-risk. Of the customers still with the company, 666 are high-risk, worth about 53.5K per month, and 662 of them are month-to-month. That gives the retention team a named list to contact first.
<img width="1142" height="662" alt="ML prediction" src="https://github.com/user-attachments/assets/edac231a-29c9-464e-9e04-52511c9204ee" />



Show Image Show Image Show Image

8. Insights
How big is the problem
26.54% of customers churned (1,869 of 7,043).
Churned customers represent 139,131 of 456,117 monthly revenue (30.5%), which is higher than the customer churn rate because they pay more per month (74.44 vs 61.27 on average).
Who leaves, and what do they have in common
Driver	Higher churn	Lower churn
Contract	Month-to-month: 42.7%	One year: 11.3%, two year: 2.8%
Tenure	0-12 months: 47.4%	49+ months: 9.5%
Payment method	Electronic check: 45.3%	Other methods: 15.2% to 19.1%
Internet service	Fiber optic: 41.9%	DSL: 19.0%, no internet: 7.4%
Tech support	No tech support: 41.6%	With tech support: 15.2%
Online security	No online security: 41.8%	With online security: 14.6%
Senior citizen	Senior: 41.7%	Non-senior: 23.6%
Billing	Paperless: 33.6%	Paper: 16.3%
Month-to-month customers drive the loss: they account for 1,655 of the 1,869 churners (88.5%) and 86.9% of the revenue lost.
The first year is the danger zone. Churned customers stayed an average of 18.0 months, against 37.6 months for customers who stayed.
Who will leave next
The model's ROC-AUC is 0.843, and its risk groups match reality: about 63% of customers scored High actually churned, against about 7% of those scored Low.
666 active customers are scored High-risk. They pay 53,462 per month (about 641,500 per year), and 662 of the 666 are on month-to-month contracts.
9. Recommendations
#	Recommendation	Based on
1	Move month-to-month customers to annual contracts, using discounts or perks, starting with the 662 high-risk month-to-month customers	Month-to-month churn is 42.7% vs 2.8% for two-year contracts, and it holds 87% of lost revenue
2	Focus on the first 12 months: a welcome and check-in programme for new customers, especially in the first 3 to 6 months	47.4% churn in months 0-12
3	Bundle tech support and online security into fiber plans or offer them free for a trial period	Customers without them churn at about 42%, with them about 15%
4	Move customers from electronic check to automatic payment with a small incentive	Electronic check churn is 45.3% vs 15% to 19% for others
5	Review the fiber optic offer (price, speed, reliability, support)	Fiber churn is 41.9% vs 19.0% for DSL, and fiber customers pay more
6	Use the risk list: contact the 666 active high-risk customers first, instead of the whole base	Risk segments are validated against actual churn

What the 666 customers are worth (illustrative): if a retention campaign saved 20% of them, about 133 customers, it would protect roughly 10.7K per month, or about 128K per year. The 20% rate is an assumption for planning, not a result from the data.

10. Limitations and Next Steps

Limitations

The drivers show association, not cause. For example, the data cannot tell us whether fiber customers leave because of price, quality, or competitors.
The risk scores were produced for all 7,043 customers, including the 80% the model trained on, so the segment results look slightly better than they would for new customers.
The dataset is a single snapshot of a sample company, with no costs, dates or competitor data.
About half of the customers the model flags do not actually leave (precision about 0.51), which is acceptable for a low-cost retention offer but not for an expensive one.

Possible next steps

Explain individual predictions with SHAP values
Choose the risk cut-off using retention cost versus customer value
Group customers with K-Means to build named personas
Add a "churn rate by risk segment" chart to the dashboard to show the model's accuracy
11. Repository Structure
customer-churn-analysis/
├── data/
│   ├── 1_Telco-Customer-Churn_Raw_DATA.csv
│   ├── 3_telco_clean.csv
│   └── 5_churn_scored_after_eda_and_ml_.csv
├── notebooks/
│   ├── 2_Customer_churn_analysis_cleanning_python.ipynb
│   └── (add your EDA and ML notebook here)
├── sql/
│   └── 4_Customer_Churn_Analysis_SQL_2.sql
├── dashboard/
│   ├── 6_Customer_Churn_Analysis_Dashboard.pbix
│   └── screenshots/
└── README.md
