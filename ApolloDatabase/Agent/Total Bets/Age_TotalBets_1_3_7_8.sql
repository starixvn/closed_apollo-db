USE [TransDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_TotalBets_1_3_7_8]    Script Date: 2/28/2013 5:30:55 PM ******/
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
 * DB			: APL.TransDB
 * Revisions	:
 *	•
 * Parameters:
 *	@custid: agent ID
 *	@Language: Language
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
	SUM(CASE WHEN bettype=1 AND betteam = 'h' THEN Stake ELSE 0 END) AS home_odds_HDP,
	SUM(CASE WHEN bettype=1 AND betteam = 'a' THEN Stake ELSE 0 END) AS away_odds_HDP,
	SUM(CASE WHEN bettype=7 AND betteam = 'h' THEN Stake ELSE 0 END) AS home_odds_HTHDP,
	SUM(CASE WHEN bettype=7 AND betteam = 'a' THEN Stake ELSE 0 END) AS away_odds_HTHDP,
	SUM(CASE WHEN bettype=3 AND betteam = 'h' THEN Stake ELSE 0 END) AS home_odds_OU,
	SUM(CASE WHEN bettype=3 AND betteam = 'a' THEN Stake ELSE 0 END) AS away_odds_OU,
	SUM(CASE WHEN bettype=8 AND betteam = 'h' THEN Stake ELSE 0 END) AS home_odds_HTOU,
	SUM(CASE WHEN bettype=8 AND betteam = 'a' THEN Stake ELSE 0 END) AS away_odds_HTOU,
	SUM(CASE WHEN bettype=1 THEN BetCount ELSE 0 END) AS BetCount_HDP,
	SUM(CASE WHEN bettype=7 THEN BetCount ELSE 0 END) AS BetCount_HTHDP,
	SUM(CASE WHEN bettype=3 THEN BetCount ELSE 0 END) AS BetCount_OU,
	SUM(CASE WHEN bettype=8 THEN BetCount ELSE 0 END) AS BetCount_HTOU,
	ISNULL(m.IsNeutral, CONVERT(BIT,0)) AS IsNeutral
FROM
	(SELECT
		bt.MatchId, bt.BetType, bt.BetTeam,
		bt.LiveIndicator, bt.LiveHomeScore, bt.LiveAwayScore,
		SUM(bta.APositionTaking * bta.Stake * CASE WHEN ABS(bt.Odds) <1 THEN 1 ELSE ABS(bt.Odds) END) Stake,
		COUNT(*) BetCount
	FROM BetTrans_Agent AS bta WITH (NOLOCK)
	INNER JOIN BetTrans AS bt WITH (NOLOCK) ON bta.TransId = bt.TransId
	WHERE
			bta.BetType IN (1,3,7,8)
			AND bta.AgentId = @AgentId
			AND bta.StatusId in (0,1)
			AND bt.Ruben = 0
	GROUP BY bt.MatchId, bt.BetType, bt.BetTeam, bt.LiveIndicator, bt.LiveHomeScore, bt.LiveAwayScore) AS b
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
	b.LiveIndicator DESC, m.MatchCode

