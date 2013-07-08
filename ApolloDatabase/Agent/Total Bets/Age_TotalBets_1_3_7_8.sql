USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_TotalBets_1_3_7_8]    Script Date: 4/26/2013 11:14:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_TotalBets_1_3_7_8]
	@AgentId INT,
	@LoggedId INT = 0
AS

/**
 * Created by	: Quinn
 * Date			: 20130228
 * Task			: Retrieve Total Bet values for bettype 1,3,7,8
 * DB			: SVRAGE.RepDB
 * Revisions	:
 - 20130509@Sophia: Revise code
 - 20130513@Sophia: Add super view
 - 20130708@Sophia: Change SuperId from 0 to 1 (@AgentID = 1)
 * Parameters :
 *	@AgentId : agent ID
 *  
 */

SET NOCOUNT ON

SELECT
	m.ShowTime, 
	m.kickofftime,
	m.LeagueId,
	m.MatchCode,
	b.LiveIndicator,
	m.MatchId,
	m.HomeId,
	m.AwayId,
	b.LiveHomeScore,
	b.LiveAwayScore,
	
	SUM(CASE WHEN bettype = 1 AND betteam = 'h' THEN Stake ELSE 0 END) AS HomeOddsHDP,
	SUM(CASE WHEN bettype = 1 AND betteam = 'a' THEN Stake ELSE 0 END) AS AwayOddsHDP,
	SUM(CASE WHEN bettype = 7 AND betteam = 'h' THEN Stake ELSE 0 END) AS HomeOddsHTHDP,
	SUM(CASE WHEN bettype = 7 AND betteam = 'a' THEN Stake ELSE 0 END) AS AwayOddsHTHDP,
	SUM(CASE WHEN bettype = 3 AND betteam = 'h' THEN Stake ELSE 0 END) AS HomeOddsOU,
	SUM(CASE WHEN bettype = 3 AND betteam = 'a' THEN Stake ELSE 0 END) AS AwayOddsOU,
	SUM(CASE WHEN bettype = 8 AND betteam = 'h' THEN Stake ELSE 0 END) AS HomeOddsHTOU,
	SUM(CASE WHEN bettype = 8 AND betteam = 'a' THEN Stake ELSE 0 END) AS AwayOddsHTOU,

	SUM(CASE WHEN bettype = 1 THEN BetCount ELSE 0 END) AS BetCountHDP,
	SUM(CASE WHEN bettype = 7 THEN BetCount ELSE 0 END) AS BetCountHTHDP,
	SUM(CASE WHEN bettype = 3 THEN BetCount ELSE 0 END) AS BetCountOU,
	SUM(CASE WHEN bettype = 8 THEN BetCount ELSE 0 END) AS BetCountHTOU,

	ISNULL(m.IsNeutral, CONVERT(BIT, 0)) AS IsNeutral
FROM
	(SELECT
		bt.MatchId, 
		bt.BetType, 
		bt.BetTeam,
		bt.LiveIndicator, 
		bt.LiveHomeScore, 
		bt.LiveAwayScore,
		SUM( CASE WHEN @LoggedId = 1 THEN (1-bt.TPositionTaking) ELSE bta.APositionTaking END * bta.Stake * CASE WHEN ABS(bt.Odds) < 1 THEN 1 ELSE ABS(bt.Odds) END) AS Stake,
		COUNT(*) AS BetCount
	FROM 
		BetTrans_Agent AS bta WITH (NOLOCK)
		INNER JOIN BetTrans AS bt WITH (NOLOCK) ON bta.TransId = bt.TransId
	WHERE bta.AgentId = @AgentId
		AND bta.StatusId IN (0, 1) -- status is waiting or running
		AND bta.BetType IN (1, 3, 7, 8)		
	GROUP BY 
		bt.MatchId, 
		bt.BetType, 
		bt.BetTeam, 
		bt.LiveIndicator, 
		bt.LiveHomeScore, 
		bt.LiveAwayScore
	) AS b
	INNER JOIN Match AS m WITH (NOLOCK) ON m.MatchId = b.MatchId
WHERE m.EventStatus = 'running'
GROUP BY
	m.ShowTime, 
	m.kickofftime,
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
	m.LeagueId,
	b.LiveIndicator DESC, 
	m.MatchCode

GO
GRANT EXECUTE ON [Age_TotalBets_1_3_7_8] TO [aplweb]
GO