USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetByUsername]    Script Date: 4/25/2013 9:55:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_GetByUsername]
	@ActorAgentId INT,
	@Username NVARCHAR(50)
AS

/**
 * Created by	: Quinn
 * Date			: 20130314
 * Task			: get Agent by username
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	•
 * Parameters:
 *	@ActorAgentId: agentId of login user
 *  @Username: username of agent
 */

SET NOCOUNT ON

DECLARE @agentHId HIERARCHYID

BEGIN
	SELECT @agentHId = AgentHId FROM AgentInfo WITH (NOLOCK) WHERE AgentId = @ActorAgentId

	SELECT 
		TOP 10
		AgentId,
		Username 
	FROM 
		AgentInfo WITH (NOLOCK) 
	WHERE 
		AgentId <> @ActorAgentId
		AND Username LIKE @Username + '%'
		AND AgentHId.IsDescendantOf(@agentHId) = 1
	ORDER BY
		Username	
END
