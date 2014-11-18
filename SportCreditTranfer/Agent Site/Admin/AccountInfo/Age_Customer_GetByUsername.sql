USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetByUsername]    Script Date: 5/2/2013 1:44:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_GetByUsername]
	@ActorAgentId	INT,
	@Username		NVARCHAR(50)
AS

/**
 * Created by	: Quinn
 * Date			: 20130314
 * Task			: Get downline customer by username
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	•
 * Parameters:
 *	@ActorAgentId	: agentId of login user
 *  @Username		: username of Customer
 */

BEGIN

	SET NOCOUNT ON

	DECLARE @agentHId HIERARCHYID

	SELECT @agentHId = AgentHId 
	FROM AgentInfo WITH (NOLOCK) 
	WHERE AgentId = @ActorAgentId

	SELECT TOP 10
		a.CustId,
		a.Username 
	FROM 
		CustInfo a WITH (NOLOCK)
		INNER JOIN AgentInfo b WITH (NOLOCK) ON a.AgentId = b.AgentId
	WHERE 
		a.Username LIKE @Username + '%'
		AND b.AgentHId.IsDescendantOf(@agentHId) = 1
	ORDER BY a.Username	
END
