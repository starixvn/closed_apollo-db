USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetDiscountForUpdate]    Script Date: 5/3/2013 4:42:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_GetDiscountForUpdate]
	@CustId		INT
AS

/**
 * Created by	: Kos
 * Date			: 20130304
 * Task			: Get customer discount and necessary information to update
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	•	20130319@Edward.Nguyen : Update Get Upline min discount from direct agent 
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON 
	
	DECLARE @agentId INT

	SELECT @agentId = AgentId
	FROM CustInfo WITH (NOLOCK)
	WHERE CustId = @CustId

	SELECT 
		pd.SportType,
		pd.BetType,
		pd.Discount,
		ad.DiscountA AS UplineMinDiscountA,
		ad.DiscountB AS UplineMinDiscountB,
		ad.DiscountC AS UplineMinDiscountC,
		ad.DiscountD AS UplineMinDiscountD
	FROM 
		CustDiscount AS pd WITH (NOLOCK)					-- customer discount
		INNER JOIN AgentDiscount AS ad WITH (NOLOCK)		-- upline discount
			ON pd.SportType = ad.SportType 
			AND pd.BetType = ad.BetType
	WHERE pd.CustId	= @CustId AND ad.AgentId = @agentId 
	
END
