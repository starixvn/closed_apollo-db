USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[DBA_Agent_GetPTToCustomer]    Script Date: 5/6/2013 3:29:17 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[DBA_Agent_GetPTToCustomer]
	@ActorAgentId	INT,
	@CustId			INT				= -1,
	@Username		NVARCHAR(50)	= '',
	@SportType		SMALLINT,
	@BetType		SMALLINT,
	@IsLive			BIT
AS

/**
 * Created by	: Edward
 * Date			: 20130417
 * Task			: Get agent position taking from current login agent to customer
 * DB			: SVRAGE.RepDB
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
		@agentLevel			SMALLINT,
		@agentHId			HIERARCHYID,
		@agentId			INT

	SELECT @actorAgentLevel = AgentLevel
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @ActorAgentId

	SELECT 
		@agentId = AgentId,
		@CustId	= CustId
	FROM CustInfo WITH (NOLOCK) 
	WHERE CustId = @CustId OR Username = @Username

	SELECT 
		@agentLevel	= AgentLevel,
		@agentHId	= AgentHId
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @agentId

	DECLARE @TableAgent TABLE (
		AgentId		INT, 
		AgentLevel	SMALLINT, 
		Username	NVARCHAR(50))

	INSERT INTO @TableAgent
	SELECT 
		AgentId,
		AgentLevel,
		Username 
	FROM AgentInfo WITH (NOLOCK) 
	WHERE @agentHId.IsDescendantOf(AgentHId) = 1

	SELECT 	
		apt.AgentId,
		ai.AgentLevel,
		ai.Username,
		capt.MaxUpperPositionTaking,
		apt.MaxGivenPositionTaking,
		apt.MinGivenPositionTaking,
		cpt.PositionTaking
	FROM 
		AgentPositionTaking AS apt WITH (NOLOCK)
		INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON apt.AgentId = ai.AgentId
		LEFT JOIN @TableAgent AS cai ON ai.AgentLevel = cai.AgentLevel
		LEFT JOIN AgentPositionTaking AS capt WITH (NOLOCK)
			ON apt.SportType	= capt.SportType
			AND apt.BetType		= capt.BetType
			AND apt.IsLive		= capt.IsLive
			AND cai.AgentId		= capt.AgentId
		INNER JOIN CustPositionTaking AS cpt WITH (NOLOCK)
			ON apt.SportType	= cpt.SportType
			AND apt.BetType		= cpt.BetType
			AND apt.IsLive		= cpt.IsLive
			AND apt.AgentId		= cpt.AgentId
	WHERE 
		apt.SportType	= @SportType
		AND apt.BetType	= @BetType
		AND apt.IsLive	= @IsLive
		AND ai.AgentLevel BETWEEN @actorAgentLevel AND @agentLevel
		AND cpt.CustId	= @CustId

END

