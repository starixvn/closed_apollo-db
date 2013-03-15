USE [DB05]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetUserSearch]    Script Date: 3/15/2013 3:28:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- [Age_Customer_GetUserSearch] 2, 'an', 1
ALTER PROCEDURE [dbo].[Age_Customer_GetUserSearch]
	@AgentId INT,
	@UserName VARCHAR(50),
	@IsMember BIT = 0
AS

/**
 * Created by	: Quinn
 * Date			: 20130314
 * Task			: Suggest when search agent or cust
 * DB			: APL.DB05
 * Revisions	:
 *	•
 * Parameters:
 *	@AgentId: agent ID
 *  @IsAgent: is agent or user
 *	@IsMember: member or agent
 */

SET NOCOUNT ON
-- Member List
IF (@IsMember = 0)
BEGIN
	SELECT 
		TOP 10
		Username 
	FROM 
		AgentInfo WITH (NOLOCK) 
	WHERE 
		AgentId <> @AgentId
		AND Username like @UserName + '%'
		AND AgentHId.IsDescendantOf((SELECT AgentHId FROM AgentInfo WITH (NOLOCK) WHERE AgentId = @AgentId)) = 1
		
	END
ELSE
BEGIN
	SELECT 
		TOP 10
		p.Username 
	FROM CustInfo p WITH (NOLOCK) 
	WHERE 
		Username like @UserName + '%'
		AND (SELECT AgentHId FROM AgentInfo WITH (NOLOCK) WHERE AgentId = p.AgentId).IsDescendantOf(
		(SELECT AgentHId FROM AgentInfo WITH (NOLOCK) WHERE AgentId = @AgentId)) = 1
END
