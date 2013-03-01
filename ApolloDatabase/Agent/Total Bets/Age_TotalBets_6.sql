USE [DB05]
GO
/****** Object:  StoredProcedure [dbo].[Age_TotalBets_6]    Script Date: 3/1/2013 6:24:42 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_TotalBets_6]

	@AgentId	INT

/**
 * Created by	: Terry.Nguyen
 * Date			: 20130228
 * Task			: Get Total Bets(Total Goal Bettype) data for Agent
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
	ba.MatchId,
	m.HomeId,
	m.AwayId,
	MatchCode,
	
	SUM((CASE BetTeam WHEN '0-1'  THEN (ba.Stake * b.Odds) - ba.Stake ELSE -ba.Stake END )*(ba.APositionTaking)) AS Total01,
	SUM((CASE BetTeam WHEN '2-3'  THEN (ba.Stake * b.Odds) - ba.Stake ELSE -ba.Stake END )*(ba.APositionTaking)) AS Total23,
	SUM((CASE BetTeam WHEN '4-6'  THEN (ba.Stake * b.Odds) - ba.Stake ELSE -ba.Stake END )*(ba.APositionTaking)) AS Total46,
	SUM((CASE BetTeam WHEN '7-over'  THEN (ba.Stake * b.Odds) - ba.Stake ELSE -ba.Stake END )*(ba.APositionTaking)) AS Total7Over,
	ISNULL(m.IsNeutral, CONVERT(BIT,0)) as IsNeutral
	
	FROM  
	BetTrans_Agent ba WITH (NOLOCK) INNER JOIN
	BetTrans b WITH (NOLOCK) ON ba.TransId = b.TransId INNER JOIN
	Match m WITH (NOLOCK) ON b.MatchId = m.MatchId 		

	WHERE    
	ba.AgentId = @AgentId	
	AND ba.BetType = 6 
	AND m.EventStatus = 'running'
	AND ba.StatusId = 0  
	AND (ISNULL(ba.SecAcceptFlag, 0) = 0 OR (ISNULL(ba.SecAcceptFlag, 0) = 1 AND ISNULL(b.CheckTime, CURRENT_TIMESTAMP) <= CURRENT_TIMESTAMP ))
	AND b.Ruben = 0
GROUP BY
	ba.MatchId,
	m.HomeId,
	m.AwayId,
	MatchCode,
	m.IsNeutral

ORDER by m.matchcode

END
