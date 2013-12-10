USE [RepDB]
GO
IF EXISTS (SELECT TOP 1 1 FROM sys.objects WHERE type = 'P' AND name = 'Acc_Agent_SuggestByUsername')
	DROP PROC dbo.Acc_Agent_SuggestByUsername
GO
CREATE PROCEDURE [dbo].[Acc_Agent_SuggestByUsername]
(
	@Username		NVARCHAR(50)
)
AS

/**
 * Created by	: Quinn
 * Date			: 20130314
 * Task			: Get Agent by username
 * DB			: SVRCSD/RepDB
 * Revisions	:
 *	• 20131203@Patrick	updated
 * Parameters:
 *  @Username		: username of agent
 * Test string	:
	exec Acc_Agent_SuggestByUsername @Username=N'aa5001'
 */

BEGIN

	SET NOCOUNT ON

	SELECT TOP 10
		AgentId,
		Username 
	FROM dbo.AgentInfo WITH (NOLOCK) 
	WHERE Username LIKE @Username + '%'
	ORDER BY Username	

END

GO
GRANT EXECUTE ON [dbo].[Acc_Agent_SuggestByUsername] TO [aplweb]
GO
