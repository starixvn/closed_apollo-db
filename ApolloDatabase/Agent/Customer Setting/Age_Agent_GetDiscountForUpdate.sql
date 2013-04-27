USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetDiscountForUpdate]    Script Date: 4/17/2013 2:57:08 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Age_Agent_GetDiscountForUpdate]
	@AgentId	INT		
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Get agent and its parent discount 
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
	
	DECLARE @agentHId			HIERARCHYID
			,@parentAgentId		INT								

	-- Get agent hierarchy ID
	SELECT 
		@agentHId		= AgentHId
		,@parentAgentId	= ParentId
	FROM 
		AgentInfo WITH (NOLOCK)
	WHERE 
		AgentId = @AgentId			

	SELECT 
		ad.SportType,
		ad.BetType,
		ad.DiscountA,		
		ad.DiscountB,		
		ad.DiscountC,		
		ad.DiscountD,
		adp.DiscountA	AS UplineMinDiscountA,
		adp.DiscountB	AS UplineMinDiscountB,
		adp.DiscountC	AS UplineMinDiscountC,
		adp.DiscountD	AS UplineMinDiscountD
	FROM 
		AgentDiscount AS ad WITH (NOLOCK)					-- agent discount
		LEFT JOIN AgentDiscount AS adp	WITH (NOLOCK)		-- parent discount
			ON ad.SportType	= adp.SportType	
			AND ad.BetType	= adp.BetType
			AND adp.AgentId = @parentAgentId
	WHERE 
		ad.AgentId		= @AgentId
		
					
END
