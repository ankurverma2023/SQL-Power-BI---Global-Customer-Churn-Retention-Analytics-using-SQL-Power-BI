USE ChurnRetentionDB
GO

BULK INSERT dbo.Dim_Customers
FROM 'E:\DATA ANALYST\Power BI\Dataset Power BI\Global Customer Churn & Retention\Dim_Customers.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK,
    CODEPAGE = '65001'
);
GO

BULK INSERT dbo.Fact_MonthlyActivity
FROM 'E:\DATA ANALYST\Power BI\Dataset Power BI\Global Customer Churn & Retention\Fact_MonthlyActivity.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    TABLOCK,
    CODEPAGE = '65001'
);
GO