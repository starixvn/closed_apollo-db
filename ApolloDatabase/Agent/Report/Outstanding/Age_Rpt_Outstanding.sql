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
DECLARE @AgentOutstanding TABLE (Username NVARCHAR(50), AgentID INT, IsAgent BIT, Outstanding MONEY, Positiontaking MONEY, Outstanding_NG MONEY, Positiontaking_NG MONEY)
DECLARE @MemberOutstanding TABLE (Username NVARCHAR(50), AgentID INT, IsAgent BIT, Outstanding MONEY, Positiontaking MONEY, Outstanding_NG MONEY, Positiontaking_NG MONEY)
		 
IF @AgentId = 0
BEGIN 
	----Super view
	INSERT INTO @AgentOutstanding
	SELECT  C.Username, C.AgentID, 1 as IsAgent,
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
	INSERT INTO @AgentOutstanding
	SELECT  C.Username, C.AgentID, 1 as IsAgent,
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

 

-----Member Outstanding
 INSERT INTO @MemberOutstanding ---(AgentId, IsAgent, Outstanding, Positiontaking, Outstanding_NG, Positiontaking_NG)
	SELECT  '', C.AgentId, 0 as IsAgent,
			ISNULL(SUM(CASE when BA.bettype < 31 OR BA.bettype between 121 and 999 OR BA.bettype between 1301 and 1334 then ABS(BA.actual_stake) END),0) Outstanding,  
			ISNULL(SUM(CASE when BA.bettype < 31 OR BA.bettype between 121 and 999 OR BA.bettype between 1301 and 1334 then ABS(BA.actual_stake) * BA.APositiontaking END),0) Positiontaking,
			ISNULL(SUM(CASE when BA.bettype BETWEEN 81 and 120 then ABS(BA.actual_stake) END),0) Outstanding_NG,
			ISNULL(SUM(CASE when BA.bettype BETWEEN 81 and 120 then ABS(BA.actual_stake) * BA.APositiontaking END),0) Positiontaking_NG
	FROM Bettrans B WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK) 
		ON BA.TransID = B.TransID 
	INNER JOIN CustInfo C WITH (NOLOCK)
		ON B.CustID = C.CustID AND C.AgentId =@AgentID
	WHERE	BA.AgentId = @AgentID AND BA.StatusId IN (0,1)
	GROUP BY C.AgentId
	 
SELECT * FROM @AgentOutstanding 
UNION ALL
SELECT * FROM @MemberOutstanding 




GO
GRANT EXECUTE ON [dbo].[Age_Rpt_Outstanding] TO [aplweb]
GO
--GRANT VIEW DEFINITION ON [dbo].[Age_Rpt_Outstanding] TO [vnteam]
