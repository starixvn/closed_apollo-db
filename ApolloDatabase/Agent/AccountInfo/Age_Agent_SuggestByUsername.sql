USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_SuggestByUsername]    Script Date: 7/7/2013 10:39:23 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_SuggestByUsername]
	@ActorAgentId	INT,
	@Username		NVARCHAR(50),
	@ExcludeActor	BIT = 0
AS

/**
 * Created by	: Quinn
 * Date			: 20130314
 * Task			: get Agent by username
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	•
 * Parameters:
 *	@ActorAgentId	: agentId of login user
 *  @Username		: username of agent
 *	@ExcludeActor	: not get Actor
 *	[dbo].[Age_Agent_GetByUsername] 2, 'testcs', 0
 */

BEGIN

	SET NOCOUNT ON

	DECLARE @agentHId HIERARCHYID

	SELECT @agentHId = AgentHId 
	FROM AgentInfo WITH (NOLOCK) 
	WHERE AgentId = @ActorAgentId

	SELECT TOP 10
		AgentId,
		Username 
	FROM AgentInfo WITH (NOLOCK) 
	WHERE 
		(@ExcludeActor = 0 OR AgentId <> @ActorAgentId)
		AND Username LIKE @Username + '%'
		AND AgentHId.IsDescendantOf(@agentHId) = 1
	ORDER BY Username	

END
