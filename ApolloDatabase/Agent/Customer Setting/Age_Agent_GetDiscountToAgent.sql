USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetDiscountToAgent]    Script Date: 5/3/2013 1:18:29 PM ******/
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
		ad.DiscountA,
		ad.DiscountB,
		ad.DiscountC,
		ad.DiscountD,
		ad1x2.DiscountA	AS Discount1x2,
		ado.DiscountA AS DiscountOthers
	FROM 
		AgentDiscount AS ad WITH (NOLOCK)
		INNER JOIN AgentDiscount AS ad1x2 WITH (NOLOCK)	ON ad.AgentId = ad1x2.AgentId
		INNER JOIN AgentDiscount AS ado WITH (NOLOCK) ON ad.AgentId	= ado.AgentId
		INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON ad.AgentId = ai.AgentId
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
	ORDER BY ai.AgentLevel
	
END

GRANT EXECUTE ON [dbo].[Age_Agent_GetDiscountToAgent] TO [aplweb] AS [dbo]

