USE [RepDB]
GO
IF EXISTS (SELECT TOP 1 1 FROM sys.objects WHERE type = 'P' AND name = 'Acc_Agent_GetAgentUplinePath')
	DROP PROC dbo.Acc_Agent_GetAgentUplinePath
GO
CREATE PROCEDURE [dbo].[Acc_Agent_GetAgentUplinePath]
(
	@AgentId	INT
)
AS

/**
 * Created by	: Patrick
 * Date			: 20131204
 * Task			: Retrieve list agent in relationship between parent agent and current agent
 * DB			: SVRCSD/RepDB
 * Test string	:
	exec Acc_Agent_GetAgentUplinePath 6437

 * Revisions	:
 *	• 
 * Parameters:
 *	@ParentId: agent Id from
 *	@AgentId: agent ID to
 */

SET NOCOUNT ON

;WITH UplinePath(AgentId, AgentLevel, Username, ParentId)
AS
(
	SELECT AgentId, AgentLevel, Username, ParentId
	FROM dbo.AgentInfo WITH (NOLOCK)
	WHERE AgentId = @AgentId

	UNION ALL

	SELECT ai.AgentId, ai.AgentLevel, ai.Username, ai.ParentId
	FROM dbo.AgentInfo AS ai WITH (NOLOCK)
	INNER JOIN UplinePath AS t ON t.ParentId = ai.AgentId
)   

SELECT AgentId, Username, AgentLevel, ParentId
FROM UplinePath		
ORDER BY AgentLevel
GO
GRANT EXECUTE ON [dbo].[Acc_Agent_GetAgentUplinePath] TO [aplweb]
GO


