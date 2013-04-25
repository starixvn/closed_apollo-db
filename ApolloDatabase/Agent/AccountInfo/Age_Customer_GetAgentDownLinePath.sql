USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetAgentDownLinePath]    Script Date: 4/25/2013 10:15:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_GetAgentDownlinePath]
	@ParentId INT,
	@AgentId INT
AS

/**
 * Created by	: Quinn
 * Date			: 20130314
 * Task			: Retrieve agent path between current agent login and agent which is searched
 * DB			: APL.DB05
 * Revisions	:
 *	•
 * Parameters:
 *	@ParentId: agent id of user login
 *	@AgentId: agent ID of agent is searched 
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
