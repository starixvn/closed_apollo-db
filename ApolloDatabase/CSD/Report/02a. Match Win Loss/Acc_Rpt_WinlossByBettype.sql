ALTER PROCEDURE [dbo].[Acc_Rpt_WinlossByBettype]
	@winlostdate date
AS
/*	
	Creator: Don
	Date: 2013-03-18
	Task: Daily summary winloss report - by bettype
	DB: SVRCSD.RepDB
	
	Revision:
		- 20130906@Sophia: revise Sp to seek index
					
	Explanation's Param:

*/
BEGIN	
	SET NOCOUNT ON		
	
	-- Fill data of all sports into temporary tables
	CREATE TABLE #tmpBettrans (matchid int, bettype int, statusID int, liveindicator bit, winlost money, pos money, comm money, LineTotal money, IBCTurnover money)
	CREATE INDEX IX_bettype on #tmpBettrans(bettype)
	
	INSERT INTO #tmpBettrans (matchid, bettype, statusID, liveindicator, winlost, pos, comm, LineTotal, IBCTurnover)
	SELECT  matchid, bettype, statusID, liveindicator,
			sum((winlost-actual_stake)*actualrate) winlost,
			sum(twinlost*actualrate) pos,
			sum(tcomm*actualrate) comm,	
			sum((winlost-actual_stake+twinlost+tcomm) *actualrate) LineTotal,
			sum((1-tpositiontaking)*stake*actualrate) IBCTurnover
	FROM	dbo.bettrans with(nolock)
	WHERE	winlostdate = @winlostdate
			AND statusID not in (0,1,101,102,103) --('VOID','REJECT','REFUND')
			AND bettype <= 19000
	GROUP BY matchid, bettype, statusID, liveindicator
	-- END - Fill data of all sports into temporary tables
	
	-- Resultset by bettype of 
	-- Sportbook without Parlay and Outright
	SELECT	b.bettype,
			sum(case when liveindicator = 1 and sporttype = 1 then LineTotal else 0 end) as LineTotal_soccer_live,
			sum(case when liveindicator = 0 and sporttype = 1 then LineTotal else 0 end) as LineTotal_soccer,
			
			sum(case when liveindicator = 1 and sporttype <> 1 then LineTotal else 0 end) as LineTotal_others_live,
			sum(case when liveindicator = 0 and sporttype <> 1 then LineTotal else 0 end) as LineTotal_others,
			
			sum(IBCTurnover) as IBCTurnover
	FROM 	#tmpBettrans b with(nolock)
			inner join match m with(nolock) on b.matchid = m.matchid
	WHERE   ((bettype < 31 and bettype <> 10) OR bettype between 121 and 999 OR bettype between 1301 and 1334 )
	GROUP BY b.bettype
	
	/*
	    -- Number Game
	UNION ALL
	SELECT	bettype,
			0 LineTotal_soccer_live,
			0 LineTotal_soccer,
			sum(case when liveindicator = 1 then LineTotal else 0 end) as LineTotal_others_live,	
			sum(case when liveindicator = 0 then LineTotal else 0 end) as LineTotal_others,
			sum(IBCTurnover) as IBCTurnover
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
			IBCTurnover
	FROM
		(
			SELECT 	bettype,
					isnull(sum(LineTotal), 0) as LineTotal,
					isnull(sum(IBCTurnover), 0) as IBCTurnover
			FROM	#tmpBettrans with (nolock)
			WHERE 	bettype IN (9, 29)
			GROUP BY bettype
		) m1
		inner join
		(
			SELECT 	bettype,	
					isnull(sum((winlost-actual_stake+twinlost+tcomm)*actualrate), 0) as LineTotal_soccer
			FROM	bettrans with(nolock)
			WHERE 	bettype IN (9, 29) and
					winlostdate = @winlostdate and
					statusid NOT IN (0,1,101,102,103) and
					refno IN (SELECT refno FROM bettransm with(nolock) inner join match with(nolock) on bettransm.matchid = match.matchid WHERE sporttype=1)
			GROUP BY bettype
		) m2 on m1.bettype = m2.bettype
		
	    -- Outright
	UNION ALL 
	SELECT	bettype,	
			0 LineTotal_soccer_live,
			sum(case when sporttype = 1 then LineTotal else 0 end) as LineTotal_soccer,
			0 LineTotal_others_live,		
			sum(case when sporttype <> 1 then LineTotal else 0 end) as LineTotal_others,
			sum(IBCTurnover) as IBCTurnover
	FROM #tmpBettrans b with(nolock) 
		inner join outright o with(nolock) on b.matchid = o.orid
		inner join league l with(nolock) on o.leagueid = l.leagueid	
	WHERE b.bettype = 10
	GROUP BY bettype 
	-- END - Resultset by bettype of 
		
    DROP TABLE #tmpBettrans
END



GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_WinlossByBettype] TO [aplweb]