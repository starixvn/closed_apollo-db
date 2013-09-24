ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_OtherSport]
	@winlostdate	date
AS
SET NOCOUNT ON

/*	Creator: Sophia
	Date: 20130815
	Task: Daily Winloss Report by Other Sport (2h)
	DB: SVRSCD.RepDB
	
	Revisions: 
	 	 - 20130916@Sophia: add ActualTurnover, exclude line test Suntest 53288	
*/

	DECLARE @Match TABLE (matchid int, sporttype tinyint, type varchar(10), primary key(matchid, type))
	
	INSERT INTO @Match
	SELECT	m.matchid,
			l.sporttype SportType,
			m.type
	FROM 
		(	select matchid, leagueid, 'match' as type from match with (nolock) where eventdate = @winlostdate
			union all
			select orid, leagueid, 'outright' as type from outright with (nolock) where eventdate = @winlostdate
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
			CONVERT(MONEY,sum((1-TPositiontaking)*ABS(stake)*actualrate)) Turnover,
			CONVERT(MONEY,SUM(CASE WHEN StatusID IN (112,113) AND (ABS(MOdds) <> 0.25 OR Bettype IN (9,29,10)) THEN ABS(Stake)
										 ELSE CASE WHEN StatusID IN (112,113) AND ABS(MOdds) =0.25 AND Bettype NOT IN (9,29,10) THEN ABS(Stake)*0.5  ELSE 0 END END * (1-TPositionTaking))) AS ActualTurnover
	FROM	bettrans b WITH (NOLOCK)
		INNER JOIN @Match m on b.matchid = m.matchid
	WHERE
			b.winlostdate = @winlostdate
			AND (b.bettype < 31 OR b.bettype BETWEEN 121 AND 999 OR bettype BETWEEN 1301 and 1334)
			AND b.statusID NOT IN (0, 1, 102, 101, 103)  ---- Void, reiject, refund			
			AND m.type = CASE WHEN b.bettype = 10 THEN 'outright' ELSE 'match' END 
			AND b.TransID NOT IN  ( SELECT	TransID 
									FROM	Bettrans_Agent WITH (NOLOCK)
									WHERE	winlostdate = @winlostdate			 
											AND statusID not in (0,1,101,102,103) --('VOID','REJECT','REFUND')
											AND (bettype < 31 OR bettype BETWEEN 121 AND 999 OR bettype BETWEEN 1301 and 1334)
											AND AgentID = 53288 -----line test Suntest
									) 
	GROUP BY
			b.liveindicator, 
			m.sporttype
	ORDER BY
			b.liveindicator, 
			m.sporttype
	 
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_OtherSport] TO [AplWeb]
GO 
