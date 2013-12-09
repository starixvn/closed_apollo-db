USE [RepDB]
GO
IF EXISTS (SELECT TOP 1 1 FROM sys.objects WHERE type = 'P' AND name = 'Acc_Agent_GetAgentByParentId')
	DROP PROC dbo.Acc_Agent_GetAgentByParentId
GO
CREATE PROCEDURE [dbo].[Acc_Agent_GetAgentByParentId]
(
	@ParentId	INT
)
AS

/**
 * Created by	: Patrick
 * Date			: 20131203
 * Task			: Get agent by parentid
 * DB			: SVRCSD/RepDB
 * Revisions	:
 *	• 
 * Parameters:
 * Test string	:
	exec [dbo].[Acc_Agent_GetAgentByParentId] 106914
	
 */

BEGIN
	SET NOCOUNT ON

	SELECT AgentId, Username
	FROM dbo.AgentInfo WITH(NOLOCK)
	WHERE ParentId = @ParentId
	ORDER BY Username
END

GO
GRANT EXECUTE ON [dbo].[Acc_Agent_GetAgentByParentId] TO [aplweb]
GO
