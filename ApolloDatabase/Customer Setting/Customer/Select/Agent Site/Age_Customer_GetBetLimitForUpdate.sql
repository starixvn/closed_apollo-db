ALTER PROCEDURE [dbo].[Age_Customer_GetBetLimitForUpdate]
	@CustId		INT,		
	@MaxBetLimit MONEY = 0 OUTPUT
AS

/**
 * Created by	: Kos
 * Date			: 20130302
 * Task			: Get customer and its parent bet limit
 * DB			: SVRCUST.CustDB
 * Revisions	: 
 	•	20131111@Sophia: Get @MaxBetLimit
	•	20131120@Dan: optimize performance
 * Parameters:
 	•
 	•
   
 */

BEGIN

	SET NOCOUNT ON
	DECLARE @CurrencyId	tinyint 

	DECLARE 
		@agentId	Int,
		@SUPERLEVEL	INT

	SET @SUPERLEVEL = 0

	-- Get agent hierarchy ID
	SELECT @agentId = AgentId,
		@CurrencyId=ci.Currency
	FROM 
		CustInfo AS ci WITH (NOLOCK)		
	WHERE ci.CustId = @CustId
	
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
		FROM AgentInfo ai  WITH (NOLOCK) INNER JOIN Agent_CTE ac 
			ON ac.Parentid = ai.AgentId		
	)
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
									FROM Agent_CTE
									WHERE AgentLevel	<> @SUPERLEVEL)
				GROUP BY 
					SportType, 
					BetType
			) AS ubl	-- upline bet limit including its parent
				ON cbl.SportType = ubl.SportType 
				AND cbl.BetType = ubl.BetType	
	WHERE cbl.CustId = @CustId

END	

