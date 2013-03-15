USE [DB05]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetMembersDownLine]    Script Date: 3/15/2013 3:28:22 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- [Age_Customer_GetDownLine] 2
ALTER PROCEDURE [dbo].[Age_Customer_GetMembersDownLine]
	@AgentId INT
AS

/**
 * Created by	: Quinn
 * Date			: 20130314
 * Task			: Retrieve members of agent which is searched
 * DB			: APL.DB05
 * Revisions	:
 *	•
 * Parameters:
 *	@AgentId: agent ID
 */

SET NOCOUNT ON
-- Member List
SELECT 
	CustId,
	Username,
	AgentId,
	Enabled 
FROM CustInfo WITH (NOLOCK) 
WHERE 
	AgentId = @AgentId
ORDER BY Username