USE [RepDB]
GO
IF EXISTS (SELECT TOP 1 1 FROM sys.objects WHERE type = 'P' AND name = 'Acc_Customer_GetByUsername')
	DROP PROC dbo.Acc_Customer_GetByUsername
GO
CREATE PROCEDURE [dbo].[Acc_Customer_GetByUsername]
(
	@Username		NVARCHAR(50)
)
AS

/**
 * Created by	: Quinn
 * Date			: 20130314
 * Task			: 
 * DB			: SVRCSD/RepDB
 * Revisions	:
 *	• 20131203@Patrick	Updated
 * Parameters:
 *  @Username		: username of Customer
 * Test string	:
	exec Acc_Customer_GetByUsername @Username=N'a'

 */

BEGIN

	SET NOCOUNT ON

	SELECT TOP 10
		CustId,
		Username 
	FROM dbo.CustInfo WITH (NOLOCK)
	WHERE Username LIKE @Username + '%'
	ORDER BY Username
END

GO
GRANT EXECUTE ON [dbo].[Acc_Customer_GetByUsername] TO [aplweb]
GO
