USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetPositionTakingToCustomer]    Script Date: 7/12/2013 1:43:32 PM ******/
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
	
	DECLARE @agentHId			HIERARCHYID,
			@agentId			INT,
			@isCheck			BIT	

	SELECT 
		@agentId = AgentId,
		@CustId	= CustId
	FROM CustInfo WITH (NOLOCK) 
	WHERE CustId = @CustId OR Username = @Username

	SELECT @agentHId	= AgentHId
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId	= @agentId

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
		apt.MaxUpperPositionTaking,
		apt.MaxGivenPositionTaking,
		apt.MinGivenPositionTaking,
		cpt.PositionTaking
	FROM 
		AgentPositionTaking AS apt WITH (NOLOCK)
		INNER JOIN AgentInfo AS ai WITH (NOLOCK) 
			ON apt.AgentId = ai.AgentId
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
		AND @isCheck = 1

END
