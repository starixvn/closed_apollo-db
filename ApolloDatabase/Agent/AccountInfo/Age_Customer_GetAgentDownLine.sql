USE RepDB
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetAgentDownline]    Script Date: 3/25/2013 2:31:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- [Age_Customer_GetAgentDownLine] 7
ALTER PROCEDURE [dbo].[Age_Customer_GetAgentDownline]
	@AgentId INT
AS

/**
 * Created by	: Quinn
 * Date			: 20130309
 * Task			: Retrieve agent of current agent
 * DB			: APL.DB05
 * Revisions	:
 *	•
 * Parameters:
 *	@AgentId: agent ID
 */

SET NOCOUNT ON

SELECT 
	AgentId AS Id, 
	Username,
	ParentId,
	Enabled,
	CASE WHEN (EXISTS (SELECT 1 FROM AgentInfo WITH (NOLOCK) WHERE ParentId = a.AgentId)) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS HasChildren
FROM AgentInfo a WITH (NOLOCK) 
WHERE 
	ParentId = @AgentId
ORDER BY Username
