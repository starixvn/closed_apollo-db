USE [RepDB]
GO
IF EXISTS (SELECT TOP 1 1 FROM sys.objects WHERE type = 'P' AND name = 'Acc_Agent_GetHierarchyById')
	DROP PROC dbo.Acc_Agent_GetHierarchyById
GO
CREATE PROCEDURE [dbo].[Acc_Agent_GetHierarchyById]
(
	@AgentId INT
)
AS

/**
 * Created by	: Patrick
 * Date			: 20131203
 * Task			: Get hierarchy agent by id
 * DB			: SVRCSD/RepDB
 * Test string	:
	exec [dbo].[Acc_Agent_GetHierarchyById] 62
	
 * Revisions	:
 *	• 
 * Parameters:
 */

BEGIN
	SET NOCOUNT ON

	;WITH UplinePath(AgentId, Username, ParentId, AgentLevel, HasAgentDownline) AS
	(
		SELECT AgentId, Username, ParentId, AgentLevel
			, IIF(EXISTS (SELECT 1 FROM dbo.AgentInfo WITH (NOLOCK) WHERE ParentId = a.AgentId), CAST(1 AS BIT), CAST(0 AS BIT)) AS HasAgentDownline
		FROM dbo.AgentInfo a WITH (NOLOCK)
		WHERE AgentId = @AgentId

		UNION ALL

		SELECT a.AgentId, a.Username, a.ParentId, a.AgentLevel
			, IIF(EXISTS (SELECT 1 FROM dbo.AgentInfo WITH (NOLOCK) WHERE ParentId = a.AgentId), CAST(1 AS BIT), CAST(0 AS BIT)) AS HasAgentDownline       
		FROM dbo.AgentInfo AS a WITH (NOLOCK)
		INNER JOIN UplinePath AS b ON b.ParentId = a.AgentId
	)   

	SELECT AgentId, Username, ParentId, AgentLevel, HasAgentDownline
	FROM
	(
		SELECT AgentId, Username, ParentId, AgentLevel, HasAgentDownline
		FROM UplinePath

		UNION
		--Get sibling of upline path
		SELECT b.AgentId, b.Username, b.ParentId, b.AgentLevel
			, IIF(EXISTS (SELECT 1 FROM dbo.AgentInfo WITH (NOLOCK) WHERE ParentId = b.AgentId), CAST(1 AS BIT), CAST(0 AS BIT)) AS HasAgentDownline
		FROM UplinePath a
		INNER JOIN dbo.AgentInfo b WITH (NOLOCK) ON a.AgentId = b.ParentId
	)a
	ORDER BY a.AgentLevel, a.Username, a.ParentId

END

GO
GRANT EXECUTE ON [dbo].[Acc_Agent_GetHierarchyById] TO [aplweb]
GO
