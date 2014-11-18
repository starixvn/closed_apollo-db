
ALTER PROCEDURE [dbo].[DBA_MatchName] 
	@InputMatch varchar(30)
AS

/*
Created: Sophia
Date:  20130530
Task : 
DB: SVRPRO.ProdDB 
Original:  

Revisions:
 
	
Param's Explanation: 

*/
SET NOCOUNT ON
	DECLARE @matchid int
	select @matchid = matchID from match with (nolock) where matchcode = @InputMatch

if @@rowcount = 0
	select @matchid = @InputMatch

select 
	match.matchid,a.teamname home,b.teamname away, match.matchcode, match.eventdate ,l.leaguename,
	match.homeid,match.awayid,mr.IsNeutral,
	match.finalhomescore, match.finalawayscore, match.eventstatus
from match (nolock),
	team a (nolock),
	team b (nolock),
	league l (nolock),
	match_remark mr (nolock)
where match.homeid=a.teamid and match.awayid=b.teamid and match.leagueid=l.leagueid AND match.matchid=mr.matchid
and match.matchid=@matchid


