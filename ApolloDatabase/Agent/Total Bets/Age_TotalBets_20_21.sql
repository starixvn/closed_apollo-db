USE [DB05]
GO
/****** Object:  StoredProcedure [dbo].[Age_TotalBets_20_21]    Script Date: 3/1/2013 6:24:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_TotalBets_20_21] 

	@AgentId		INT	

AS

/**
 * Created by	: Terry.Nguyen
 * Date			: 20130228
 * Task			: Get Total Bets(Money Line Bettype) data for Agent
 * DB			: APL.TransDB
 * Revisions	:
 *	• 20132801@Terry.Nguyen	: Implement
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
	b.LiveIndicator,
	m.MatchId,
	m.HomeId,
	m.AwayId,
	b.LiveHomeScore,
	b.LiveAwayScore,
	
	SUM((CASE WHEN ba.BetType = 20 THEN (CASE WHEN b.BetTeam = 'h' THEN (ba.APositionTaking) * ba.Stake ELSE 0 END) * (CASE WHEN ABS(b.Odds) <1 THEN 1 ELSE ABS(b.Odds) END) ELSE 0 END)) AS Home_Odds,
	SUM((CASE WHEN ba.BetType = 20 THEN (CASE WHEN b.BetTeam = 'a' THEN (ba.APositionTaking) * ba.Stake ELSE 0 END) * (CASE WHEN ABS(b.Odds) <1 THEN 1 ELSE ABS(b.Odds) END) ELSE 0 END)) AS Away_Odds,
	
	SUM(CASE WHEN ba.BetType = 20 THEN (CASE WHEN b.BetTeam = 'h' THEN ba.Stake * (CASE WHEN b.Odds < 0 THEN 1 ELSE b.Odds END) * ba.APositionTaking ELSE - ba.Actual_Stake * ba.APositionTaking END) ELSE 0 END ) AS WinLost_Home,
	SUM(CASE WHEN ba.BetType = 20 THEN (CASE WHEN b.BetTeam = 'a' THEN ba.Stake * (CASE WHEN b.Odds < 0 THEN 1 ELSE b.Odds END) * ba.APositionTaking ELSE - ba.Actual_Stake * ba.APositionTaking END) ELSE 0 END) AS WinLost_Away,
	
	SUM((CASE WHEN ba.BetType = 21 THEN (CASE WHEN b.BetTeam = 'h' THEN (ba.APositionTaking) * ba.Stake ELSE 0 END)*(CASE WHEN ABS(b.Odds) <1 THEN 1 ELSE ABS(b.Odds) END) ELSE 0 END)) AS Home_Odds_HalfTime,
	SUM((CASE WHEN ba.BetType = 21 THEN (CASE WHEN b.BetTeam = 'a' THEN (ba.APositionTaking) * ba.Stake ELSE 0 END)*(CASE WHEN ABS(b.Odds) <1 THEN 1 ELSE ABS(b.Odds) END) ELSE 0 END)) AS Away_Odds_HalfTime,
	
	SUM(CASE WHEN ba.BetType = 21 THEN (CASE WHEN b.BetTeam = 'h' THEN ba.Stake * (CASE WHEN b.Odds < 0 THEN 1 ELSE b.Odds END)* ba.APositionTaking ELSE - ba.Actual_Stake * ba.APositionTaking END) ELSE 0 END) AS WinLost_Home_HT,
	SUM(CASE WHEN ba.BetType = 21 THEN (CASE WHEN b.BetTeam = 'a' THEN ba.Stake * (CASE WHEN b.Odds < 0 THEN 1 ELSE b.Odds END)* ba.APositionTaking ELSE - ba.Actual_Stake * ba.APositionTaking END) ELSE 0 END) AS WinLost_Away_HT,
	
	ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral
		
FROM
	BetTrans_Agent ba WITH (NOLOCK)
	INNER JOIN BetTrans b WITH (NOLOCK) ON ba.TransId = b.TransId
	INNER JOIN Match m WITH (NOLOCK) ON b.MatchId = m.MatchId	
	
WHERE 
	ba.bettype IN (20,21) AND
	ba.AgentId = @AgentId AND
	m.EventStatus = 'running'  AND
	ba.StatusId = 0  AND 
	(	ISNULL(ba.SecAcceptFlag, 0) = 0	
		OR (ISNULL(ba.SecAcceptFlag, 0) = 1 AND ISNULL(b.CheckTime, CURRENT_TIMESTAMP) <= CURRENT_TIMESTAMP )
	)
	
	
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
	m.MatchCode, b.LiveIndicator DESC