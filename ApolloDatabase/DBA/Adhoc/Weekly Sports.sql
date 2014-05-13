--RepDB:

DECLARE @fromDate datetime, @todate datetime

select @fromDate = '2014-1-6', @todate = '2014-4-6'

select agentid
into #TestAgents
from AgentInfo (nolock)
WHERE AgentLevel=1 and Username <> 'pal'

select winlostdate [Date], 
	case when LiveIndicator = 0 then 'Non-Live' else 'Live' end [Live Status],
	bt.typenamee [Bet Type],
	sp.sportname Sport,
	ISNULL(groupname, 'Others') [Group],
	l.leaguename League,
	-SUM((winlost-actual_stake+Twinlost+TComm)*actualrate) [Winloss Sunbet],		
	SUM((1-tpositiontaking)*actualrate*
		case when winlostdate < '2014-3-28' then
			CASE WHEN B.StatusID IN (112,113) AND (ABS(B.MOdds) <> 0.25 OR B.Bettype IN (9,29,10)) THEN ABS(B.Stake) 
			ELSE CASE WHEN B.StatusID IN (112,113) AND ABS(B.MOdds) =0.25 AND B.Bettype NOT IN (9,29,10) THEN  ABS(B.Stake)*0.5 ELSE 0 END END
		else CASE WHEN B.StatusID IN (112,113) THEN dbo.[F_GetCommBase] (B.Stake, B.Odds, B.Bettype, B.MOdds) ELSE 0 END
		end) [Turnover Sunbet]
from ArchiveDB.dbo.bettrans_bk b with (nolock)
	left join ArchiveDB.dbo.match_bk m on b.matchid = m.matchid
	left join ArchiveDB.dbo.outright_bk o on b.matchid = o.orid
    left join league l with ( nolock) on m.leagueid = l.leagueid
	left join ReportDB.dbo.tbl_league_group lg with ( nolock) on l.leagueid = lg.leagueid
	left join bettype bt with (nolock) on b.BetType = bt.typeid
	left join Sports sp with (nolock) on l.sporttype = sp.SportType
where winlostdate >= @fromDate
	AND bettype IN(1,3,7,8)
	AND b.statusID NOT IN (0, 1)   ----- Void, reject, refund
	AND b.TransID NOT IN 
	(
		SELECT	TransID FROM ArchiveDB.dbo.Bettrans_Agent_bk WITH (NOLOCK)
		WHERE	winlostdate between @fromDate AND @toDate 
			AND statusID not in (0,1) --('VOID','REJECT','REFUND')
			AND bettype IN(1,3,7,8)
			AND AgentID IN(select agentID from #TestAgents)
	)
group by winlostdate, 
	LiveIndicator,
	bt.typenamee,
	sp.sportname, 
	ISNULL(groupname, 'Others'),
	l.leaguename
UNION ALL
select winlostdate [Date], 
	case when LiveIndicator = 0 then 'Non-Live' else 'Live' end [Live Status],
	bt.typenamee [Bet Type],
	sp.sportname Sport,
	ISNULL(groupname, 'Others') [Group],
	l.leaguename League,
	-SUM((winlost-actual_stake+Twinlost+TComm)*actualrate) [Winloss Sunbet],
	SUM((1-tpositiontaking)*actualrate*
		case when winlostdate < '2014-3-28' then
			CASE WHEN B.StatusID IN (112,113) AND (ABS(B.MOdds) <> 0.25 OR B.Bettype IN (9,29,10)) THEN ABS(B.Stake) 
			ELSE CASE WHEN B.StatusID IN (112,113) AND ABS(B.MOdds) =0.25 AND B.Bettype NOT IN (9,29,10) THEN  ABS(B.Stake)*0.5 ELSE 0 END END
		else CASE WHEN B.StatusID IN (112,113) THEN dbo.[F_GetCommBase] (B.Stake, B.Odds, B.Bettype, B.MOdds) ELSE 0 END
		end) [Turnover Sunbet]
from dbo.bettrans14 b with (nolock)
	left join dbo.match14 m on b.matchid = m.matchid
	left join dbo.outright14 o on b.matchid = o.orid
    left join league l with ( nolock) on m.leagueid = l.leagueid
	left join ReportDB.dbo.tbl_league_group lg with ( nolock) on l.leagueid = lg.leagueid
	left join bettype bt with (nolock) on b.BetType = bt.typeid
	left join Sports sp with (nolock) on l.sporttype = sp.SportType
where 
	bettype IN(1,3,7,8)
	AND b.statusID NOT IN (0, 1)   ----- Void, reject, refund
	AND b.TransID NOT IN 
	(
		SELECT	TransID FROM dbo.Bettrans14_Agent WITH (NOLOCK)
		WHERE	winlostdate between @fromDate AND @toDate 
			AND statusID not in (0,1) --('VOID','REJECT','REFUND')
			AND bettype IN(1,3,7,8)
			AND AgentID IN(select agentID from #TestAgents)
	)
group by winlostdate, 
	LiveIndicator,
	bt.typenamee,
	sp.sportname, 
	ISNULL(groupname, 'Others'),
	l.leaguename
UNION ALL
select winlostdate [Date], 
	case when LiveIndicator = 0 then 'Non-Live' else 'Live' end [Live Status],
	bt.typenamee [Bet Type],
	sp.sportname Sport,
	ISNULL(groupname, 'Others') [Group],
	l.leaguename League,
	-SUM((winlost-actual_stake+Twinlost+TComm)*actualrate) [Winloss Sunbet],
	SUM((1-tpositiontaking)*actualrate*
		case when winlostdate < '2014-3-28' then
			CASE WHEN B.StatusID IN (112,113) AND (ABS(B.MOdds) <> 0.25 OR B.Bettype IN (9,29,10)) THEN ABS(B.Stake) 
			ELSE CASE WHEN B.StatusID IN (112,113) AND ABS(B.MOdds) =0.25 AND B.Bettype NOT IN (9,29,10) THEN  ABS(B.Stake)*0.5 ELSE 0 END END
		else CASE WHEN B.StatusID IN (112,113) THEN dbo.[F_GetCommBase] (B.Stake, B.Odds, B.Bettype, B.MOdds) ELSE 0 END
		end) [Turnover Sunbet]
from dbo.bettrans b with (nolock)
	left join dbo.match m on b.matchid = m.matchid
	left join dbo.outright o on b.matchid = o.orid
    left join league l with ( nolock) on m.leagueid = l.leagueid
	left join ReportDB.dbo.tbl_league_group lg with ( nolock) on l.leagueid = lg.leagueid
	left join bettype bt with (nolock) on b.BetType = bt.typeid
	left join Sports sp with (nolock) on l.sporttype = sp.SportType
where winlostdate <= @toDate
	AND bettype IN(1,3,7,8) and b.ruben = 1
	AND b.statusID NOT IN (0, 1)   ----- Void, reject, refund
	AND b.TransID NOT IN 
	(
		SELECT	TransID FROM dbo.Bettrans_Agent WITH (NOLOCK)
		WHERE	winlostdate between @fromDate AND @toDate 
			AND statusID not in (0,1) --('VOID','REJECT','REFUND')
			AND bettype IN(1,3,7,8) and b.ruben = 1
			AND AgentID IN(select agentID from #TestAgents)
	)
group by winlostdate, 
	LiveIndicator,
	bt.typenamee,
	sp.sportname, 
	ISNULL(groupname, 'Others'),
	l.leaguename
order by Date, [Live Status], league, [Bet Type]

---Get matchcount

select winlostdate [Date], 
	case when LiveIndicator = 0 then 'Non-Live' else 'Live' end [Live Status],
	sp.sportname Sport,
	ISNULL(groupname, 'Others') [Group],
	l.leaguename League,
	count(distinct b.matchid) [Match Count]
from ArchiveDB.dbo.bettrans_bk b with (nolock)
	left join ArchiveDB.dbo.match_bk m on b.matchid = m.matchid
	left join ArchiveDB.dbo.outright_bk o on b.matchid = o.orid
    left join league l with ( nolock) on m.leagueid = l.leagueid
	left join ReportDB.dbo.tbl_league_group lg with ( nolock) on l.leagueid = lg.leagueid
	left join Sports sp with (nolock) on l.sporttype = sp.SportType
where winlostdate >= @fromDate
	AND bettype IN(1,3,7,8)
	AND b.statusID NOT IN (0, 1)   ----- Void, reject, refund
	AND b.TransID NOT IN 
	(
		SELECT	TransID FROM ArchiveDB.dbo.Bettrans_Agent_bk WITH (NOLOCK)
		WHERE	winlostdate between @fromDate AND @toDate 
			AND statusID not in (0,1) --('VOID','REJECT','REFUND')
			AND bettype IN(1,3,7,8)
			AND AgentID IN(select agentID from #TestAgents)
	)
group by winlostdate, 
	LiveIndicator,
	sp.sportname, 
	ISNULL(groupname, 'Others'),
	l.leaguename
UNION ALL
select winlostdate [Date], 
	case when LiveIndicator = 0 then 'Non-Live' else 'Live' end [Live Status],
	sp.sportname Sport,
	ISNULL(groupname, 'Others') [Group],
	l.leaguename League,
	count(distinct b.matchid) [Match Count]
from dbo.bettrans14 b with (nolock)
	left join dbo.match14 m on b.matchid = m.matchid
	left join dbo.outright14 o on b.matchid = o.orid
    left join league l with ( nolock) on m.leagueid = l.leagueid
	left join ReportDB.dbo.tbl_league_group lg with ( nolock) on l.leagueid = lg.leagueid
	left join Sports sp with (nolock) on l.sporttype = sp.SportType
where 
	bettype IN(1,3,7,8)
	AND b.statusID NOT IN (0, 1)   ----- Void, reject, refund
	AND b.TransID NOT IN 
	(
		SELECT	TransID FROM dbo.Bettrans14_Agent WITH (NOLOCK)
		WHERE	winlostdate between @fromDate AND @toDate 
			AND statusID not in (0,1) --('VOID','REJECT','REFUND')
			AND bettype IN(1,3,7,8)
			AND AgentID IN(select agentID from #TestAgents)
	)
group by winlostdate, 
	LiveIndicator,
	sp.sportname, 
	ISNULL(groupname, 'Others'),
	l.leaguename
UNION ALL
select winlostdate [Date], 
	case when LiveIndicator = 0 then 'Non-Live' else 'Live' end [Live Status],
	sp.sportname Sport,
	ISNULL(groupname, 'Others') [Group],
	l.leaguename League,
	count(distinct b.matchid) [Match Count]
from dbo.bettrans b with (nolock)
	left join dbo.match m on b.matchid = m.matchid
	left join dbo.outright o on b.matchid = o.orid
    left join league l with ( nolock) on m.leagueid = l.leagueid
	left join ReportDB.dbo.tbl_league_group lg with ( nolock) on l.leagueid = lg.leagueid
	left join Sports sp with (nolock) on l.sporttype = sp.SportType
where winlostdate <= @toDate
	AND bettype IN(1,3,7,8) and b.ruben = 1
	AND b.statusID NOT IN (0, 1)   ----- Void, reject, refund
	AND b.TransID NOT IN 
	(
		SELECT	TransID FROM dbo.Bettrans_Agent WITH (NOLOCK)
		WHERE	winlostdate between @fromDate AND @toDate 
			AND statusID not in (0,1) --('VOID','REJECT','REFUND')
			AND bettype IN(1,3,7,8) and b.ruben = 1
			AND AgentID IN(select agentID from #TestAgents)
	)
group by winlostdate, 
	LiveIndicator,
	sp.sportname, 
	ISNULL(groupname, 'Others'),
	l.leaguename
order by Date, [Live Status], league




DROP TABLE #TestAgents