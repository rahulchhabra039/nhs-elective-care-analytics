USE NHS_Elective_Care_Analytics;
GO

SELECT
    COUNT(*) AS Total_Rows,
    COUNT(DISTINCT Reporting_Month) AS Reporting_Months,
    MIN(Reporting_Month) AS Earliest_Month,
    MAX(Reporting_Month) AS Latest_Month
FROM dbo.Staging_RTT_Performance;
GO


-- Check missing or blank provider and specialty identifiers
SELECT
    SUM(CASE WHEN Provider_Code IS NULL
                  OR LTRIM(RTRIM(Provider_Code)) = ''
             THEN 1 ELSE 0 END) AS Missing_Provider_Code,

    SUM(CASE WHEN Provider_Name IS NULL
                  OR LTRIM(RTRIM(Provider_Name)) = ''
             THEN 1 ELSE 0 END) AS Missing_Provider_Name,

    SUM(CASE WHEN Treatment_Function_Code IS NULL
                  OR LTRIM(RTRIM(Treatment_Function_Code)) = ''
             THEN 1 ELSE 0 END) AS Missing_Specialty_Code,

    SUM(CASE WHEN Treatment_Function IS NULL
                  OR LTRIM(RTRIM(Treatment_Function)) = ''
             THEN 1 ELSE 0 END) AS Missing_Specialty_Name
FROM dbo.Staging_RTT_Performance;
GO


-- Check whether pathway measures exceed the total waiting list
SELECT
    SUM(CASE
            WHEN Total_Within_18_Weeks > Total_Incomplete_Pathways
            THEN 1 ELSE 0
        END) AS Within_18_Exceeds_Total,

    SUM(CASE
            WHEN Total_52_Plus_Weeks > Total_Incomplete_Pathways
            THEN 1 ELSE 0
        END) AS Wait_52_Plus_Exceeds_Total,

    SUM(CASE
            WHEN Total_65_Plus_Weeks > Total_52_Plus_Weeks
            THEN 1 ELSE 0
        END) AS Wait_65_Exceeds_52,

    SUM(CASE
            WHEN Total_78_Plus_Weeks > Total_65_Plus_Weeks
            THEN 1 ELSE 0
        END) AS Wait_78_Exceeds_65
FROM dbo.Staging_RTT_Performance;
GO


-- Check that nonblank text values can be converted to decimals
SELECT
    SUM(
        CASE
            WHEN NULLIF(LTRIM(RTRIM(Median_Waiting_Time_Weeks)), '') IS NOT NULL
             AND TRY_CONVERT(
                    DECIMAL(9,2),
                    LTRIM(RTRIM(Median_Waiting_Time_Weeks))
                 ) IS NULL
            THEN 1 ELSE 0
        END
    ) AS Invalid_Median_Values,

    SUM(
        CASE
            WHEN NULLIF(LTRIM(RTRIM(P92_Waiting_Time_Weeks)), '') IS NOT NULL
             AND TRY_CONVERT(
                    DECIMAL(9,2),
                    LTRIM(RTRIM(P92_Waiting_Time_Weeks))
                 ) IS NULL
            THEN 1 ELSE 0
        END
    ) AS Invalid_P92_Values,

    SUM(
        CASE
            WHEN NULLIF(LTRIM(RTRIM(Percent_52_Plus_Weeks)), '') IS NOT NULL
             AND TRY_CONVERT(
                    DECIMAL(9,4),
                    LTRIM(RTRIM(Percent_52_Plus_Weeks))
                 ) IS NULL
            THEN 1 ELSE 0
        END
    ) AS Invalid_Percent_52_Values
FROM dbo.Staging_RTT_Performance;
GO


-- Show the invalid % 52+ weeks values
SELECT
    Percent_52_Plus_Weeks AS Invalid_Value,
    COUNT(*) AS Occurrences
FROM dbo.Staging_RTT_Performance
WHERE NULLIF(LTRIM(RTRIM(Percent_52_Plus_Weeks)), '') IS NOT NULL
  AND TRY_CONVERT(
        DECIMAL(9,4),
        LTRIM(RTRIM(Percent_52_Plus_Weeks))
      ) IS NULL
GROUP BY Percent_52_Plus_Weeks
ORDER BY Occurrences DESC;
GO

SELECT
    Reporting_Month,
    Provider_Code,
    Provider_Name,
    Treatment_Function_Code,
    Treatment_Function,
    Total_Incomplete_Pathways,
    Total_52_Plus_Weeks,
    Percent_52_Plus_Weeks
FROM dbo.Staging_RTT_Performance
WHERE NULLIF(LTRIM(RTRIM(Percent_52_Plus_Weeks)), '') IS NOT NULL
  AND TRY_CONVERT(
        DECIMAL(9,4),
        LTRIM(RTRIM(Percent_52_Plus_Weeks))
      ) IS NULL
ORDER BY Reporting_Month, Provider_Code;
GO

-- Confirm that % 52+ week values are valid numbers,
-- including values stored in scientific notation
SELECT
    SUM(
        CASE
            WHEN NULLIF(LTRIM(RTRIM(Percent_52_Plus_Weeks)), '') IS NOT NULL
             AND TRY_CONVERT(
                    FLOAT,
                    LTRIM(RTRIM(Percent_52_Plus_Weeks))
                 ) IS NULL
            THEN 1
            ELSE 0
        END
    ) AS Truly_Invalid_Percent_52_Values,

    MIN(
        TRY_CONVERT(
            FLOAT,
            NULLIF(LTRIM(RTRIM(Percent_52_Plus_Weeks)), '')
        )
    ) AS Minimum_Percent_52_Value,

    MAX(
        TRY_CONVERT(
            FLOAT,
            NULLIF(LTRIM(RTRIM(Percent_52_Plus_Weeks)), '')
        )
    ) AS Maximum_Percent_52_Value
FROM dbo.Staging_RTT_Performance;
GO


