CREATE DATABASE NHS_Elective_Care_Analytics;
GO

USE NHS_Elective_Care_Analytics;
GO

CREATE TABLE dbo.Staging_RTT_Performance
(
     Median_Waiting_Time_Weeks   NVARCHAR(50) NULL,
    P92_Waiting_Time_Weeks      NVARCHAR(50) NULL,
    Percent_52_Plus_Weeks       NVARCHAR(50) NULL, 
	 Region_Code                 NVARCHAR(20) NULL,
    Provider_Code               NVARCHAR(20) NOT NULL,
     Treatment_Function_Code     NVARCHAR(20) NOT NULL, 
    Provider_Name                  NVARCHAR(255) NOT NULL,
    Treatment_Function             NVARCHAR(255) NOT NULL,
    Total_Incomplete_Pathways      INT NOT NULL,
    Total_Within_18_Weeks          INT NOT NULL,
    Percent_Within_18_Weeks        DECIMAL(9,4) NOT NULL,
    Total_52_Plus_Weeks            INT NOT NULL,
    Total_65_Plus_Weeks            INT NOT NULL,
    Total_78_Plus_Weeks            INT NOT NULL,
    Reporting_Month                DATE NOT NULL
);
GO