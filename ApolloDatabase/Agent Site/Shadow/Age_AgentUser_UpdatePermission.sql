

ALTER  PROCEDURE [dbo].[Age_AgentUser_UpdatePermission]
	@AgentId		INT,
	@AgentUserId	INT,	
	@PageAccess		VARCHAR(50),
	@ErrCode		INT				= 0	 OUTPUT,
	@ErrMsg			NVARCHAR(1000)	= '' OUTPUT
AS
/**
 * Created by	: Terry.Nguyen
 * Date			: 20130314
 * Task			: Update permission for Shadow
 * DB			: SVRCUST.CustDB
 * Revisions	:
 *	• 
 * Parameters:
 *	•
 *	•
 *  
 */
BEGIN
	IF EXISTS(SELECT 1 FROM AgentUser WITH(NOLOCK) WHERE AgentId = @AgentId AND AgentUserId = @AgentUserId)
	BEGIN
		UPDATE AgentUser 
		SET PageAccess = @PageAccess
		WHERE AgentId = @AgentId AND AgentUserId = @AgentUserId		
		
	END
	ELSE
	BEGIN
		SELECT 
				@ErrCode = 1,
				@ErrMsg = 'Shadow account dose not exist'
	END

	IF @@ERROR > 0
	BEGIN
		SELECT 
				@ErrCode = 2,
				@ErrMsg = 'Fail to update permission shadow[AgentUserID=' + COALESCE(CAST(@AgentUserId AS VARCHAR(10)), SPACE(1)) + ']'
	END
END

