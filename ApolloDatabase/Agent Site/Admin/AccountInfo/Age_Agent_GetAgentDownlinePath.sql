USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetAgentDownlinePath]    Script Date: 9/9/2013 5:30:21 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_GetAgentDownlinePath]
	@ParentId	INT,
	@AgentId	INT
AS

/**
 * Created by	: Quinn
 * Date			: 20130314
 * Task			: Retrieve list agent in relationship between parent agent and current agent
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	•
 * Parameters:
 *	@ParentId: agent Id from
 *	@AgentId: agent ID to
 */

SET NOCOUNT ON

DECLARE @parentHId	HIERARCHYID

SELECT @parentHId = AgentHId 
FROM AgentInfo WITH (NOLOCK) 
WHERE AgentId = @ParentId

;WITH Tree(AgentId, AgentLevel, Username, ParentId, AgentHId)
AS
(
	SELECT 
		AgentId,
		AgentLevel,
		Username,
		ParentId,
		AgentHId 
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @AgentId

	UNION ALL

	SELECT  
		ai.AgentId,
		CAST(ai.AgentLevel AS SMALLINT) AS AgentLevel,
		ai.Username,
		ai.ParentId,
		ai.AgentHId        
	FROM
		AgentInfo AS ai WITH (NOLOCK)
		INNER JOIN Tree AS t ON	t.AgentHId.GetAncestor(1) = ai.AgentHId
)   

SELECT 
	AgentId, 
	Username,
	AgentLevel,
	ParentId
FROM Tree		
WHERE Tree.AgentHId.IsDescendantOf(@parentHId) = 1
ORDER BY AgentLevel