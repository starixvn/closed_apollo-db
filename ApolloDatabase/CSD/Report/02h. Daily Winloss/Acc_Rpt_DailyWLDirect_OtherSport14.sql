ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_OtherSport14]
	@winlostdate	date
AS
SET NOCOUNT ON

/*	Creator: Sophia
	Date: 20130815
	Task: Daily Winloss Report by Other Sport (2h)
	DB: SVRSCD.RepDB
	
	Revisions: 
	 		
*/

	DECLARE @Match14 TABLE (matchid int, sporttype tinyint, type varchar(10), primary key(matchid, type))
	
	INSERT INTO @Match14
	SELECT	m.matchid,
			l.sporttype SportType,
			m.type
	FROM 
		(	select matchid, leagueid, 'match' as type from match14 with (nolock) where eventdate = @winlostdate
			union all
			select orid, leagueid, 'outright' as type from outright14 with (nolock) where eventdate = @winlostdate
		) m
	INNER JOIN league l with (nolock) ON m.leagueid = l.leagueid
	WHERE l.sporttype >1
	
	-----------------------------------------------------

	SELECT
			b.liveindicator, 
			m.sporttype as SportType,
			CONVERT(MONEY,sum((winlost-actual_stake)*actualrate)) WinLost,
			CONVERT(MONEY,sum((TWinlost)*actualrate)) Share,
			CONVERT(MONEY,sum(TComm*actualrate)) Commission,	
			CONVERT(MONEY,sum((winlost-actual_stake+TWinlost+Tcomm)*actualrate)) LineTotal,
			CONVERT(MONEY,sum((1-TPositiontaking)*ABS(stake)*actualrate)) Turnover
	FROM	bettrans14 b WITH (NOLOCK)
		INNER JOIN @Match14 m on b.matchid = m.matchid
	WHERE
			b.winlostdate = @winlostdate
			AND (b.bettype < 31 OR b.bettype BETWEEN 121 AND 999 OR bettype BETWEEN 1301 and 1334)
			AND b.statusID NOT IN (0, 1, 102, 101, 103)  ---- Void, reiject, refund			
			AND m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END  
	GROUP BY
			b.liveindicator, 
			m.sporttype
	ORDER BY
			b.liveindicator, 
			m.sporttype
	
 
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_OtherSport14] TO [AplWeb]
GO 
