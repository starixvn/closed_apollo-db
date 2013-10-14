ALTER PROCEDURE [dbo].[Acc_Rpt_WinlossByBettype14]
	@winlostdate date
AS
/*	
	Creator: Don
	Date: 2013-03-18
	Task: Daily summary winloss report - by bettype
	DB: SRVCSD.RepDB
	
	Revision:
		- 20130906@Sophia: revise Sp to seek index
		- 20130916@Sophia: add ActualTurnover, exclude line test Suntest 53288		
		- 20130923@Sophia: add Comm	
		- 20131014@Sophia: Fixed Parlay use Left join , and use liveawayscore to define Soccer
	Explanation's Param:

*/
BEGIN	
	SET NOCOUNT ON		
	
	-- Fill data of all sports into temporary tables
	CREATE TABLE #tmpBettrans (matchid int, bettype int, statusID int, liveindicator bit, winlost money, pos money, comm money, LineTotal money, Turnover money, ActualTurnover money)
	CREATE INDEX IX_bettype on #tmpBettrans(bettype)
	
	
	CREATE TABLE #TestLine (TransID BIGINT)

	INSERT INTO #TestLine (TransID)
	SELECT	TransID 
	FROM	Bettrans14_Agent WITH (NOLOCK)
	WHERE	winlostdate = @winlostdate			 
	AND statusID not in (0,1,101,102,103) --('VOID','REJECT','REFUND')
	AND bettype <= 19000
	AND AgentID = 53288 -----line test Suntest


	INSERT INTO #tmpBettrans (matchid, bettype, statusID, liveindicator, winlost, pos, comm, LineTotal, Turnover, ActualTurnover)
	SELECT  matchid, bettype, statusID, liveindicator,
			sum((winlost-actual_stake)*actualrate) winlost,
			sum(twinlost*actualrate) pos,
			sum(tcomm*actualrate) comm,	
			sum((winlost-actual_stake+twinlost+tcomm) *actualrate) LineTotal,
			sum((1-tpositiontaking)*ABS(stake)*actualrate) Turnover,
				SUM(CASE WHEN StatusID IN (112,113) AND (ABS(MOdds) <> 0.25 OR Bettype IN (9,29,10)) THEN ABS(Stake)
				 ELSE CASE WHEN StatusID IN (112,113) AND ABS(MOdds) =0.25 AND Bettype NOT IN (9,29,10) THEN ABS(Stake)*0.5  ELSE 0 END END * (1-TPositionTaking) *actualrate) AS ActualTurnover
	FROM	dbo.bettrans14 with(nolock)
	WHERE	winlostdate = @winlostdate		
			AND statusID not in (0,1,101,102,103) --('VOID','REJECT','REFUND')
			AND bettype <= 19000
			AND TransID NOT IN (SELECT TransID FROM #TestLine)
	GROUP BY matchid, bettype, statusID, liveindicator
	-- END - Fill data of all sports into temporary tables
	
	-- Resultset by bettype of 
	    -- Sportbook without Parlay and Outright
	SELECT	b.bettype,
			sum(case when liveindicator = 1 and sporttype = 1 then LineTotal else 0 end) as LineTotal_soccer_live,
			sum(case when liveindicator = 0 and sporttype = 1 then LineTotal else 0 end) as LineTotal_soccer,
			
			sum(case when liveindicator = 1 and sporttype <> 1 then LineTotal else 0 end) as LineTotal_others_live,
			sum(case when liveindicator = 0 and sporttype <> 1 then LineTotal else 0 end) as LineTotal_others,
			
			sum(Turnover) as Turnover,
			SUM(ActualTurnover) as ActualTurnover,
			SUM(Comm) as Comm
	FROM 	#tmpBettrans b with(nolock)
			inner join match14 m with(nolock) on b.matchid = m.matchid
	WHERE   ((bettype < 31 and bettype <> 10) OR bettype between 121 and 999  OR bettype between 1301 and 1334)
	GROUP BY b.bettype
	
	/*
	    -- Number Game
	UNION ALL
	SELECT	bettype,	
			0 LineTotal_soccer_live,
			0 LineTotal_soccer,
			sum(case when liveindicator = 1 then LineTotal else 0 end) as LineTotal_others_live,		
			sum(case when liveindicator = 0 then LineTotal else 0 end) as LineTotal_others,
			sum(Turnover) as Turnover,
			SUM(ActualTurnover) as ActualTurnover,
			SUM(Comm) as Comm
	FROM	#tmpBettrans with (nolock)
	WHERE	bettype BETWEEN 81 AND 120			
	GROUP BY bettype
	*/

	    -- Parlay
	UNION ALL 
	SELECT 	m1.bettype,
			0 LineTotal_soccer_live,
			LineTotal_soccer,
			
			0 LineTotal_others_live,
			LineTotal - LineTotal_soccer as LineTotal_others,
			
			Turnover,
			ActualTurnover,
			Comm
	FROM
		(
			SELECT 	bettype,
					isnull(sum(LineTotal), 0) as LineTotal,
					isnull(sum(Turnover), 0) as Turnover,
					isnull(SUM(ActualTurnover),0) as ActualTurnover,
					ISNULL(SUM(Comm),0) as Comm
			FROM	#tmpBettrans with (nolock)
			WHERE 	bettype IN (9, 29) 
			GROUP BY bettype
		) m1
		LEFt JOIN 
		(
			SELECT 	bettype,	
					isnull(sum((winlost-actual_stake+twinlost+tcomm)*actualrate), 0) as LineTotal_soccer
			FROM	bettrans14 with(nolock)
			WHERE 	bettype IN (9, 29) and
					winlostdate = @winlostdate and					
					statusid NOT IN (0,1,101,102,103) and
					TransID NOT IN (SELECT TransID FROM #TestLine) and
					liveawayscore IN (1,3)
					---refno IN (SELECT refno FROM bettransm14 with(nolock) inner join match14 with(nolock) on bettransm14.matchid = match14.matchid WHERE sporttype=1)
			GROUP BY bettype
		) m2 on m1.bettype = m2.bettype
		
	    -- Outright
	UNION ALL 
	SELECT	bettype,	
			0 LineTotal_soccer_live,
			sum(case when sporttype = 1 then LineTotal else 0 end) as LineTotal_soccer,
			0 LineTotal_others_live,	
			sum(case when sporttype <> 1 then LineTotal else 0 end) as LineTotal_others,
			sum(Turnover) as Turnover,
			SUM(ActualTurnover) as ActualTurnover,
			SUM(Comm) as Comm
	FROM #tmpBettrans b with(nolock) 
		inner join outright14 o with(nolock) on b.matchid = o.orid
		inner join league l with(nolock) on o.leagueid = l.leagueid	
	WHERE b.bettype = 10
	GROUP BY Bettype
	-- END - Resultset by bettype of 
		
    DROP TABLE #tmpBettrans
END



GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_WinlossByBettype14] TO [aplweb]