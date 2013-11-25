ALTER PROCEDURE [dbo].[Age_Agent_GetParentInfoWithAgentUser_xtest]	
	@AgentUserId		INT		
AS

/**
 * Created by	: Edward
 * Date			: 20131003
 * Task			: Get downline agent information by ID or Username
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	•
 * Parameters:
 *	
 *	 
 */

	SET NOCOUNT ON
	
	SELECT
		pau.AgentUserId,
		pau.Username,
		pai.AgentId,
		pai.AgentLevel,
		pai.Username				
	FROM 
		AgentUser AS au WITH (NOLOCK)
		INNER JOIN AgentInfo AS ai WITH (NOLOCK) 
			ON ai.AgentId = au.AgentId			
		INNER JOIN AgentInfo AS pai WITH (NOLOCK) 
			ON ai.ParentId = pai.AgentId		
		INNER JOIN AgentUser AS pau WITH (NOLOCK) 
			ON pai.AgentId = pau.AgentId 
			AND pau.IsMaster = 1
	WHERE au.AgentUserId = @AgentUserId
	

