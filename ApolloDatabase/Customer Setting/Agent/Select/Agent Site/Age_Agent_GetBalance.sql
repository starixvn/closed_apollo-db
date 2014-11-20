CREATE PROCEDURE [dbo].[Age_Agent_GetBalance]
(
	@AgentID INT 
)
AS

BEGIN 
SET NOCOUNT ON 

SELECT SUM(ISNULL(Amount,0)) AS SportCredit FROM dbo.CreditTrans WITH (NOLOCK) WHERE AgentId = @AgentId 

END
GO 
GRANT EXECUTE ON [dbo].[Age_Agent_GetBalance] TO [aplweb]
GO 