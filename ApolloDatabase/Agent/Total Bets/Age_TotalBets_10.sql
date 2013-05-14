USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_TotalBets_10]    Script Date: 4/26/2013 11:16:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_TotalBets_10]
	@AgentId INT,
	@LoggedId INT = 0
AS

/**
 * Created by	: Quinn
 * Date			: 20130228
 * Task			: Retrieve Total Bet values for bettype 10
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	- 20130513@Sophia: Add super view
 * Parameters:
 *	@AgentId: agent ID
 *  
 */

SET NOCOUNT ON
IF @LoggedId = 0
BEGIN 
	SELECT
		m.leagueid, 
		m.matchcode, 
		m.orid AS MatchId,
		m.teamid,
		SUM((1-bt.TPositionTaking) * bta.Stake) AS balance,
		SUM(1) AS BetCount,
		SUM((1-bt.TPositionTaking) * bt.Stake * bt.Odds) - ISNULL(lt.totalbalance, 0) AS totalwinlost,
		CONVERT(BIT, 0) AS IsNeutral
	FROM
		outright AS m WITH (NOLOCK) 
		INNER JOIN BetTrans AS bt  WITH (NOLOCK) ON m.orid = bt.MatchId
		INNER JOIN BetTrans_Agent AS bta WITH (NOLOCK) ON bta.TransId = bt.TransId
		INNER JOIN 
		(
			SELECT	m.leagueid, SUM((1-b.TPositionTaking) * b.Stake) AS totalbalance
			FROM	BetTrans AS b WITH (NOLOCK)
				 INNER JOIN Bettrans_Agent ba WITH (NOLOCK) ON b.TransID = ba.TransID 
				 INNER JOIN outright AS m WITH (NOLOCK) ON m.orid = b.MatchId 
			WHERE	ba.AgentID = @AgentId
					AND ba.StatusId = 0 -- status is running
					AND ba.BetType = 10
					
			GROUP BY m.leagueid
		) AS lt ON lt.leagueid = m.leagueid
	WHERE 
		bta.AgentId = @AgentId 
		AND bt.BetType = 10
		AND bt.StatusId = 0 -- status is running
	GROUP BY
		m.teamid,
		m.orid,
		m.matchcode, 
		m.leagueid,
		lt.totalbalance,
		m.leagueid
	ORDER BY m.MatchCode DESC
END 
ELSE
BEGIN
	SELECT
		m.leagueid, 
		m.matchcode, 
		m.orid AS MatchId,
		m.teamid,
		SUM(bta.APositionTaking * bta.Stake) AS balance,
		SUM(1) AS BetCount,
		SUM(bta.APositionTaking * bta.Stake * bt.Odds) - ISNULL(lt.totalbalance, 0) AS totalwinlost,
		CONVERT(BIT, 0) AS IsNeutral
	FROM
		outright AS m WITH (NOLOCK) 
		INNER JOIN BetTrans AS bt  WITH (NOLOCK) ON m.orid = bt.MatchId
		INNER JOIN BetTrans_Agent AS bta WITH (NOLOCK) ON bta.TransId = bt.TransId
		INNER JOIN 
		(
			SELECT 
				m.leagueid, 
				SUM(a.APositionTaking * a.Stake) AS totalbalance
			FROM
				BetTrans_Agent AS a WITH (NOLOCK) 
				INNER JOIN outright AS m WITH (NOLOCK) ON m.orid = a.MatchId 
			WHERE
				a.AgentId = @AgentId
				AND a.StatusId = 0 -- status is running
				AND a.BetType = 10
			GROUP BY m.leagueid
		) AS lt ON lt.leagueid = m.leagueid
	WHERE 
		bta.AgentId = @AgentId 
		AND bta.BetType = 10
		AND bta.StatusId = 0 -- status is running
	GROUP BY
		m.teamid,
		m.orid,
		m.matchcode, 
		m.leagueid,
		lt.totalbalance,
		m.leagueid
	ORDER BY m.MatchCode DESC
END