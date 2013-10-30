USE [ReportDB]
GO
/****** Object:  StoredProcedure [dbo].[GEN_rptKPI_Account]    Script Date: 10/28/2013 5:07:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[GEN_rptKPI_Account]
    @date DATETIME, 
    @date2 DATETIME = null
AS
/*
Created: 20131009@winnie
Task: Generate data into rptKPI_Account from Staging and DB03.ON_USER.dbo.TotalOnline (refer to SP [Dot_Admin_GetTotalOnline_Report] for more detail)
Task: Generate data into rptKPI_Account for Peak concurrent bettors Suncity
DB: KPIReport
Revisions:

Param's Explanation:

*/


IF @date2 IS NULL 
SELECT @date2=@date
SELECT @date2 = DATEADD(day,1,@date2)


DELETE FROM dbo.rpt_KPI_Account WHERE rptDate >= @date and rptDate < @date2

INSERT INTO dbo.rpt_KPI_Account(rptDate,[hour],UniqueBettorCount)
    SELECT 
        CONVERT(VARCHAR(10),bet.transdate,120) rptDate,
        DATEPART(HOUR,transdate) [hour],  
        COUNT(DISTINCT bet.custid) UniqueBettorCount
    FROM dbo.bettrans bet (NOLOCK)
        inner join RepDB.dbo.[CustInfo] cust (NOLOCK) ON bet.custid = cust.custid     
    WHERE 
        transdate >= @date and transdate < @date2
    GROUP BY 
        CONVERT(VARCHAR(10),transdate,120),
        DATEPART(HOUR,transdate)


/*
Created: 20131009@winnie
Task: Generate data into rptKPI_Account for Peak concurrent bettors Suncity
*/
/*
DECLARE @nvDate nvarchar(10)
SET @nvDate = CONVERT(nvarchar(10), @date, 120)

CREATE TABLE #TotalOnline (KeyID int IDENTITY(1,1), LogHour tinyint, LogMinute tinyint, ServerGrp int, ServerID int, Users int)

IF (EXISTS (SELECT * FROM DB03.ON_USER.dbo.TotalOnline WITH(NOLOCK) WHERE LogDate BETWEEN @nvDate + ' 00:00' AND DATEADD(day, 1, @nvDate + ' 00:00')))
	INSERT INTO #TotalOnline
	    SELECT CAST(RIGHT(CONVERT(nvarchar(13),LogDate, 120),2) as tinyint) LogHour, CAST(RIGHT(CONVERT(nvarchar(16),LogDate, 120),2) as tinyint) LogMinute, 
	    207 AS ServerGrp, ServerID, Users
	    FROM DB03.ON_USER.dbo.TotalOnline WITH(NOLOCK)
	    WHERE LogDate BETWEEN @nvDate + ' 00:00' AND DATEADD(day, 1, @nvDate + ' 00:00')
		AND   ServerID = 207000  --Suncity
ELSE
	INSERT INTO #TotalOnline
	    SELECT CAST(RIGHT(CONVERT(nvarchar(13),LogDate, 120),2) as tinyint) LogHour, CAST(RIGHT(CONVERT(nvarchar(16),LogDate, 120),2) as tinyint) LogMinute, 
	    207 AS ServerGrp, ServerID, Users
	    FROM DB03.ON_USER.dbo.TotalOnline_BK WITH(NOLOCK)
	    WHERE LogDate BETWEEN @nvDate + ' 00:00' AND DATEADD(day, 1, @nvDate + ' 00:00')
		AND   ServerID = 207000  --Suncity

CREATE TABLE #tmp1 (LogHour tinyint, LogMinute tinyint, ServerGrp int, Users int)
INSERT INTO #tmp1
    SELECT LogHour, LogMinute, ServerGrp, SUM(Users) Users FROM #TotalOnline GROUP BY LogHour, LogMinute, ServerGrp

CREATE TABLE #tmp2 (LogHour tinyint, LogMinute tinyint, Users int, IsMax bit default 0)
INSERT INTO #tmp2 (LogHour, LogMinute, Users)
    SELECT LogHour, LogMinute, SUM(Users) users FROM #tmp1 GROUP BY LogHour, LogMinute

UPDATE #tmp2
SET IsMax = 1
FROM (SELECT LogHour, MAX(Users) Users FROM #tmp2 GROUP BY LogHour) X
WHERE X.LogHour = #tmp2.LogHour AND X.Users = #tmp2.Users

CREATE TABLE #AvgUser (LogHour tinyint, ServerGrp int, Users int)
INSERT INTO #AvgUser
    SELECT a.LogHour, a.ServerGrp, a.Users
    FROM #tmp1 a INNER JOIN #tmp2 b ON a.LogHour = b.LogHour AND a.LogMinute = b.LogMinute
    WHERE b.IsMax = 1

DROP TABLE #TotalOnline
DROP TABLE #tmp1
DROP TABLE #tmp2

UPDATE acc
SET acc.PeakBettorCount = u.Users
FROM dbo.rptKPI_Account acc  
    INNER JOIN #AvgUser u ON acc.Hour = u.LogHour 
WHERE acc.rptDate = (@nvDate + ' 00:00')

DROP TABLE #AvgUser
*/