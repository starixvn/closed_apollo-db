ALTER PROCEDURE [dbo].[Age_Rpt_Outstanding_Agent] 
	@AgentId int
AS

/*
Created: Sophia
Date: 20130329 
Task : Report Outstanding Detail Agent
DB:  SVRAGE.RepDB
Original: [Age_Rpt_Outstanding_Ag]
Revisions:

*/
SET NOCOUNT ON
	
----- Agent Outstanding
	SELECT  C.Username, B.AgentID, 
		ISNULL(SUM(CASE when B.bettype NOT BETWEEN 80 and 120 then ABS(B.actual_stake) END),0) Outstanding,  
		ISNULL(SUM(CASE when B.bettype NOT BETWEEN 80 and 120 then B.actual_stake * BP.APositiontaking END),0) Positiontaking,
		ISNULL(SUM(CASE when B.bettype BETWEEN 80 and 120 then B.actual_stake END),0) Outstanding_NG,
		ISNULL(SUM(CASE when B.bettype BETWEEN 80 and 120 then B.actual_stake * BP.APositiontaking END),0) Positiontaking_NG

	FROM	AgentInfo P WITH (NOLOCK)
	INNER JOIN AgentInfo C  WITH (NOLOCK)
			ON C.AgentHId.IsDescendantOf(P.AgentHId) = 1 AND C.AgentLevel = P.AgentLevel + 1
	INNER JOIN BetTrans_Agent AS B WITH (NOLOCK)
			ON B.AgentID = C.AgentID
	INNER JOIN BetTrans_Agent AS BP WITH (NOLOCK)
			ON BP.AgentID = P.AgentID AND BP.TransID = B.TransID
	WHERE	P.AgentId= @AgentId AND BP.StatusID IN (0,1)			
	GROUP BY B.AgentID, C.Username
	 
	 

GO
GRANT EXECUTE ON [dbo].[Age_Rpt_Outstanding_Agent] TO [aplweb]
GO
--GRANT VIEW DEFINITION ON [dbo].[Age_Rpt_Outstanding_Agent] TO [vnteam]
