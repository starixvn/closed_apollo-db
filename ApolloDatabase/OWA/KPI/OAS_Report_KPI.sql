ALTER PROCEDURE [dbo].[OAS_Report_KPI]
    @ReportDate datetime = NULL
AS
/*
    Created: 20131017@winnie
    Task: Implement SP for main KPI report
    DB: DBLAS.LASDB

    Revisions:            
    Param's Explanation:

*/
SET NOCOUNT ON

DECLARE 
    @FirstDayOfLastThreeMonths	 DATETIME,
    @FirstDayOfYear				 DATETIME,
	@FirstDayOfLastMonth		 DATETIME,
	@LastDayOfLastMonth			 DATETIME,
	@CurrentDayOfLastMonth		 DATETIME,
	@FirstDayOfCurrentMonth		 DATETIME,
    @FromDate					 DATETIME,
    @ToDate						 DATETIME
  
IF (@ReportDate IS NULL)
    SELECT @ToDate = CONVERT(VARCHAR(10), DATEADD(dd, -1, CURRENT_TIMESTAMP), 120)
ELSE
    SELECT @ToDate = CONVERT(VARCHAR(10), @ReportDate, 120)
    
SELECT @FirstDayOfLastThreeMonths	= DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToDate) - 3, 0)	-- First Day of Last Three Months
SELECT @FirstDayOfLastMonth			= DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToDate) - 1, 0)	-- First Day of Last Month
SELECT @LastDayOfLastMonth			= DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,@ToDate),0))	-- Last Day of Last Month
SELECT @CurrentDayOfLastMonth		= DATEADD(mm, -1, @ToDate)							    -- Current Day of Last Month
SELECT @FirstDayOfCurrentMonth		= DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToDate) , 0)		-- First Day of current Month
SELECT @FirstDayOfYear				= DATEADD(yy, DATEDIFF(yy,0,@ToDate), 0)				-- First Day of Year

IF (@FirstDayOfYear > @FirstDayOfLastThreeMonths)
    SELECT @FromDate = @FirstDayOfLastThreeMonths
ELSE
    SELECT @FromDate = @FirstDayOfYear


DECLARE @ExchangeDaily TABLE(ExchangeDate SMALLDATETIME,ExchangeId INT,EUR FLOAT,UNIQUE CLUSTERED (ExchangeDate,ExchangeId)) INSERT INTO @ExchangeDaily(ExchangeDate,ExchangeId,EUR) SELECT exchangedate,exchangeid,EUR FROM RepDB.dbo.Lrf_f_GetExchangeDaily
(@FromDate,@ToDate)


CREATE TABLE #TmpMTDCross
(
    Day			DATETIME,
	Currency	INT,
    StatID		SMALLINT,
    MonthToDate FLOAT,
    Type		VARCHAR(2)
)

INSERT INTO #TmpMTDCross(Day, Currency, StatId, MonthToDate, Type)
-- ****** Current month ******
    SELECT 
        rptdate, 
		CurrencyID,
        statid, 
        Monthtodate,
        '1' AS Type   -- current date Current month
    FROM dbo.rptKPI_MTD_Cross (NOLOCK)
    WHERE rptDate = @ToDate
	UNION ALL 
	SELECT 
        rptdate, 
		CurrencyID,
        statid, 
        Monthtodate,
        '2' AS Type   -- Month To Date Current month
    FROM dbo.rptKPI_MTD_Cross (NOLOCK)
    WHERE rptDate BETWEEN @FirstDayOfCurrentMonth AND @ToDate
	UNION ALL 
	SELECT 
        rptdate, 
		CurrencyID,
        statid, 
        Monthtodate,
        '3' AS Type   -- Month To Date Last month
    FROM dbo.rptKPI_MTD_Cross (NOLOCK)
    WHERE rptDate BETWEEN @FirstDayOfLastMonth AND @CurrentDayOfLastMonth
	UNION ALL 
	SELECT 
        rptdate, 
		CurrencyID,
        statid, 
        Monthtodate,
        '4' AS Type   -- Full month Last month
    FROM dbo.rptKPI_MTD_Cross (NOLOCK)
    WHERE rptDate BETWEEN @FirstDayOfLastMonth AND @LastDayOfLastMonth
	UNION ALL 
	SELECT 
        rptdate, 
		CurrencyID,
        statid, 
        Monthtodate,
        '5' AS Type   -- Full year to current day Actual
    FROM dbo.rptKPI_MTD_Cross (NOLOCK)
    WHERE rptDate BETWEEN @FirstDayOfYear AND @ToDate
	UNION ALL 
	SELECT 
        rptdate, 
		CurrencyID,
        statid, 
        Monthtodate,
        '6' AS Type   -- Full year to last month
    FROM dbo.rptKPI_MTD_Cross (NOLOCK)
    WHERE rptDate BETWEEN @FirstDayOfYear AND @LastDayOfLastMonth
	UNION ALL 
	SELECT 
        rptdate, 
		CurrencyID,
        statid, 
        Monthtodate,
        '7' AS Type   -- Full year 3 last months
    FROM dbo.rptKPI_MTD_Cross (NOLOCK)
    WHERE rptDate BETWEEN @FirstDayOfLastThreeMonths AND @LastDayOfLastMonth
	-- ****** Return result ******
	    SELECT		
        s.StatName,s.StatID,
        SUM(CASE 
            WHEN type = '1' AND o.StatID !=5 AND o.StatID !=7 AND o.StatID !=17  AND o.StatID !=27 THEN ISNULL(Monthtodate,0)*e.EUR
			WHEN type = '1' AND (o.StatID =5  OR o.StatID =7 OR o.StatID =17 OR o.StatID =27) THEN ISNULL(Monthtodate,0)
            ELSE 0
        END) AS [CurrentDate],
        SUM(CASE 
            WHEN type = '2' AND o.StatID !=5 AND o.StatID !=7 AND o.StatID !=17 AND o.StatID !=27 AND o.StatID !=8 AND o.StatID !=24 THEN ISNULL(Monthtodate,0)*e.EUR
			WHEN type = '2'  AND  (o.StatID =5  OR o.StatID =7 OR o.StatID =17 )  THEN ISNULL(Monthtodate,0)
			WHEN type = '2'  AND  ( o.StatID =27) THEN ISNULL(Monthtodate,0)/(DATEDIFF(dd,@FirstDayOfCurrentMonth,@ToDate)+1)
			WHEN type = '2'  AND  ( o.StatID =8 OR o.StatID=24) THEN ISNULL(Monthtodate,0)*e.EUR/(DATEDIFF(dd,@FirstDayOfCurrentMonth,@ToDate)+1)
            ELSE 0
        END)
		AS [CurrentMonthMonthToDate],

		SUM(CASE 
				WHEN type = '3' AND  o.StatID !=5 AND o.StatID !=7 AND o.StatID !=17  AND o.StatID !=27 AND o.StatID !=8 AND o.StatID !=24 THEN ISNULL(Monthtodate,0)*e.EUR
				WHEN type = '3' AND (o.StatID =5  OR o.StatID =7 OR o.StatID =17) THEN ISNULL(Monthtodate,0)
				WHEN type = '3' AND (o.StatID =27 ) THEN ISNULL(Monthtodate,0)/(DATEDIFF(dd,@FirstDayOfLastMonth,@CurrentDayOfLastMonth)+1)
				WHEN type = '3'  AND  ( o.StatID =8 OR o.StatID=24) THEN ISNULL(Monthtodate,0)*e.EUR/(DATEDIFF(dd,@FirstDayOfLastMonth,@CurrentDayOfLastMonth)+1)
            ELSE 0
        END)
		AS [LastMonthMonthToDate],
		SUM(CASE 
			WHEN type = '4' AND  o.StatID !=5 AND o.StatID !=7 AND o.StatID !=17 AND o.StatID !=27 AND o.StatID !=8 AND o.StatID !=24 THEN ISNULL(Monthtodate,0)*e.EUR
			WHEN type = '4' AND (o.StatID =5  OR o.StatID =7 OR o.StatID =17 )  THEN ISNULL(Monthtodate,0)
			WHEN type = '4' AND (o.StatID =27)  THEN ISNULL(Monthtodate,0)/(DATEDIFF(dd,@FirstDayOfLastMonth,@LastDayOfLastMonth)+1)
			WHEN type = '4'  AND  ( o.StatID =8 OR o.StatID=24) THEN ISNULL(Monthtodate,0)*e.EUR/(DATEDIFF(dd,@FirstDayOfLastMonth,@LastDayOfLastMonth)+1)
			ELSE 0
        END)
		AS [LastMonthFullMonth],

		SUM(CASE 
			WHEN type = '5' AND o.StatID !=5 AND o.StatID !=7 AND o.StatID !=17 AND o.StatID !=27 AND o.StatID !=8 AND o.StatID !=24 THEN ISNULL(Monthtodate,0)*e.EUR
			WHEN type = '5' AND  (o.StatID =5  OR o.StatID =7 OR o.StatID =17 )  THEN ISNULL(Monthtodate,0)
			WHEN type = '5' AND  (o.StatID =27)  THEN ISNULL(Monthtodate,0)/(DATEDIFF(dd,@FirstDayOfYear,@ToDate)+1)
			WHEN type = '5'  AND  ( o.StatID =8 OR o.StatID=24) THEN ISNULL(Monthtodate,0)*e.EUR/(DATEDIFF(dd,@FirstDayOfYear,@ToDate)+1)
			ELSE 0
        END)
		AS [FullYearToCurrentDateActual],

		SUM(CASE 
			WHEN type = '5' AND o.StatID !=5 AND o.StatID !=7 AND o.StatID !=17 AND o.StatID !=27 THEN ISNULL(Monthtodate,0)*e.EUR
			WHEN type = '5' AND  (o.StatID =5  OR o.StatID =7 OR o.StatID =17 OR o.StatID =27)  THEN ISNULL(Monthtodate,0)
			ELSE 0
        END)/ (DATEDIFF(dd,@FirstDayOfYear,@ToDate)+1)
		 AS [FullYearToCurrentDateDailyAve],

		SUM(CASE 
			WHEN type = '6' AND o.StatID !=5 AND o.StatID !=7 AND o.StatID !=17 AND o.StatID !=27 AND o.StatID !=8 AND o.StatID !=24 THEN ISNULL(Monthtodate,0)*e.EUR/(DATEDIFF(mm,@FirstDayOfYear,@LastDayOfLastMonth)+1)
			WHEN type = '6' AND  (o.StatID =5  OR o.StatID =7 OR o.StatID =17)  THEN ISNULL(Monthtodate,0)/(DATEDIFF(mm,@FirstDayOfYear,@LastDayOfLastMonth)+1)
			WHEN type = '6' AND  (o.StatID =27)  THEN ISNULL(Monthtodate,0)/(DATEDIFF(dd,@FirstDayOfYear,@LastDayOfLastMonth)+1)
			WHEN type = '6'  AND  ( o.StatID =8 OR o.StatID=24) THEN ISNULL(Monthtodate,0)*e.EUR/(DATEDIFF(dd,@FirstDayOfYear,@LastDayOfLastMonth)+1)
			ELSE 0
        END)
		AS [FullYearToLastMonthMonthlyAve],

		SUM(CASE 
			WHEN type = '7' AND o.StatID !=5 AND o.StatID !=7 AND o.StatID !=17 AND o.StatID !=27 AND o.StatID !=8 AND o.StatID !=24  THEN ISNULL(Monthtodate,0)*e.EUR/(DATEDIFF(mm,@FirstDayOfLastThreeMonths,@LastDayOfLastMonth)+1) 
			WHEN type = '7' AND  (o.StatID =5  OR o.StatID =7 OR o.StatID =17)  THEN ISNULL(Monthtodate,0)/(DATEDIFF(mm,@FirstDayOfLastThreeMonths,@LastDayOfLastMonth) +1)
			WHEN type = '7' AND  (o.StatID =27)  THEN ISNULL(Monthtodate,0)/(DATEDIFF(dd,@FirstDayOfLastThreeMonths,@LastDayOfLastMonth)+1)
			WHEN type = '7'  AND  ( o.StatID =8 OR o.StatID=24) THEN ISNULL(Monthtodate,0)*e.EUR/(DATEDIFF(dd,@FirstDayOfLastThreeMonths,@LastDayOfLastMonth)+1)
			ELSE 0
        END)
		AS [ThreeLastMonthsMonthlyAve],

		SUM(CASE 
			WHEN type = '7' AND o.StatID !=5 AND o.StatID !=7 AND o.StatID !=17 AND o.StatID !=27  THEN ISNULL(Monthtodate,0)*e.EUR
			WHEN type = '7' AND  (o.StatID =5  OR o.StatID =7 OR o.StatID =17 OR o.StatID =27)  THEN ISNULL(Monthtodate,0)
			ELSE 0
        END)/(DATEDIFF(dd,@FirstDayOfLastThreeMonths,@LastDayOfLastMonth)+1) AS [ThreeLastMonthsDailyAve]
    FROM
        #TmpMTDCross o (nolock)      
	LEFT JOIN tbl_KPI_Stats s ON o.StatID=s.StatID
	LEFT JOIN @ExchangeDaily e ON o.Currency = e.ExchangeId AND o.Day=e.ExchangeDate	
    GROUP BY        
       s.StatName,s.StatID

    
SET NOCOUNT OFF


