USE [DB05]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetAgentDownLinePath]    Script Date: 3/15/2013 3:27:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- [Age_Customer_GetDownLinePath] 3, 8
ALTER PROCEDURE [dbo].[Age_Customer_GetAgentDownLinePath]
	@CustID INT,
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
 *	@CustID: agent id of user login
 *	@AgentId: agent ID of agent is searched 
 */

SET NOCOUNT ON

SELECT 
	AgentId, 
	Username,
	AgentLevel,
	ParentId,
	Enabled 
FROM 
	AgentInfo WITH (NOLOCK) 
WHERE 
	AgentHId.IsDescendantOf((SELECT AgentHId FROM AgentInfo WITH (NOLOCK) WHERE AgentId = @CustID)) = 1
	AND (SELECT AgentHId FROM AgentInfo WITH (NOLOCK) WHERE AgentId = @AgentId).IsDescendantOf(AgentHId) = 1
	-- AND AgentId <> @CustID

