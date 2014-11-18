USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[DBA_Agent_GetPTToAgent]    Script Date: 5/6/2013 3:09:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[DBA_Agent_GetPTToAgent]
	@ActorAgentId	INT,
	@AgentId		INT				= -1,
	@Username		NVARCHAR(50)	= '',
	@SportType		SMALLINT,
	@BetType		SMALLINT,
	@IsLive			BIT
AS

/**
 * Created by	: Edward
 * Date			: 20130417
 * Task			: Get agent position taking from current login agent to agent
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
		@agentHId			HIERARCHYID

	SELECT @actorAgentLevel = AgentLevel
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @ActorAgentId

	SELECT 
		@agentLevel	= AgentLevel,
		@agentHId	= AgentHId
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId	= @AgentId OR Username = @Username

	DECLARE @TableAgent TABLE (
		AgentId		INT, 
		AgentLevel	SMALLINT, 
		Username	NVARCHAR(50)
	)

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
		apt.MinGivenPositionTaking
	FROM 
		AgentPositionTaking AS apt WITH (NOLOCK)
		INNER JOIN @TableAgent AS ai ON apt.AgentId = ai.AgentId
		LEFT JOIN @TableAgent AS cai ON ai.AgentLevel = cai.AgentLevel
		LEFT JOIN AgentPositionTaking AS capt WITH (NOLOCK)
			ON apt.SportType	= capt.SportType
			AND apt.BetType		= capt.BetType
			AND apt.IsLive		= capt.IsLive
			AND cai.AgentId		= capt.AgentId
	WHERE 
		apt.SportType	= @SportType
		AND apt.BetType	= @BetType
		AND apt.IsLive	= @IsLive
		AND ai.AgentLevel BETWEEN @actorAgentLevel AND @agentLevel
	ORDER BY ai.AgentLevel
	
END

GRANT EXECUTE ON [dbo].[DBA_Agent_GetPTToAgent] TO [aplweb] AS [dbo]
