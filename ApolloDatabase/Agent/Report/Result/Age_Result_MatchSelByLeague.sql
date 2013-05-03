ALTER PROCEDURE [dbo].[Age_Result_MatchSelByLeague]
	@FromDate DATETIME,
	@LeagueID INT,
	@Language NVARCHAR(2) = 'E',
	@sporttype smallint = 0,
	@isShowAll bit = 1 -- 1: Show All; 0: is NOT show Test	

AS
/*
Created: Sophia
Date: 20130401
Task: 
DB: SVRAGE.RepDB
Original: Age_Result_MatchSelByLeague
Revision:
	
*/
SET NOCOUNT ON 
	
DECLARE @ToDate datetime
SELECT @ToDate = dateadd(s,-1, dateadd(d, 1, @FromDate))

SELECT
		l.sporttype, 
		ISNULL(e.betstatus,'') AS betstatus , 
		m.leagueid,
		m.matchid,
		l.lcolor, 
		m.matchcode,
		m.eventdate, 
		m.kickofftime,
		m.homeID,
		m.awayID,
		ISNULL(e.hthomescore,0) AS hthomescore,
		ISNULL(e.htawayscore,0) AS htawayscore,
		ISNULL(e.finalhomescore,0) AS finalhomescore ,
		ISNULL(e.finalawayscore,0) AS finalawayscore,
		case when ISNULL(e.betstatus,'') like 'Refund FT%' then 'Refund FT' 
			 when ISNULL(e.betstatus,'') like 'Refund HT%' then 'Refund HT'
			 when ISNULL(e.betstatus,'') like 'Refund%' then 'Refund' 
		else ISNULL(e.eventstatus,'') end as eventstatus,  
		m.showtime,
		m.homeid2 , 
		ISNULL(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
		ISNULL(e.goalrecord, '') AS goalrecord,
		ISNULL(e.IsHTCal,0) as IsHTCal,
		ISNULL(e.calculate,0) as calculate	,
		ISNULL(mr.IsPending,0) as IsPending
	FROM league l WITH (NOLOCK) 
		INNER JOIN
			(	SELECT	sporttype, matchid, matchcode, homeid, awayid, leagueid, eventdate, kickofftime, showtime, isneutral,homeid2
			 	FROM	match WITH (NOLOCK)
			 	WHERE	eventdate BETWEEN @FromDate AND @ToDate 
						AND sporttype <= 99
						AND sporttype = CASE WHEN @sporttype = 0 THEN sporttype ELSE @sporttype END
						AND (@LeagueID = 0 OR leagueid = @LeagueID)	
						AND matchcode NOT LIKE '%hedge%'	
						AND matchcode NOT LIKE '%betdaq%'		 		
				UNION ALL
				SELECT	sporttype, matchid, matchcode, homeid, awayid, leagueid, eventdate, kickofftime, showtime, isneutral,homeid2
				FROM	match14 WITH (NOLOCK)	
				WHERE	eventdate BETWEEN  @FromDate AND @ToDate 
						AND sporttype <= 99
						AND (@LeagueID = 0 OR leagueid = @LeagueID)		
						AND matchcode NOT LIKE '%hedge%'	
						AND matchcode NOT LIKE '%betdaq%'		
			) AS m ON m.leagueid=l.leagueid	
		LEFT OUTER JOIN match_remark mr WITH (NOLOCK) ON m.matchid = mr.matchid
		LEFT OUTER JOIN match_remark_ex e WITH (NOLOCK) ON m.matchid = e.matchid
	WHERE
			(	
		        e.eventstatus NOT IN ('internal', 'closed', 'running')
		        OR (
		               mr.IsPending = 1
		               AND e.eventstatus IN ('running', 'closed')
		           )
		        OR (e.IsHTCal = 1 AND e.eventstatus = 'running')
		    )
		
		AND (l.isTest = 0 OR @isShowAll = 1)
	ORDER BY m.eventdate, m.sporttype, m.leagueid

GO

GRANT EXECUTE ON [dbo].[Age_Result_MatchSelByLeague] TO [aplWeb]
GO
--GRANT VIEW DEFINITION ON [dbo].[Age_Result_MatchSelByLeague] TO [vnteam]
