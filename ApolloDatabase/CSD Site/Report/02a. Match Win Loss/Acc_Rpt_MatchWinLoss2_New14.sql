ALTER PROCEDURE [dbo].[Acc_Rpt_MatchWinLoss2_New14]
	@winlostdate date
AS
/*	
	Creator: Don
	Date: 2013-03-18
	Task: Daily detail winloss report - by match
	DB: SVRCSD.RepDB
	
	Revision:
	- 20130906@Sophia:  group by at Outright section to avoid one row which no data
					    Change Ruben = 1 to StatusID not in (0,1) to seek index
						remove virtualrate
	- 20130916@Sophia: add ActualTurnover, exclude line test Suntest 53288 						   			
	Explanation's Param:

*/
BEGIN	
	SET NOCOUNT ON		
	
	-- Fill data of all sports into temporary tables
	CREATE TABLE #tmpBettrans (matchid int, bettype int, statusID int, liveindicator bit, winlost money, pos money, comm money, LineTotal money, Turnover money, ActualTurnover money)
	CREATE INDEX IX_bettype on #tmpBettrans(bettype)
	
	INSERT INTO #tmpBettrans (matchid, bettype, statusID, liveindicator, winlost, pos, comm, LineTotal, Turnover, ActualTurnover )
	SELECT  matchid, bettype, statusID, liveindicator,
			sum((winlost-actual_stake)*actualrate) winlost,
			sum(twinlost*actualrate) pos,
			sum(tcomm*actualrate) comm,		
			sum((winlost-actual_stake+twinlost+tcomm) *actualrate) LineTotal,
			sum((1-tpositiontaking)*ABS(stake)*actualrate) Turnover,
			SUM(CASE WHEN StatusID IN (112,113) AND (ABS(MOdds) <> 0.25 OR Bettype IN (9,29,10)) THEN ABS(Stake)
				 ELSE CASE WHEN StatusID IN (112,113) AND ABS(MOdds) =0.25 AND Bettype NOT IN (9,29,10) THEN ABS(Stake)*0.5  ELSE 0 END END * (1-TPositionTaking)*actualrate) AS ActualTurnover
	FROM	dbo.bettrans14 with(nolock)
	WHERE	winlostdate = @winlostdate
			AND statusID not in (0,1,101,102,103 ) --('VOID','REJECT','REFUND' )
			AND bettype <= 19000
			AND TransID NOT IN (SELECT	TransID 
								FROM	Bettrans14_Agent WITH (NOLOCK)
								WHERE	winlostdate = @winlostdate			 
										AND statusID not in (0,1,101,102,103) --('VOID','REJECT','REFUND')
										AND bettype <= 19000
										AND AgentID = 53288 -----line test Suntest
								)
	GROUP BY matchid, bettype, statusID, liveindicator
	-- END - Fill data of all sports into temporary tables
	
	-- Resultset of Sportbook without Parlay and Outright
	SELECT 
	    UPPER(case when l.leaguenametc = '' or l.leaguenametc is null  then 'Other Sports' else l.leaguenametc end) as leaguenametc,
		b.bettype,
		b.liveindicator,		
		m.matchcode,
		m.kickofftime,
		b.matchid,
		m.homeid,
		m.awayid,
		isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
        b.winlost,
        b.pos,
        b.comm,   
        b.LineTotal,
        b.Turnover,
		b.ActualTurnover
	FROM 
	    (
	        SELECT 
	            matchid, bettype, liveindicator,
	            sum(winlost) winlost,
                sum(pos) pos,
                sum(comm) comm,
                sum(LineTotal) LineTotal,
                sum(Turnover) Turnover,
				Sum(ActualTurnover) ActualTurnover
	        FROM #tmpBettrans with(nolock)
	        GROUP BY matchid, bettype, liveindicator
	    ) b
		inner join match14 m with(nolock) on m.matchid = b.matchid
		inner join league l with(nolock) on l.leagueid = m.leagueid
	WHERE ((bettype < 31 AND bettype <> 10) OR bettype between 121 and 999 OR bettype between 1301 and 1334 )
	ORDER BY l.leaguenametc, b.bettype, b.liveindicator desc
	
	-- Resultset of 3rd products and Parlay, Outright
	    -- Mix Parlay
	SELECT	@winlostdate winlostdate,
	        sum(b.winlost) as winlost,
			sum(b.pos) as pos,
			sum(b.comm) as comm,
			sum(b.Linetotal) as LineTotal,
			sum(b.Turnover) Turnover,
			Sum(ActualTurnover) ActualTurnover,
			'Parlay-' + case when b.statusID = 111 THEN 'DRAW'
							 WHEN b.statusID = 113 THEN 'LOSE'
							 WHEN b.statusID = 112 THEN 'WON' END as bettype
	FROM	#tmpBettrans b with(nolock)
	WHERE	bettype = 9 OR bettype = 29 	
	GROUP BY StatusId		
	
	    -- Outright 
	UNION ALL
	SELECT	@winlostdate winlostdate,
	        sum(b.winlost) as winlost,
			sum(b.pos) as pos,
			sum(b.comm) as comm,
			sum(b.Linetotal) as LineTotal,
			sum(b.Turnover) Turnover,
			Sum(ActualTurnover) ActualTurnover,
			'Outright' as bettype 
	FROM	#tmpBettrans b with(nolock)
	WHERE	bettype = 10 			
	GROUP BY bettype 	
	/*
		-- Number Game
	UNION ALL
	SELECT	@winlostdate winlostdate,
	        sum(b.winlost) as winlost,
			sum(b.pos) as pos,
			sum(b.comm) as comm,
			sum(b.Linetotal) as LineTotal,
			sum(b.Turnover) Turnover,
			Sum(ActualTurnover) ActualTurnover,
			'Number Game' as bettype
	FROM	#tmpBettrans b with(nolock)
	WHERE	bettype BETWEEN 81 AND 120
	*/

	-- END - Resultset of 3rd products and Parlay, Outright
		
    DROP TABLE #tmpBettrans
END



GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_MatchWinLoss2_New14] TO [aplweb]