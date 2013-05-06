USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetBetLimitForUpdate]    Script Date: 5/3/2013 4:46:30 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Age_Customer_GetBetLimitForUpdate]
	@CustId		INT	
AS

/**
 * Created by	: Kos
 * Date			: 20130302
 * Task			: Get customer and its parent bet limit
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

	DECLARE 
		@agentHId	HIERARCHYID,
		@SUPERLEVEL	INT

	SET @SUPERLEVEL = 0

	-- Get agent hierarchy ID
	SELECT @agentHId = ai.AgentHId
	FROM 
		CustInfo AS ci WITH (NOLOCK)
		INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON ci.AgentId = ai.AgentId
	WHERE ci.CustId = @CustId

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