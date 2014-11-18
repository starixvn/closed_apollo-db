ALTER PROCEDURE [dbo].[OAS_Get_TopSports_KPIs]
    @ReportDate datetime = NULL
    ,@TimeType int
WITH RECOMPILE
AS
/*
    Created: 20131025@winnie
    Task: Get Top 3 Sports (All)
    DB: SVRREPORT/ReportDB

    Revisions:
		- 20140212@Dan: remove *100 percent
    Param's Explanation:

*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #MTD_TopThreeSports
	(
		rptDate datetime
		,CurrencyID int
		,SportID int
		,Turnover float
	)

	CREATE TABLE #TurnoverByLicensee 
	(
		rptDate datetime
		,CurrencyID int
		,TotalTurnover float
		,PRIMARY KEY CLUSTERED (rptDate,CurrencyID)
	)

	CREATE CLUSTERED INDEX IX_MTD_TopThreeSports ON #MTD_TopThreeSports 
	(
		[rptDate] ASC,
		CurrencyID,
		SportID ASC
	)

	DECLARE @Labels TABLE(LabelID int, DateStarted datetime)

	DECLARE @Type int
	SELECT @Type = @TimeType



	-- Date
	DECLARE 
		@Date_TheDayBefore datetime
		,@Date_MTDCurrentMonth datetime
		,@Date_MTDLastMonth datetime
		,@Date_FirstDayOfYear datetime
		,@Date_FirstDayOfLastMonth datetime
		,@Date_FirstDayOfCurrentMonth datetime
		,@FromDate datetime
		,@ToDate datetime
    
	DECLARE 
		@Distance_MTDCurrentMonth int
		,@Distance_MTDLastMonth int
		,@Distance_FullLastMonth int
		,@Distance_MTDYear int
    
	IF @ReportDate IS NULL
		SELECT @Date_MTDCurrentMonth = GETDATE()
	ELSE
	BEGIN
		SELECT @Date_MTDCurrentMonth = @ReportDate
		SELECT @Date_MTDCurrentMonth = DATEADD(DAY, 1, @Date_MTDCurrentMonth)
	END

	SELECT @Date_MTDLastMonth = DATEADD(MONTH, -1, @Date_MTDCurrentMonth)

	SELECT  
		@Date_TheDayBefore = DATEADD(DAY, -1, @Date_MTDCurrentMonth)
		,@Date_FirstDayOfYear = DATEADD(yy, DATEDIFF(yy,0,@Date_TheDayBefore), 0)
		,@Date_FirstDayOfCurrentMonth = DATEADD(MONTH, DATEDIFF(MONTH,0,@Date_TheDayBefore), 0)
		,@Date_FirstDayOfLastMonth = DATEADD(MONTH, DATEDIFF(MONTH,0,@Date_TheDayBefore) - 1, 0)
    
	SELECT
		@Distance_MTDCurrentMonth = DATEDIFF(dd, @Date_FirstDayOfCurrentMonth, @Date_MTDCurrentMonth)
		,@Distance_MTDLastMonth = @Distance_MTDCurrentMonth
		,@Distance_FullLastMonth = DATEDIFF(dd, @Date_FirstDayOfLastMonth, @Date_FirstDayOfCurrentMonth)
		,@Distance_MTDYear = DATEDIFF(dd, @Date_FirstDayOfYear, @Date_MTDCurrentMonth)
    
	IF (@Type = 1)
		SELECT @FromDate = @Date_TheDayBefore, @ToDate = @Date_MTDCurrentMonth
	ELSE IF (@Type = 2)
		SELECT @FromDate = @Date_FirstDayOfCurrentMonth, @ToDate = @Date_MTDCurrentMonth
	ELSE IF (@Type = 11)
		SELECT @FromDate = @Date_FirstDayOfLastMonth, @ToDate = @Date_MTDLastMonth
	ELSE IF (@Type = 12)
		SELECT @FromDate = @Date_FirstDayOfLastMonth, @ToDate = @Date_FirstDayOfCurrentMonth
	ELSE IF (@Type = 21)
		SELECT @FromDate = @Date_FirstDayOfYear, @ToDate = @Date_MTDCurrentMonth



	--INSERT INTO @Labels
	--    SELECT DISTINCT LabelID,AffectedDate
	--    FROM dbo.view_kpi_labels (NOLOCK)
	--    WHERE IsDeposit=1 AND IsKPIActive=1

	INSERT INTO #MTD_TopThreeSports(rptDate,CurrencyID,SportID,Turnover)
		SELECT rptDate,b.CurrencyID,l.sporttype,SUM(Turnover) Turnover  
		FROM (
				SELECT rptDate,LeagueID,CurrencyID,Turnover
				FROM dbo.rpt_Betting (NOLOCK) 
				WHERE rptDate>=@FromDate AND rptDate<@ToDate
					AND status NOT IN (-1,103) 
					AND currencyID<>20 
					AND Bettype NOT BETWEEN 31 AND 120
					--AND ISNULL(customercategory,-1) NOT IN (27,28)-- 8RM&BARM            
			) b
			--INNER JOIN @Labels lic ON b.SiteID=lic.LabelID AND (lic.DateStarted is null OR b.rptDate>=lic.DateStarted)
			INNER JOIN RepDB.dbo.League l (NOLOCK) ON b.leagueid=l.leagueid 
		GROUP BY rptDate,b.CurrencyID,l.sporttype
    
	INSERT INTO #TurnoverByLicensee(rptDate,CurrencyID,TotalTurnover)
		SELECT rptDate,CurrencyID,SUM(Turnover)
		FROM #MTD_TopThreeSports
		GROUP BY rptDate,CurrencyID



	-- Get Result
	;WITH CTE_ExchangeDaily (ExchangeDate,ExchangeId,EUR) AS (
		SELECT exchangedate,exchangeid,EUR 
		FROM RepDB.dbo.Lrf_f_GetExchangeDaily(@FromDate,DATEADD(DAY,-1,@ToDate)) 
		WHERE EUR > 0
	)

	SELECT TOP(3)
		s.SportName Sport 
		--,ISNULL(SUM(tmp.PercentTurnover),0)*100/(CASE @Type 
		,ISNULL(SUM(tmp.PercentTurnover),0)/(CASE @Type 
										WHEN 2 THEN @Distance_MTDCurrentMonth 
										WHEN 11 THEN @Distance_MTDLastMonth 
										WHEN 12 THEN @Distance_FullLastMonth 
										WHEN 21 THEN @Distance_MTDYear 
										ELSE 1 END) PercentTurnover
		,ROW_NUMBER()over(ORDER BY SUM(tmp.PercentTurnover) DESC)
	FROM RepDB.dbo.Sports s (NOLOCK)
		INNER JOIN (
			SELECT mtd.rptDate
				,mtd.SportID
				,SUM(mtd.Turnover*EUR)/SUM(total.TotalTurnover*EUR) PercentTurnover
			FROM #MTD_TopThreeSports mtd 
				INNER JOIN CTE_ExchangeDaily e ON mtd.currencyID = e.exchangeid AND mtd.rptdate = e.exchangedate 
				INNER JOIN #TurnoverByLicensee total ON mtd.rptDate = total.rptDate AND mtd.currencyID = total.CurrencyID
			GROUP BY mtd.rptDate,SportID
		) tmp ON s.SportType = tmp.SportID
	GROUP BY s.SportName
	ORDER BY SUM(tmp.PercentTurnover) DESC

	DROP TABLE #MTD_TopThreeSports 
	DROP TABLE #TurnoverByLicensee  

	--------

	SET NOCOUNT OFF

END


GO
GRANT EXECUTE ON  OAS_Get_TopSports_KPIs TO aplweb
GO