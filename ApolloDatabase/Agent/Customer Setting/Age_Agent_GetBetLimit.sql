USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetBetLimit]    Script Date: 3/29/2013 9:55:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[Age_Agent_GetBetLimit]
	@AgentId	INT	
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Get agent bet limit and bet limit 3rd
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

	SELECT 
		SportType,
		BetType,
		MinBet,
		MaxBet,
		MaxPerMatch,
		0 AS MaxPerBall	 
	FROM AgentBetLimit AS abt WITH (NOLOCK)
	WHERE AgentId = @AgentId
		
	UNION

	SELECT 
		SportType,
		BetType,
		MinBet,
		MaxBet,
		MaxPerMatch,
		MaxPerBall	 
	FROM AgentBetLimit3rd AS abt WITH (NOLOCK)
	WHERE AgentId = @AgentId
	
END
