ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_OtherSport_Bettype]
	@winlostdate	datetime,
	@sporttype int
AS
SET NOCOUNT ON

/*	Creator: Sophia
	Date: 20130815
	Task : Daily Winloss Report / Other Sports by Bettype (2h)
	DB: SVRCSD.RepDB

	Revisions:
		- 20130916@Sophia: add ActualTurnover, exclude line test Suntest 53288	
*/

	Declare @tmpBettype table (Bettype int primary key, DisplayOrder int)


	Insert into @tmpBettype
	select 1, 1 --'Handicap'
	UNION ALL
	Select 3, 2 --'Over/Under'
	UNION ALL
	select 7, 3 --'1st Half Handicap'
	UNION ALL
	Select 8, 4 -- '1st Half Over/Under',
	UNION ALL
	select 2, 5 -- 'Odd/Even',
	UNION ALL
	select 5, 6 -- '1x2',
	UNION ALL
	Select 4, 7 --'Correct Score',
	UNION ALL
	Select 6, 8 --'Total Goal',
	UNION ALL
	Select 10, 10 -- 'Outright',
 
	
	INSERT INTO @tmpBettype
		SELECT typeid, typeid
		FROM bettype WITH(NOLOCK)
		WHERE (typeid > 10 AND typeid < 31) OR typeid BETWEEN 121 AND 999 OR typeid BETWEEN 1301 AND 1334

	
	--Declare @temp table to contain all matches
	DECLARE @Match TABLE (matchid int, type varchar(10), primary key(matchid, type))
	INSERT INTO @Match
	SELECT	m.matchid,
			m.type
	FROM 
		(	select matchid, leagueid, 'match' as type from match with (nolock) where eventdate = @winlostdate
			union all
			select orid, leagueid, 'outright' as type from outright with (nolock) where eventdate = @winlostdate
		) m
	INNER JOIN league l with (nolock) ON m.leagueid = l.leagueid
	WHERE	l.sporttype = @sporttype 
			 

	SELECT		
			b.liveindicator,
			bt.Bettype,
			CONVERT(MONEY,sum((winlost-actual_stake)*ActualRate)) WinLost,
			CONVERT(MONEY,sum((TWinlost)*ActualRate)) Share,
			CONVERT(MONEY,sum(TComm*ActualRate)) Commission,	 
			CONVERT(MONEY,sum((winlost-actual_stake+TWinlost+TComm)*ActualRate)) LineTotal,
			CONVERT(MONEY,sum((1-TPositiontaking)* ABS(stake) * ActualRate)) Turnover,
			CONVERT(MONEY,SUM(CASE WHEN ABS(MOdds) <> 0.25 AND StatusID IN (112,113) THEN ABS(Stake) ELSE CASE WHEN ABS(MOdds) =0.25 AND StatusID IN (112,113) THEN  ABS(Stake)*0.5  ELSE 0 END END * (1-TPositionTaking))) AS ActualTurnover
	FROM	bettrans b WITH (NOLOCK)
			INNER JOIN @Match m on b.matchid = m.matchid
			INNER JOIN @tmpBettype bt ON b.bettype = bt.Bettype
	WHERE	winlostdate = @winlostdate
			AND (b.bettype < 31 OR b.bettype BETWEEN 121 AND 999 OR b.bettype BETWEEN 1301 and 1334)
			AND b.statusID NOT IN (0, 1, 102, 101, 103) 
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
			bt.Bettype,
			bt.DisplayOrder
	ORDER BY
			b.liveindicator, 
			bt.DisplayOrder
	
GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_OtherSport_Bettype] TO [aplweb]
GO 