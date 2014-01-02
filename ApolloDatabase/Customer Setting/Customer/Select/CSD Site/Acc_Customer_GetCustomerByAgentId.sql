USE [RepDB]
GO
IF EXISTS (SELECT TOP 1 1 FROM sys.objects WHERE type = 'P' AND name = 'Acc_Customer_GetCustomerByAgentId')
	DROP PROC dbo.Acc_Customer_GetCustomerByAgentId
GO
CREATE PROCEDURE [dbo].[Acc_Customer_GetCustomerByAgentId]
(
	@AgentId	INT
)
AS

/**
 * Created by	: Patrick
 * Date			: 20131203
 * Task			: Get customer by agentid
 * DB			: SVRCSD/RepDB
 * Revisions	:
 *	• 
 * Parameters:
 * Test string	:
	exec [dbo].[Acc_Customer_GetCustomerByAgentId] 152
	
 */

BEGIN
	SET NOCOUNT ON

	SELECT CustId, Username
	FROM dbo.CustInfo WITH(NOLOCK)
	WHERE AgentId = @AgentId
	ORDER BY Username
END

GO
GRANT EXECUTE ON [dbo].[Acc_Customer_GetCustomerByAgentId] TO [aplweb]
GO
