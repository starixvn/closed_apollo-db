--RepDB:

DECLARE @fromDate datetime, @todate datetime

select @fromDate = '2014-3-3', @todate = '2014-5-4'

select agentid
into #TestAgents
from AgentInfo (nolock)
WHERE AgentLevel=1 and Username <> 'pal'

CREATE TABLE #matchCat(matchid INT,
		LeagueName VARCHAR(500),
		TeamName VARCHAR(500),
		ISNoOfCorners BIT,IsNextCorner BIT,ISKickOff BIT,IsSpecific10MINS BIT,IsSpecific15MINS BIT,IsFANTASY BIT)

insert into #matchCat
select m.Matchid,L.LeagueName,
	CASE WHEN ISNULL(h.TeamName,'')<> '' THEN h.TeamName ELSE '' END +
	CASE WHEN ISNULL(a.TeamName,'')<> '' THEN a.TeamName ELSE '' END
		AS TeamName,
	CASE WHEN h.teamname like '%No.of Corners%' THEN 1 ELSE 0 END ISNoOfCorners,
	CASE WHEN h.teamname like '%1st Corner%'
				OR h.teamname like '%2nd Corner%'
				OR h.teamname like '%3rd Corner%'
				OR h.teamname like '%th Corner%' THEN 1 ELSE 0 END IsNextCorner,
	CASE WHEN h.teamname like '%Kick Off%' THEN 1 ELSE 0 END KickOff,
	CASE WHEN l.leaguename like '%Specific 10 MINS %' THEN 1 ELSE 0 END Specific10MINS,
	CASE WHEN l.leaguename like '%Specific 15 MINS %' THEN 1 ELSE 0 END Specific15MINS,
	CASE WHEN l.leaguename like '%FANTASY%' THEN 1 ELSE 0 END FANTASY
from dbo.match14 m WITH (NOLOCK)
	LEFT join dbo.team h WITH (nolock) on m.homeid = h.teamid
	LEFT join dbo.team a WITH (nolock) on m.awayid = a.teamid
	LEFT join dbo.league l WITH (nolock) on m . leagueid = l .leagueid
WHERE eventdate BETWEEN @fromDate AND @toDate


select winlostdate [Date], 
	case when LiveIndicator = 0 then 'Non-Live' else 'Live' end [Live Status],
	sp.sportname Sport,
	CASE WHEN lg.groupid = 1 THEN 'Major League' ELSE 'Non-Major League' END [Group],
	CASE 
	WHEN mc.ISNoOfCorners =1 THEN 'No. of Corners'
	WHEN mc.IsNextCorner =1 THEN 'Next Corner'
	WHEN mc.IsSpecific10MINS =1 THEN 'Specific 10 Minutes'
	WHEN mc.IsSpecific15MINS =1 THEN 'Specific 15 Minutes'
	WHEN mc.IsFANTASY =1 THEN 'Fantasy'
	ELSE bt.typenamee END Bettype,
	COUNT(DISTINCT COALESCE(mc.teamname,h.teamname,a.teamname)) NoOfMatches
	--count(distinct b.matchid) [Match Count]
from dbo.bettrans14 b with (nolock)
	left join dbo.bettype bt on b.bettype = bt.typeid
	left join dbo.match14 m on b.matchid = m.matchid
	left join dbo.outright14 o on b.matchid = o.orid
	LEFT JOIN #matchCat mc with (NOLOCK) ON m.matchid = mc.matchid
	LEFT JOIN dbo.team h WITH (nolock) on h.teamid=  m.homeid
	LEFT JOIN dbo.team a WITH (nolock) on a.teamid=  m.awayid
    left join league l with ( nolock) on m.leagueid = l.leagueid
	left join ReportDB.dbo.tbl_league_group lg with ( nolock) on l.leagueid = lg.leagueid
	left join Sports sp with (nolock) on l.sporttype = sp.SportType
where 
	bettype IN(1,3,7,8)
	AND b.statusID NOT IN (0, 1)   ----- Void, reject, refund
	AND winlostdate BETWEEN @fromDate AND @toDate
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
	CASE WHEN lg.groupid = 1 THEN 'Major League' ELSE 'Non-Major League' END,
	CASE 
	WHEN mc.ISNoOfCorners =1 THEN 'No. of Corners'
	WHEN mc.IsNextCorner =1 THEN 'Next Corner'
	WHEN mc.IsSpecific10MINS =1 THEN 'Specific 10 Minutes'
	WHEN mc.IsSpecific15MINS =1 THEN 'Specific 15 Minutes'
	WHEN mc.IsFANTASY =1 THEN 'Fantasy'
	ELSE bt.typenamee END

DROP TABLE #matchCat
DROP TABLE #TestAgents