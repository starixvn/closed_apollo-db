

ALTER PROCEDURE [dbo].[Age_AgentUser_GetInfo]
	@AgentUserId	INT	
AS

/**
 * Created by	: Kos
 * Date			: 20130305
 * Task			: Get agent user information
 * DB			:SVRAGE.RepDB
 * Revisions	:
 *	• 
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON	

	SELECT 
		au.AgentUserId,			
		au.Username,
		au.IsMaster,
		au.PageAccess,
		au.CreateDate,
		au.Closed,
		au.Creator,
		au.LoginCount
	FROM AgentUser AS au WITH (NOLOCK)
	WHERE au.AgentUserId = @AgentUserId
		
END	
