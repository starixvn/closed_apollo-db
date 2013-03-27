ALTER PROCEDURE [dbo].[Age_AgentUser_GetByAgent]
	@AgentId	INT	
AS

/**
 * Created by	: Edward
 * Date			: 20130304
 * Task			: Get agent user by agent
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	• 20130314@Terry.Nguyen: check filter isMaster=0
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
	WHERE au.AgentId = @AgentId AND au.IsMaster = 0
	ORDER BY au.Username, au.Closed	
END	



