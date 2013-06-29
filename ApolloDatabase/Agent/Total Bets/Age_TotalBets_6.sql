USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_TotalBets_6]    Script Date: 4/26/2013 11:20:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_TotalBets_6]
	@AgentId	INT,
	@LoggedID INT = 0
AS

/**
 * Created by	: Terry.Nguyen
 * Date			: 20130228
 * Task			: Get Total Bets(Total Goal Bettype) data for Agent
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	• 20130128@Terry.Nguyen	: Implement
 *	• 20130629@Sophia: Add Showtime
 * Parameters:
 *	•
 *	•
 *  
 */

SET NOCOUNT ON
BEGIN
	SELECT
		ba.MatchId,
		m.HomeId,
		m.AwayId,
		m.MatchCode,
		m.kickofftime,
		m.Showtime,
		SUM((CASE BetTeam WHEN '0-1' THEN (ba.Stake * b.Odds) - ba.Stake ELSE - ba.Stake END ) * (CASE WHEN @LoggedID = 0 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END)) AS Total01,
		SUM((CASE BetTeam WHEN '2-3' THEN (ba.Stake * b.Odds) - ba.Stake ELSE - ba.Stake END ) * (CASE WHEN @LoggedID = 0 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END)) AS Total23,
		SUM((CASE BetTeam WHEN '4-6' THEN (ba.Stake * b.Odds) - ba.Stake ELSE - ba.Stake END ) * (CASE WHEN @LoggedID = 0 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END)) AS Total46,
		SUM((CASE BetTeam WHEN '7-over' THEN (ba.Stake * b.Odds) - ba.Stake ELSE -ba.Stake END ) * (CASE WHEN @LoggedID = 0 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END)) AS Total7Over,
		ISNULL(m.IsNeutral, CONVERT(BIT, 0)) AS IsNeutral
	FROM  
		BetTrans_Agent AS ba WITH (NOLOCK) 
		INNER JOIN BetTrans AS b WITH (NOLOCK) ON ba.TransId = b.TransId 
		INNER JOIN Match AS m WITH (NOLOCK) ON b.MatchId = m.MatchId
	WHERE
		ba.AgentId = @AgentId	
		AND b.BetType = 6 	
		AND b.StatusId = 0
		AND m.EventStatus = 'running'  
		AND (ISNULL(b.SecAcceptFlag, 0) = 0 OR (ISNULL(b.SecAcceptFlag, 0) = 1 AND ISNULL(b.CheckTime, CURRENT_TIMESTAMP) <= CURRENT_TIMESTAMP ))
		AND b.Ruben = 0
	GROUP BY
		ba.MatchId,
		m.HomeId,
		m.AwayId,
		m.MatchCode,
		m.kickofftime,
		m.Showtime,
		m.IsNeutral
	ORDER by m.matchcode

END

