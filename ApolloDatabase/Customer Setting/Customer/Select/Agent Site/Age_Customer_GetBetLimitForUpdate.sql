ALTER PROCEDURE [dbo].[Age_Customer_GetBetLimitForUpdate]
	@CustId		INT,		
	@MaxBetLimit MONEY = 0 OUTPUT
AS

/**
 * Created by	: Kos
 * Date			: 20130302
 * Task			: Get customer and its parent bet limit
 * DB			: SVRAGE.RepDB
 * Revisions	: 
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
	SELECT @agentHId = ai.AgentHId,
		@CurrencyId=ci.Currency
	FROM 
		CustInfo AS ci WITH (NOLOCK)
		INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON ci.AgentId = ai.AgentId
	WHERE ci.CustId = @CustId
	
	SELECT @MaxBetLimit = MinMaxBet
	FROM   Exchange WITH (NOLOCK)
	WHERE  ExchangeId = @CurrencyId

	SELECT 
		cbl.SportType,
		cbl.BetType,
		cbl.MinBet,
		cbl.MaxBet,
		cbl.MaxPerMatch,
		ubl.MaxMinBet,
		ubl.MinMaxBet,
		ubl.MinMaxPerMatch
	FROM 
		CustBetLimit AS cbl WITH (NOLOCK)
		INNER JOIN 
			(
				SELECT 
					SportType,
					BetType,
					MAX(MinBet)		AS MaxMinBet,
					MIN(MaxBet)		AS MinMaxBet,
					MIN(MaxPerMatch)AS MinMaxPerMatch
				FROM AgentBetLimit WITH (NOLOCK)
				WHERE AgentId IN (	SELECT AgentId 
									FROM AgentInfo WITH (NOLOCK)
									WHERE @AgentHId.IsDescendantOf(AgentHId) = 1
									AND AgentLevel	<> @SUPERLEVEL)
				GROUP BY 
					SportType, 
					BetType
			) AS ubl	-- upline bet limit including its parent
				ON cbl.SportType = ubl.SportType 
				AND cbl.BetType = ubl.BetType	
	WHERE cbl.CustId = @CustId

END	

