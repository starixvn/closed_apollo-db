ALTER PROCEDURE [dbo].[LA_Report_SunSportWinLoss]
	@FromDate DATE,
	@ToDate DATE,
	@Currency INT = 0, 
	@DrawType SMALLINT = 0 ,
	@ReportBy SMALLINT = 0, 
	@BaseCurrency TINYINT = 1
AS
/*
Created: 20140109@Sophia
Task :  Report Sunsport Winloss for LicenseeAdmin
DB:  SVRReport.ReportDB
Original: OAS_Report_SunSportWinLoss

Revisions:
 
Param's Explanation:  
	 @DrawType = 0: Normal
			   = 1: No Draw for turnover and Betcount
			   = 2: No Draw for turnover only 	
     @ReportBy = 0: Daily
			   = 1: Monthly
	 @BaseCurrency  = 0: MYR
					= 1: EUR
					= 2: USD

EX:	   
LA_Report_SunSportWinLoss  '2013-08-01', '2013-10-22', 0,0,0, 2 
	
*/  
SET NOCOUNT ON
 
DECLARE @Str AS VARCHAR(MAX) 

SELECT @Str =
	 'DECLARE @ExchangeDaily TABLE(ExchangeDate SMALLDATETIME, ExchangeId INT, BaseExchange FLOAT, UNIQUE CLUSTERED (ExchangeDate, ExchangeId)) ' + char(13) 
SELECT @Str = @Str + 
	 'INSERT INTO @ExchangeDaily (ExchangeDate,ExchangeId, BaseExchange) ' + char(13) +
	 'SELECT Exchangedate, exchangeid, '+ 
			 CASE @BaseCurrency WHEN 0 THEN 'MYR' 
								WHEN 1 THEN 'EUR' 
								WHEN 2 THEN 'USD' 
			 END  +' AS BaseExchange 
	  FROM RepDB.dbo.Lrf_f_GetExchangeDaily(''' + CONVERT(varchar(10),@FromDate, 120) + ''',''' +  CONVERT(varchar(10),@ToDate, 120) + ''')' + char(13) + char(13) 



SELECT  @Str = @Str 
				+ 'SELECT CurrencyID,  Currency as CurrencyName, '
				+ CASE WHEN @ReportBy = 0 THEN ' rptDate, ' ELSE  ' DATEADD(MONTH, DATEDIFF(MONTH,0, rptDate),0) AS rptDate, '  END + char(13) 
				+ CASE WHEN @DrawType = 1 THEN ' SUM (CASE WHEN Status <> 111 THEN BetCount ELSE 0 END) as TotalTrans, ' ELSE  ' SUM (BetCount) as TotalTrans, '  END + char(13) 
				+ CASE WHEN @DrawType IN (1,2) THEN ' SUM (CASE WHEN Status <> 111 THEN TurnOver ELSE 0 END) as TurnOver, ' ELSE  ' SUM (TurnOver) as TurnOver, '  END + char(13)
				+ CASE WHEN @DrawType IN (1,2) THEN ' SUM (CASE WHEN Status <> 111 THEN TurnOver ELSE 0 END)* BaseExchange as TurnOverBase, ' ELSE  ' SUM (TurnOver)* BaseExchange as TurnOverBase, '  END + char(13)
				+ ' SUM (WinLoss) as WinLoss, 
				SUM (WinLoss)*BaseExchange as WinLossBase,
				SUM (WinLossCompany) as WinLossCompany, 
				SUM (WinLossCompany)*BaseExchange as WinLossCompanyBase,
				SUM (TCommission) as TCommission, 
				SUM (TCommission)*BaseExchange as TCommissionBase,
				SUM (WinLossCompany - TCommission) as GrossWinLossCompany, 
				SUM (WinLossCompany - TCommission)*BaseExchange as GrossWinLossCompanyBase
		FROM	rpt_SummaryWinloss b WITH (NOLOCK)
			LEFT JOIN REPDB.DBO.Exchange c WITH (NOLOCK) ON c.ExchangeId = CurrencyID
			LEFT JOIN @ExchangeDaily e ON b.CurrencyID = e.exchangeid AND b.rptdate = e.exchangedate
		WHERE	rptDate BETWEEN '''+ CONVERT(VARCHAR(10),@FromDate) +''' AND '''+CONVERT(VARCHAR(10),@ToDate) +'''
				AND Status IN (111,112,113,114,115) ' + char(13) 
				+ CASE WHEN @Currency <> 0 THEN ' AND CurrencyID = '+ CONVERT(VARCHAR(5),@Currency)  ELSE ' ' END + char(13) 
				+ CASE WHEN @ReportBy = 0 THEN ' GROUP BY CurrencyID,  Currency, BaseExchange, rptDate ' ELSE  ' GROUP BY CurrencyID, Currency, BaseExchange, DATEADD(MONTH, DATEDIFF(MONTH,0, rptDate),0)'  END + char(13) 
				+ ' ORDER BY rptDate, Currency
				
				'
 		 	 
  
--PRINT @Str
EXEC ( @Str)

GO 
 
GRANT EXECUTE ON [dbo].[LA_Report_SunSportWinLoss] TO [aplweb]
GO   
  


