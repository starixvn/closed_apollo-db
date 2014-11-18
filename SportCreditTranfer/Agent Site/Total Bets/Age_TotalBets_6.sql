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
  - 20130128@Terry.Nguyen	: Implement
  - 20130629@Sophia: Add Showtime
  - 20130708@Sophia: Change SuperId from 0 to 1 (@AgentID = 1)
  - 20140820@Sophia: Add 1H total goal (bettype = 126)
 * Parameters:
 *	•
 *	•
 *  
 */

SET NOCOUNT ON
BEGIN
	SELECT
		b.MatchId,
		m.HomeId,
		m.AwayId,
		m.MatchCode,
		m.kickofftime,
		m.Showtime,

		SUM((CASE WHEN b.Bettype = 6 
				  THEN CASE WHEN b.BetTeam = '0-1'
							THEN (b.Stake * b.Odds) - b.Stake 
							ELSE - b.Stake END
				  ELSE 0 END) * APositionTaking) AS Total01,

		SUM((CASE WHEN b.Bettype = 6 
				  THEN CASE WHEN b.BetTeam = '2-3'
							THEN (b.Stake * b.Odds) - b.Stake 
							ELSE - b.Stake END
				  ELSE 0 END) * APositionTaking) AS Total23,

		SUM((CASE WHEN b.Bettype = 6 
				  THEN CASE WHEN b.BetTeam = '4-6'
							THEN (b.Stake * b.Odds) - b.Stake 
							ELSE - b.Stake END
				  ELSE 0 END) * APositionTaking) AS Total46,	 
				   		    
		SUM((CASE WHEN b.Bettype = 6 
				  THEN CASE WHEN b.BetTeam IN ('7-over','7&Over') 
							THEN (b.Stake * b.Odds) - b.Stake 
							ELSE - b.Stake END
				  ELSE 0 END) * APositionTaking) AS Total7Over,

		--------------------------------

		SUM((CASE WHEN b.Bettype = 126 
				  THEN CASE WHEN b.BetTeam = '0-1'
							THEN (b.Stake * b.Odds) - b.Stake 
							ELSE - b.Stake END
				  ELSE 0 END) * APositionTaking) AS HTTotal01,

		SUM((CASE WHEN b.Bettype = 126 
				  THEN CASE WHEN b.BetTeam = '2-3'
							THEN (b.Stake * b.Odds) - b.Stake 
							ELSE - b.Stake END
				  ELSE 0 END) * APositionTaking) AS HTTotal23,

					   		    
		SUM((CASE WHEN b.Bettype = 126 
				  THEN CASE WHEN b.BetTeam IN ('4-over','4&Over') 
							THEN (b.Stake * b.Odds) - b.Stake 
							ELSE - b.Stake END
				  ELSE 0 END) * APositionTaking) AS HTTotal4Over,

		ISNULL(m.IsNeutral, CONVERT(BIT, 0)) AS IsNeutral

	FROM	(
			SELECT	b.bettype, b.BetTeam, b.Stake, b.Odds, b.MatchId,					
					CASE WHEN @LoggedId = 1 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END AS APositionTaking
			FROM dbo.BetTrans AS b WITH (NOLOCK) 
				INNER JOIN dbo.BetTrans_Agent AS ba WITH (NOLOCK) 
						ON ba.TransId = b.TransId 
			WHERE  ba.AgentId = @AgentId	
					AND b.BetType IN (6, 126)
					AND b.StatusId = 0
					AND (ISNULL(b.SecAcceptFlag, 0) = 0 OR (ISNULL(b.SecAcceptFlag, 0) = 1 AND ISNULL(b.CheckTime, CURRENT_TIMESTAMP) <= CURRENT_TIMESTAMP ))
					AND b.Ruben = 0
			) b		
			INNER JOIN dbo.Match AS m WITH (NOLOCK) 
					ON b.MatchId = m.MatchId
	WHERE m.EventStatus = 'running'  		
	GROUP BY
		b.MatchId,
		m.HomeId,
		m.AwayId,
		m.MatchCode,
		m.kickofftime,
		m.Showtime,
		m.IsNeutral
	ORDER by m.matchcode

END
GO
GRANT EXECUTE ON  [Age_TotalBets_6] TO [aplweb]
GO
 