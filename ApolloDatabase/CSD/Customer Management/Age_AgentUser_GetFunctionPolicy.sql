USE [RepDB]
GO
IF EXISTS (SELECT TOP 1 1 FROM sys.objects WHERE type = 'P' AND name = 'Age_AgentUser_GetFunctionPolicy')
	DROP PROC dbo.Age_AgentUser_GetFunctionPolicy
GO
CREATE PROCEDURE [dbo].[Age_AgentUser_GetFunctionPolicy]
(	
	@AgentUserId		INT
	,@FunctionGroupId	SMALLINT	= 0
	,@IsActive			BIT			= NULL		
)
AS

/**
 * Created by	: Edward
 * Date			: 20131002
 * Task			: Get function policy of user
 * DB			: SVRCUST.CustDB
 * Test string	:
	exec Age_AgentUser_GetFunctionPolicy @AgentUserId=1,@FunctionGroupId=0,@IsActive=1

 * Revisions	:
 *	• 20131203@Patrick	Clone sp from Agent Site
 * Parameters:
 *	• 
 *	•
 */

BEGIN
	
	SET NOCOUNT ON			  	
	
	SELECT 	auf.Policy
			,f.FunctionId
			,f.FunctionName
			,f.FunctionKey
			,f.Description
			,f.CRUD
			,f.DisplayOrder
			,f.IsActive
			,f.FunctionGroupId
			,fg.GroupName
			,fg.DisplayOrder 
			,fg.IsActive
	FROM dbo.[Function] AS f WITH (NOLOCK)
	INNER JOIN dbo.FunctionGroup AS fg WITH (NOLOCK) ON f.FunctionGroupId = fg.FunctionGroupId
	INNER JOIN dbo.AgentUserFunction AS auf WITH (NOLOCK) ON f.FunctionId = auf.FunctionId
	WHERE auf.AgentUserId = @AgentUserId
		AND (@FunctionGroupId = 0 OR f.FunctionGroupId = @FunctionGroupId)
		AND fg.IsActive = 1
		AND (@IsActive IS NULL OR (@IsActive IS NOT NULL AND f.IsActive = @IsActive))
	ORDER BY fg.DisplayOrder, f.DisplayOrder
END
GO
GRANT EXECUTE ON [dbo].[Age_AgentUser_GetFunctionPolicy] TO [aplweb]
GO

