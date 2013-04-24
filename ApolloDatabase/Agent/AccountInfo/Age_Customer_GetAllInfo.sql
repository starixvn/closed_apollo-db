USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetAllInfo]    Script Date: 4/24/2013 12:28:40 PM ******/
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

BEGIN
	SELECT 
		a.CustId,
		a.Username,
		a.AgentId,
		b.Username AS ParentName,
		a.UGroup
	FROM 
	(	SELECT 
			 CustId,
			 Username,
			 AgentId,
			 UGroup
		FROM CustInfo p WITH (NOLOCK) 
		WHERE 
			((@CustId <> -1 AND CustId = @CustId) OR (@CustId = -1 AND Username = @Username))
			AND (SELECT AgentHId FROM AgentInfo WITH (NOLOCK) WHERE AgentId = p.AgentId).IsDescendantOf(
			(SELECT AgentHId FROM AgentInfo WITH (NOLOCK) WHERE AgentId = @ActorAgentId)) = 1
	) a
	INNER JOIN AgentInfo b WITH (NOLOCK) ON a.AgentId = b.AgentId
END
