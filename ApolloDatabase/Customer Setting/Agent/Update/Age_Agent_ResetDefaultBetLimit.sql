ALTER PROCEDURE [dbo].[Age_Agent_ResetDefaultBetLimit]
	@AgentID INT
AS
/*
Created by: Sophia	
Date:		20131205
Task:		Reset BetLimit setting for downline (by @AgentID)
DB:			SVRCUST.CustDB
Revisions:	

*/

SET NOCOUNT ON 

DECLARE @ExchangeId INT, @AgentHId HIERARCHYID

SELECT	@ExchangeId = Currency, @AgentHId = AgentHId
FROM	AgentInfo A WITH (NOLOCK)
WHERE	AgentID = @AgentId

 

---Update Agent 
UPDATE	A
SET		Minbet = E.MinBet, 
		MaxBet = E.MaxBet, 
		MaxPerMatch = E.MaxPerMatch
FROM	AgentBetLimit A WITH (NOLOCK)
INNER JOIN ExchangeBetLimit E WITH (NOLOCK) 
		ON A.SportType = E.SportType
		AND A.BetType = E.BetType		
		AND E.ExchangeId =@ExchangeId
WHERE AgentId IN (	SELECT AgentId 
					FROM AgentInfo WITH (NOLOCK)
					WHERE  AgentHId.IsDescendantOf(@AgentHId) = 1  
					  )
					 

---Update Member 
UPDATE	A
SET		Minbet = E.MinBet, 
		MaxBet = E.MaxBet, 
		MaxPerMatch = E.MaxPerMatch
FROM	CustBetLimit A WITH (NOLOCK)
INNER JOIN CustInfo C WITH (NOLOCK) 
		ON C.CustID = A.CustID
INNER JOIN ExchangeBetLimit E WITH (NOLOCK) 
		ON A.SportType = E.SportType
		AND A.BetType = E.BetType		
		AND E.ExchangeId = @ExchangeId
WHERE	C.AgentId IN (	SELECT AgentId 
						FROM AgentInfo WITH (NOLOCK)
						WHERE  AgentHId.IsDescendantOf(@AgentHId) = 1  
					  )


GO

GRANT EXECUTE ON [dbo].[Age_Agent_ResetDefaultBetLimit] TO [aplweb]
GO   
 