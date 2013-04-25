ALTER PROCEDURE [dbo].[Age_Rpt_Outstanding_Member] 
	@AgentId int
AS

/*
Created: Sophia
Date: 20130329 
Task : Report Outstanding Detail Member
DB:  SVRAGE.RepDB
Original: [Age_Rpt_Outstanding_Ag]
Revisions:

*/
SET NOCOUNT ON

-----Member Outstanding

	SELECT  C.Username, B.CustID, 
			ISNULL(SUM(CASE when BA.bettype < 31 OR BA.bettype between 121 and 999 OR BA.bettype between 1301 and 1334 then ABS(BA.actual_stake) END),0) Outstanding,  
			ISNULL(SUM(CASE when BA.bettype < 31 OR BA.bettype between 121 and 999 OR BA.bettype between 1301 and 1334 then ABS(BA.actual_stake) * BA.APositiontaking END),0) Positiontaking,
			ISNULL(SUM(CASE when BA.bettype BETWEEN 81 and 120 then ABS(BA.actual_stake) END),0) Outstanding_NG,
			ISNULL(SUM(CASE when BA.bettype BETWEEN 81 and 120 then ABS(BA.actual_stake) * BA.APositiontaking END),0) Positiontaking_NG
	FROM	bettrans B WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK)
		ON	BA.TransID = B.TransID
	INNER JOIN CustInfo C WITH (NOLOCK)
			ON B.CustID = C.CustID AND BA.AgentId = C.AgentId
	WHERE	BA.AgentId = @AgentID AND BA.StatusId IN (0,1)	 
	GROUP BY C.Username, B.CustID
	ORDER BY C.Username

GO
GRANT EXECUTE ON [dbo].[Age_Rpt_Outstanding_Member] TO [aplweb]
GO
--GRANT VIEW DEFINITION ON [dbo].[Age_Rpt_Outstanding_Member] TO [vnteam]

