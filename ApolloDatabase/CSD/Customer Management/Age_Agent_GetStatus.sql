USE [RepDB]
GO
IF EXISTS (SELECT TOP 1 1 FROM sys.objects WHERE type = 'P' AND name = 'Age_Agent_GetStatus')
	DROP PROC dbo.Age_Agent_GetStatus
GO
CREATE PROCEDURE [dbo].[Age_Agent_GetStatus]
(
	@AgentId		INT,
	@AgentUserId	INT
)
AS

/**
 * Created by	: Ricky
 * Date			: 20130329
 * Task			: Get agent status
 * DB			: SVRCSD/RepDB
 * Test string:
		exec [dbo].[Age_Agent_GetStatus] 1, 1

 * Revisions	:
 *  • 20131120@Patick	: change method get UplineStatus & UplineBetStatus
 *	• 20131203@Patrick	Clone sp from Agent Site
 * Parameters:
 *	•
 *	•
 *  Status
	1: Active
	2: Stopped
	3: Locked
 */

BEGIN
	
	SET NOCOUNT ON	

	DECLARE @AgentUserStatus TINYINT, @AgentStatus TINYINT, @AgentUplineStatus TINYINT
		, @ParentAgentId INT

	SELECT TOP(1) @AgentUserStatus = [Status]
	FROM dbo.AgentUser WITH (NOLOCK) 
	WHERE AgentId = @AgentId AND AgentUserId = @AgentUserId

	SELECT TOP(1) @AgentStatus = [Status], @ParentAgentId = ParentId
	FROM dbo.AgentInfo WITH (NOLOCK)
	WHERE AgentId = @AgentId
	
	--++Get UplineStatus
	SELECT @AgentUplineStatus = dbo.f_GetAgentUplineStatusById(@ParentAgentId)
	IF @AgentUplineStatus IS NULL OR @AgentUplineStatus > 1 --UPLINE WAS LOCKED
	BEGIN
		SELECT @AgentUplineStatus AS CurrentStatus
	END
	ELSE 
	BEGIN
		IF @AgentStatus IS NULL OR @AgentStatus > 1
		BEGIN
			SELECT @AgentStatus AS CurrentStatus
		END
		ELSE
		BEGIN
			SELECT @AgentUserStatus AS CurrentStatus
		END
	END
END	

GO
GRANT EXECUTE ON [dbo].[Age_Agent_GetStatus] TO [aplweb]
GO

