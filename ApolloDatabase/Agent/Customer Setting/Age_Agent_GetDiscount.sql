USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetDiscount]    Script Date: 3/29/2013 9:57:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Age_Agent_GetDiscount]
	@AgentId	INT		
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Get agent discount and discount 3rd
 * DB			: APL.CustDB
 * Revisions	:
 *	•  20132802@Edward : Implement
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
		DiscountA,
		DiscountB,
		DiscountC,
		DiscountD
	FROM AgentDiscount WITH (NOLOCK)
	WHERE AgentId = @AgentId	

	UNION

	SELECT 
		SportType,
		BetType,
		DiscountA,
		DiscountB,
		DiscountC,
		DiscountD
	FROM AgentDiscount3rd WITH (NOLOCK)
	WHERE AgentId = @AgentId	

END
