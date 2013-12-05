USE [RepDB]
GO
IF EXISTS (SELECT TOP 1 1 FROM sys.objects WHERE type = 'P' AND name = 'Age_Customer_GetByUsername')
	DROP PROC dbo.Age_Customer_GetByUsername
GO
CREATE PROCEDURE [dbo].[Age_Customer_GetByUsername]
(
	@ActorAgentId	INT,
	@Username		NVARCHAR(50)
)
AS

/**
 * Created by	: Quinn
 * Date			: 20130314
 * Task			: Get downline customer by username
 * DB			: SVRCSD/RepDB
 * Test string	:
	exec Age_Customer_GetByUsername @ActorAgentId=1,@Username=N'a'

 * Revisions	:
 *	• 20131203@Patrick	Clone sp from Agent Site
 * Parameters:
 *	@ActorAgentId	: agentId of login user
 *  @Username		: username of Customer
 */

BEGIN

	SET NOCOUNT ON

	DECLARE @agentHId HIERARCHYID

	SELECT @agentHId = AgentHId 
	FROM dbo.AgentInfo WITH (NOLOCK) 
	WHERE AgentId = @ActorAgentId

	SELECT TOP 10
		a.CustId,
		a.Username 
	FROM dbo.CustInfo a WITH (NOLOCK)
	INNER JOIN dbo.AgentInfo b WITH (NOLOCK) ON a.AgentId = b.AgentId
	WHERE a.Username LIKE @Username + '%'
		AND b.AgentHId.IsDescendantOf(@agentHId) = 1
	ORDER BY a.Username
END

GO
GRANT EXECUTE ON [dbo].[Age_Customer_GetByUsername] TO [aplweb]
GO
