ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_SystemParlay14]
	@winlostdate	datetime	
AS


/*	Creator: Sophia
	Date: 20130819
	Task: Daily Winloss Report (2h)/ System parlay
	DB: SVRCSD.RepDB

	Revisions: 
		
	
	Parameter's Explanation:	
				   
*/
SET NOCOUNT ON 


CREATE TABLE #tmpMixSports( refno BIGINT )
DECLARE @tmpOtherSports TABLE( refno BIGINT)


INSERT INTO #tmpMixSports(refno)
SELECT	refno 
FROM(
		SELECT DISTINCT m.sporttype, bm.refno 
		FROM	bettransm14 bm WITH (NOLOCK)
				INNER JOIN Match14 m WITH (NOLOCK) ON bm.matchid = m.matchid 
		WHERE	refno IN( 
			SELECT	refno
			FROM	bettrans14 WITH (NOLOCK)
			WHERE	bettype = 29	 
					AND statusID NOT IN (0,1,101,102,103) ---- 'Runing','VOID','REJECT','REFUND'
					AND winlostdate = @winlostdate
							)
		UNION 
		SELECT DISTINCT m14.sporttype, bm14.refno
		FROM	bettransm14 bm14 WITH (NOLOCK)
				INNER JOIN match14 m14 WITH (NOLOCK) ON bm14.matchid = m14.matchid 
		WHERE	refno IN (
			SELECT	refno
			FROM	bettrans14 WITH (NOLOCK)
			WHERE	bettype = 29		
					AND statusID NOT IN (0,1,101,102,103) ---- 'Runing','VOID','REJECT','REFUND' 
					AND winlostdate = @winlostdate
							)	
) s
GROUP BY refno 
HAVING COUNT(refno) > 1 	

INSERT INTO @tmpOtherSports( refno)
SELECT	refno 
FROM(
		SELECT DISTINCT m.sporttype, bm.refno 
		FROM	bettransm14 bm WITH (NOLOCK)
				INNER JOIN Match14 m WITH (NOLOCK) ON bm.matchid = m.matchid 
		WHERE	refno IN( 
			SELECT	refno
			FROM	bettrans14 WITH (NOLOCK)
			WHERE	bettype = 29
					AND statusID NOT IN (0,1,101,102,103) ---- 'Runing','VOID','REJECT','REFUND' 
					AND winlostdate = @winlostdate
		)
		UNION 
		SELECT DISTINCT m14.sporttype, bm14.refno
		FROM	bettransm14 bm14 WITH (NOLOCK)
				INNER JOIN match14 m14 WITH (NOLOCK) ON bm14.matchid = m14.matchid 
		WHERE	refno IN (
			SELECT	refno
			FROM	bettrans14 WITH (NOLOCK)
			WHERE	bettype = 29
					AND statusID NOT IN (0,1,101,102,103) ---- 'Runing','VOID','REJECT','REFUND' 
					AND winlostdate = @winlostdate
		)	
) o
WHERE sporttype <> 1 
AND refno NOT IN (SELECT refno FROM #tmpMixSports with (NOLOCK))



---- Multi
SELECT  98 sporttype,status, 
		CONVERT(MONEY,sum((winlost-actual_stake)*ActualRate)) WinLost,
		CONVERT(MONEY,sum((TWinLost)*ActualRate)) Share,
		CONVERT(MONEY,sum(TComm*ActualRate)) Commission,	
		CONVERT(MONEY,sum((winlost-actual_stake+TWinlost+TComm)*ActualRate)) LineTotal,
		CONVERT(MONEY,sum((1-TPositionTaking)*ABS(case when bettype=29 and betid>0 then actual_stake else stake end)*ActualRate)) Turnover
		
FROM	bettrans14 b14 WITH (NOLOCK)
		INNER JOIN #tmpMixSports m WITH (NOLOCK) ON b14.refno = m.refno 
WHERE	bettype = 29 AND		
		b14.winlostdate = @winlostdate AND		 
		b14.statusID NOT IN (0,1,101,102,103)
GROUP BY status 

----Soccer
UNION ALL
SELECT 
		1 sporttype,status, 
		CONVERT(MONEY,sum((winlost-actual_stake)*ActualRate)) WinLost,
		CONVERT(MONEY,sum((TWinlost)*ActualRate)) Share,
		CONVERT(MONEY,sum(TComm*ActualRate)) Commission,	
		CONVERT(MONEY,sum((winlost-actual_stake+TComm)*ActualRate)) LineTotal,
		CONVERT(MONEY,sum((1-tpositiontaking)*ABS(case when bettype=29 and betid>0 then  actual_stake else stake end)*ActualRate)) Turnover
FROM	bettrans14 b14 WITH (NOLOCK)
WHERE 	bettype = 29 AND	 
		b14.winlostdate = @winlostdate AND		 
		b14.statusID NOT IN (0,1,101,102,103) AND
		b14.refno NOT IN (	SELECT refno FROM #tmpMixSports WITH (NOLOCK) 
							UNION 
							SELECT refno FROM @tmpOtherSports 
							)
GROUP BY status 

--- Others 
UNION ALL 
SELECT 
		99 sporttype,status, 
		CONVERT(MONEY,sum((winlost-actual_stake)*ActualRate)) WinLost,
		CONVERT(MONEY,sum((TWinLost)*ActualRate)) Share,
		CONVERT(MONEY,sum(TComm*ActualRate)) Commission,	
		CONVERT(MONEY,sum((winlost-actual_stake+TWinlost+TComm)*ActualRate)) LineTotal,
		CONVERT(MONEY,sum((1-tpositiontaking)*ABS(case when bettype=29 and betid>0 then  actual_stake else stake end)*ActualRate)) Turnover
FROM	bettrans14 b14 WITH (NOLOCK)
WHERE	bettype = 29 AND
		b14.winlostdate = @winlostdate AND	
		b14.statusID NOT IN (0,1,101,102,103) AND
		b14.refno IN (SELECT refno FROM @tmpOtherSports)
GROUP BY status 

DROP TABLE #tmpMixSports
	-------------------
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_SystemParlay14] TO [aplweb]
GO