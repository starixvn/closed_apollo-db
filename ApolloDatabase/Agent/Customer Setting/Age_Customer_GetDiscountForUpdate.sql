USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetDiscountForUpdate]    Script Date: 4/17/2013 2:58:40 PM ******/
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
 * DB			: APL.CustDB
 * Revisions	:
 *	•	20130319@Edward.Nguyen : Update Get Upline min discount from direct agent 
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON 
	
	DECLARE @agentHId HIERARCHYID
	DECLARE @agentId	INT

	-- Get agent hierarchy ID
	SELECT @agentHId = AgentHId	, @agentId = AgentId
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = (	SELECT pli.AgentId
						FROM CustInfo AS pli WITH (NOLOCK)
						WHERE pli.CustId = @CustId	)		

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
	WHERE pd.CustId		= @CustId
		AND ad.AgentId	= @agentId 
	
END
