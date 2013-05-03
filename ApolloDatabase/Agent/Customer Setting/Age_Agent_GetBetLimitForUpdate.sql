USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetBetLimitForUpdate]    Script Date: 5/3/2013 3:41:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_GetBetLimitForUpdate]
	@AgentId	INT
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Get agent and its parent bet limit and bet limit 3rd
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
		@agentHId	HIERARCHYID,
		@SUPERLEVEL	INT

	SET @SUPERLEVEL = 0

	-- Get agent hierarchy ID
	SELECT @agentHId = AgentHId
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @AgentId

	-- Select of AgentBetLimit
	SELECT  
		abl.SportType,
		abl.BetType,
		abl.MinBet,
		abl.MaxBet,
		abl.MaxPerMatch,
		ubl.MaxMinBet,
		ubl.MinMaxBet,
		ubl.MinMaxPerMatch
	FROM 
		AgentBetLimit AS abl WITH (NOLOCK)
		LEFT JOIN (
			---- Select up line max of min bet, min of max bet, min of max per match 
			SELECT 
				SportType,
				BetType,
				MAX(MinBet) AS MaxMinBet,
				MIN(MaxBet) AS MinMaxBet,
				MIN(MaxPerMatch) AS MinMaxPerMatch
			FROM AgentBetLimit WITH (NOLOCK)
			WHERE AgentId IN (	SELECT AgentId 
								FROM AgentInfo WITH (NOLOCK)
								WHERE 
									@AgentHId.IsDescendantOf(AgentHId) = 1 
									AND AgentId <> @AgentId 
									AND AgentLevel <> @SUPERLEVEL )
			GROUP BY 
				SportType,
				BetType 
		) AS ubl 
			ON abl.SportType = ubl.SportType 
			AND abl.BetType = ubl.BetType	
	WHERE abl.AgentId = @AgentId

END

