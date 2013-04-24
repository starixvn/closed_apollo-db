USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetAllInfo]    Script Date: 4/24/2013 12:27:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_GetAllInfo]
	@ActorAgentId INT,
	@AgentId INT = -1,
	@Username NVARCHAR(50) = ''
AS

/**
 * Created by	: Quinn
 * Date			: 20130307
 * Task			: Get Agent Info by Id or Username
 * DB			: APL.DB05
 * Revisions	:
 *	•
 * Parameters:
 *	@ActorAgentId: agentId of login user
 *	@AgentId: agent ID
 *  @UserName: username of Agent
 */

SET NOCOUNT ON

BEGIN
	SELECT 
		a.AgentId, 
		a.Username,
		a.AgentLevel,
		a.ParentId,
		b.Username AS ParentName,
		CASE WHEN (EXISTS (SELECT 1 FROM AgentInfo WITH (NOLOCK) WHERE ParentId = a.AgentId)) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS HasAgentDownline,
		CASE WHEN (EXISTS (SELECT 1 FROM CustInfo WITH (NOLOCK) WHERE AgentId = a.AgentId)) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS HasMemberDownline
	FROM 
	(	SELECT 
			AgentId,
			Username,
			AgentLevel,
			ParentId  
		FROM AgentInfo WITH (NOLOCK) 
		WHERE 
		(AgentId = @AgentId OR Username = @Username)
		AND AgentId <> @ActorAgentId
		AND AgentHId.IsDescendantOf((SELECT AgentHId FROM AgentInfo WITH (NOLOCK) WHERE AgentId = @ActorAgentId)) = 1
	) a
	INNER JOIN AgentInfo b WITH (NOLOCK) ON a.ParentId = b.AgentId
END
