USE [CustDB]
GO

/****** Object:  StoredProcedure [dbo].[Age_Agent_GetPositionTakingToCustomer_xtest]    Script Date: 11/29/2013 4:01:32 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Age_Agent_GetPositionTakingToCustomer_xtest    Script Date: 10/7/2013 4:56:44 PM ******/


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
 *	•	20130722@Edward : Add super view	
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
		@SUPERID			INT			= 1

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
		acpt.PositionTaking
	FROM 
		AgentPositionTaking AS apt WITH (NOLOCK)
		INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON apt.AgentId = ai.AgentId
		INNER JOIN AgentCustPositionTaking AS acpt WITH (NOLOCK)
			ON apt.SportType	= acpt.SportType
			AND apt.BetType		= acpt.BetType
			AND apt.IsLive		= acpt.IsLive
			AND apt.AgentId		= acpt.AgentId
	WHERE 
		apt.SportType			= @SportType
		AND apt.BetType			= @BetType
		AND apt.IsLive			= @IsLive		
		AND acpt.AgentCustId	= @agentId
		AND ai.AgentLevel		>= @actorAgentLevel
		AND @isCheck			= 1	
	ORDER BY ai.AgentLevel
	
	SELECT * FROM 
	(
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
		WHERE ai.AgentId = @SUPERID
			AND @isCheck = 1	
			AND @ActorAgentId =	@SUPERID
		) AS temp
	ORDER BY temp.AgentLevel
END
GO

GRANT EXECUTE ON [dbo].[Age_Agent_GetPositionTakingToCustomer] TO [aplweb] AS [dbo]
GO


