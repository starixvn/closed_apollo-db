USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetPositionTakingForUpdate_xtest]    Script Date: 8/20/2013 10:52:05 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_GetPositionTakingForUpdate]
	@AgentId	INT
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Get agent and its parent position taking and position taking 3rd
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	•	20132802@Edward : Implement
 *	•	20130820@Edward : Refacter duplicate code LEFT JOIN AgentPositionTaking
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON

	DECLARE 
		@parentId	INT,
		@agentLevel	SMALLINT,
		@agentHId	HIERARCHYID

	DECLARE 
		@MAXMAINSHAREHOLDERPT	INT	= 10000,
		@MAINSHAREHOLDERLEVEL	INT	= 1,
		@SHAREHOLDERLEVEL		INT = 2,
		@MINSHAREMUSTCOVER		INT	= 5000

	-- Get agent information
	SELECT 
		@parentId	= ParentId,
		@agentLevel	= AgentLevel,
		@agentHId	= AgentHId
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @AgentId

	SELECT 
		apt.SportType,
		apt.BetType,
		apt.IsLive,
		apt.MaxUpperPositionTaking,
		CASE 
			WHEN @agentLevel = @MAINSHAREHOLDERLEVEL THEN @MAXMAINSHAREHOLDERPT
			ELSE papt.MaxGivenPositionTaking
		END AS ParentMaxGivenPositionTaking,
		apt.MaxGivenPositionTaking,
		CASE
			WHEN @agentLevel <= @SHAREHOLDERLEVEL AND ISNULL(maxDownAgent.MaxOfMaxUpperAndGiven, 0) < @MINSHAREMUSTCOVER
				THEN @MINSHAREMUSTCOVER
			ELSE ISNULL(maxDownAgent.MaxOfMaxUpperAndGiven, 0)
		END	AS MinOfMaxGivenPositionTaking,
		apt.MinGivenPositionTaking
		,ISNULL(papt.MinGivenPositionTaking, 0) AS MinGivenPositionTakingOfParent
	FROM 
		AgentPositionTaking AS apt WITH (NOLOCK)
		LEFT JOIN AgentPositionTaking AS papt WITH (NOLOCK)
			ON apt.SportType	= papt.SportType
			AND apt.BetType		= papt.BetType
			AND apt.IsLive		= papt.IsLive
			AND papt.AgentId	= @parentId	
		LEFT JOIN (
			SELECT	
				capt.SportType,
				capt.BetType,
				capt.IsLive,
				MAX(capt.MaxUpperPositionTaking + capt.MaxGivenPositionTaking) AS MaxOfMaxUpperAndGiven
			FROM AgentPositionTaking AS capt WITH (NOLOCK)
			WHERE 
				capt.AgentId <> @AgentId
				AND EXISTS (	SELECT 1 
								FROM AgentInfo WITH (NOLOCK) 
								WHERE AgentId = capt.AgentId	AND AgentHId.IsDescendantOf(@agentHId) = 1 )
			GROUP BY 
				capt.SportType,
				capt.BetType,
				capt.IsLive
		) AS maxDownAgent
			ON apt.SportType	= maxDownAgent.SportType
			AND apt.BetType		= maxDownAgent.BetType
			AND apt.IsLive		= maxDownAgent.IsLive
	WHERE apt.AgentId = @AgentId 

END
