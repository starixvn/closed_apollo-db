USE [RepDB]
GO
IF EXISTS (SELECT TOP 1 1 FROM sys.objects WHERE type = 'P' AND name = 'Age_AgentUser_GetUserFunctionPolicy')
	DROP PROC dbo.Age_AgentUser_GetUserFunctionPolicy
GO
CREATE PROCEDURE [dbo].[Age_AgentUser_GetUserFunctionPolicy]		
	@AgentUserId	INT
	,@FunctionKey	NVARCHAR(50)
AS

/**
 * Created by	: Edward
 * Date			: 20131002
 * Task			: Get user function policy of user
 * DB			: SVRCSD/RepDB
 * Test string	:
	exec Age_AgentUser_GetUserFunctionPolicy @AgentUserId=1,@FunctionKey=N'DownlineDetails'

 * Revisions	:
 *	• 20131203@Patrick	Clone sp from Agent Site
 * Parameters:
 *	• 
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON			  	
	
	SELECT auf.Policy 
	FROM dbo.AgentUserFunction AS auf WITH (NOLOCK)
	INNER JOIN dbo.[Function] AS f WITH (NOLOCK) ON auf.FunctionId = f.FunctionId
	WHERE auf.AgentUserId = @AgentUserId AND f.FunctionKey = @FunctionKey

END		  
GO
GRANT EXECUTE ON [dbo].[Age_AgentUser_GetUserFunctionPolicy] TO [aplweb]
GO


