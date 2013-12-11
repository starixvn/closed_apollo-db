ALTER PROCEDURE [dbo].[Age_Agent_GetBetLimitForUpdate]
	@AgentId	INT,	
	@MaxBetLimit MONEY = 0 OUTPUT
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Get agent and its parent bet limit and bet limit 3rd
 * DB			: SVRCUST.CustDB
 * Revisions	:
 	•	20132802@Edward : Implement
  	•	20131111@Sophia: Get @MaxBetLimit
	•	20131120@Dan: optimize performance
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

	;WITH Agent_CTE(agentid, Parentid, AgentLevel) as 
	(
		SELECT ai.AgentId as agentid, 
				Parentid,
				AgentLevel				
		FROM AgentInfo ai  WITH (NOLOCK)
		WHERE AgentID = @AgentId
		UNION ALL
		SELECT ai.AgentId as agentid,
			   ai.Parentid as Parentid,
			   ai.AgentLevel as AgentLevel
		FROM AgentInfo ai WITH (NOLOCK) 
			INNER JOIN Agent_CTE ac ON ac.Parentid = ai.AgentId		
	)

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
								FROM Agent_CTE
								WHERE AgentId <> @AgentId 
									AND AgentLevel <> @SUPERLEVEL )
			GROUP BY 
				SportType,
				BetType 
		) AS ubl 
			ON abl.SportType = ubl.SportType 
			AND abl.BetType = ubl.BetType	
	WHERE abl.AgentId = @AgentId

END


