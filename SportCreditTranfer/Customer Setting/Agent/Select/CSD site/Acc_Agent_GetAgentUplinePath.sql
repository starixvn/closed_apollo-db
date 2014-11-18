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
 * Task			: Get upline path by id
 * DB			: SVRCSD/RepDB
 * Revisions	:
 *	• 
 * Parameters:
 * Test string	:
	exec Acc_Agent_GetAgentUplinePath 6437

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
	FROM UplinePath AS t
	INNER JOIN dbo.AgentInfo AS ai WITH (NOLOCK) ON t.ParentId = ai.AgentId
)   

SELECT AgentId, Username, AgentLevel, ParentId
FROM UplinePath
WHERE AgentId <> @AgentId /*only get upline agent --> exclude this agent*/
ORDER BY AgentLevel DESC
GO
GRANT EXECUTE ON [dbo].[Acc_Agent_GetAgentUplinePath] TO [aplweb]
GO


