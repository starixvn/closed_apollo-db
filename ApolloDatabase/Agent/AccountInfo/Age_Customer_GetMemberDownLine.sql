USE [DB05]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetMemberDownLine]    Script Date: 3/18/2013 11:33:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- [Age_Customer_GetDownLine] 2
ALTER PROCEDURE [dbo].[Age_Customer_GetMemberDownLine]
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