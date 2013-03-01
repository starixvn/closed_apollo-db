USE [DB05]
GO
/****** Object:  StoredProcedure [dbo].[Age_TotalBets_25_121_122]    Script Date: 3/1/2013 6:25:44 PM ******/
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
AS
BEGIN
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

	sum(CASE WHEN ba.BetType = 25 AND BetTeam = 'h' THEN  (ba.APositionTaking) * ba.Stake   ELSE 0 END) AS home_odds_DNB,
	sum(CASE WHEN ba.BetType = 25 AND BetTeam = 'a' THEN  (ba.APositionTaking) * ba.Stake   ELSE 0 END) AS away_odds_DNB,

	sum(CASE WHEN ba.BetType = 121 AND BetTeam = 'x' THEN  (ba.APositionTaking) * ba.Stake   ELSE 0 END) AS home_odds_HNB,
	sum(CASE WHEN ba.BetType = 121 AND BetTeam = 'a' THEN  (ba.APositionTaking) * ba.Stake   ELSE 0 END) AS away_odds_HNB,
	
	sum(CASE WHEN ba.BetType = 122 AND BetTeam = 'h' THEN  (ba.APositionTaking) * ba.Stake   ELSE 0 END) AS home_odds_ANB,
	sum(CASE WHEN ba.BetType = 122 AND BetTeam = 'x' THEN  (ba.APositionTaking) * ba.Stake   ELSE 0 END) AS away_odds_ANB,

	sum(CASE WHEN ba.BetType = 25 THEN 1 ELSE 0 END) AS BetCount_DNB,
	sum(CASE WHEN ba.BetType = 121 THEN 1 ELSE 0 END) AS BetCount_HNB,
	sum(CASE WHEN ba.BetType = 122 THEN 1 ELSE 0 END) AS BetCount_ANB,
	
	isnull(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral
FROM
	BetTrans_Agent AS ba  WITH (NOLOCK) INNER JOIN 
	BetTrans b WITH (NOLOCK) ON ba.TransId = b.TransId INNER JOIN
	Match m WITH (NOLOCK) ON b.MatchId = m.MatchId AND m.EventStatus = 'running'	
WHERE  	
	ba.AgentId = @AgentId 
	AND m.EventStatus='running'
	AND b.BetType in (25,121,122)
	AND b.statusID in (0,1)
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
