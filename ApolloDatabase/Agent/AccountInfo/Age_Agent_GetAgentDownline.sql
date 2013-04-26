USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetAgentDownline]    Script Date: 4/26/2013 10:38:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_GetAgentDownline]
	@AgentId INT
AS

/**
 * Created by	: Quinn
 * Date			: 20130309
 * Task			: Retrieve all direct agents of current agent
 * DB			: SVRAGE.RepDB
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
	CASE WHEN (EXISTS (SELECT 1 FROM AgentInfo WITH (NOLOCK) WHERE ParentId = AgentId)) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS HasAgentDownline
FROM AgentInfo WITH (NOLOCK) 
WHERE 
	ParentId = @AgentId
ORDER BY Username
