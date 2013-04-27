ALTER PROCEDURE [dbo].[Age_Result_MatchSelGoalHistory]
	@MatchID int
AS
/*
Created:  Sophia
Date: 20130401
Task: 
DB: SVRAGE.REPDB
Original: Age_Result_MatchSelGoalHistory  
  
Revisions:   
 

*/ 
SET NOCOUNT ON

SELECT isnull(GoalRecord,'') as GoalRecord,leagueid,homeid,awayid,isNeutral 
FROM match (nolock)
WHERE matchid=@MatchID

GO
GRANT EXECUTE ON [dbo].[Age_Result_MatchSelGoalHistory] TO aplweb
GO

--GRANT VIEW DEFINITION ON [dbo].[Age_Result_MatchSelGoalHistory] TO [vnteam]
GO

