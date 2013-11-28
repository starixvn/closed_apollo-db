ALTER PROCEDURE [dbo].[OAS_Report_SunSportWinLoss]
	@FromDate DATE,
	@ToDate DATE,
	@Currency INT = 0, 
	@DrawType SMALLINT = 0 ,
	@ReportBy SMALLINT = 0
AS
/*
Created: 201301015@Sophia
Task :  
DB:  SVRReport.ReportDB
Original:  

Revisions:
- 20131128@Sophia: Add column TCommission, TCommissionEUR, GrossWinLossCompany, GrossWinLossCompanyEUR
    
Param's Explanation:  
	 @DrawType = 0: Normal
			   = 1: No Draw for turnover and Betcount
			   = 2: No Draw for turnover only 	
     @ReportBy = 0: Daily
			   = 1: Monthly

EX:	   
OAS_Report_SunSportWinLoss  '2013-08-01', '2013-10-22', 0,0,0
OAS_Report_SunSportWinLoss  '2013-08-01', '2013-10-22', 0,0,1
OAS_Report_SunSportWinLoss  '2013-08-01', '2013-10-22', 0,1,0
OAS_Report_SunSportWinLoss  '2013-08-01', '2013-10-22', 0,1,1
OAS_Report_SunSportWinLoss  '2013-08-01', '2013-10-22', 0,1,2


OAS_Report_SunSportWinLoss  '2013-08-01', '2013-10-22', 1,0,0
OAS_Report_SunSportWinLoss  '2013-08-01', '2013-10-22', 1,0,1
OAS_Report_SunSportWinLoss  '2013-08-01', '2013-10-22', 1,1,0
OAS_Report_SunSportWinLoss  '2013-08-01', '2013-10-22', 1,1,1
OAS_Report_SunSportWinLoss  '2013-08-01', '2013-10-22', 1,1,2


OAS_Report_SunSportWinLoss  '2013-08-01', '2013-10-22', 1,0,0
OAS_Report_SunSportWinLoss  '2013-08-01', '2013-10-22', 1,0,1
OAS_Report_SunSportWinLoss  '2013-08-01', '2013-10-22', 1,2,0
OAS_Report_SunSportWinLoss  '2013-08-01', '2013-10-22', 1,2,1
OAS_Report_SunSportWinLoss  '2013-08-01', '2013-10-22', 1,2,2
	
*/  
SET NOCOUNT ON
 
DECLARE @Str  AS VARCHAR(MAX)
 

SELECT @Str =
	 'DECLARE @ExchangeDaily TABLE(ExchangeDate smalldatetime,ExchangeId int, EUR float,unique clustered (ExchangeDate,ExchangeId)) ' + char(13) 
SELECT @Str = @Str + 
	 'INSERT INTO @ExchangeDaily(ExchangeDate,ExchangeId,EUR) ' + char(13) +
	 'SELECT exchangedate,exchangeid,EUR FROM RepDB.dbo.Lrf_f_GetExchangeDaily(''' + CONVERT(varchar(10),@FromDate, 120) + ''',''' +  CONVERT(varchar(10),@ToDate, 120) + ''')' + char(13) + char(13) 



SELECT  @Str = @Str 
				+ 'SELECT CurrencyID,  Currency as CurrencyName, '
				+ CASE WHEN @ReportBy = 0 THEN ' rptDate, ' ELSE  ' DATEADD(MONTH, DATEDIFF(MONTH,0, rptDate),0) AS rptDate, '  END + char(13) 
				+ CASE WHEN @DrawType = 1 THEN ' SUM (CASE WHEN Status <> 111 THEN BetCount ELSE 0 END) as TotalTrans, ' ELSE  ' SUM (BetCount) as TotalTrans, '  END + char(13) 
				+ CASE WHEN @DrawType IN (1,2) THEN ' SUM (CASE WHEN Status <> 111 THEN TurnOver ELSE 0 END) as TurnOver, ' ELSE  ' SUM (TurnOver) as TurnOver, '  END + char(13)
				+ CASE WHEN @DrawType IN (1,2) THEN ' SUM (CASE WHEN Status <> 111 THEN TurnOver ELSE 0 END)*EUR as TurnOverEUR, ' ELSE  ' SUM (TurnOver)*EUR as TurnOverEUR, '  END + char(13)
				+ ' SUM (WinLoss) as WinLoss, 
				SUM (WinLoss)*EUR as WinLossEUR,
				SUM (WinLossCompany) as WinLossCompany, 
				SUM (WinLossCompany)*EUR as WinLossCompanyEUR,
				SUM (TCommission) as TCommission, 
				SUM (TCommission)*EUR as TCommissionEUR,
				SUM (WinLossCompany+TCommission) as GrossWinLossCompany, 
				SUM (WinLossCompany+TCommission)*EUR as GrossWinLossCompanyEUR
		FROM	rpt_SummaryWinloss b WITH (NOLOCK)
			LEFT JOIN REPDB.DBO.Exchange c WITH (NOLOCK) ON c.ExchangeId = CurrencyID
			LEFT JOIN @ExchangeDaily e ON b.CurrencyID = e.exchangeid AND b.rptdate = e.exchangedate
		WHERE	rptDate BETWEEN '''+ CONVERT(VARCHAR(10),@FromDate) +''' AND '''+CONVERT(VARCHAR(10),@ToDate) +'''
				AND Status IN (111,112,113,114,115) ' + char(13) 
				+ CASE WHEN @Currency <> 0 THEN ' AND CurrencyID = '+ CONVERT(VARCHAR(5),@Currency)  ELSE ' ' END + char(13) 
				+ CASE WHEN @ReportBy = 0 THEN ' GROUP BY CurrencyID,  Currency, EUR, rptDate ' ELSE  ' GROUP BY CurrencyID, Currency,  EUR, DATEADD(MONTH, DATEDIFF(MONTH,0, rptDate),0)'  END + char(13) 
				+ ' ORDER BY rptDate, Currency'
 		 	 
  
--PRINT @Str
EXEC ( @Str)

GO 
 
GRANT EXECUTE ON [dbo].[OAS_Report_SunSportWinLoss] TO [aplweb]
GO   
  


