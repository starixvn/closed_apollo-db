USE [ReportDB]
GO
/****** Object:  StoredProcedure [dbo].[GEN_RptKPI_MTD_Account]    Script Date: 10/28/2013 5:08:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[GEN_RptKPI_MTD_Account]
    @date datetime, 
    @date2 datetime = null
    
AS
/*
Created: 20131010@winnie
Task: Generate data into GEN_RptKPI_MTD from rptKPI_Account
DB: KPIReport

Revisions:
    
Param's Explanation:

*/


IF @date2 IS NULL 
SELECT @date2=@date
SELECT @date2 = DATEADD(day,1,@date2)

    DELETE dbo.rptKPI_MTD_Cross WHERE rptDate >= @date AND rptDate < @date2 AND StatID =5

    INSERT INTO dbo.rptKPI_MTD_Cross
        SELECT account.rptDate, account.CurrencyID, cast(f.StatID as int) StatID, f.MTD
        FROM 
            (
                SELECT b.rptDate, -1 AS CurrencyID, 
                    SUM(CAST(UniqueBettorCount AS FLOAT))/24 AverageBettorsDuringDays                   
                FROM dbo.rpt_KPI_Account b (NOLOCK)
                WHERE b.rptDate >= @date AND b.rptDate < @date2
                GROUP BY b.rptDate
            ) account CROSS APPLY (
                SELECT 5, AverageBettorsDuringDays     
            ) f(StatID,MTD)

