USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetDiscount]    Script Date: 5/3/2013 5:03:15 PM ******/
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
 * Task			: Get agent discount
 * DB			: SVRAGE.RepDB
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
END
