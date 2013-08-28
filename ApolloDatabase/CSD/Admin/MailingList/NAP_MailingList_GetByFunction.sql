CREATE PROCEDURE [dbo].[NAP_MailingList_GetByFunction]
	@FunctionId SMALLINT	
AS
SET NOCOUNT ON

SELECT	* 
FROM	MailingList WITH (NOLOCK)
WHERE	FunctionId = @FunctionId

GO
GRANT EXECUTE ON [NAP_MailingList_GetByFunction] TO [bodbAdminNet]
GO
