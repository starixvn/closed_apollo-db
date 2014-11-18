USE [RepDB]
GO
IF EXISTS (SELECT TOP 1 1 FROM sys.objects WHERE type = 'P' AND name = 'Acc_Agent_GetAgentDownline')
	DROP PROC dbo.Acc_Agent_GetAgentDownline
GO
CREATE PROCEDURE [dbo].[Acc_Agent_GetAgentDownline]
(
	@AgentId INT
)
AS
/**
 * Created by	: Quinn
 * Date			: 20130309
 * Task			: Retrieve all direct agents of current agent
 * DB			: SVRCSD/RepDB
 * Revisions	:
 *	• 20131203@Patrick	Clone sp from Agent Site
 * Parameters:
 *	@AgentId: agent ID
  * Test string	:
	exec Acc_Agent_GetAgentDownline @AgentId=1

 */

SET NOCOUNT ON

SELECT 
	AgentId, 
	Username,
	ParentId,
	AgentLevel,
	IIF(EXISTS (SELECT 1 FROM dbo.AgentInfo WITH (NOLOCK) WHERE ParentId = a.AgentId), CAST(1 AS BIT), CAST(0 AS BIT)) AS HasAgentDownline
FROM dbo.AgentInfo AS a WITH (NOLOCK) 
WHERE ParentId = @AgentId
ORDER BY Username

GO
GRANT EXECUTE ON [dbo].[Acc_Agent_GetAgentDownline] TO [aplweb]
GO


