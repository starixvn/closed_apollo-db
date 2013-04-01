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
DECLARE @MemberOutstanding TABLE (CustID INT, Outstanding MONEY , Positiontaking MONEY, Outstanding_NG MONEY, Positiontaking_NG MONEY)

-----Member Outstanding
	INSERT INTO @MemberOutstanding 
	SELECT  B.CustID, ISNULL(SUM(CASE when BA.bettype NOT BETWEEN 80 and 120 then ABS(BA.actual_stake) END),0) Outstanding,  
			ISNULL(SUM(CASE when BA.bettype NOT BETWEEN 80 and 120 then BA.actual_stake * BA.APositiontaking END),0) Positiontaking,
			ISNULL(SUM(CASE when BA.bettype BETWEEN 80 and 120 then ABS(BA.actual_stake) END),0) Outstanding_NG,
			ISNULL(SUM(CASE when BA.bettype BETWEEN 80 and 120 then BA.actual_stake * BA.APositiontaking END),0) Positiontaking_NG
	FROM	bettrans B WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK)
		ON	BA.TransID = B.TransID
	INNER JOIN CustInfo C WITH (NOLOCK)
			ON B.CustID = C.CustID AND BA.AgentId = C.AgentId
	WHERE	BA.AgentId = @AgentID AND BA.StatusId IN (0,1)	 
	GROUP BY B.CustID


	SELECT C.Username, M.*
	FROM	@MemberOutstanding M
	INNER JOIN CustInfo C WITH (NOLOCK)
			ON C.CustID = M.CustID

	  


GO
GRANT EXECUTE ON [dbo].[Age_Rpt_Outstanding_Member] TO [aplweb]
GO
--GRANT VIEW DEFINITION ON [dbo].[Age_Rpt_Outstanding_Member] TO [vnteam]

