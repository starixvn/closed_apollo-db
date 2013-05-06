USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetDiscountToCustomer]    Script Date: 5/6/2013 12:45:30 PM ******/
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
		,MAX(CASE WHEN ad.BetType = 1 AND ad.SportType = 1 THEN ad.DiscountA ELSE 0 END) AS DiscountA
		,MAX(CASE WHEN ad.BetType = 1 AND ad.SportType = 1 THEN ad.DiscountB ELSE 0 END) AS DiscountB
		,MAX(CASE WHEN ad.BetType = 1 AND ad.SportType = 1 THEN ad.DiscountC ELSE 0 END) AS DiscountC
		,MAX(CASE WHEN ad.BetType = 1 AND ad.SportType = 1 THEN ad.DiscountD ELSE 0 END) AS DiscountD					
		,MAX(CASE WHEN ad.Bettype = 5 AND ad.SportType = 1 THEN ad.DiscountA ELSE 0 END) AS Discount1x2					
		,MAX(CASE WHEN ad.Bettype = 4 AND ad.SportType = 1 THEN ad.DiscountA ELSE 0 END) AS DiscountOthers
	FROM AgentDiscount AS ad WITH (NOLOCK)		
		INNER JOIN AgentInfo AS ai WITH (NOLOCK)
			ON ad.AgentId		= ai.AgentId		
	WHERE
		ai.AgentLevel BETWEEN @actorAgentLevel AND @agentLevel
		AND @agentHId.IsDescendantOf(ai.AgentHId) = 1
		AND ai.AgentLevel	<> 0	
	GROUP BY ai.AgentId
			,ai.AgentLevel
			,ai.Username		
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


