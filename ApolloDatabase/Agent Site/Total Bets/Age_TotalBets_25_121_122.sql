USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_TotalBets_25_121_122]    Script Date: 4/26/2013 11:19:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_TotalBets_25_121_122]
	@AgentId	INT,
	@LoggedID INT = 0
AS

/**
 * Created by	: Terry.Nguyen
 * Date			: 20130228
 * TASk			: Get Total Bets(Home/Draw/Away/No Bet) data for Agent
 * DB			: SVRAGE.RepDB
 * Revisions	:
  - 20132801@Terry.Nguyen	: Implement
  - 20130509@Sophia: revise code, order by LeagueId
  - 20130514@Sophia: Add super view
  - 20130708@Sophia: Change SuperId from 0 to 1 (@AgentID = 1)
 * Parameters:
 *	•
 *	•
 *  
 */
SET NOCOUNT ON
IF @LoggedId = 1 
BEGIN 
	SELECT 
		m.ShowTime, 
		m.LeagueId,
		m.MatchCode, 
		m.kickofftime,
		b.LiveIndicator, 
		b.LiveHomeScore,
		b.LiveAwayScore,
		m.MatchId,
		m.HomeId,
		m.AwayId,

		SUM(CASE WHEN ba.BetType = 25 AND BetTeam = 'h' THEN (1-b.TPositionTaking) * ba.Stake ELSE 0 END) AS HomeOddsDNB,
		SUM(CASE WHEN ba.BetType = 25 AND BetTeam = 'a' THEN (1-b.TPositionTaking) * ba.Stake ELSE 0 END) AS AwayOddsDNB,

		SUM(CASE WHEN ba.BetType = 121 AND BetTeam = 'x' THEN (1-b.TPositionTaking) * ba.Stake ELSE 0 END) AS HomeOddsHNB,
		SUM(CASE WHEN ba.BetType = 121 AND BetTeam = 'a' THEN (1-b.TPositionTaking) * ba.Stake ELSE 0 END) AS AwayOddsHNB,
	
		SUM(CASE WHEN ba.BetType = 122 AND BetTeam = 'h' THEN (1-b.TPositionTaking) * ba.Stake ELSE 0 END) AS HomeOddsANB,
		SUM(CASE WHEN ba.BetType = 122 AND BetTeam = 'x' THEN (1-b.TPositionTaking) * ba.Stake ELSE 0 END) AS AwayOddsANB,

		SUM(CASE WHEN ba.BetType = 25 THEN 1 ELSE 0 END) AS BetCountDNB,
		SUM(CASE WHEN ba.BetType = 121 THEN 1 ELSE 0 END) AS BetCountHNB,
		SUM(CASE WHEN ba.BetType = 122 THEN 1 ELSE 0 END) AS BetCountANB,
	
		ISNULL(m.isNeutral, CONVERT(BIT, 0)) AS IsNeutral
	FROM
		BetTrans_Agent AS ba WITH (NOLOCK)  
		INNER JOIN BetTrans AS b WITH (NOLOCK) ON ba.TransId = b.TransId 
		INNER JOIN Match AS m WITH (NOLOCK) ON b.MatchId = m.MatchId
	WHERE  	
		ba.AgentId = @AgentId 
		AND m.EventStatus = 'running'
		AND ba.BetType IN (25, 121, 122)
		AND ba.statusID IN (0,1)
		AND b.Ruben = 0
	GROUP BY 
		b.LiveIndicator, 
		b.LiveHomeScore,
		b.LiveAwayScore,
		m.HomeId,
		m.AwayId,
		m.MatchId,
		m.MatchCode, 
		m.kickofftime,
		m.LeagueId,
		m.showtime,
		m.isNeutral
	ORDER BY
		m.LeagueId,
		b.LiveIndicator DESC, 
		m.matchcode
END
ELSE
BEGIN 
	SELECT 
		m.ShowTime, 
		m.LeagueId,
		m.MatchCode, 
		m.kickofftime,
		b.LiveIndicator, 
		b.LiveHomeScore,
		b.LiveAwayScore,
		m.MatchId,
		m.HomeId,
		m.AwayId,

		SUM(CASE WHEN ba.BetType = 25 AND BetTeam = 'h' THEN ba.APositionTaking * ba.Stake ELSE 0 END) AS HomeOddsDNB,
		SUM(CASE WHEN ba.BetType = 25 AND BetTeam = 'a' THEN ba.APositionTaking * ba.Stake ELSE 0 END) AS AwayOddsDNB,

		SUM(CASE WHEN ba.BetType = 121 AND BetTeam = 'x' THEN ba.APositionTaking * ba.Stake ELSE 0 END) AS HomeOddsHNB,
		SUM(CASE WHEN ba.BetType = 121 AND BetTeam = 'a' THEN ba.APositionTaking * ba.Stake ELSE 0 END) AS AwayOddsHNB,
	
		SUM(CASE WHEN ba.BetType = 122 AND BetTeam = 'h' THEN ba.APositionTaking * ba.Stake ELSE 0 END) AS HomeOddsANB,
		SUM(CASE WHEN ba.BetType = 122 AND BetTeam = 'x' THEN ba.APositionTaking * ba.Stake ELSE 0 END) AS AwayOddsANB,

		SUM(CASE WHEN ba.BetType = 25 THEN 1 ELSE 0 END) AS BetCountDNB,
		SUM(CASE WHEN ba.BetType = 121 THEN 1 ELSE 0 END) AS BetCountHNB,
		SUM(CASE WHEN ba.BetType = 122 THEN 1 ELSE 0 END) AS BetCountANB,
	
		ISNULL(m.isNeutral, CONVERT(BIT, 0)) AS IsNeutral
	FROM
		BetTrans_Agent AS ba WITH (NOLOCK)  
		INNER JOIN BetTrans AS b WITH (NOLOCK) ON ba.TransId = b.TransId 
		INNER JOIN Match AS m WITH (NOLOCK) ON b.MatchId = m.MatchId
	WHERE  	
		ba.AgentId = @AgentId 
		AND m.EventStatus = 'running'
		AND ba.BetType IN (25, 121, 122)
		AND ba.statusID IN (0,1)
		AND b.Ruben = 0
	GROUP BY 
		b.LiveIndicator, 
		b.LiveHomeScore,
		b.LiveAwayScore,
		m.HomeId,
		m.AwayId,
		m.MatchId,
		m.MatchCode, 
		m.kickofftime,
		m.LeagueId,
		m.showtime,
		m.isNeutral
	ORDER BY
		m.LeagueId,
		b.LiveIndicator DESC, 
		m.matchcode
END


