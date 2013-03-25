ALTER PROCEDURE [dbo].[Acc_BettransDelSpecial_OutrightSel]
	@LeagueID int = 0
AS
SET NOCOUNT ON

/*
Created: Sophia
Date: 20130307
Task : Select outright for special delete
DB: SVRCSD.RepDB
Original:

Revisions:    
 
Param's Explanation:

*/	

select	orid, 
		leagueid,
		teamid
from	outright with (nolock) 
where	orid IN(select matchid from bettrans with (nolock) where bettype = 10) 
	and  leagueid = case when @LeagueID = 0 then leagueid else @leagueid end

GO
GRANT EXECUTE ON [dbo].[Acc_BettransDelSpecial_OutrightSel] TO [aplweb]
GO
--GRANT VIEW DEFINITION ON [dbo].[Acc_BettransDelSpecial_OutrightSel] TO [VNTeam]