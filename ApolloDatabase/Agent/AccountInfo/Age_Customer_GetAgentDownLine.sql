USE [DB05]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetAgentDownLine]    Script Date: 3/18/2013 11:29:59 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- [Age_Customer_GetAgentDownLine] 7
ALTER PROCEDURE [dbo].[Age_Customer_GetAgentDownLine]
	@AgentId INT
AS

/**
 * Created by	: Quinn
 * Date			: 20130309
 * Task			: Retrieve agent and member of current agent
 * DB			: APL.DB05
 * Revisions	:
 *	•
 * Parameters:
 *	@AgentId: agent ID
 */

SET NOCOUNT ON

SELECT 
	AgentId, 
	Username,
	ParentId,
	Enabled,
	CASE WHEN (EXISTS (SELECT 1 FROM AgentInfo WITH (NOLOCK) WHERE ParentId = a.AgentId)) THEN 'true' ELSE 'false' END AS hasChildren
FROM AgentInfo a WITH (NOLOCK) 
WHERE 
	ParentId = @AgentId
ORDER BY Username

