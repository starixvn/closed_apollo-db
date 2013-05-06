USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetDiscountToAgent]    Script Date: 5/6/2013 12:45:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_GetDiscountToAgent]
	@ActorAgentId	INT,
	@AgentId		INT				= -1,
	@Username		NVARCHAR(50)	= ''	
AS

/**
 * Created by	: Edward
 * Date			: 20130417
 * Task			: Get agent discount from current login agent to agent
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
	
	DECLARE 
		@actorAgentLevel	INT,
		@agentLevel			INT,
		@agentHId			HIERARCHYID

	SELECT @actorAgentLevel = AgentLevel
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @ActorAgentId

	SELECT 
		@agentLevel	= AgentLevel,
		@agentHId = AgentHId
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @AgentId OR Username = @Username

	SELECT
		ai.AgentId,
		ai.Username,	
		ai.AgentLevel,		
		MAX(CASE WHEN ad.BetType = 1 AND ad.SportType = 1 THEN ad.DiscountA ELSE 0 END) AS DiscountA,
		MAX(CASE WHEN ad.BetType = 1 AND ad.SportType = 1 THEN ad.DiscountB ELSE 0 END) AS DiscountB,
		MAX(CASE WHEN ad.BetType = 1 AND ad.SportType = 1 THEN ad.DiscountC ELSE 0 END) AS DiscountC,
		MAX(CASE WHEN ad.BetType = 1 AND ad.SportType = 1 THEN ad.DiscountD ELSE 0 END) AS DiscountD,					
		MAX(CASE WHEN ad.Bettype = 5 AND ad.SportType = 1 THEN ad.DiscountA ELSE 0 END) AS Discount1x2,					
		MAX(CASE WHEN ad.Bettype = 4 AND ad.SportType = 1 THEN ad.DiscountA ELSE 0 END) AS DiscountOthers
	FROM 
		AgentDiscount AS ad WITH (NOLOCK)		
		INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON ad.AgentId = ai.AgentId
	WHERE		
		ai.AgentLevel BETWEEN @actorAgentLevel AND @agentLevel
		AND @agentHId.IsDescendantOf(ai.AgentHId) = 1
		AND ai.AgentLevel	<> 0
	GROUP BY ai.AgentId
			,ai.Username
			,ai.AgentLevel
	ORDER BY ai.AgentLevel
	
	
END