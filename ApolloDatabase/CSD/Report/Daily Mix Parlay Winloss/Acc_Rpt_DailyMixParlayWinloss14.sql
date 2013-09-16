ALTER PROCEDURE [dbo].[Acc_Rpt_DailyMixParlayWinloss14]
	@FromDate datetime,
	@ToDate datetime
AS
/*	Creator: Sophia
	Date: 20130819
	Task: Daily parlay winloss report ->Parlay Combination Win Loss / 2h report -> Mix Parlay
	DB: SVRCSD.REPDB

	Revisions: 		
		 - 20130911@Sophia: Add currency <> 20
	Parameter's Explanation:
		- Combinations: Bettrans.betcheck is stored the number of selection by format 'm4', 'm3' ...
		- LiveType (Livehomescore):
			0: Non Live : All bets are Dead Ball 
			1: Live: All bets are Live Ball 
			2: Mix Live and Non Live: contains Live and Dead Ball

*/
SET NOCOUNT ON 
 
SELECT 
		case when betcheck in ('m2','m3','m4','m5') then betcheck else 'm6' end as Combinations, 
		livehomescore as LiveType, status, 
		CONVERT(MONEY,SUM((winlost-actual_stake)*actualrate)) WinLost,
		CONVERT(MONEY,SUM(stake*actualrate)) turnoverp,
		count(1) BetCount,
		CONVERT(MONEY,SUM((TWinlost)*actualrate)) Share,
		CONVERT(MONEY,SUM(TComm*actualrate)) Commission,	
		CONVERT(MONEY,SUM((winlost-actual_stake+TWinlost+TComm)*actualrate)) LineTotal,
		CONVERT(MONEY,SUM((1-tpositiontaking)*(ABS(stake)*actualrate))) Turnover	
FROM	bettrans14 WITH (NOLOCK)
WHERE	bettype = 9 AND
		winlostdate between @FromDate AND @ToDate and 
		statusID NOT IN (0,1,101,102,103) AND
		Currency <> 20
GROUP BY  case when betcheck in ('m2','m3','m4','m5') then betcheck else 'm6' end, livehomescore, status
ORDER BY  case when betcheck in ('m2','m3','m4','m5') then betcheck else 'm6' end, livehomescore, status


GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyMixParlayWinloss14] TO [aplweb]