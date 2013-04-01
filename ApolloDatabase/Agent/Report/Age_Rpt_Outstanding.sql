ALTER PROCEDURE [dbo].[Age_Rpt_Outstanding] 
	@AgentId int
AS

/*
Created: Sophia
Date: 20130329
Task : Report Outstanding
DB:  SVRAGE.RepDB
Original: [Age_Rpt_Outstanding_Ag]
Revisions:

*/
SET NOCOUNT ON
DECLARE @AgentTotalOutsanding TABLE (Outstanding MONEY, Positiontaking MONEY, Outstanding_NG MONEY, Positiontaking_NG MONEY)
DECLARE @MemberOutsanding TABLE (Outstanding MONEY, Positiontaking MONEY, Outstanding_NG MONEY, Positiontaking_NG MONEY)
	
----- Agent Total Outstanding
	INSERT INTO @AgentTotalOutsanding  
	SELECT  ISNULL(SUM(CASE when BA.bettype NOT BETWEEN 80 and 120 then ABS(BA.actual_stake) END),0) Outstanding,  
			ISNULL(SUM(CASE when BA.bettype NOT BETWEEN 80 and 120 then BA.actual_stake * BA.APositiontaking END),0) Positiontaking,
			ISNULL(SUM(CASE when BA.bettype BETWEEN 80 and 120 then ABS(BA.actual_stake) END),0) Outstanding_NG,
			ISNULL(SUM(CASE when BA.bettype BETWEEN 80 and 120 then BA.actual_stake * BA.APositiontaking END),0) Positiontaking_NG
	FROM	BetTrans_Agent AS BA WITH (NOLOCK)
	WHERE	BA.AgentId= @AgentId AND BA.StatusID IN (0,1)			
	 


-----Member Outstanding
	INSERT INTO @MemberOutsanding
	SELECT  ISNULL(SUM(CASE when BA.bettype NOT BETWEEN 80 and 120 then ABS(BA.actual_stake) END),0) Outstanding,  
			ISNULL(SUM(CASE when BA.bettype NOT BETWEEN 80 and 120 then BA.actual_stake * BA.APositiontaking END),0) Positiontaking,
			ISNULL(SUM(CASE when BA.bettype BETWEEN 80 and 120 then ABS(BA.actual_stake) END),0) Outstanding_NG,
			ISNULL(SUM(CASE when BA.bettype BETWEEN 80 and 120 then BA.actual_stake * BA.APositiontaking END),0) Positiontaking_NG
	FROM bettrans B WITH (NOLOCK)
	INNER JOIN CustInfo C WITH (NOLOCK)
			ON B.CustID = C.CustID 
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK) 
		ON BA.TransID = B.TransID AND BA.AgentId = C.AgentId
	WHERE	BA.AgentId = @AgentID AND BA.StatusId IN (0,1)
	 


SELECT  A.Outstanding - M.Outstanding as Outstanding, A.Positiontaking - M.Positiontaking as Positiontaking,
		A.Outstanding_NG - M.Outstanding_NG as Outstanding_NG, A.Positiontaking_NG - M.Positiontaking_NG as Positiontaking_NG
FROM @AgentTotalOutsanding A
CROSS JOIN @MemberOutsanding M
UNION ALL
SELECT * FROM @MemberOutsanding



GO
GRANT EXECUTE ON [dbo].[Age_Rpt_Outstanding] TO [aplweb]
GO
--GRANT VIEW DEFINITION ON [dbo].[Age_Rpt_Outstanding] TO [vnteam]
 