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

declare @toDate datetime
Select @toDate = dateadd(s,-1, dateadd(d, 1, @EventDate))

IF @sporttype <= 99 --- OR @sporttype = 161
BEGIN
	select distinct league.leaguename,
		league.leagueid, match.eventdate, match.sporttype
	from league (nolock)
	inner join 
	(
		select matchid, leagueid, eventdate, eventstatus, sporttype
		from match (nolock)
		UNION ALL
		select matchid, leagueid, eventdate, eventstatus, sporttype
		from match14 (nolock)
	) match on match.leagueid = league.leagueid
	LEFT OUTER JOIN match_remark mr WITH(NOLOCK) ON match.matchid = mr.matchid
	where
		match.eventdate >= @EventDate
		and match.eventdate <= @toDate
		and (match.eventstatus not in ('internal','closed','running')
				OR ( mr.IsPending=1 AND match.eventstatus IN ('running','closed') )
				OR ( mr.IsHTCal = 1 AND match.eventstatus ='running')
			)
		and match.sporttype = case when @sporttype = 0 then match.sporttype else @sporttype end
		and (league.isTest = 0 OR @isShowAll = 1)
	order by match.sporttype, league.leaguename
END


GO
GRANT EXECUTE ON [dbo].[Age_Result_LeagueSelByDate] TO [Aplweb]
GO
---GRANT VIEW DEFINITION ON [dbo].[Age_Result_LeagueSelByDate] TO [vnteam]
