USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_TotalBets_14]    Script Date: 4/26/2013 11:16:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER  PROCEDURE [dbo].[Age_TotalBets_14]
	@AgentId INT,
	@LoggedID INT = 0 
AS

/**
 * Created by	: Quinn
 * Date			: 20130228
 * Task			: Retrieve Total Bet values for bettype 14 (First Goal/Last Goal)
 * DB			: SVRAGE.RepDB
 * Revisions	:
  - 20130509@Sophia: revise code, order by LeagueId
  - 20130513@Sophia: add super view
  - 20130708@Sophia: Change SuperId from 0 to 1 (@AgentID = 1)
  - 20140820@Sophia: Add 1HT FGLF (bettype = 127)
 * Parameters:
 *	@AgentId: agent ID
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
		b.LiveHomeScore,
		SUM((CASE WHEN b.Bettype = 14 
					THEN CASE WHEN hdp1 = 1 AND hdp2 = 1 
							  THEN b.Stake * (CASE WHEN odds < 0 THEN 1 ELSE odds - 1 END) 
							  ELSE - b.Actual_Stake END 
					ELSE 0 END) * b.APositionTaking) AS WinLostHomeFG,

		SUM((CASE WHEN b.Bettype = 14 
					THEN CASE WHEN hdp1 = 1 AND hdp2 = 2 
							  THEN b.Stake * (CASE WHEN odds < 0 THEN 1 ELSE odds - 1 END) 
							  ELSE - b.Actual_Stake END 
					ELSE 0 END) * b.APositionTaking) AS WinLostHomeLG,

		SUM((CASE WHEN b.Bettype = 14 
					THEN CASE WHEN hdp1 = 2 AND hdp2 = 1
							  THEN b.Stake * (CASE WHEN odds < 0 THEN 1 ELSE odds - 1 END) 
							  ELSE - b.Actual_Stake END 
					ELSE 0 END) * b.APositionTaking) AS WinLostAwayFG,

		SUM((CASE WHEN b.Bettype = 14 
					THEN CASE WHEN hdp1 = 2 AND hdp2 = 2
							  THEN b.Stake * (CASE WHEN odds < 0 THEN 1 ELSE odds - 1 END) 
							  ELSE - b.Actual_Stake END 
					ELSE 0 END) * b.APositionTaking) AS WinLostAwayLG,

		SUM((CASE WHEN b.Bettype = 14 
					THEN CASE WHEN hdp1 = 0 AND hdp2 = 0
							  THEN b.Stake * (CASE WHEN odds < 0 THEN 1 ELSE odds - 1 END) 
							  ELSE - b.Actual_Stake END 
					ELSE 0 END) * b.APositionTaking) AS WinLostNoGoal,
								
		----------------------------------------------

		SUM((CASE WHEN b.Bettype = 127 
					THEN CASE WHEN hdp1 = 1 AND hdp2 = 1 
							  THEN b.Stake * (CASE WHEN odds < 0 THEN 1 ELSE odds - 1 END) 
							  ELSE - b.Actual_Stake END 
					ELSE 0 END) * b.APositionTaking) AS HTWinLostHomeFG,

		SUM((CASE WHEN b.Bettype = 127 
					THEN CASE WHEN hdp1 = 1 AND hdp2 = 2 
							  THEN b.Stake * (CASE WHEN odds < 0 THEN 1 ELSE odds - 1 END) 
							  ELSE - b.Actual_Stake END 
					ELSE 0 END) * b.APositionTaking) AS HTWinLostHomeLG,

		SUM((CASE WHEN b.Bettype = 127 
					THEN CASE WHEN hdp1 = 2 AND hdp2 = 1
							  THEN b.Stake * (CASE WHEN odds < 0 THEN 1 ELSE odds - 1 END) 
							  ELSE - b.Actual_Stake END 
					ELSE 0 END) * b.APositionTaking) AS HTWinLostAwayFG,

		SUM((CASE WHEN b.Bettype = 127 
					THEN CASE WHEN hdp1 = 2 AND hdp2 = 2
							  THEN b.Stake * (CASE WHEN odds < 0 THEN 1 ELSE odds - 1 END) 
							  ELSE - b.Actual_Stake END 
					ELSE 0 END) * b.APositionTaking) AS HTWinLostAwayLG,

		SUM((CASE WHEN b.Bettype = 127 
					THEN CASE WHEN hdp1 = 0 AND hdp2 = 0
							  THEN b.Stake * (CASE WHEN odds < 0 THEN 1 ELSE odds - 1 END) 
							  ELSE - b.Actual_Stake END 
					ELSE 0 END) * b.APositionTaking) AS HTWinLostNoGoal,

		ISNULL(m.IsNeutral, CONVERT(BIT, 0)) AS IsNeutral
	FROM (
			SELECT  b.LiveIndicator, b.LiveHomeScore, b.LiveAwayScore, b.MatchId,
					b.Hdp1, b.Hdp2, b.Odds, b.Stake, b.Actual_Stake, b.bettype,
					CASE WHEN @LoggedId = 1 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END AS APositionTaking
			FROM  dbo.BetTrans_Agent AS ba WITH (NOLOCK)
				INNER JOIN dbo.BetTrans AS b  WITH (NOLOCK)
						ON ba.TransId = b.TransId
			WHERE ba.AgentId = @AgentId 
				AND b.BetType IN (14,127)
				AND b.Ruben = 0 -- Match not yet settle
				AND b.StatusId = 0 -- status is running
				AND (	ISNULL(b.SecAcceptFlag, 0) = 0
						OR (ISNULL(b.SecAcceptFlag, 0) = 1 AND ISNULL(b.CheckTime, CURRENT_TIMESTAMP) <= CURRENT_TIMESTAMP))
		) b
		INNER JOIN Match AS m WITH (NOLOCK) 
				ON m.MatchId = b.MatchId
	WHERE m.EventStatus ='running'		
	GROUP BY
		b.LiveIndicator,
		m.HomeId,
		m.AwayId,
		m.MatchId,
		m.MatchCode, 
		m.LeagueId,
		b.LiveHomeScore,
		b.LiveAwayScore,
		m.ShowTime,
		m.KickOffTime,
		m.IsNeutral
	ORDER BY
		m.LeagueId,
		m.MatchCode, 
		b.LiveIndicator DESC


GO
GRANT EXECUTE ON  [Age_TotalBets_14] TO [aplweb]
GO