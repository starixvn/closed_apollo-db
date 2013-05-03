ALTER PROCEDURE [dbo].[Age_Result_LeagueSelByDate]
	@EventDate DATETIME,
	@Language NVARCHAR(2) = 'E',
	@sporttype tinyint = 0,
	@isShowAll bit = 1 -- 1: Show All; 0: is NOT show Test	
AS
/*
Created: Sophia
Date: 20130401
Task: 
DB: SVRAGE.RepDB
Original: Age_Result_LeagueSelByDate

Revisions: 



*/

SET NOCOUNT ON

DECLARE @toDate datetime
SELECT @toDate = dateadd(s,-1, dateadd(d, 1, @EventDate))

IF @sporttype <= 99 --- OR @sporttype = 161
BEGIN
	SELECT	DISTINCT league.leaguename,
			league.leagueid, match.eventdate, match.sporttype
	FROM	league WITH (NOLOCK)
	INNER JOIN (
				SELECT	m.matchid, m.leagueid, m.eventdate, m.sporttype
				FROM	match m WITH (NOLOCK)	
				WHERE	m.eventdate BETWEEN @EventDate AND @toDate	
						and m.sporttype = case when @sporttype = 0 then m.sporttype else @sporttype end	
				UNION ALL
				SELECT  m.matchid, m.leagueid, m.eventdate, m.sporttype
				FROM	match14 m WITH (NOLOCK)
				WHERE	m.eventdate BETWEEN @EventDate AND @toDate	
						and m.sporttype = case when @sporttype = 0 then m.sporttype else @sporttype end	
				) match 
			ON match.leagueid = league.leagueid
	LEFT OUTER JOIN match_remark mr WITH (NOLOCK) ON match.matchid = mr.matchid
	LEFT OUTER JOIN match_remark_ex e WITH (NOLOCK) ON match.matchid = e.matchid
	WHERE	( e.eventstatus not in ('internal','closed','running')
					OR ( mr.IsPending=1 AND e.eventstatus IN ('running','closed') )
					OR ( e.IsHTCal = 1 AND e.eventstatus ='running')
				)
			and (league.isTest = 0 OR @isShowAll = 1)
	ORDER BY match.sporttype, league.leaguename
END


GO
GRANT EXECUTE ON [dbo].[Age_Result_LeagueSelByDate] TO [Aplweb]
GO
---GRANT VIEW DEFINITION ON [dbo].[Age_Result_LeagueSelByDate] TO [vnteam]
