ALTER PROCEDURE [dbo].[Age_Result_MatchSelNumberGameByLeague]
 @FromDate DATETIME,
 @ToDate DATETIME = NULL,
 @LeagueID INT,
 @Language NVARCHAR(2) = 'E',
 @isShowAll bit = 1 -- 1: Show All; 0: is NOT show Test	
AS
/*
Created:  Sophia
Date: 20130401
Task: Get Number Game result by league  
DB: SVRAGE.REPDB
Original: Age_Result_MatchSelNumberGameByLeague  
  
Revisions:   
 

*/  
  
SET NOCOUNT ON  


IF @ToDate IS NULL
SELECT @ToDate = DATEADD(s,-1, DATEADD(d, 1, @FromDate))  
  
SELECT   
	ISNULL(e.betstatus,'') AS betstatus,   
	m.leagueid,  
	m.matchid,
	m.matchcode,  
	m.eventdate,   
	m.kickofftime,
	m.homeid,
	CASE WHEN ISNULL(e.betstatus,'') LIKE 'Refund FT%' THEN 'Refund FT'   
		 WHEN ISNULL(e.betstatus,'') LIKE 'Refund HT%' THEN 'Refund HT'  
		 WHEN ISNULL(e.betstatus,'') LIKE 'Refund%' THEN 'Refund'   
		 ELSE ISNULL(e.eventstatus,'') END AS eventstatus,
	CASE WHEN ISNULL(e.betstatus,'') LIKE 'Refund' THEN 1   
		 ELSE 0 END AS IsRefund,
	b.seq,
	b.number
FROM  
   (SELECT sporttype, matchid, matchcode, leagueid, eventdate, kickofftime, homeid  
	FROM MATCH (NOLOCK)  
    WHERE	eventdate BETWEEN  @FromDate AND @ToDate 
			AND sporttype=161
			AND (@LeagueID = 0 OR leagueid = @LeagueID)
	UNION ALL  
	SELECT sporttype, matchid, matchcode, leagueid, eventdate, kickofftime,homeid   
	FROM match14 (NOLOCK)  
	WHERE	eventdate BETWEEN  @FromDate AND @ToDate 
			AND sporttype=161
			AND (@LeagueID = 0 OR leagueid = @LeagueID)
    )AS m 
	LEFT JOIN (SELECT matchid, seq, number FROM bingoball(NOLOCK)
				UNION ALL
				SELECT matchid, seq, number FROM bingoball14(NOLOCK)
				) AS B ON B.matchid = m.matchid
	LEFT OUTER JOIN match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid  
	LEFT OUTER JOIN match_remark_ex e WITH(NOLOCK) ON m.matchid = e.matchid  
	INNER JOIN league with (nolock) on m.leagueid = league.leagueid
WHERE (e.eventstatus NOT IN ('internal','running') OR (e.eventstatus = 'running' AND e.ishtcal=1))
		and (league.isTest = 0 OR @isShowAll = 1)

GO

GRANT EXECUTE ON [dbo].[Age_Result_MatchSelNumberGameByLeague] TO [aplweb]
GO
---GRANT VIEW DEFINITION ON [dbo].[Age_Result_MatchSelNumberGameByLeague] TO [vnteam]
GO


