USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetPositionTakingForUpdate]    Script Date: 4/17/2013 2:57:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




ALTER PROCEDURE [dbo].[Age_Agent_GetPositionTakingForUpdate]
	@AgentId		INT		
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Get agent and its parent position taking and position taking 3rd
 * DB			: APL.CustDB
 * Revisions	:
 *	•	20132802@Edward : Implement
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON
	DECLARE @parentId		INT
			,@agentLevel	INT
			,@agentHId		HIERARCHYID

	DECLARE @MAXMAINSHAREHOLDERPT			INT
			,@MAINAGENTLEVEL				INT

	SET @MAXMAINSHAREHOLDERPT	= 9000
	SET @MAINAGENTLEVEL			= 1

	---- Select parent og agent
	SELECT @parentId		= ai.ParentId
			,@agentLevel	= ai.AgentLevel
			,@agentHId		= ai.AgentHId
	FROM 
		AgentInfo AS ai WITH (NOLOCK)
	WHERE ai.AgentId = @AgentId

	SELECT apt.SportType,
			apt.BetType,
			apt.IsLive,
			apt.PresetPositionTaking,
			CASE WHEN @agentLevel = @MAINAGENTLEVEL
				THEN @MAXMAINSHAREHOLDERPT
				ELSE aptp.MaxPositionTaking
			END									AS ParentMaxPositionTaking,			
			apt.MaxPositionTaking,
			maxDownAgent.MaxOfMaxUpperAndGiven	AS MinOfMaxPositionTaking,
			apt.MinPositionTaking
	FROM AgentPositionTaking AS apt WITH (NOLOCK)
		LEFT JOIN (
			SELECT apt.SportType,
				apt.BetType,
				apt.IsLive,
				apt.PresetPositionTaking,			
				apt.MaxPositionTaking
			FROM AgentPositionTaking AS apt WITH (NOLOCK)	
			WHERE apt.AgentId = @parentId
		) AS aptp
			ON apt.SportType = aptp.SportType
			AND apt.BetType = aptp.BetType
			AND apt.IsLive = aptp.IsLive
		LEFT JOIN (
			SELECT	
				downAgent.SportType
				,downAgent.BetType
				,downAgent.IsLive
				,MAX(downAgent.SumOfMaxUpperAndGiven) AS MaxOfMaxUpperAndGiven
			FROM (
					SELECT ai.AgentId
							,apt.PresetPositionTaking + apt.MaxPositionTaking AS SumOfMaxUpperAndGiven
							,apt.SportType
							,apt.BetType
							,apt.IsLive
					FROM AgentPositionTaking AS apt WITH (NOLOCK)
						INNER JOIN AgentInfo AS ai WITH (NOLOCK)
							ON apt.AgentId = ai.AgentId
					WHERE ai.AgentHId.IsDescendantOf(@agentHId) = 1
						AND ai.AgentId <> @AgentId
				) AS downAgent	
			GROUP BY downAgent.SportType
					,downAgent.BetType
					,downAgent.IsLive
		) AS maxDownAgent
			ON apt.SportType	= maxDownAgent.SportType
			AND apt.BetType		= maxDownAgent.BetType
			AND apt.IsLive		= maxDownAgent.IsLive
	WHERE apt.AgentId = @AgentId

END



