USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetAgentDownline]    Script Date: 4/25/2013 12:31:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_Customer_GetAgentDownline]
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
	CASE WHEN (EXISTS (SELECT 1 FROM AgentInfo WITH (NOLOCK) WHERE ParentId = a.AgentId)) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS HasAgentDownline
FROM AgentInfo a WITH (NOLOCK) 
WHERE 
	ParentId = @AgentId
ORDER BY Username
