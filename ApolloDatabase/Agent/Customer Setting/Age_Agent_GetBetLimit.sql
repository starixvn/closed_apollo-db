USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetBetLimit]    Script Date: 5/3/2013 5:01:54 PM ******/
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
 * Task			: Get agent bet limit
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

	SELECT 
		SportType,
		BetType,
		MinBet,
		MaxBet,
		MaxPerMatch
	FROM AgentBetLimit WITH (NOLOCK)
	WHERE AgentId = @AgentId
	
END
