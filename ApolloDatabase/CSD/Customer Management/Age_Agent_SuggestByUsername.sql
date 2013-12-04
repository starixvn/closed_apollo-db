USE [RepDB]
GO
IF EXISTS (SELECT TOP 1 1 FROM sys.objects WHERE type = 'P' AND name = 'Age_Agent_SuggestByUsername')
	DROP PROC dbo.Age_Agent_SuggestByUsername
GO
CREATE PROCEDURE [dbo].[Age_Agent_SuggestByUsername]
(
	@ActorAgentId	INT,
	@Username		NVARCHAR(50),
	@ExcludeActor	BIT = 0
)
AS

/**
 * Created by	: Quinn
 * Date			: 20130314
 * Task			: get Agent by username
 * DB			: SVRCSD/RepDB
 * Test string	:
	exec Age_Agent_SuggestByUsername @ActorAgentId=1,@Username=N'aa5001',@ExcludeActor=0

 * Revisions	:
 *	• 20131203@Patrick	Clone sp from Agent Site
 * Parameters:
 *	@ActorAgentId	: agentId of login user
 *  @Username		: username of agent
 *	@ExcludeActor	: not get Actor
 */

BEGIN

	SET NOCOUNT ON

	DECLARE @agentHId HIERARCHYID

	SELECT @agentHId = AgentHId 
	FROM dbo.AgentInfo WITH (NOLOCK) 
	WHERE AgentId = @ActorAgentId

	SELECT TOP 10
		AgentId,
		Username 
	FROM dbo.AgentInfo WITH (NOLOCK) 
	WHERE (@ExcludeActor = 0 OR AgentId <> @ActorAgentId)
		AND Username LIKE @Username + '%'
		AND AgentHId.IsDescendantOf(@agentHId) = 1
	ORDER BY Username	

END

GO
GRANT EXECUTE ON [dbo].[Age_Agent_SuggestByUsername] TO [aplweb]
GO
