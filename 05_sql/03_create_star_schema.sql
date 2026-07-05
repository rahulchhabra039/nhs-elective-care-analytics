USE NHS_Elective_Care_Analytics;
GO

CREATE TABLE dbo.Dim_Date
(
    Date_Key          INT PRIMARY KEY,
    Reporting_Month   DATE NOT NULL UNIQUE,
    Calendar_Year     SMALLINT NOT NULL,
    Month_Number      TINYINT NOT NULL,
    Month_Name        VARCHAR(20) NOT NULL,
    Quarter_Number    TINYINT NOT NULL,
    Year_Month        CHAR(7) NOT NULL
);
GO

INSERT INTO dbo.Dim_Date
(
    Date_Key,
    Reporting_Month,
    Calendar_Year,
    Month_Number,
    Month_Name,
    Quarter_Number,
    Year_Month
)
SELECT DISTINCT
    CONVERT(INT, CONVERT(CHAR(8), Reporting_Month, 112)),
    Reporting_Month,
    YEAR(Reporting_Month),
    MONTH(Reporting_Month),
    DATENAME(MONTH, Reporting_Month),
    DATEPART(QUARTER, Reporting_Month),
    CONVERT(CHAR(7), Reporting_Month, 126)
FROM dbo.Staging_RTT_Performance;
GO

SELECT *
FROM dbo.Dim_Date
ORDER BY Reporting_Month;
GO


-- Check that each provider code maps to one provider name and one region
SELECT
    Provider_Code,
    COUNT(DISTINCT Provider_Name) AS Provider_Name_Count,
    COUNT(DISTINCT Region_Code) AS Region_Count
FROM dbo.Staging_RTT_Performance
GROUP BY Provider_Code
HAVING
    COUNT(DISTINCT Provider_Name) > 1
    OR COUNT(DISTINCT Region_Code) > 1;
GO

-- Show the different names used for the affected provider codes
SELECT DISTINCT
    Provider_Code,
    Provider_Name,
    Region_Code
FROM dbo.Staging_RTT_Performance
WHERE Provider_Code IN
(
    SELECT Provider_Code
    FROM dbo.Staging_RTT_Performance
    GROUP BY Provider_Code
    HAVING COUNT(DISTINCT Provider_Name) > 1
)
ORDER BY
    Provider_Code,
    Provider_Name;
GO


CREATE TABLE dbo.Dim_Provider
(
    Provider_Key   INT IDENTITY(1,1) PRIMARY KEY,
    Provider_Code  NVARCHAR(20) NOT NULL UNIQUE,
    Provider_Name  NVARCHAR(255) NOT NULL,
    Region_Code    NVARCHAR(20) NULL
);
GO

WITH Provider_History AS
(
    SELECT DISTINCT
        Provider_Code,
        Provider_Name,
        Region_Code,
        Reporting_Month
    FROM dbo.Staging_RTT_Performance
),
Ranked_Providers AS
(
    SELECT
        Provider_Code,
        Provider_Name,
        Region_Code,
        ROW_NUMBER() OVER
        (
            PARTITION BY Provider_Code
            ORDER BY Reporting_Month DESC
        ) AS Provider_Rank
    FROM Provider_History
)
INSERT INTO dbo.Dim_Provider
(
    Provider_Code,
    Provider_Name,
    Region_Code
)
SELECT
    Provider_Code,
    Provider_Name,
    Region_Code
FROM Ranked_Providers
WHERE Provider_Rank = 1;
GO

SELECT *
FROM dbo.Dim_Provider
ORDER BY Provider_Code;
GO

-- Confirm that every provider code was loaded once
SELECT
    (SELECT COUNT(DISTINCT Provider_Code)
     FROM dbo.Staging_RTT_Performance) AS Staging_Provider_Count,

    (SELECT COUNT(*)
     FROM dbo.Dim_Provider) AS Dimension_Provider_Count,

    (SELECT COUNT(DISTINCT Provider_Code)
     FROM dbo.Dim_Provider) AS Unique_Dimension_Provider_Count;
GO

-- Check whether each specialty code has only one specialty name
SELECT
    Treatment_Function_Code,
    COUNT(DISTINCT Treatment_Function) AS Specialty_Name_Count
FROM dbo.Staging_RTT_Performance
GROUP BY Treatment_Function_Code
HAVING COUNT(DISTINCT Treatment_Function) > 1;
GO


CREATE TABLE dbo.Dim_Specialty
(
    Specialty_Key             INT IDENTITY(1,1) PRIMARY KEY,
    Treatment_Function_Code   NVARCHAR(20) NOT NULL UNIQUE,
    Treatment_Function        NVARCHAR(255) NOT NULL,
    Is_Total                  BIT NOT NULL
);
GO

INSERT INTO dbo.Dim_Specialty
(
    Treatment_Function_Code,
    Treatment_Function,
    Is_Total
)
SELECT DISTINCT
    Treatment_Function_Code,
    Treatment_Function,
    CASE
        WHEN Treatment_Function_Code = 'C_999'
        THEN 1
        ELSE 0
    END AS Is_Total
FROM dbo.Staging_RTT_Performance;
GO

SELECT *
FROM dbo.Dim_Specialty
ORDER BY Treatment_Function_Code;
GO


CREATE TABLE dbo.Fact_RTT_Performance
(
    Fact_Key                      BIGINT IDENTITY(1,1) PRIMARY KEY,

    Date_Key                      INT NOT NULL,
    Provider_Key                  INT NOT NULL,
    Specialty_Key                 INT NOT NULL,

    Total_Incomplete_Pathways     INT NOT NULL,
    Total_Within_18_Weeks         INT NOT NULL,
    Percent_Within_18_Weeks       DECIMAL(9,4) NOT NULL,

    Median_Waiting_Time_Weeks     DECIMAL(9,2) NULL,
    P92_Waiting_Time_Weeks        DECIMAL(9,2) NULL,

    Total_52_Plus_Weeks           INT NOT NULL,
    Total_65_Plus_Weeks           INT NOT NULL,
    Total_78_Plus_Weeks           INT NOT NULL,
    Percent_52_Plus_Weeks         DECIMAL(18,10) NULL,

    CONSTRAINT FK_Fact_RTT_Date
        FOREIGN KEY (Date_Key)
        REFERENCES dbo.Dim_Date(Date_Key),

    CONSTRAINT FK_Fact_RTT_Provider
        FOREIGN KEY (Provider_Key)
        REFERENCES dbo.Dim_Provider(Provider_Key),

    CONSTRAINT FK_Fact_RTT_Specialty
        FOREIGN KEY (Specialty_Key)
        REFERENCES dbo.Dim_Specialty(Specialty_Key),

    CONSTRAINT UQ_Fact_RTT_Grain
        UNIQUE (Date_Key, Provider_Key, Specialty_Key)
);
GO


-- Check whether any staging rows fail to match a dimension
SELECT
    SUM(CASE WHEN d.Date_Key IS NULL THEN 1 ELSE 0 END)
        AS Missing_Date_Matches,

    SUM(CASE WHEN p.Provider_Key IS NULL THEN 1 ELSE 0 END)
        AS Missing_Provider_Matches,

    SUM(CASE WHEN s.Specialty_Key IS NULL THEN 1 ELSE 0 END)
        AS Missing_Specialty_Matches
FROM dbo.Staging_RTT_Performance AS st

LEFT JOIN dbo.Dim_Date AS d
    ON st.Reporting_Month = d.Reporting_Month

LEFT JOIN dbo.Dim_Provider AS p
    ON st.Provider_Code = p.Provider_Code

LEFT JOIN dbo.Dim_Specialty AS s
    ON st.Treatment_Function_Code = s.Treatment_Function_Code;
GO

INSERT INTO dbo.Fact_RTT_Performance
(
    Date_Key,
    Provider_Key,
    Specialty_Key,
    Total_Incomplete_Pathways,
    Total_Within_18_Weeks,
    Percent_Within_18_Weeks,
    Median_Waiting_Time_Weeks,
    P92_Waiting_Time_Weeks,
    Total_52_Plus_Weeks,
    Total_65_Plus_Weeks,
    Total_78_Plus_Weeks,
    Percent_52_Plus_Weeks
)
SELECT
    d.Date_Key,
    p.Provider_Key,
    s.Specialty_Key,
    st.Total_Incomplete_Pathways,
    st.Total_Within_18_Weeks,
    st.Percent_Within_18_Weeks,

    TRY_CONVERT(
        DECIMAL(9,2),
        NULLIF(LTRIM(RTRIM(st.Median_Waiting_Time_Weeks)), '')
    ),

    TRY_CONVERT(
        DECIMAL(9,2),
        NULLIF(LTRIM(RTRIM(st.P92_Waiting_Time_Weeks)), '')
    ),

    st.Total_52_Plus_Weeks,
    st.Total_65_Plus_Weeks,
    st.Total_78_Plus_Weeks,

    TRY_CONVERT(
        DECIMAL(18,10),
        TRY_CONVERT(
            FLOAT,
            NULLIF(LTRIM(RTRIM(st.Percent_52_Plus_Weeks)), '')
        )
    )
FROM dbo.Staging_RTT_Performance AS st

INNER JOIN dbo.Dim_Date AS d
    ON st.Reporting_Month = d.Reporting_Month

INNER JOIN dbo.Dim_Provider AS p
    ON st.Provider_Code = p.Provider_Code

INNER JOIN dbo.Dim_Specialty AS s
    ON st.Treatment_Function_Code = s.Treatment_Function_Code;
GO

SELECT COUNT(*) AS Fact_Row_Count
FROM dbo.Fact_RTT_Performance;
GO

-- Confirm there are no duplicate month-provider-specialty combinations
SELECT
    Date_Key,
    Provider_Key,
    Specialty_Key,
    COUNT(*) AS Duplicate_Count
FROM dbo.Fact_RTT_Performance
GROUP BY
    Date_Key,
    Provider_Key,
    Specialty_Key
HAVING COUNT(*) > 1;
GO