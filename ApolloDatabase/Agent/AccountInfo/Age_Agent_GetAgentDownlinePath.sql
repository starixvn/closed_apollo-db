USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetAgentDownLinePath]    Script Date: 4/26/2013 10:44:30 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_GetAgentDownlinePath]
	@ParentId INT,
	@AgentId INT
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

DECLARE @agentHId HIERARCHYID,
		@parentHId HIERARCHYID

SELECT @agentHId = AgentHId FROM AgentInfo WITH (NOLOCK) WHERE AgentId = @AgentId
SELECT @parentHId = AgentHId FROM AgentInfo WITH (NOLOCK) WHERE AgentId = @ParentId

SELECT 
	AgentId, 
	Username,
	AgentLevel,
	ParentId
FROM 
	AgentInfo WITH (NOLOCK) 
WHERE 
	AgentHId.IsDescendantOf(@parentHId) = 1
	AND @agentHId.IsDescendantOf(AgentHId) = 1
ORDER BY AgentLevel