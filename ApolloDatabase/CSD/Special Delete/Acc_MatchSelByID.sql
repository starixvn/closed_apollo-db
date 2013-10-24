
CREATE PROCEDURE [dbo].[Acc_MatchSelByID] 
	@matchID INT = 0,
	@transid bigint = 0
AS

/*
Created: Sophia
Date: 20130311
Task : View match info
DB: SVRCSD.RepDB
Original:

Revisions: 
- 20131024@Sophia: Add IsOutright

*/
SET NOCOUNT ON
declare @bettype int

if @matchid=0
	select @matchid = matchid, @bettype = bettype from bettrans (nolock) where transid = @transid
if @bettype = 10
	SELECT
		match.orid as matchid,
        MATCH.teamid AS homeid,
        0 AS awayid,
        MATCH.matchcode,
        MATCH.eventdate,
        MATCH.leagueid,
        GETDATE() AS DATETIME,
        CONVERT(BIT,0) AS IsNeutral,
		1 as IsOutright
    FROM
        Outright AS MATCH WITH (NOLOCK)
    WHERE 
        MATCH.orid = @matchID
else
	SELECT 
			match.matchid,
			match.homeid,
			match.awayid,
			match.matchcode, 
			match.eventdate, 
			match.leagueid,
			isnull(match.isNeutral, CONVERT(BIT,0)) as IsNeutral,
			0 as IsOutright
		FROM 
			match WITH (NOLOCK) 
		WHERE  
			match.matchid = @matchID  




GO
GRANT EXECUTE ON [dbo].[Acc_MatchSelByID] TO [aplweb]
GO
--GRANT VIEW DEFINITION ON [dbo].[Acc_MatchSelByID] TO [vnteam]
GO

