USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetByUsername]    Script Date: 4/26/2013 10:53:11 AM ******/
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
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	•
 * Parameters:
 *	@ActorAgentId: agentId of login user
 *  @Username: username of Customer
 */

SET NOCOUNT ON

DECLARE @agentHId HIERARCHYID

BEGIN
	SELECT @agentHId = AgentHId FROM AgentInfo WITH (NOLOCK) WHERE AgentId = @ActorAgentId

	SELECT 
		TOP 10
		a.CustId,
		a.Username 
	FROM CustInfo a WITH (NOLOCK)
		INNER JOIN AgentInfo b WITH (NOLOCK) ON a.AgentId = b.AgentId
	WHERE 
		a.Username LIKE @Username + '%'
		AND b.AgentHId.IsDescendantOf(@agentHId) = 1
	ORDER BY
		Username	
END
