ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_Soccer_Bettype14]
	@winlostdate	date 
AS
/*	Creator: Sophia
	Date: 20130814
	Task: Daily Winloss Report by Bettype (2h)
	DB: SVRCSD.RepDB
		
	Revision:
		  - 20130916@Sophia: add ActualTurnover, exclude line test Suntest 53288	
	Explanation's Param:
		

*/
SET NOCOUNT ON
 	
	Declare @tmpBettype table (	Bettype			int primary key, 
								DisplayOrder	int)

	Insert into @tmpBettype
	select 1,  1 --'Handicap',
	UNION ALL
	Select 3,  2 --'Over/Under',
	UNION ALL
	select 7,  3 --'1st Half Handicap',
	UNION ALL
	Select 8,  4 --'1st Half Over/Under',
	UNION ALL
	select 2,  5 --'Odd/Even',
	UNION ALL
	select 5,  6 --'1x2',
	UNION ALL
	Select 4,  7 --'Correct Score',
	UNION ALL
	Select 6,  8 --'Total Goal',
	UNION ALL 
	Select 10,  10 --'Outright',


	INSERT INTO @tmpBettype
	SELECT typeid, typeid
	FROM bettype WITH(NOLOCK)
	WHERE (typeid > 10 AND typeid < 31) OR typeid BETWEEN 121 AND 999

	------------------------------------------------------------
	--Declare @Match14 table to contain all matches based on @winlostdate
	DECLARE @Match14 TABLE (matchid INT, type varchar(10), primary key(matchid, type))
	INSERT INTO @Match14 
	SELECT	m.matchid, 		
			m.type
	FROM (
			SELECT matchid, leagueid, 'match' as type FROM Match14 WITH (NOLOCK) WHERE eventdate = @winlostdate
			UNION ALL
			SELECT orid, leagueid,'outright' as type FROM outright14 WITH (NOLOCK) WHERE eventdate = @winlostdate
			)m	
	INNER JOIN league l WITH (NOLOCK) ON m.leagueid = l.leagueid	
	WHERE l.sporttype = 1

	----------------------------------------------------------
	CREATE TABLE #Tempbettrans14 (Liveindicator BIT, Bettype TINYINT, matchid INT, WinLost MONEY,  
								Share MONEY, Commission MONEY, LineTotal MONEY, Turnover MONEY, ActualTurnover MONEY )
	INSERT INTO #TempBettrans14	
	SELECT	liveindicator,
			Bettype,			
			matchid,
			sum((winlost-actual_stake)*ActualRate) WinLost,
			sum((TWinlost)*ActualRate) Share,
			sum(TComm*ActualRate) Commission,	
			sum((winlost-actual_stake+TWinlost+TComm)*ActualRate) LineTotal, 
			sum((1-TPositionTaking)*ABS(stake)*ActualRate) Turnover,
			CONVERT(MONEY,SUM(CASE WHEN StatusID IN (112,113) AND (ABS(MOdds) <> 0.25 OR Bettype IN (9,29,10)) THEN ABS(Stake)
									ELSE CASE WHEN StatusID IN (112,113) AND ABS(MOdds) =0.25 AND Bettype NOT IN (9,29,10) THEN ABS(Stake)*0.5  ELSE 0 END END * (1-TPositionTaking))) AS ActualTurnover
	FROM	bettrans14 b WITH (NOLOCK)			
	WHERE	winlostdate = @winlostdate
			AND (bettype < 31 OR b.bettype BETWEEN 121 AND 999 OR bettype BETWEEN 1301 and 1334)	
			AND statusID NOT IN (0, 1, 102, 101, 103)   ----- Void, reiject, refund
			AND b.TransID NOT IN  ( SELECT	TransID 
									FROM	Bettrans14_Agent WITH (NOLOCK)
									WHERE	winlostdate = @winlostdate			 
											AND statusID not in (0,1,101,102,103) --('VOID','REJECT','REFUND')
											AND (bettype < 31 OR bettype BETWEEN 121 AND 999 OR bettype BETWEEN 1301 and 1334)
											AND AgentID = 53288 -----line test Suntest
									)  	 	
	GROUP BY		
			liveindicator,
			Bettype,
			matchid	
	

	----------------------------------------------------------
	--Get data

	SELECT	b.liveindicator,
			bt.Bettype,
			sum(WinLost) winlost,
			sum(Share) Share,
			sum(Commission) commission,	
			sum(LineTotal) LineTotal,
			sum(Turnover) turnover,
			SUM(ActualTurnover) ActualTurnover 
	FROM	#Tempbettrans14 b
		INNER JOIN @Match14 m on b.matchid = m.matchid 	
		INNER JOIN @tmpBettype bt ON b.bettype = bt.Bettype
	WHERE   m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END
	GROUP BY		
			b.liveindicator,
			bt.Bettype, 		
			bt.DisplayOrder		
	ORDER BY
			b.liveindicator, bt.DisplayOrder

DROP TABLE #TempBettrans14


GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_Soccer_Bettype14] TO [aplweb]