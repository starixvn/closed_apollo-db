USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_TotalBets_1_3_7_8]    Script Date: 4/2/2013 8:44:23 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_TotalBets_1_3_7_8]
	@AgentId INT
AS

/**
 * Created by	: Quinn
 * Date			: 20130228
 * Task			: Retrieve Total Bet values for bettype 1,3,7,8
 * DB			: APL.REPDB
 * Revisions	:
 *	•
 * Parameters:
 *	@AgentId: agent ID
 *  
 */

SET NOCOUNT ON

SELECT
	m.ShowTime, 
	m.LeagueId,
	m.MatchCode,
	b.LiveIndicator,
	m.MatchId,
	m.HomeId,
	m.AwayId,
	b.LiveHomeScore,
	b.LiveAwayScore,
	SUM(CASE WHEN bettype = 1 AND betteam = 'h' THEN Stake ELSE 0 END) AS home_odds_HDP,
	SUM(CASE WHEN bettype = 1 AND betteam = 'a' THEN Stake ELSE 0 END) AS away_odds_HDP,
	SUM(CASE WHEN bettype = 7 AND betteam = 'h' THEN Stake ELSE 0 END) AS home_odds_HTHDP,
	SUM(CASE WHEN bettype = 7 AND betteam = 'a' THEN Stake ELSE 0 END) AS away_odds_HTHDP,
	SUM(CASE WHEN bettype = 3 AND betteam = 'h' THEN Stake ELSE 0 END) AS home_odds_OU,
	SUM(CASE WHEN bettype = 3 AND betteam = 'a' THEN Stake ELSE 0 END) AS away_odds_OU,
	SUM(CASE WHEN bettype = 8 AND betteam = 'h' THEN Stake ELSE 0 END) AS home_odds_HTOU,
	SUM(CASE WHEN bettype = 8 AND betteam = 'a' THEN Stake ELSE 0 END) AS away_odds_HTOU,
	SUM(CASE WHEN bettype = 1 THEN BetCount ELSE 0 END) AS BetCount_HDP,
	SUM(CASE WHEN bettype = 7 THEN BetCount ELSE 0 END) AS BetCount_HTHDP,
	SUM(CASE WHEN bettype = 3 THEN BetCount ELSE 0 END) AS BetCount_OU,
	SUM(CASE WHEN bettype = 8 THEN BetCount ELSE 0 END) AS BetCount_HTOU,
	ISNULL(m.IsNeutral, CONVERT(BIT, 0)) AS IsNeutral
FROM
	(SELECT
		bt.MatchId, 
		bt.BetType, 
		bt.BetTeam,
		bt.LiveIndicator, 
		bt.LiveHomeScore, 
		bt.LiveAwayScore,
		SUM(bta.APositionTaking * bta.Stake * CASE WHEN ABS(bt.Odds) < 1 THEN 1 ELSE ABS(bt.Odds) END) AS Stake,
		COUNT(*) AS BetCount
	FROM 
		BetTrans_Agent AS bta WITH (NOLOCK)
		INNER JOIN BetTrans AS bt WITH (NOLOCK) ON bta.TransId = bt.TransId
	WHERE
		bt.BetType IN (1, 3, 7, 8)
		AND bta.AgentId = @AgentId
		AND bt.StatusId IN (0,1) -- status is waiting or running
		AND bt.Ruben = 0	-- match not yet settle
	GROUP BY 
		bt.MatchId, 
		bt.BetType, 
		bt.BetTeam, 
		bt.LiveIndicator, 
		bt.LiveHomeScore, 
		bt.LiveAwayScore
	) AS b
	INNER JOIN Match AS m WITH (NOLOCK) ON m.MatchId = b.MatchId 	
WHERE	
	m.EventStatus = 'running'
GROUP BY
	m.ShowTime, 
	m.LeagueId,
	m.MatchCode,
	b.LiveIndicator,
	m.MatchId,
	m.HomeId,
	m.AwayId,
	b.LiveHomeScore,
	b.LiveAwayScore,
	m.IsNeutral
ORDER BY	
	b.LiveIndicator DESC, 
	m.MatchCode


