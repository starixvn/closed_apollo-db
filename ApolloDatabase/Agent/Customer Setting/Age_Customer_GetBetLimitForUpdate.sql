USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetBetLimitForUpdate]    Script Date: 3/29/2013 10:05:40 AM ******/
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
 * Task			: Get customer and its parent bet limit and bet limit 3rd
 * DB			: APL.CustDB
 * Revisions	:
 *	•	
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN

	SET NOCOUNT ON

	DECLARE @agentHId HIERARCHYID

	-- Get agent hierarchy ID
	SELECT @agentHId = AgentHId
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = ( 	SELECT pli.AgentId
						FROM CustInfo AS pli WITH (NOLOCK)
						WHERE pli.CustId = @CustId	)

	SELECT 
		pbl.SportType,
		pbl.BetType,
		pbl.MinBet,
		pbl.MaxBet,
		pbl.MaxPerMatch,
		0 AS MaxPerBall,
		ubl.MaxMinBet,
		ubl.MinMaxBet,
		ubl.MinMaxPerMatch,
		0 AS MinMaxPerBall
	FROM 
		CustBetLimit pbl WITH (NOLOCK)
		INNER JOIN 
		(
			SELECT 
				SportType,
				BetType,
				MAX(MinBet)	AS MaxMinBet,
				MIN(MaxBet)	AS MinMaxBet,
				MIN(MaxPerMatch) AS MinMaxPerMatch
			FROM AgentBetLimit WITH (NOLOCK)
			WHERE AgentId IN (	SELECT AgentId 
								FROM AgentInfo 
								WHERE @AgentHId.IsDescendantOf(AgentHId) = 1)
			GROUP BY SportType, BetType
		) AS ubl	-- upline bet limit including its parent
		ON pbl.SportType = ubl.SportType AND pbl.BetType = ubl.BetType	
	WHERE pbl.CustId = @CustId

	UNION
	
	SELECT 
		pbl.SportType,
		pbl.BetType,
		pbl.MinBet,
		pbl.MaxBet,
		pbl.MaxPerMatch,
		pbl.MaxPerBall,
		ubl.MaxMinBet,
		ubl.MinMaxBet,
		ubl.MinMaxPerMatch,
		ubl.MinMaxPerBall
	FROM 
		CustBetLimit3rd pbl WITH (NOLOCK)
		INNER JOIN 
		(
			SELECT 
				SportType,
				BetType,
				MAX(MinBet)	AS MaxMinBet,
				MIN(MaxBet)	AS MinMaxBet,
				MIN(MaxPerMatch) AS MinMaxPerMatch,
				MIN(MaxPerBall) AS MinMaxPerBall
			FROM AgentBetLimit3rd WITH (NOLOCK)
			WHERE AgentId IN (	SELECT AgentId 
								FROM AgentInfo 
								WHERE @AgentHId.IsDescendantOf(AgentHId) = 1)
			GROUP BY SportType, BetType
		) AS ubl	-- upline bet limit including its parent
		ON pbl.SportType = ubl.SportType AND pbl.BetType = ubl.BetType	
	WHERE pbl.CustId = @CustId
		
END

