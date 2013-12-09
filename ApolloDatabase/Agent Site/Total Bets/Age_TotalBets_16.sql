USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_TotalBets_16]    Script Date: 4/26/2013 11:18:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_TotalBets_16]
	@AgentId	INT,
	@LoggedID INT = 0 	
AS

	/**
 * Created by	: Terry.Nguyen
 * Date			: 20130228
 * Task			: Get Total Bets(halfTime AND FullTime) data for Agent
 * DB			: SVRAGE.RepDB
 * Revisions	:
  - 20132801@Terry.Nguyen	: Implement
  - 20130513@Sophia: add super view
  - 20130629@Sophia: Add Showtime
  - 20130708@Sophia: Change SuperId from 0 to 1 (@AgentID = 1)

 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	SET NOCOUNT ON

IF @LoggedId = 1 
BEGIN 
	SELECT
		ba.MatchId,
		m.HomeId,
		m.AwayId,
		m.MatchCode,
		m.kickofftime,
		m.Showtime,
		SUM((CASE WHEN hdp1 = 1 AND hdp2 = 1 THEN (b.Stake * b.Odds) - b.Stake ELSE - b.Stake END ) * (1-b.TPositiontaking)) AS TotalHH,
		SUM((CASE WHEN hdp1 = 1 AND hdp2 = 0 THEN (b.Stake * b.Odds) - b.Stake ELSE - b.Stake END ) * (1-b.TPositiontaking)) AS TotalHD,
		SUM((CASE WHEN hdp1 = 1 AND hdp2 = 2 THEN (b.Stake * b.Odds) - b.Stake ELSE - b.Stake END ) * (1-b.TPositiontaking)) AS TotalHA,
		SUM((CASE WHEN hdp1 = 0 AND hdp2 = 1 THEN (b.Stake * b.Odds) - b.Stake ELSE - b.Stake END ) * (1-b.TPositiontaking)) AS TotalDH,
	
		SUM((CASE WHEN hdp1 = 0 AND hdp2 = 0 THEN (b.Stake * b.Odds) - b.Stake ELSE - b.Stake END ) * (1-b.TPositiontaking)) AS TotalDD,
		SUM((CASE WHEN hdp1 = 0 AND hdp2 = 2 THEN (b.Stake * b.Odds) - b.Stake ELSE - b.Stake END ) * (1-b.TPositiontaking)) AS TotalDA,
		SUM((CASE WHEN hdp1 = 2 AND hdp2 = 1 THEN (b.Stake * b.Odds) - b.Stake ELSE - b.Stake END ) * (1-b.TPositiontaking)) AS TotalAH,
		SUM((CASE WHEN hdp1 = 2 AND hdp2 = 0 THEN (b.Stake * b.Odds) - b.Stake ELSE - b.Stake END ) * (1-b.TPositiontaking)) AS TotalAD,
		SUM((CASE WHEN hdp1 = 2 AND hdp2 = 2 THEN (b.Stake * b.Odds) - b.Stake ELSE - b.Stake END ) * (1-b.TPositiontaking)) AS TotalAA,

		ISNULL(m.isNeutral, CONVERT(BIT, 0)) as IsNeutral
	FROM  
		BetTrans_Agent AS ba WITH (NOLOCK)
		INNER JOIN BetTrans AS b WITH (NOLOCK) ON ba.TransId = b.TransId
		INNER JOIN Match AS m WITH (NOLOCK) ON b.MatchId = m.MatchId	
	WHERE    
		ba.AgentId = @AgentId 
		AND ba.BetType = 16 
		AND	m.EventStatus = 'running' 
		AND	ba.StatusId = 0 
		AND (	ISNULL(ba.SecAcceptFlag, 0) = 0	
				OR (	ISNULL(ba.SecAcceptFlag, 0) = 1 
						AND ISNULL(b.CheckTime, CURRENT_TIMESTAMP) <= CURRENT_TIMESTAMP)) 
		AND m.matchid > 0
	GROUP BY 
		ba.MatchId,
		m.HomeId,
		m.AwayId,
		m.MatchCode,
		m.kickofftime,
		m.Showtime,
		m.IsNeutral
	ORDER BY m.MatchCode
END
ELSE
BEGIN 
SELECT
		ba.MatchId,
		m.HomeId,
		m.AwayId,
		m.MatchCode,
		m.kickofftime,	
		m.Showtime,
		SUM((CASE WHEN hdp1 = 1 AND hdp2 = 1 THEN (ba.Stake * b.Odds) - ba.Stake ELSE - ba.Stake END ) * ba.APositionTaking) AS TotalHH,
		SUM((CASE WHEN hdp1 = 1 AND hdp2 = 0 THEN (ba.Stake * b.Odds) - ba.Stake ELSE - ba.Stake END ) * ba.APositionTaking) AS TotalHD,
		SUM((CASE WHEN hdp1 = 1 AND hdp2 = 2 THEN (ba.Stake * b.Odds) - ba.Stake ELSE - ba.Stake END ) * ba.APositionTaking) AS TotalHA,
		SUM((CASE WHEN hdp1 = 0 AND hdp2 = 1 THEN (ba.Stake * b.Odds) - ba.Stake ELSE - ba.Stake END ) * ba.APositionTaking) AS TotalDH,
	
		SUM((CASE WHEN hdp1 = 0 AND hdp2 = 0 THEN (ba.Stake * b.Odds) - ba.Stake ELSE - ba.Stake END ) * ba.APositionTaking) AS TotalDD,
		SUM((CASE WHEN hdp1 = 0 AND hdp2 = 2 THEN (ba.Stake * b.Odds) - ba.Stake ELSE - ba.Stake END ) * ba.APositionTaking) AS TotalDA,
		SUM((CASE WHEN hdp1 = 2 AND hdp2 = 1 THEN (ba.Stake * b.Odds) - ba.Stake ELSE - ba.Stake END ) * ba.APositionTaking) AS TotalAH,
		SUM((CASE WHEN hdp1 = 2 AND hdp2 = 0 THEN (ba.Stake * b.Odds) - ba.Stake ELSE - ba.Stake END ) * ba.APositionTaking) AS TotalAD,
		SUM((CASE WHEN hdp1 = 2 AND hdp2 = 2 THEN (ba.Stake * b.Odds) - ba.Stake ELSE - ba.Stake END ) * ba.APositionTaking) AS TotalAA,

		ISNULL(m.isNeutral, CONVERT(BIT, 0)) as IsNeutral
	FROM  
		BetTrans_Agent AS ba WITH (NOLOCK)
		INNER JOIN BetTrans AS b WITH (NOLOCK) ON ba.TransId = b.TransId
		INNER JOIN Match AS m WITH (NOLOCK) ON b.MatchId = m.MatchId	
	WHERE    
		ba.AgentId = @AgentId 
		AND ba.BetType = 16 
		AND	m.EventStatus = 'running' 
		AND	ba.StatusId = 0 
		AND (	ISNULL(ba.SecAcceptFlag, 0) = 0	
				OR (	ISNULL(ba.SecAcceptFlag, 0) = 1 
						AND ISNULL(b.CheckTime, CURRENT_TIMESTAMP) <= CURRENT_TIMESTAMP)) 
		AND m.matchid > 0
	GROUP BY 
		ba.MatchId,
		m.HomeId,
		m.AwayId,
		m.MatchCode,
		m.kickofftime,
		m.Showtime,
		m.IsNeutral
	ORDER BY m.MatchCode
END 
END
GO
GO
GRANT EXECUTE ON [Age_TotalBets_16] TO [aplweb]
GO
