USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetPositionTakingToAgent]    Script Date: 7/12/2013 1:43:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_GetPositionTakingToAgent]
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
 *	•	07122013@Edward : Get the same structure in DB	
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON	
	
	DECLARE @agentHId			HIERARCHYID,
			@isCheck			BIT
	
	SELECT @agentHId	= AgentHId
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @AgentId OR Username = @Username	
   
	
	SET @isCheck = 1

	IF NOT EXISTS (
		SELECT TOP(1) *
		FROM AgentInfo WITH (NOLOCK)
		WHERE 
			@agentHId.IsDescendantOf(AgentHId) = 1
			AND AgentId	= @ActorAgentId	
	)
		BEGIN					
			SET @isCheck = 0	
		END
	
	DECLARE @TableAgent TABLE (
		AgentId		INT, 
		AgentLevel	SMALLINT, 
		Username	NVARCHAR(50) )

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
		apt.MaxUpperPositionTaking,
		apt.MaxGivenPositionTaking,
		apt.MinGivenPositionTaking
	FROM 
		AgentPositionTaking AS apt WITH (NOLOCK)
		INNER JOIN @TableAgent AS ai ON apt.AgentId = ai.AgentId				
	WHERE 
		apt.SportType	= @SportType
		AND apt.BetType	= @BetType
		AND apt.IsLive	= @IsLive		
		AND @isCheck = 1
	ORDER BY ai.AgentLevel
	
END

GRANT EXECUTE ON [dbo].[Age_Agent_GetPositionTakingToAgent] TO [aplweb] AS [dbo]