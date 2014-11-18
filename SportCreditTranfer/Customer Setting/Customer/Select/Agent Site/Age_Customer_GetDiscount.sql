USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetDiscount]    Script Date: 5/3/2013 4:56:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Age_Customer_GetDiscount]
	@CustId		INT
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Get customer discount
 * DB			: SVRAGE.RepDB
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
		SportType,
		BetType,
		Discount
	FROM CustDiscount WITH (NOLOCK)
	WHERE CustId = @CustId
		
END	