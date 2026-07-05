CREATE VIEW dbo.vw_Monthly_Performance
AS
SELECT
    d.Reporting_Month,
    d.Calendar_Year,
    d.Month_Number,
    d.Month_Name,
    d.Year_Month,

    SUM(f.Total_Incomplete_Pathways) AS Total_Waiting_List,
    SUM(f.Total_Within_18_Weeks) AS Total_Within_18_Weeks,

    CAST(
        SUM(f.Total_Within_18_Weeks) * 1.0
        / NULLIF(SUM(f.Total_Incomplete_Pathways), 0)
        AS DECIMAL(9,4)
    ) AS Weighted_Percent_Within_18_Weeks,

    SUM(f.Total_52_Plus_Weeks) AS Total_52_Plus_Weeks,
    SUM(f.Total_65_Plus_Weeks) AS Total_65_Plus_Weeks,
    SUM(f.Total_78_Plus_Weeks) AS Total_78_Plus_Weeks

FROM dbo.Fact_RTT_Performance AS f

INNER JOIN dbo.Dim_Date AS d
    ON f.Date_Key = d.Date_Key

INNER JOIN dbo.Dim_Specialty AS s
    ON f.Specialty_Key = s.Specialty_Key

WHERE s.Is_Total = 1

GROUP BY
    d.Reporting_Month,
    d.Calendar_Year,
    d.Month_Number,
    d.Month_Name,
    d.Year_Month;
GO

SELECT *
FROM dbo.vw_Monthly_Performance
ORDER BY Reporting_Month;


CREATE VIEW dbo.vw_Provider_Performance
AS
SELECT
    d.Reporting_Month,
    d.Year_Month,
    p.Provider_Code,
    p.Provider_Name,
    p.Region_Code,

    SUM(f.Total_Incomplete_Pathways) AS Total_Waiting_List,
    SUM(f.Total_Within_18_Weeks) AS Total_Within_18_Weeks,

    CAST(
        SUM(f.Total_Within_18_Weeks) * 1.0
        / NULLIF(SUM(f.Total_Incomplete_Pathways), 0)
        AS DECIMAL(9,4)
    ) AS Weighted_Percent_Within_18_Weeks,

    SUM(f.Total_52_Plus_Weeks) AS Total_52_Plus_Weeks,
    SUM(f.Total_65_Plus_Weeks) AS Total_65_Plus_Weeks,
    SUM(f.Total_78_Plus_Weeks) AS Total_78_Plus_Weeks

FROM dbo.Fact_RTT_Performance AS f

INNER JOIN dbo.Dim_Date AS d
    ON f.Date_Key = d.Date_Key

INNER JOIN dbo.Dim_Provider AS p
    ON f.Provider_Key = p.Provider_Key

INNER JOIN dbo.Dim_Specialty AS s
    ON f.Specialty_Key = s.Specialty_Key

WHERE s.Is_Total = 1

GROUP BY
    d.Reporting_Month,
    d.Year_Month,
    p.Provider_Code,
    p.Provider_Name,
    p.Region_Code;
GO

SELECT TOP 100 *
FROM dbo.vw_Provider_Performance
ORDER BY Reporting_Month, Total_Waiting_List DESC;
GO


CREATE VIEW dbo.vw_Specialty_Performance
AS
SELECT
    d.Reporting_Month,
    d.Year_Month,
    s.Treatment_Function_Code,
    s.Treatment_Function,

    SUM(f.Total_Incomplete_Pathways) AS Total_Waiting_List,
    SUM(f.Total_Within_18_Weeks) AS Total_Within_18_Weeks,

    CAST(
        SUM(f.Total_Within_18_Weeks) * 1.0
        / NULLIF(SUM(f.Total_Incomplete_Pathways), 0)
        AS DECIMAL(9,4)
    ) AS Weighted_Percent_Within_18_Weeks,

    SUM(f.Total_52_Plus_Weeks) AS Total_52_Plus_Weeks,
    SUM(f.Total_65_Plus_Weeks) AS Total_65_Plus_Weeks,
    SUM(f.Total_78_Plus_Weeks) AS Total_78_Plus_Weeks

FROM dbo.Fact_RTT_Performance AS f

INNER JOIN dbo.Dim_Date AS d
    ON f.Date_Key = d.Date_Key

INNER JOIN dbo.Dim_Specialty AS s
    ON f.Specialty_Key = s.Specialty_Key

WHERE s.Is_Total = 0

GROUP BY
    d.Reporting_Month,
    d.Year_Month,
    s.Treatment_Function_Code,
    s.Treatment_Function;
GO

SELECT TOP 100 *
FROM dbo.vw_Specialty_Performance
ORDER BY Reporting_Month, Total_Waiting_List DESC;
GO