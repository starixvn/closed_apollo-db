USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetAllInfo]    Script Date: 4/25/2013 10:00:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_GetAllInfo]
	@ActorAgentId INT,
	@CustId INT = -1,
	@Username NVARCHAR(50) = ''
AS

/**
 * Created by	: Quinn
 * Date			: 20130307
 * Task			: Get Customer Info by Id or Username
 * DB			: APL.DB05
 * Revisions	:
 *	•
 * Parameters:
 *	@ActorAgentId: AgentId of login user
 *	@CustId: Customer ID
 *  @UserName: Username of Agent
 */

SET NOCOUNT ON

DECLARE @agentHId HIERARCHYID

BEGIN
	SELECT @agentHId = AgentHId FROM AgentInfo WITH (NOLOCK) WHERE AgentId = @ActorAgentId

	SELECT 
		a.CustId,
		a.Username,
		a.AgentId,
		b.Username AS ParentName,
		a.UGroup
	FROM CustInfo a WITH (NOLOCK) 
		INNER JOIN 
		AgentInfo b WITH (NOLOCK) ON a.AgentId = b.AgentId
	WHERE 
		(a.CustId = @CustId OR a.Username = @Username)
		AND b.AgentHId.IsDescendantOf(@agentHId) = 1
END
