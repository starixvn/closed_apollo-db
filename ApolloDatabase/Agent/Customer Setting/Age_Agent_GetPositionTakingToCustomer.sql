USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetPositionTakingToCustomer]    Script Date: 7/18/2013 1:53:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_GetPositionTakingToCustomer]
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
		@agentHId			HIERARCHYID,
		@agentId			INT,
		@isCheck			BIT,
		@actorAgentLevel	SMALLINT,			
		@MAXPISITIONTAKING	SMALLINT	= 10000,
		@SUPPERID			INT			= 1

	SELECT 
		@agentId = AgentId,
		@CustId	= CustId
	FROM CustInfo WITH (NOLOCK) 
	WHERE CustId = @CustId OR Username = @Username

	SELECT @agentHId = AgentHId
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId	= @agentId

	SELECT @actorAgentLevel = AgentLevel
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId	= @ActorAgentId

	SET @isCheck = 1

	IF NOT EXISTS (	SELECT 1
					FROM AgentInfo WITH (NOLOCK)
					WHERE 
						@agentHId.IsDescendantOf(AgentHId) = 1
						AND AgentId	= @ActorAgentId )
		BEGIN
			SET @isCheck = 0	
		END	

	DECLARE @TablePositionTaking TABLE( 
		AgentId			INT
		,AgentLevel		SMALLINT
		,Username		NVARCHAR(50)
		,MaxUpper		SMALLINT
		,MaxGiven		SMALLINT
		,MinGiven		SMALLINT
		,PositionTaking	SMALLINT)

	INSERT @TablePositionTaking(
		AgentId
		,AgentLevel
		,Username
		,MaxUpper
		,MaxGiven
		,MinGiven
		,PositionTaking
	)
	SELECT
		apt.AgentId,
		ai.AgentLevel,
		ai.Username,
		apt.MaxUpperPositionTaking,
		apt.MaxGivenPositionTaking,
		apt.MinGivenPositionTaking,
		cpt.PositionTaking
	FROM 
		AgentPositionTaking AS apt WITH (NOLOCK)
		INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON apt.AgentId = ai.AgentId
		INNER JOIN CustPositionTaking AS cpt WITH (NOLOCK)
			ON apt.SportType	= cpt.SportType
			AND apt.BetType		= cpt.BetType
			AND apt.IsLive		= cpt.IsLive
			AND apt.AgentId		= cpt.AgentId
	WHERE 
		apt.SportType	= @SportType
		AND apt.BetType	= @BetType
		AND apt.IsLive	= @IsLive		
		AND cpt.CustId	= @CustId
		AND ai.AgentLevel >= @actorAgentLevel
		AND @isCheck = 1	
	ORDER BY ai.AgentLevel
	
	SELECT
		AgentId,
		AgentLevel,
		Username,
		MaxUpper	AS MaxUpperPositionTaking,
		MaxGiven	AS MaxGivenPositionTaking,
		MinGiven	AS MinGivenPositionTaking,
		PositionTaking
	FROM @TablePositionTaking 
	UNION
	SELECT
		ai.AgentId
		,ai.AgentLevel
		,ai.Username
		,apt.MaxUpperPositionTaking
		,apt.MaxGivenPositionTaking
		,apt.MinGivenPositionTaking
		,@MAXPISITIONTAKING - CONVERT(SMALLINT,(SELECT SUM(PositionTaking) FROM @TablePositionTaking)) AS PositionTaking
	FROM AgentInfo AS ai WITH (NOLOCK)
		INNER JOIN AgentPositionTaking AS apt WITH (NOLOCK)
			ON ai.AgentId	= apt.AgentId
	WHERE ai.AgentId = @SUPPERID
END
