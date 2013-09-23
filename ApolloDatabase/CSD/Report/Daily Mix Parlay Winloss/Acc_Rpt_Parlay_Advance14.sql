ALTEr PROCEDURE [dbo].[Acc_Rpt_Parlay_Advance14]
	@FromDate	datetime,
	@ToDate		datetime,
	@bettype	int = 9
AS
/*	Creator: Sophia
	Date: 20130819
	Task: Parlay Win Loss by Product From :
			- View Detail of Mix Parlay for 2a, 2h reports.
		    - Accounting/ report/ 2a,2h/ Link Mix parlay
	DB: SVRCSD.RepDb

	Revisions: 				
		- 20130911@Sophia: Add currency <> 20
	    - 20130916@Sophia: exclude line test Suntest 53288, and add ActualTurnover

	Parameter's Explanation:	
			+ LiveType (Livehomescore):
				0: Non Live : All bets are Dead Ball 
				1: Live: All bets are Live Ball 
				2: Mix Live and Non Live: contains Live and Dead Ball 

			+ SportType (Liveawayscore):
				1: Soccer Sports: soccer only 
				2: Other Sport: Other sport and Multi other sport (not including Soccer)
				3: Multi Sports: include Soccer and Other sports

*/
SET NOCOUNT ON 

SELECT  livehomescore as LiveType, liveawayscore as SportType, status, 
		CONVERT(MONEY,sum((winlost-actual_stake)*actualrate)) WinLost,		
		CONVERT(MONEY,SUM(stake*actualrate)) turnoverp,
		CONVERT(MONEY,sum((TWinlost)*actualrate)) Share,
		CONVERT(MONEY,sum(TComm*actualrate)) Commission,	
		CONVERT(MONEY,sum((winlost-actual_stake+TWinlost+TComm)*actualrate)) LineTotal,
		CONVERT(MONEY,sum((1-tpositiontaking)*(ABS(stake)*actualrate))) Turnover,
		CONVERT(MONEY,SUM(CASE WHEN StatusID IN (112,113) AND (ABS(MOdds) <> 0.25 OR Bettype IN (9,29,10)) THEN ABS(Stake) ELSE CASE WHEN StatusID IN (112,113) AND ABS(MOdds) =0.25 AND Bettype NOT IN (9,29,10) THEN  ABS(Stake)*0.5  ELSE 0 END END * (1-TPositionTaking))) AS ActualTurnover		
FROM	bettrans14 WITH (NOLOCK)
WHERE	bettype = @bettype AND		
		winlostdate between @FromDate AND @ToDate and
		statusID NOT IN (0,1,101,102,103) AND
		Currency <> 20 AND
		TransID NOT IN  (	SELECT	TransID 
							FROM	Bettrans14_Agent WITH (NOLOCK)
							WHERE	winlostdate between @FromDate AND @ToDate 
									AND statusID not in (0,1,101,102,103) --('VOID','REJECT','REFUND')
									AND bettype = @bettype 
									AND AgentID = 53288 -----line test Suntest
									)  
GROUP BY  livehomescore, liveawayscore, status
ORDER BY  livehomescore, liveawayscore, status

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_Parlay_Advance14] TO [aplweb]