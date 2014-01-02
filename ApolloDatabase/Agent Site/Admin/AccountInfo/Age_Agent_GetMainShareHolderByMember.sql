ALTER PROCEDURE [Age_Agent_GetMainShareHolderByMember]
	@CustID INT
AS 
/*
	Created by: Sophia
	Date: 20130515
	Task: Get Main Share Holder of a member
	DB: SVRAGE/RepDB
	Original: 
	
	Revision:
*/
SET NOCOUNT ON	

	DECLARE @agentHId	HIERARCHYID
	DECLARE @AgentLevel	SMALLINT	
	DECLARE @parentId	INT

	---- Get parent id
	SELECT @parentId = AgentId
	FROM CustInfo WITH (NOLOCK)	
	WHERE CustId = @CustId

	---- Get agent hierarchy ID
	SELECT @agentHId = AgentHId,  @AgentLevel= AgentLevel
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @parentId


	---- Get parent information
	SELECT AgentId
	FROM AgentInfo WITH (NOLOCK)
	WHERE @AgentHId.IsDescendantOf(AgentHId) = 1 
		AND AgentLevel = 1 --- Get main Share holder
	  
GO
GRANT EXECUTE ON [Age_Agent_GetMainShareHolderByMember] TO [aplweb]


	