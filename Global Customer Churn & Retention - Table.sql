CREATE DATABASE ChurnRetentionDB
USE ChurnRetentionDB

CREATE TABLE Dim_Customers (
    CustomerID          INT PRIMARY KEY,
    CustomerName         NVARCHAR(100),
    Gender               NVARCHAR(20),
    Age                  INT,
    Country              NVARCHAR(50),
    Region               NVARCHAR(50),
    Currency             NVARCHAR(10),
    SignupDate           DATE,
    ContractType         NVARCHAR(30),
    PaymentMethod        NVARCHAR(30),
    PlanType             NVARCHAR(30),
    DeviceType           NVARCHAR(30),
    AcquisitionChannel   NVARCHAR(30),
    MonthlyCharges       DECIMAL(10,2),
    TotalCharges         DECIMAL(10,2),
    TenureMonths         INT,
    IsChurned            TINYINT,
    ChurnDate            DATE NULL,
    ChurnReason          NVARCHAR(50) NULL,
    SatisfactionScore    INT,
    NPS_Score            INT,
    SupportTicketsRaised INT
)

CREATE TABLE Fact_MonthlyActivity (
    ActivityID           BIGINT PRIMARY KEY,
    CustomerID            INT NOT NULL,
    ActivityYearMonth     DATE,
    PlanType              NVARCHAR(30),
    BilledAmount          DECIMAL(10,2),
    DataUsageGB           DECIMAL(10,1),
    LoginCount             INT,
    SupportCallsRaised    INT,
    PaymentStatus         NVARCHAR(20),
    IsChurnMonth          TINYINT,
    CONSTRAINT FK_Fact_Customer FOREIGN KEY (CustomerID) REFERENCES Dim_Customers(CustomerID)
)

SELECT * FROM DBO.Dim_Customers

SELECT * FROM DBO.Fact_MonthlyActivity

SELECT COUNT(*) FROM DBO.Dim_Customers

SELECT COUNT(*) FROM DBO.Fact_MonthlyActivity

SELECT TOP 5 * FROM Dim_Customers

SELECT TOP 5 * FROM Fact_MonthlyActivity

SELECT
    SUM(CAST(IsChurned AS INT)) * 1.0 / COUNT(*) AS ChurnRate
FROM Dim_Customers


-- Page 1 - EXECUTIVE OVERVIEW
-- 1. KPI Cards: Customers, Churn Rate, Retention Rate, Revenue, Avg NPS

SELECT
    COUNT(*)                                                        AS Customers,
    ROUND(SUM(CAST(IsChurned AS FLOAT)) * 100.0 / COUNT(*), 2)      AS ChurnRatePct,
    ROUND(100 - (SUM(CAST(IsChurned AS FLOAT)) * 100.0 / COUNT(*)), 2) AS RetentionRatePct,
    (SELECT SUM(BilledAmount) FROM dbo.Fact_MonthlyActivity)        AS TotalRevenue,
    ROUND(AVG(CAST(NPS_Score AS FLOAT)), 2)                         AS AvgNPS
FROM dbo.Dim_Customers

-- 2. "Revenue & Active Customers" trend chart (by month)

SELECT
    FORMAT(ActivityYearMonth, 'yyyy-MM')   AS YearMonth,
    SUM(BilledAmount)                      AS TotalRevenue,
    COUNT(DISTINCT CustomerID)             AS ActiveCustomers
FROM dbo.Fact_MonthlyActivity
GROUP BY FORMAT(ActivityYearMonth, 'yyyy-MM')
ORDER BY YearMonth

-- 3. "Customer Status" donut (Active vs Churned)
SELECT  
    CASE WHEN IsChurned = 1 THEN 'Churned' ELSE 'Active' END AS CustomerStatus,
    COUNT(*)                                                 AS CustomerCount,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)       AS Percentage
FROM DBO.Dim_Customers
GROUP BY CASE WHEN IsChurned = 1 THEN 'Churned' ELSE 'Active' END

-- 4. "Churn Reasons" ranked list
SELECT
    ChurnReason,
    COUNT(*) AS ChurnCount
FROM DBO.Dim_Customers
WHERE IsChurned = 1
GROUP BY ChurnReason
ORDER BY ChurnCount DESC
GO

-- 5. "Revenue by Plan"
SELECT
    PlanType,
    SUM(BilledAmount) AS Revenue
FROM DBO.Fact_MonthlyActivity
GROUP BY PlanType
ORDER BY Revenue DESC

-- 6. "Churn by Contract" (%)
SELECT
    ContractType,
    COUNT(*)                                            AS TotalCustomer,
    SUM(CAST(IsChurned AS INT))                         AS ChurnedCustomers,
    ROUND(SUM(CAST(IsChurned AS float)) * 100.0 / COUNT(*), 2) AS ChurnRatepct
FROM DBO.Dim_Customers
GROUP BY ContractType
ORDER BY ChurnRatepct DESC

-- 7. Region slicer breakdown (Customers + Churn Rate by Region)
SELECT
    Region,
    COUNT(*)                                                  AS TotalCustomers,
    ROUND(SUM(CAST(IsChurned AS FLOAT)) * 100.0 / COUNT(*), 2) AS ChurnRatePct
FROM dbo.Dim_Customers
GROUP BY Region
ORDER BY TotalCustomers DESC

-- PAGE 2 — CHURN INTELLIGENCE
-- 1. KPI Cards: Churned Customers, Churn Rate, Avg Satisfaction, Avg NPS
SELECT
    SUM(CAST(IsChurned AS INT))                                AS ChurnedCustomers,
    ROUND(SUM(CAST(IsChurned AS FLOAT)) * 100.0 / COUNT(*), 2)  AS ChurnRatePct,
    ROUND(AVG(CAST(SatisfactionScore AS FLOAT)), 2)             AS AvgSatisfaction,
    ROUND(AVG(CAST(NPS_Score AS FLOAT)), 2)                     AS AvgNPS
FROM dbo.Dim_Customers;

-- 2. (HighRiskFlag was a DAX calculated column — here we replicate the same logic in SQL)
SELECT
    CustomerName,
    Country,
    ContractType,
    PlanType,
    TenureMonths,
    SatisfactionScore,
    NPS_Score,
    SupportTicketsRaised,
    'High Risk' AS HighRiskFlag
FROM dbo.Dim_Customers
WHERE SatisfactionScore <= 2
  AND ContractType = 'Month-to-Month'
ORDER BY CustomerName

-- 3. "Satisfaction vs NPS" scatter (aggregated: count of customers per score, split by status)
SELECT
    SatisfactionScore,
    CASE WHEN IsChurned = 1 THEN 'Churned' ELSE 'Active' END AS ChurnStatus,
    COUNT(*)                                                 AS CustomerCount
FROM dbo.Dim_Customers
GROUP BY SatisfactionScore, CASE WHEN IsChurned = 1 THEN 'Churned' ELSE 'Active' END
ORDER BY SatisfactionScore

-- 4. "Churn Drivers" (same as Churn Reasons on Page 1 — repeated here for this page)
SELECT
    ChurnReason,
    COUNT(*) AS ChurnCount
FROM dbo.Dim_Customers
WHERE IsChurned = 1
GROUP BY ChurnReason
ORDER BY ChurnCount DESC

-- 5. "Churn Driver Heatmap" — ContractType x PlanType churn rate matrix
SELECT
    ContractType,
    ROUND(SUM(CASE WHEN PlanType = 'Basic'      THEN CAST(IsChurned AS FLOAT) END) * 100.0
        / NULLIF(SUM(CASE WHEN PlanType = 'Basic'      THEN 1 END), 0), 2) AS Basic,
    ROUND(SUM(CASE WHEN PlanType = 'Enterprise' THEN CAST(IsChurned AS FLOAT) END) * 100.0
        / NULLIF(SUM(CASE WHEN PlanType = 'Enterprise' THEN 1 END), 0), 2) AS Enterprise,
    ROUND(SUM(CASE WHEN PlanType = 'Premium'    THEN CAST(IsChurned AS FLOAT) END) * 100.0
        / NULLIF(SUM(CASE WHEN PlanType = 'Premium'    THEN 1 END), 0), 2) AS Premium,
    ROUND(SUM(CASE WHEN PlanType = 'Standard'   THEN CAST(IsChurned AS FLOAT) END) * 100.0
        / NULLIF(SUM(CASE WHEN PlanType = 'Standard'   THEN 1 END), 0), 2) AS Standard,
    ROUND(SUM(CAST(IsChurned AS FLOAT)) * 100.0 / COUNT(*), 2)             AS OverallTotal
FROM dbo.Dim_Customers
GROUP BY ContractType
ORDER BY ContractType

-- 6. "Churn by Tenure" — retention curve by tenure bucket
-- (TenureBucket was a DAX calculated column — replicated here with CASE WHEN)
SELECT
    CASE
        WHEN TenureMonths <= 6  THEN '0-6 Months'
        WHEN TenureMonths <= 12 THEN '7-12 Months'
        WHEN TenureMonths <= 24 THEN '13-24 Months'
        ELSE '25+ Months'
    END                                                          AS TenureBucket,
    COUNT(*)                                                     AS TotalCustomers,
    ROUND(100 - (SUM(CAST(IsChurned AS FLOAT)) * 100.0 / COUNT(*)), 2) AS RetentionRatePct
FROM dbo.Dim_Customers
GROUP BY
    CASE
        WHEN TenureMonths <= 6  THEN '0-6 Months'
        WHEN TenureMonths <= 12 THEN '7-12 Months'
        WHEN TenureMonths <= 24 THEN '13-24 Months'
        ELSE '25+ Months'
    END
ORDER BY MIN(TenureMonths)

--  PAGE 3 — CUSTOMER VALUE ANALYSIS
-- 1. KPI Cards: Total Revenue, Revenue/Customer, CLV, Revenue at Risk
SELECT
    SUM(f.BilledAmount)                                             AS TotalRevenue,
    ROUND(SUM(f.BilledAmount) / COUNT(DISTINCT c.CustomerID), 2)    AS RevenuePerCustomer,
    ROUND(AVG(c.MonthlyCharges) * AVG(c.TenureMonths), 2)           AS CLV_Approx,
    SUM(CASE WHEN f.IsChurnMonth = 1 THEN f.BilledAmount ELSE 0 END) AS RevenueAtRisk
FROM dbo.Fact_MonthlyActivity f
JOIN dbo.Dim_Customers c ON f.CustomerID = c.CustomerID

-- 2. "Revenue Trend" + MoM Growth % (uses LAG window function)
WITH MonthlyRevenue AS (
    SELECT
        FORMAT(ActivityYearMonth, 'yyyy-MM') AS YearMonth,
        SUM(BilledAmount)                    AS Revenue
    FROM dbo.Fact_MonthlyActivity
    GROUP BY FORMAT(ActivityYearMonth, 'yyyy-MM')
)
SELECT
    YearMonth,
    Revenue,
    LAG(Revenue) OVER (ORDER BY YearMonth) AS PrevMonthRevenue,
    ROUND(
        (Revenue - LAG(Revenue) OVER (ORDER BY YearMonth)) * 100.0
        / NULLIF(LAG(Revenue) OVER (ORDER BY YearMonth), 0), 2
    ) AS MoM_Growth_Pct
FROM MonthlyRevenue
ORDER BY YearMonth

-- 3. "Revenue by Plan" (share of total revenue %)
SELECT
    PlanType,
    SUM(BilledAmount)                                                    AS Revenue,
    ROUND(SUM(BilledAmount) * 100.0 / SUM(SUM(BilledAmount)) OVER (), 2) AS PctOfTotalRevenue
FROM dbo.Fact_MonthlyActivity
GROUP BY PlanType
ORDER BY Revenue DESC

-- 4. "Risk by Contract" — Revenue at risk (churn-month billing) split by contract type
SELECT
    c.ContractType,
    SUM(f.BilledAmount) AS RevenueAtRisk
FROM dbo.Fact_MonthlyActivity f
JOIN dbo.Dim_Customers c ON f.CustomerID = c.CustomerID
WHERE f.IsChurnMonth = 1
GROUP BY c.ContractType
ORDER BY RevenueAtRisk DESC

-- 5. "Acquisition Insights" — Revenue & Customers by acquisition channel and plan
SELECT
    c.AcquisitionChannel,
    c.PlanType,
    SUM(f.BilledAmount)         AS TotalRevenue,
    COUNT(DISTINCT c.CustomerID) AS TotalCustomers
FROM dbo.Dim_Customers c
JOIN dbo.Fact_MonthlyActivity f ON c.CustomerID = f.CustomerID
GROUP BY c.AcquisitionChannel, c.PlanType
ORDER BY TotalRevenue DESC

-- 6. "Channel Performance" table
SELECT
    c.AcquisitionChannel,
    SUM(f.BilledAmount)                                             AS TotalRevenue,
    COUNT(DISTINCT c.CustomerID)                                    AS TotalCustomers,
    ROUND(SUM(CASE WHEN c.IsChurned = 1 THEN 1.0 ELSE 0 END) * 100.0
        / COUNT(DISTINCT c.CustomerID), 2)                          AS ChurnRatePct
FROM dbo.Dim_Customers c
JOIN dbo.Fact_MonthlyActivity f ON c.CustomerID = f.CustomerID
GROUP BY c.AcquisitionChannel
ORDER BY TotalRevenue DESC