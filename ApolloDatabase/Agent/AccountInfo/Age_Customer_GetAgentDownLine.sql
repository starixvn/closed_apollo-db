USE [DB05]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetAgentDownLine]    Script Date: 3/15/2013 3:27:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- [Age_Customer_GetDownLine] 2
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
	Enabled
FROM AgentInfo WITH (NOLOCK) 
WHERE 
	ParentId = @AgentId
ORDER BY Username

