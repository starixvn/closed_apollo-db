USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetDiscount]    Script Date: 4/17/2013 2:58:31 PM ******/
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
 * Task			: Get customer discount and discount 3rd
 * DB			: APL.CustDB
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