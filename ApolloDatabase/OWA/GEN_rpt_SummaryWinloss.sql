USE [ReportDB]
GO
/****** Object:  StoredProcedure [dbo].[GEN_rpt_SummaryWinloss]    Script Date: 11/27/2013 5:47:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[GEN_rpt_SummaryWinloss]
    @date datetime, 
    @date2 datetime = null
AS
/*
Created: 20131015@Sophia
Task: Generate data into rpt_SummaryWinloss
DB: ReportDB

Revisions:
- 20131127@Sophia: Add TCommission column 
- 20131129@Sophia: Calculate Turnover/2 for Half Won, Half Lose

Param's Explanation:

*/
IF @date2 IS NULL SET @date2 = @date
SET @date2 = DATEADD(day,1,@date2)

SELECT  b.rptDate,	  
		b.CurrencyID,
		Status,			
		SUM(Betcount) Betcount,
		SUM(CASE WHEN Status IN (114,115) THEN Turnover / 2 ELSE Turnover END) Turnover,
		SUM(WinLoss) winloss,
		- SUM(Winloss + TWinLoss) WinLossCompany,
		SUM(TCommission) TCommission
INTO	#TMP
FROM	dbo.rpt_Betting b (NOLOCK) 	 	       
WHERE	rptDate>=@date AND rptDate<@date2
		AND Status IN (111,112,113,114,115)
GROUP BY b.rptDate,	  
		 b.CurrencyID,
		 Status

DELETE FROM dbo.rpt_SummaryWinloss
WHERE rptDate>=@date AND rptDate<@date2


INSERT INTO dbo.rpt_SummaryWinloss
        ([rptDate]
      ,[CurrencyID]
      ,[Status]
      ,[BetCount]
      ,[TurnOver]
      ,[WinLoss]
	  , WinLossCompany      
	  , TCommission 
     )
SELECT  [rptDate]
      ,[CurrencyID]
      ,[Status]
      ,[BetCount]
      ,[TurnOver]
      ,[WinLoss]
	  , WinLossCompany     
	  , TCommission 
FROM    #TMP 

