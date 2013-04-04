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
	
 IF @AgentId = 0
BEGIN 
	----Super view
	SELECT  C.Username, C.AgentID, 
		ISNULL(SUM(CASE when BA.bettype < 31 OR BA.bettype between 121 and 999 OR BA.bettype between 1301 and 1334 then ABS(BA.actual_stake) END),0) Outstanding,  
		ISNULL(SUM(CASE when BA.bettype < 31 OR BA.bettype between 121 and 999 OR BA.bettype between 1301 and 1334 then ABS(BA.actual_stake) * (1-B.TPositiontaking) END),0) Positiontaking,
		ISNULL(SUM(CASE when BA.bettype BETWEEN 80 and 120 then  ABS(BA.actual_stake) END),0) Outstanding_NG,
		ISNULL(SUM(CASE when BA.bettype BETWEEN 80 and 120 then  ABS(BA.actual_stake) * (1-B.TPositiontaking) END),0) Positiontaking_NG
	FROM AgentInfo C WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK)
			ON BA.AgentID = C.AgentID		
	INNER JOIN Bettrans B WITH (NOLOCK) 
			ON B.TransID = BA.TransID			
	WHERE	C.ParentId = @AgentID
	GROUP BY  C.Username, C.AgentID
END
ELSE 
BEGIN
	----- Agent Outstanding
	SELECT  C.Username, C.AgentID, 
		ISNULL(SUM(CASE when BA.bettype < 31 OR BA.bettype between 121 and 999 OR BA.bettype between 1301 and 1334 then ABS(BA.actual_stake) END),0) Outstanding,  
		ISNULL(SUM(CASE when BA.bettype < 31 OR BA.bettype between 121 and 999 OR BA.bettype between 1301 and 1334 then ABS(BA.actual_stake) * BP.APositiontaking END),0) Positiontaking,
		ISNULL(SUM(CASE when BA.bettype BETWEEN 80 and 120 then ABS(BA.actual_stake) END),0) Outstanding_NG,
		ISNULL(SUM(CASE when BA.bettype BETWEEN 80 and 120 then ABS(BA.actual_stake) * BP.APositiontaking END),0) Positiontaking_NG
	FROM	AgentInfo C  WITH (NOLOCK)
	INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK)
			ON BA.AgentID = C.AgentID
	INNER JOIN BetTrans_Agent AS BP WITH (NOLOCK)
			ON BP.TransID = BA.TransID AND BP.AgentID = @AgentID
	WHERE	C.ParentId = @AgentID AND BA.StatusID IN (0,1)			
	GROUP BY C.Username, C.AgentID

END

	 

GO
GRANT EXECUTE ON [dbo].[Age_Rpt_Outstanding_Agent] TO [aplweb]
GO
--GRANT VIEW DEFINITION ON [dbo].[Age_Rpt_Outstanding_Agent] TO [vnteam]
