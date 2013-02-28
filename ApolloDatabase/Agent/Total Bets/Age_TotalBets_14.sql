USE [TransDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_TotalBets_14]    Script Date: 2/28/2013 5:50:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_TotalBets_14]
	@AgentId INT
AS

/**
 * Created by	: Quinn
 * Date			: 20130228
 * Task			: Retrieve Total Bet values for bettype 14
 * DB			: APL.TransDB
 * Revisions	:
 *	•
 * Parameters:
 *	@AgentId: agent ID
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
	SUM(CASE WHEN hdp1 = 1 AND hdp2 = 1 THEN bta.Stake*(CASE WHEN odds<0 THEN 1 ELSE odds-1 END)* bta.APositionTaking ELSE -bta.Actual_Stake*bta.APositionTaking END) AS WinLost_HomeFG,
	SUM(CASE WHEN hdp1 = 1 AND hdp2 = 2 THEN bta.Stake*(CASE WHEN odds<0 THEN 1 ELSE odds-1 END)* bta.APositionTaking ELSE -bta.Actual_Stake*bta.APositionTaking END) AS WinLost_HomeLG,
	SUM(CASE WHEN hdp1 = 2 AND hdp2 = 1 THEN bta.Stake*(CASE WHEN odds<0 THEN 1 ELSE odds-1 END)* bta.APositionTaking ELSE -bta.Actual_Stake*bta.APositionTaking END) AS WinLost_AwayFG,
	SUM(CASE WHEN hdp1 = 2 AND hdp2 = 2 THEN bta.Stake*(CASE WHEN odds<0 THEN 1 ELSE odds-1 END)* bta.APositionTaking ELSE -bta.Actual_Stake*bta.APositionTaking END) AS WinLost_AwayLG,
	SUM(CASE WHEN hdp1 = 0 AND hdp2 = 0 THEN bta.Stake*(CASE WHEN odds<0 THEN 1 ELSE odds-1 END)* bta.APositionTaking ELSE -bta.Actual_Stake*bta.APositionTaking END) AS WinLost_NoGoal,
	ISNULL(m.IsNeutral, CONVERT(BIT,0)) as IsNeutral
FROM
	BetTrans_Agent AS bta WITH (NOLOCK)
	INNER JOIN BetTrans AS bt  WITH (NOLOCK) ON bta.TransId = bt.TransId
	INNER JOIN Match AS m  WITH (NOLOCK) ON m.MatchId = bt.MatchId
WHERE 
	bta.AgentId = @AgentId 
	AND m.EventStatus='running'
	AND bta.BetType = 14 
	AND bt.Ruben=0 
	AND bta.StatusId = 0 
	AND (ISNULL(bta.SecAcceptFlag, 0) = 0	
			OR (ISNULL(bta.SecAcceptFlag, 0) = 1 AND ISNULL(bt.CheckTime, CURRENT_TIMESTAMP) <= CURRENT_TIMESTAMP)
		)
	
GROUP BY
	bt.LiveIndicator,
	m.HomeId,
	m.AwayId,
	m.MatchId,
	m.MatchCode, 
	m.LeagueId,
	bt.LiveHomeScore,
	bt.LiveAwayScore,
	m.ShowTime,
	m.IsNeutral
ORDER BY
	m.MatchCode, bt.LiveIndicator DESC