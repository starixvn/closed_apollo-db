ALTER PROCEDURE [dbo].[Age_Agent_GetBetLimitForUpdate]
	@AgentId	INT,	
	@MaxBetLimit MONEY = 0 OUTPUT
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Get agent and its parent bet limit and bet limit 3rd
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	•	20132802@Edward : Implement
  *	•	20131111@Sophia: Get @MaxBetLimit
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN

	SET NOCOUNT ON
	DECLARE @CurrencyId	tinyint 
	 
	

	DECLARE 
		@agentHId	HIERARCHYID,
		@SUPERLEVEL	INT

	SET @SUPERLEVEL = 0

	-- Get agent hierarchy ID
	SELECT @agentHId = AgentHId,
		@CurrencyId = Currency
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @AgentId

	SELECT @MaxBetLimit = MinMaxBet			
	FROM   Exchange WITH (NOLOCK)
	WHERE  ExchangeId = @CurrencyId

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



