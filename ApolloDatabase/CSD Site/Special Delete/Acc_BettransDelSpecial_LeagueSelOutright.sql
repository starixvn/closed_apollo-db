CREATE PROCEDURE [dbo].[Acc_BettransDelSpecial_LeagueSelOutright]
AS
/*
Created: Sophia
Date: 20130307
Task : Select outright leagues for Special Del
DB: SVRCSD.RepDB 
Original:

Revisions:    
  
Param's Explanation:

*/

SET NOCOUNT ON

SELECT DISTINCT League.leagueid
FROM		outright WITH (NOLOCK) 
INNER JOIN	League WITH (NOLOCK) 
		ON	outright.leagueid = League.leagueid
WHERE   outright.orid IN
            (SELECT MatchId
            FROM   BetTrans WITH (NOLOCK)
            WHERE  BetType = 10)

GO
GRANT EXECUTE ON [dbo].[Acc_BettransDelSpecial_LeagueSelOutright] TO [aplweb]
GO
--GRANT VIEW DEFINITION ON [dbo].[Acc_BettransDelSpecial_LeagueSelOutright] TO [VNTeam]
