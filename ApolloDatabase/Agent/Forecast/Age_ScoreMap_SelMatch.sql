USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_ScoreMap_SelMatch]    Script Date: 4/2/2013 8:39:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_ScoreMap_SelMatch]
	@AgentId	INT,
	@LeagueId	INT
AS

/**
 * Created by	: Terry.Nguyen
 * Date			: 20130203
 * Task			: Get Match for ScoreMap
 * DB			: APL.TransDB
 * Revisions	:
 *	• 20130203@Terry.Nguyen	: Implement
 * Parameters:
 *	•
 *	•
 *  
 */
 
BEGIN

	SET NOCOUNT ON

	SELECT 
		MatchId, 
		HomeId, 
		AwayId
	FROM Match WITH (NOLOCK)
	WHERE 
		LeagueId = @LeagueId
		AND EventStatus <> 'completed'
		AND MatchId IN (	SELECT DISTINCT MatchId
							FROM BetTrans_Agent WITH (NOLOCK)
							WHERE 
								AgentId = @AgentId
								AND StatusId IN (0,1)
								AND Ruben = 0 
								AND BetType IN (1, 2, 3, 4, 5, 6, 7, 8, 12, 13, 15, 20, 21, 24, 25, 26, 27, 28, 30, 121, 122, 123) )
END

