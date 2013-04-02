USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_TotalBets_2_5_12_15_123]    Script Date: 4/2/2013 8:54:24 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_TotalBets_2_5_12_15_123]
	@AgentId INT
AS

/**
 * Created by	: Quinn
 * Date			: 20130228
 * Task			: Retrieve Total Bet values for bettype 2, 5, 12, 15, 123
 * DB			: APL.DB05
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
	bt.LiveIndicator,
	bt.LiveHomeScore,
	bt.LiveAwayScore,
	m.MatchId,
	m.HomeId,
	m.AwayId,

	SUM((CASE WHEN bt.BetType = 2 AND betteam = 'h' THEN bta.APositionTaking * bta.Stake ELSE 0 END) * (CASE WHEN ABS(bt.Odds) < 1 THEN 1 ELSE ABS(bt.Odds) END)) AS home_odds_OE,
	SUM((CASE WHEN bt.BetType = 2 AND betteam = 'a' THEN bta.APositionTaking * bta.Stake ELSE 0 END) * (CASE WHEN ABS(bt.Odds) < 1 THEN 1 ELSE ABS(bt.Odds) END)) AS away_odds_OE,
	
	SUM((CASE WHEN bt.BetType = 12 AND betteam = 'h' THEN bta.APositionTaking * bta.Stake ELSE 0 END) * (CASE WHEN ABS(bt.Odds) < 1 THEN 1 ELSE ABS(bt.Odds) END)) AS home_odds_OE_1st,
	SUM((CASE WHEN bt.BetType = 12 AND betteam = 'a' THEN bta.APositionTaking * bta.Stake ELSE 0 END) * (CASE WHEN ABS(bt.Odds) < 1 THEN 1 ELSE ABS(bt.Odds) END)) AS away_odds_OE_1st,
	
	SUM(CASE WHEN bt.BetType = 5 AND betteam = '1' THEN bta.APositionTaking * bta.Stake ELSE 0 END) AS odds_1,
	SUM(CASE WHEN bt.BetType = 5 AND betteam = 'x' THEN bta.APositionTaking * bta.Stake ELSE 0 END) AS odds_x,
	SUM(CASE WHEN bt.BetType = 5 AND betteam = '2' THEN bta.APositionTaking * bta.Stake ELSE 0 END) AS odds_2,

	SUM(CASE WHEN bt.BetType = 15 AND betteam = '1' THEN bta.APositionTaking * bta.Stake ELSE 0 END) AS odds_1_1st,
	SUM(CASE WHEN bt.BetType = 15 AND betteam = 'x' THEN bta.APositionTaking * bta.Stake ELSE 0 END) AS odds_x_1st,
	SUM(CASE WHEN bt.BetType = 15 AND betteam = '2' THEN bta.APositionTaking * bta.Stake ELSE 0 END) AS odds_2_1st,
	
	SUM(CASE WHEN bt.BetType = 123 AND betteam = 'h' THEN bta.APositionTaking * bta.Stake ELSE 0 END) AS home_odds_DND,
	SUM(CASE WHEN bt.BetType = 123 AND betteam = 'a' THEN bta.APositionTaking * bta.Stake ELSE 0 END) AS away_odds_DND,

	SUM(CASE WHEN bt.BetType = 2 THEN 1 ELSE 0 END) AS BetCount_OE,
	SUM(CASE WHEN bt.BetType = 12 THEN 1 ELSE 0 END) AS BetCount_OE_1st,
	SUM(CASE WHEN bt.BetType = 5 THEN 1 ELSE 0 END) AS BetCount_1x2,
	SUM(CASE WHEN bt.BetType = 15 THEN 1 ELSE 0 END) AS BetCount_1x2_1st,
	SUM(CASE WHEN bt.BetType = 123 THEN 1 ELSE 0 END) AS BetCount_DND,

	ISNULL(m.IsNeutral, CONVERT(BIT, 0)) AS IsNeutral
FROM
	BetTrans_Agent AS bta WITH (NOLOCK)
	INNER JOIN BetTrans AS bt WITH (NOLOCK) ON bta.TransId = bt.TransId
	INNER JOIN Match AS m  WITH (NOLOCK) ON m.MatchId = bt.MatchId
WHERE
	bta.AgentId = @AgentId 
	AND m.EventStatus = 'running'
	AND bt.BetType IN (2, 12, 5, 15, 123)
	AND bt.StatusId IN (0, 1) -- status is waiting or running
	AND bt.Ruben = 0	-- match not yet settle
GROUP BY
	bt.LiveIndicator, 
	bt.LiveHomeScore,
	bt.LiveAwayScore,
	m.HomeId,
	m.AwayId,
	m.MatchId,
	m.MatchCode, 
	m.LeagueId,
	m.ShowTime,
	m.IsNeutral
ORDER BY
	bt.LiveIndicator DESC, 
	m.MatchCode
