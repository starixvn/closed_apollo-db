ALTER PROCEDURE [dbo].[Acc_Rpt_MatchWinLoss2_New]
	@winlostdate date
AS
/*	
	Creator: Don
	Date: 2013-03-18
	Task: Daily detail winloss report - by match
	DB: SVRCSD.RepDB
	
	Revision:
		- 20130906@Sophia: group by at Outright section to avoid one row which no data
						   Change Ruben = 1 to StatusID not in (0,1) to seek index
						   remove virtualrate 
	Explanation's Param:

*/
BEGIN	
	SET NOCOUNT ON		
	
	-- Fill data of all sports into temporary tables
	CREATE TABLE #tmpBettrans (matchid int, bettype int, statusID int,liveindicator bit, winlost money, pos money, comm money, LineTotal money, IBCTurnover money)
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
        b.IBCTurnover
	FROM 
	    (
	        SELECT 
	            matchid, bettype, liveindicator,
	            sum(winlost) winlost,
                sum(pos) pos,
                sum(comm) comm,
                sum(LineTotal) LineTotal,
                sum(IBCTurnover) IBCTurnover
	        FROM #tmpBettrans with(nolock)
	        GROUP BY matchid, bettype, liveindicator
	    ) b
		inner join match m with(nolock) on m.matchid = b.matchid
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
			sum(b.IBCTurnover) IBCTurnover,
			'Parlay-' + case when b.statusID = 111 THEN 'DRAW'
							 WHEN b.statusID = 113 THEN 'LOSE'
							 WHEN b.statusID = 112 THEN 'WON' END as bettype 
	FROM	#tmpBettrans b with(nolock)
	WHERE	bettype = 9 OR bettype = 29 	
	GROUP BY  b.statusID	
	
	    -- Outright 
	UNION ALL
	SELECT	@winlostdate winlostdate,
	        sum(b.winlost) as winlost,
			sum(b.pos) as pos,
			sum(b.comm) as comm,
			sum(b.Linetotal) as LineTotal,
			sum(b.IBCTurnover) IBCTurnover,
			'Outright' as bettype
	FROM	#tmpBettrans b with(nolock)
	WHERE	bettype = 10 			
	GROUP BY bettype				

		-- Number Game
	/*
	UNION ALL
	SELECT	@winlostdate winlostdate,
	        sum(b.winlost) as winlost,
			sum(b.pos) as pos,
			sum(b.comm) as comm,
			sum(b.Linetotal) as LineTotal,
			sum(b.IBCTurnover) IBCTurnover,
			'Number Game' as bettype
	FROM	#tmpBettrans b with(nolock)
	WHERE	bettype BETWEEN 81 AND 120
	*/
	-- END - Resultset of 3rd products and Parlay, Outright
		
    DROP TABLE #tmpBettrans
END



GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_MatchWinLoss2_New] TO [aplweb]