USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_TotalBets_25_121_122]    Script Date: 4/2/2013 8:59:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[Age_TotalBets_25_121_122]
	@AgentId	INT
AS

/**
 * Created by	: Terry.Nguyen
 * Date			: 20130228
 * TASk			: Get Total Bets(Home/Draw/Away/No Bet) data for Agent
 * DB			: APL.TransDB
 * Revisions	:
 *	• 20132801@Terry.Nguyen	: Implement
 * Parameters:
 *	•
 *	•
 *  
 */
 
BEGIN

	SET NOCOUNT ON

	SELECT 
		m.ShowTime, 
		m.LeagueId,
		m.MatchCode, 
		b.LiveIndicator, 
		b.LiveHomeScore,
		b.LiveAwayScore,
		m.MatchId,
		m.HomeId,
		m.AwayId,

		SUM(CASE WHEN ba.BetType = 25 AND BetTeam = 'h' THEN ba.APositionTaking * ba.Stake ELSE 0 END) AS home_odds_DNB,
		SUM(CASE WHEN ba.BetType = 25 AND BetTeam = 'a' THEN ba.APositionTaking * ba.Stake ELSE 0 END) AS away_odds_DNB,

		SUM(CASE WHEN ba.BetType = 121 AND BetTeam = 'x' THEN ba.APositionTaking * ba.Stake ELSE 0 END) AS home_odds_HNB,
		SUM(CASE WHEN ba.BetType = 121 AND BetTeam = 'a' THEN ba.APositionTaking * ba.Stake ELSE 0 END) AS away_odds_HNB,
	
		SUM(CASE WHEN ba.BetType = 122 AND BetTeam = 'h' THEN ba.APositionTaking * ba.Stake ELSE 0 END) AS home_odds_ANB,
		SUM(CASE WHEN ba.BetType = 122 AND BetTeam = 'x' THEN ba.APositionTaking * ba.Stake ELSE 0 END) AS away_odds_ANB,

		SUM(CASE WHEN ba.BetType = 25 THEN 1 ELSE 0 END) AS BetCount_DNB,
		SUM(CASE WHEN ba.BetType = 121 THEN 1 ELSE 0 END) AS BetCount_HNB,
		SUM(CASE WHEN ba.BetType = 122 THEN 1 ELSE 0 END) AS BetCount_ANB,
	
		ISNULL(m.isNeutral, CONVERT(BIT, 0)) AS IsNeutral
	FROM
		BetTrans_Agent AS ba WITH (NOLOCK)  
		INNER JOIN BetTrans AS b WITH (NOLOCK) ON ba.TransId = b.TransId 
		INNER JOIN Match AS m WITH (NOLOCK) ON b.MatchId = m.MatchId
	WHERE  	
		ba.AgentId = @AgentId 
		AND m.EventStatus = 'running'
		AND b.BetType IN (25, 121, 122)
		AND b.statusID IN (0,1)
		AND b.Ruben = 0
	GROUP BY 
		b.LiveIndicator, 
		b.LiveHomeScore,
		b.LiveAwayScore,
		m.HomeId,
		m.AwayId,
		m.MatchId,
		m.MatchCode, 
		m.LeagueId,
		m.showtime,
		m.isNeutral
	ORDER BY
		b.LiveIndicator DESC, 
		m.matchcode

END

