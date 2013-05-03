USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetDiscountToCustomer]    Script Date: 5/3/2013 1:19:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




ALTER PROCEDURE [dbo].[Age_Agent_GetDiscountToCustomer]
	@ActorAgentId		INT,
	@CustId				INT				= -1,
	@Username			NVARCHAR(50)	= ''
AS

/**
 * Created by	: Edward
 * Date			: 20130417
 * Task			: Get agent discount from current login agent to customer
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
	
	DECLARE @actorAgentLevel	INT
			,@agentLevel		INT
			,@agentHId			HIERARCHYID
			,@agentId			INT
			,@uGroup			VARCHAR(3)
			,@tempLevel			INT

	SET @tempLevel = 99999

	SELECT @actorAgentLevel = AgentLevel
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @ActorAgentId

	SELECT @agentId		= AgentId
			,@uGroup	= UGroup
			,@Username	= Username
	FROM CustInfo WITH (NOLOCK) 
	WHERE CustId	= @CustId
		OR Username	= @Username

	SELECT @agentLevel	= AgentLevel
			,@agentHId	= AgentHId			
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId	= @agentId		

	SELECT
		ai.AgentId		AS Id
		,ai.AgentLevel
		,ai.Username 	
		,ad.DiscountA
		,ad.DiscountB
		,ad.DiscountC
		,ad.DiscountD
		,ad1x2.DiscountA	AS Discount1x2
		,ado.DiscountA		AS DiscountOthers
	FROM AgentDiscount AS ad WITH (NOLOCK)
		INNER JOIN AgentDiscount AS ad1x2 WITH (NOLOCK)
			ON ad.AgentId		= ad1x2.AgentId
		INNER JOIN AgentDiscount AS ado WITH (NOLOCK)
			ON ad.AgentId		= ado.AgentId
		INNER JOIN AgentInfo AS ai WITH (NOLOCK)
			ON ad.AgentId		= ai.AgentId		
	WHERE
		ad.SportType		= 1
		AND ad.BetType		= 1
		AND ad1x2.SportType	= 1 
		AND ad1x2.BetType	= 5
		AND ado.SportType	= 1
		AND ado.BetType		= 4
		AND ai.AgentLevel BETWEEN @actorAgentLevel AND @agentLevel
		AND @agentHId.IsDescendantOf(ai.AgentHId) = 1
		AND ai.AgentLevel	<> 0			
	UNION
	SELECT 
		cd.CustId			AS Id
		,@tempLevel			AS AgentLevel
		,@Username			AS Username
		,CASE WHEN @uGroup = 'a' 
			THEN cd.Discount		
			ELSE 0
		END AS DiscountA
		,CASE WHEN @uGroup = 'b' 
			THEN cd.Discount		
			ELSE 0
		END AS DiscountB
		,CASE WHEN @uGroup = 'c' 
			THEN cd.Discount		
			ELSE 0
		END AS DiscountC
		,CASE WHEN @uGroup = 'd' 
			THEN cd.Discount		
			ELSE 0
		END AS DiscountD		
		,cd1x2.Discount		AS Discount1x2
		,cdo.Discount		AS DiscountOthers
	FROM CustDiscount AS cd WITH (NOLOCK)
		INNER JOIN CustDiscount AS cd1x2 WITH (NOLOCK)
			ON cd.CustId	= cd1x2.CustId
		INNER JOIN CustDiscount AS cdo WITH (NOLOCK)
			ON cd.CustId	= cdo.CustId
	WHERE
		cd.CustId			= @CustId
		AND cd.SportType	= 1
		AND cd.BetType		= 1
		AND cd1x2.SportType	= 1
		AND cd1x2.BetType	= 5
		AND cdo.SportType	= 1
		AND cdo.BetType		= 4		
	ORDER BY ai.AgentLevel	
END

