USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_ScoreMap_SelMatch]    Script Date: 5/2/2013 1:00:23 PM ******/
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
 * DB			: SVRAGE.RepDB
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
		m.MatchId, 
		HomeId, 
		AwayId
	FROM Match m WITH (NOLOCK)
	LEFT JOIN Match_remark_ex e WITH (NOLOCK) ON e.MatchId = m.MatchId
	WHERE 
		LeagueId = @LeagueId
		AND e.EventStatus <> 'completed'
		AND m.MatchId IN (	SELECT DISTINCT MatchId
							FROM BetTrans_Agent WITH (NOLOCK)
							WHERE 
								AgentId = @AgentId
								AND StatusId IN (0,1)
								AND e.Ruben = 0 
								AND BetType IN (1, 2, 3, 4, 5, 6, 7, 8, 12, 13, 15, 20, 21, 24, 25, 26, 27, 28, 30, 121, 122, 123) )
END
