USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_TotalBets_20_21]    Script Date: 4/26/2013 11:19:37 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_TotalBets_20_21]
	@AgentId	INT,
	@LoggedID INT = 0
AS

/**
 * Created by	: Terry.Nguyen
 * Date			: 20130228
 * Task			: Get Total Bets(Money Line Bettype) data for Agent
 * DB			: SVRAGE.RepDB
 * Revisions	:
	- 20132801@Terry.Nguyen	: Implement
	- 20130509@Sophia: revise code, order by LeagueId
	- 20130514@Sophia: Add super view
 * Parameters:
 *	•
 *	•
 *  
 */

SET NOCOUNT ON

SELECT 
	m.ShowTime, 
	m.LeagueId,
	m.MatchCode,
	bt.LiveIndicator,
	m.MatchId,
	m.HomeId,
	m.AwayId,
	bt.LiveHomeScore,
	bt.LiveAwayScore,
	
	SUM((CASE WHEN bt.BetType = 20 THEN (CASE WHEN bt.BetTeam = 'h' THEN bt.PositionTaking * bt.Stake ELSE 0 END) * (CASE WHEN ABS(bt.Odds) < 1 THEN 1 ELSE ABS(bt.Odds) END) ELSE 0 END)) AS HomeOdds,
	SUM((CASE WHEN bt.BetType = 20 THEN (CASE WHEN bt.BetTeam = 'a' THEN bt.PositionTaking * bt.Stake ELSE 0 END) * (CASE WHEN ABS(bt.Odds) < 1 THEN 1 ELSE ABS(bt.Odds) END) ELSE 0 END)) AS AwayOdds,
	
	SUM(CASE WHEN bt.BetType = 20 THEN (CASE WHEN bt.BetTeam = 'h' THEN bt.Stake * (CASE WHEN bt.Odds < 0 THEN 1 ELSE bt.Odds END) * bt.PositionTaking ELSE - bt.Actual_Stake * bt.PositionTaking END) ELSE 0 END ) AS HomeWinLost,
	SUM(CASE WHEN bt.BetType = 20 THEN (CASE WHEN bt.BetTeam = 'a' THEN bt.Stake * (CASE WHEN bt.Odds < 0 THEN 1 ELSE bt.Odds END) * bt.PositionTaking ELSE - bt.Actual_Stake * bt.PositionTaking END) ELSE 0 END) AS AwayWinLost,
	
	SUM((CASE WHEN bt.BetType = 21 THEN (CASE WHEN bt.BetTeam = 'h' THEN bt.PositionTaking * bt.Stake ELSE 0 END) * (CASE WHEN ABS(bt.Odds) < 1 THEN 1 ELSE ABS(bt.Odds) END) ELSE 0 END)) AS HomeOddsHT,
	SUM((CASE WHEN bt.BetType = 21 THEN (CASE WHEN bt.BetTeam = 'a' THEN bt.PositionTaking * bt.Stake ELSE 0 END) * (CASE WHEN ABS(bt.Odds) < 1 THEN 1 ELSE ABS(bt.Odds) END) ELSE 0 END)) AS AwayOddsHT,
	
	SUM(CASE WHEN bt.BetType = 21 THEN (CASE WHEN bt.BetTeam = 'h' THEN bt.Stake * (CASE WHEN bt.Odds < 0 THEN 1 ELSE bt.Odds END)* bt.PositionTaking ELSE - bt.Actual_Stake * bt.PositionTaking END) ELSE 0 END) AS HomeWinLostHT,
	SUM(CASE WHEN bt.BetType = 21 THEN (CASE WHEN bt.BetTeam = 'a' THEN bt.Stake * (CASE WHEN bt.Odds < 0 THEN 1 ELSE bt.Odds END)* bt.PositionTaking ELSE - bt.Actual_Stake * bt.PositionTaking END) ELSE 0 END) AS AwayWinLostHT,

	SUM(CASE WHEN bt.BetType = 20 AND bt.BetTeam = 'h' THEN BetCount ELSE 0 END) AS HomeBetCount,
	SUM(CASE WHEN bettype = 20 AND bt.BetTeam = 'a'  THEN BetCount ELSE 0 END) AS AwayBetCount,
	SUM(CASE WHEN bt.BetType = 21 AND bt.BetTeam = 'h' THEN BetCount ELSE 0 END) AS HomeBetCountHT,
	SUM(CASE WHEN bettype = 21 AND bt.BetTeam = 'a'  THEN BetCount ELSE 0 END) AS AwayBetCountHT,

	ISNULL(m.isNeutral, CONVERT(BIT, 0)) AS IsNeutral
FROM
	(
		SELECT 
			b.LiveIndicator,
			b.LiveHomeScore,
			b.LiveAwayScore,
			b.MatchId,
			b.BetType,
			b.BetTeam,
			b.Stake,
			b.Actual_Stake,
			b.Odds,
			(CASE WHEN @LoggedID = 0 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END) AS PositionTaking,
			COUNT(*) AS BetCount 
		FROM 
			BetTrans_Agent AS ba WITH (NOLOCK)
			INNER JOIN BetTrans AS b WITH (NOLOCK) ON ba.TransId = b.TransId
		WHERE	ba.AgentId = @AgentId
			AND ba.BetType IN (20, 21) 
			AND ba.StatusId IN (0, 1)
			AND b.Ruben = 0
		GROUP BY 
			b.LiveIndicator,
			b.LiveHomeScore,
			b.LiveAwayScore,
			b.MatchId,
			b.BetType,
			b.BetTeam,
			b.Stake,
			b.Actual_Stake,
			b.Odds,
			ba.APositionTaking,
			b.TPositionTaking
	) AS bt
	INNER JOIN match AS m WITH (NOLOCK) ON m.matchid = bt.MatchId
WHERE m.eventstatus = 'running'
GROUP BY
	m.ShowTime, 
	m.LeagueId,
	m.MatchCode,
	bt.LiveIndicator,
	m.MatchId,
	m.HomeId,
	m.AwayId,
	bt.LiveHomeScore,
	bt.LiveAwayScore,
	m.isNeutral
ORDER BY
	m.LeagueId,
	m.MatchCode, 
	bt.LiveIndicator DESC

