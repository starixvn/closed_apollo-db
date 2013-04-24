USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetByUsername]    Script Date: 4/24/2013 12:26:58 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_GetByUsername]
	@ActorAgentId INT,
	@Username NVARCHAR(50)
AS

/**
 * Created by	: Quinn
 * Date			: 20130314
 * Task			: get Customer by username
 * DB			: APL.DB05
 * Revisions	:
 *	•
 * Parameters:
 *	@ActorAgentId: agentId of login user
 *  @Username: username of Customer
 */

SET NOCOUNT ON

BEGIN
	SELECT 
		TOP 10
		p.CustId,
		p.Username 
	FROM CustInfo p WITH (NOLOCK) 
	WHERE 
		Username LIKE @Username + '%'
		AND (SELECT AgentHId FROM AgentInfo WITH (NOLOCK) WHERE AgentId = p.AgentId).IsDescendantOf(
		(SELECT AgentHId FROM AgentInfo WITH (NOLOCK) WHERE AgentId = @ActorAgentId)) = 1
	ORDER BY
		Username	
END
