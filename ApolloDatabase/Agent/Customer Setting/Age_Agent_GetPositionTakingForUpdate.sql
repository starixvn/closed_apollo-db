USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetPositionTakingForUpdate]    Script Date: 5/3/2013 3:50:23 PM ******/
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
		@MAXMAINSHAREHOLDERPT	INT,
		@MAINAGENTLEVEL			INT

	SET @MAXMAINSHAREHOLDERPT	= 9000
	SET @MAINAGENTLEVEL			= 1

	---- Select parent og agent
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
			WHEN @agentLevel = @MAINAGENTLEVEL THEN @MAXMAINSHAREHOLDERPT
			ELSE aptp.MaxGivenPositionTaking
		END AS ParentMaxGivenPositionTaking,
		apt.MaxGivenPositionTaking,
		CASE 
			WHEN maxDownAgent.MaxOfMaxUpperAndGiven > apt.MinGivenPositionTaking THEN maxDownAgent.MaxOfMaxUpperAndGiven
			ELSE apt.MinGivenPositionTaking
		END AS MinOfMaxGivenPositionTaking,
		apt.MinGivenPositionTaking
	FROM 
		AgentPositionTaking AS apt WITH (NOLOCK)
		LEFT JOIN (
			SELECT 
				SportType,
				BetType,
				IsLive,
				MaxUpperPositionTaking,
				MaxGivenPositionTaking
			FROM AgentPositionTaking WITH (NOLOCK)
			WHERE AgentId = @parentId
		) AS aptp
			ON apt.SportType = aptp.SportType
			AND apt.BetType = aptp.BetType
			AND apt.IsLive = aptp.IsLive
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
	WHERE apt.AgentId = @AgentId

END
