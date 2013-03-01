USE [DB05]
GO
/****** Object:  StoredProcedure [dbo].[Age_ScoreMap_SelLeague]    Script Date: 3/1/2013 6:26:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_ScoreMap_SelLeague]
	@AgentId		INT
/**
 * Created by	: Terry.Nguyen
 * Date			: 20130228
 * Task			: Get League for ScoreMap
 * DB			: APL.TransDB
 * Revisions	:
 *	• 20132801@Terry.Nguyen	: Implement
 * Parameters:
 *	•
 *	•
 *  
 */
AS
BEGIN
	SELECT 
		m.LeagueId, 
		m.SportType
	FROM 
		match m WITH(NOLOCK) INNER JOIN 
		BetTrans_Agent ba WITH(NOLOCK) ON m.MatchId = ba.MatchId	

	WHERE 
		m.eventstatus = 'running' AND
		m.matchid IN (SELECT DISTINCT matchid 
								FROM bettrans WITH(NOLOCK)
								WHERE ba.AgentId = @AgentId 
									AND StatusId IN (0,1)
									AND Ruben = 0
									AND BetType IN (1,2,3,4,5,6,7,8,12,13,15,20,21,24,25,26,27,28,30,121,122,123))
	GROUP BY 
	m.SportType, m.LeagueId 
END
