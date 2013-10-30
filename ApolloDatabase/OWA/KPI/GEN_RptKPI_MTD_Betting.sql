USE [ReportDB]
GO
/****** Object:  StoredProcedure [dbo].[GEN_RptKPI_MTD_Betting]    Script Date: 10/28/2013 5:08:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[GEN_RptKPI_MTD_Betting]
    @date	DATETIME, 
    @date2	DATETIME = null
   
AS
/*
Created: 20131010@winnie
Task: Generate data into GEN_RptKPI_MTD_Cross from rpt_Betting
DB: KPIReport

Revisions:
    
Param's Explanation:

*/

IF @date2 IS NULL 
SELECT @date2=@date
SELECT @date2 = DATEADD(day,1,@date2)

CREATE TABLE #Betting
(
     rptDate					DATETIME    
    ,CurrencyID					INT
    ,BetCount					INT
    ,Turnover					FLOAT
    --,AverageBetsize			FLOAT
    --,AverageBetsizeNoDraw		FLOAT  
    ,TotalNetWin				FLOAT
    ,TotalCommGiven				FLOAT
    ,BetCountNoDraw				INT
    ,TurnoverNoDraw				FLOAT
	--,Margin					INT
    ,FinancialSportRevenue		FLOAT
    
    
)
    INSERT INTO #Betting (rptDate,CurrencyID,BetCount,Turnover,BetCountNoDraw,TurnoverNoDraw,
	--AverageBetsize,AverageBetsizeNoDraw,
	TotalNetWin,TotalCommGiven,
	--Margin,
	FinancialSportRevenue)
        SELECT 
             b.rptDate 
            ,b.CurrencyID
            ,SUM(b.betcount) AS BetCount 
            ,SUM(b.turnover) AS Turnover    
            ,SUM(CASE WHEN b.status = 111 THEN 0 ELSE b.betcount END) AS BetCountNoDraw 
            ,SUM(CASE WHEN b.status = 111 THEN 0 WHEN b.status in (114,115) THEN (0.5*b.turnover) ELSE b.turnover END) AS TurnoverNoDraw 
			--,SUM(b.turnover)/sum(b.betcount)				AS AverageBetsize
			--,SUM(CASE WHEN b.status = 111 then 0 WHEN b.status in (114,115) THEN (0.5*b.turnover) ELSE b.turnover END)/SUM(CASE WHEN b.status = 111 THEN 0 ELSE b.betcount END)	AS AverageBetsizeNoDraw
			,- SUM(Winloss + TWinLoss + TCommission) AS TotalNetWin
			,SUM(b.TCommission) AS TotalCommGiven
			--,- SUM(Winloss + TWinLoss + TCommission)/SUM(CASE WHEN b.status = 111 THEN 0 WHEN b.status in (114,115) THEN (0.5*b.turnover) ELSE b.turnover END) AS Margin
			,- SUM(Winloss + TWinLoss + TCommission) AS FinancialSportRevenue
        FROM dbo.rpt_Betting b (NOLOCK)           
        WHERE b.rptDate >= @date AND b.rptDate < @date2
            AND b.status NOT IN (-1,103)
            AND b.CurrencyID <> 20
            AND ( b.bettype < 31 OR (b.bettype >= 121 AND b.bettype < 1000) )           
        GROUP BY b.rptDate, b.CurrencyID


    DELETE dbo.rptKPI_MTD_Cross WHERE rptDate >= @date AND rptDate < @date2 AND StatID !=5

    INSERT INTO dbo.rptKPI_MTD_Cross
        SELECT b.rptDate,  b.CurrencyID, cast(f.StatID as int) StatID, f.MTD
        FROM #Betting b
            CROSS APPLY (
                SELECT 7,	BetCount					UNION ALL
                SELECT 9,	Turnover					UNION ALL             
                SELECT 17,	BetCountNoDraw				UNION ALL
                SELECT 19,	TurnoverNoDraw				UNION ALL
				--SELECT 8,	AverageBetsize				UNION ALL
				--SELECT 24,	AverageBetsizeNoDraw	UNION ALL    
                SELECT 25,	TotalNetWin					UNION ALL
				SELECT 26,	TotalCommGiven				UNION ALL
				--SELECT 27,	Margin					UNION ALL
				SELECT 28,	FinancialSportRevenue				
             
            ) f(StatID,MTD)

		

