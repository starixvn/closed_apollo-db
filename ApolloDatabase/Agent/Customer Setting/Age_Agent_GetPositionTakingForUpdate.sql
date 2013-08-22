USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetPositionTakingForUpdate]    Script Date: 8/20/2013 10:07:16 AM ******/
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
		,ISNULL(papt.MinGivenPositionTaking, 0)			AS MinGivenPositionTakingOfParent
	FROM 
		AgentPositionTaking AS apt WITH (NOLOCK)
		LEFT JOIN AgentPositionTaking AS papt WITH (NOLOCK)
			ON apt.SportType	= papt.SportType
			AND apt.BetType		= papt.BetType
			AND apt.IsLive		= papt.IsLive
			AND papt.AgentId	= @parentId					
		LEFT JOIN (
			SELECT	
				downAgent.SportType,
				downAgent.BetType,
				downAgent.IsLive,
				MAX(downAgent.SumOfMaxUpperAndGiven) AS MaxOfMaxUpperAndGiven
			FROM (
					SELECT 
						ai.AgentId,
						apt.MaxUpperPositionTaking + apt.MaxGivenPositionTaking AS SumOfMaxUpperAndGiven,
						apt.SportType,
						apt.BetType,
						apt.IsLive
					FROM 
						AgentPositionTaking AS apt WITH (NOLOCK)
						INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON apt.AgentId = ai.AgentId
					WHERE ai.AgentHId.IsDescendantOf(@agentHId) = 1 AND ai.AgentId <> @AgentId
				) AS downAgent
			GROUP BY 
				downAgent.SportType,
				downAgent.BetType,
				downAgent.IsLive
		) AS maxDownAgent
			ON apt.SportType	= maxDownAgent.SportType
			AND apt.BetType		= maxDownAgent.BetType
			AND apt.IsLive		= maxDownAgent.IsLive
	WHERE apt.AgentId	= @AgentId		

END
