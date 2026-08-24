# SQL-Power-BI---Global-Customer-Churn-Retention-Analytics-using-SQL-Power-BI
End-to-end churn and retention analytics project for an international subscription business — from raw relational data in SQL Server to a fully interactive Power BI dashboard suite.

📌 Project Overview
Customer churn quietly erodes revenue in every subscription business. This project simulates a realistic international subscriber base (55,000 customers across 30 countries) and builds a complete analytics pipeline to identify who is churning, why, and how much revenue is at risk — so a retention team can act on it, not just report on it.

🎯 Business Questions Answered
What is the overall churn rate, and how does it vary by country, contract type, and plan?
Which customers are the highest churn risk right now?
How much revenue is at risk from customers in their churn month?
Which acquisition channels bring in customers who stay longest and spend the most?
How does retention change as tenure increases (cohort-style analysis)?

🧱 Data Architecture
Star-schema model, 1.37M+ rows total:
Table	Rows	Grain
Dim_Customers	55,000	1 row per customer
Fact_MonthlyActivity	1,320,680	1 row per customer per active month
Dim_Date	~1,460	1 row per calendar day

Relationships: Dim_Customers[CustomerID] (1) → Fact_MonthlyActivity[CustomerID] () · Dim_Date[Date] (1) → Fact_MonthlyActivity[ActivityYearMonth] ()

🛠️ Tech Stack
Layer	Tools
Database	SQL Server (T-SQL, BULK INSERT, CTEs, window functions)
Modeling	Power BI (Power Query, star schema, DAX)
Visualization	Power BI (3-page interactive dashboard)

📊 Dashboard Pages
Executive Overview — headline KPIs, revenue trend, churn reasons, churn by contract type, regional breakdown
Churn Intelligence — high-risk customer watchlist, satisfaction vs. NPS, churn-driver heatmap, retention-by-tenure curve
Customer Value Analysis — revenue trend & MoM growth, CLV, revenue-at-risk, acquisition-channel performance

📈 Key Outcomes
26.05% churn rate / 73.95% retention across the full customer base
$31.5M+ in tracked revenue, with $344K+ flagged as revenue at risk (billing tied to customers in their churn month)
Month-to-month contracts churn at 38.6% vs. 6.3% for two-year contracts — the clearest lever for retention strategy
"Price too high" and "better competitor offer" are the top two churn drivers, together accounting for 5,200+ lost customers
Built a repeatable High-Risk Customer view (low satisfaction + month-to-month) for proactive outreach
Estimated Customer Lifetime Value (CLV) and tenure-based retention curve to quantify long-term customer value

🗂️ Repo Contents
├── data/
│   ├── Dim_Customers.csv
│   └── Fact_MonthlyActivity.csv
├── sql/
│   ├── 01_create_tables.sql
│   ├── 02_load_data.sql
│   └── 03_dashboard_queries.sql
├── powerbi/
│   └── Global_Churn_Retention_Dashboard.pbix
├── docs/
│   └── SQL_PowerBI_Project_Guide.md
└── README.md

🚀 How to Reproduce
Run sql/01_create_tables.sql in SQL Server to create the schema
Run sql/02_load_data.sql (BULK INSERT) to load both CSVs
Open the .pbix file in Power BI Desktop and point the SQL Server connection to your instance
Refresh — all measures and visuals rebuild automatically

📬 Connect
Built by Ankur Verma — Data Analyst & BI Consultant (SQL Server · Power BI · Tableau · Advanced Excel) LinkedIn · Portfolio
