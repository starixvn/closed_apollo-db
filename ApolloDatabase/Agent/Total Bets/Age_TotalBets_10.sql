USE [TransDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_TotalBets_10]    Script Date: 2/28/2013 5:49:53 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_TotalBets_10]
	@AgentId INT
AS

/**
 * Created by	: Quinn
 * Date			: 20130228
 * Task			: Retrieve Total Bet values for bettype 10
 * DB			: APL.TransDB
 * Revisions	:
 *	•
 * Parameters:
 *	@AgentId: agent ID
 *  
 */

SET NOCOUNT ON

SELECT
	m.leagueid, 
	m.matchcode, 
	m.orid,
	m.teamid,
	SUM(bta.APositionTaking*bta.Stake) AS balance,
	SUM(1) AS BetCount,
	SUM(bta.APositionTaking*bta.Stake*bt.Odds) - ISNULL(leaguetotal.totalbalance, 0) AS totalwinlost,
	CONVERT(BIT,0) AS IsNeutral
FROM
	outright AS m WITH (NOLOCK) 
	INNER JOIN BetTrans AS bt  WITH (NOLOCK) ON m.orid = bt.MatchId
	INNER JOIN BetTrans_Agent AS bta WITH (NOLOCK) ON bta.TransId = bt.TransId
	INNER JOIN (
					SELECT 
						m.leagueid, SUM(a.APositionTaking*a.Stake) AS totalbalance
					FROM
						BetTrans_Agent AS a WITH (NOLOCK) 
						INNER JOIN outright AS m WITH (NOLOCK) ON m.orid = a.MatchId 
					WHERE
						a.AgentId = @AgentId
						AND a.StatusId = 0
						AND a.BetType = 10
					GROUP BY m.leagueid
				) AS leaguetotal ON leaguetotal.leagueid = m.leagueid
WHERE 
	bta.AgentId = @AgentId 
	AND bta.BetType = 10
	AND bta.StatusId = 0
GROUP BY
	m.teamid,
	m.orid,
	m.matchcode, 
	m.leagueid,
	leaguetotal.totalbalance,
	m.leagueid
ORDER BY
	m.MatchCode DESC