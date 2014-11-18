USE [RepDB]
GO
ALTER PROCEDURE [dbo].[Acc_Customer_GetGroupByCustId]
	@CustId		INT
AS
/**

 * Created by	: Kos
 * Date			: 20130305
 * Task			: Get customer information
 * DB			: SVRAGE/RepDB
 * Revisions	:
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	SET NOCOUNT ON	
	SELECT @CustId AS CustId, ci.UGroup, ci.IsUGroupChanged
	FROM dbo.CustInfo AS ci WITH (NOLOCK)
	WHERE CustId = @CustId

END

GO

GRANT EXECUTE ON [dbo].[Acc_Customer_GetGroupByCustId] TO [aplweb] AS [dbo]
GO


