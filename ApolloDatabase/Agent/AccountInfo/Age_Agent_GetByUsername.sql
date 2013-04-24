USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetByUsername]    Script Date: 4/24/2013 12:26:06 PM ******/
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
 * DB			: APL.DB05
 * Revisions	:
 *	•
 * Parameters:
 *	@ActorAgentId: agentId of login user
 *  @Username: username of agent
 */

SET NOCOUNT ON

BEGIN
	SELECT 
		TOP 10
		AgentId,
		Username 
	FROM 
		AgentInfo WITH (NOLOCK) 
	WHERE 
		AgentId <> @ActorAgentId
		AND Username LIKE @Username + '%'
		AND AgentHId.IsDescendantOf((SELECT AgentHId FROM AgentInfo WITH (NOLOCK) WHERE AgentId = @ActorAgentId)) = 1
	ORDER BY
		Username	
END
