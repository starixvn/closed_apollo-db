USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Forecast_5_15_GetByMatch]    Script Date: 5/2/2013 12:45:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_Forecast_5_15_GetByMatch]
	@MatchId INT,
	@BetType INT,
	@AgentId INT,
	@LoggedID INT  = 0
AS

/**
 * Created by	: Quinn
 * Date			: 20130301
 * Task			: Forecast by Match for 1x2 bettype
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	• 20130514@Sophia: Add super view
 * Parameters:
 *	@MatchId: Match ID
 *	@BetType: BetType
 *	@AgentId: Agent ID
 */

SET NOCOUNT ON

BEGIN
	SELECT 
		x.MatchID,
		x.homeid,
		x.awayid,
		x.liveindicator,
		ISNULL(x.LiveHomeScore, 0) AS livehomescore, 
		ISNULL(x.LiveAwayScore, 0) AS liveawayscore,
		x.ShowTime,
		x.MatchCode,
		isNeutral,
		(x.awaywin - x.homelose - x.drawlose) AS al,
		(x.homewin - x.awaylose - x.drawlose) AS hl,
		(x.drawwin - x.awaylose - x.homelose) AS dl,
	
		(x.ht_awaywin - x.ht_drawlose - x.ht_homelose) AS ht_al,
		(x.ht_homewin - x.ht_drawlose - x.ht_awaylose) AS ht_hl,
		(x.ht_drawwin - x.ht_awaylose - x.ht_homelose) AS ht_dl
	FROM (
		SELECT 
			m.MatchID,
			m.homeid,
			m.awayid,
			b.liveindicator,
			ISNULL(b.LiveHomeScore, 0) AS livehomescore,
			ISNULL(b.LiveAwayScore, 0) AS liveawayscore,
			M.ShowTime,
			M.MatchCode,
			ISNULL(m.isNeutral, CONVERT(BIT, 0)) AS IsNeutral,

			SUM(CASE WHEN betteam = '1' AND b.BetType = 5 THEN (CASE WHEN odds < 0 THEN 1 ELSE odds - 1 END) * b.Stake * CASE WHEN @LoggedID = 0 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END ELSE 0 END) AS homewin,
			SUM(CASE WHEN betteam = '2' AND b.BetType = 5 THEN (CASE WHEN odds < 0 THEN 1 ELSE odds - 1 END) * b.Stake * CASE WHEN @LoggedID = 0 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END ELSE 0 END) AS awaywin,
			SUM(CASE WHEN betteam = 'x' AND b.BetType = 5 THEN (CASE WHEN odds < 0 THEN 1 ELSE odds - 1 END) * b.Stake * CASE WHEN @LoggedID = 0 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END ELSE 0 END) AS drawwin,

			SUM(CASE WHEN betteam = '1' AND b.BetType = 5 THEN (CASE WHEN odds < 0 THEN ABS(odds - 1) ELSE 1 END) * b.Stake * CASE WHEN @LoggedID = 0 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END ELSE 0 END) AS homelose,
			SUM(CASE WHEN betteam = '2' AND b.BetType = 5 THEN (CASE WHEN odds < 0 THEN ABS(odds - 1) ELSE 1 END) * b.Stake * CASE WHEN @LoggedID = 0 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END ELSE 0 END) AS awaylose,
			SUM(CASE WHEN betteam = 'x' AND b.BetType = 5 THEN (CASE WHEN odds < 0 THEN ABS(odds - 1) ELSE 1 END) * b.Stake * CASE WHEN @LoggedID = 0 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END ELSE 0 END) AS drawlose,

			SUM(CASE WHEN betteam = '1' AND b.BetType = 15 THEN (CASE WHEN odds < 0 THEN 1 ELSE odds - 1 END) * b.Stake * CASE WHEN @LoggedID = 0 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END ELSE 0 END) AS ht_homewin,
			SUM(CASE WHEN betteam = '2' AND b.BetType = 15 THEN (CASE WHEN odds < 0 THEN 1 ELSE odds - 1 END) * b.Stake * CASE WHEN @LoggedID = 0 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END ELSE 0 END) AS ht_awaywin,
			SUM(CASE WHEN betteam = 'x' AND b.BetType = 15 THEN (CASE WHEN odds < 0 THEN 1 ELSE odds - 1 END) * b.Stake * CASE WHEN @LoggedID = 0 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END ELSE 0 END) AS ht_drawwin,

			SUM(CASE WHEN betteam = '1' AND b.BetType = 15 THEN (CASE WHEN odds < 0 THEN ABS(odds - 1) ELSE 1 END) * b.Stake * CASE WHEN @LoggedID = 0 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END ELSE 0 END) AS ht_homelose,
			SUM(CASE WHEN betteam = '2' AND b.BetType = 15 THEN (CASE WHEN odds < 0 THEN ABS(odds - 1) ELSE 1 END) * b.Stake * CASE WHEN @LoggedID = 0 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END ELSE 0 END) AS ht_awaylose,
			SUM(CASE WHEN betteam = 'x' AND b.BetType = 15 THEN (CASE WHEN odds < 0 THEN ABS(odds - 1) ELSE 1 END) * b.Stake * CASE WHEN @LoggedID = 0 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END ELSE 0 END) AS ht_drawlose
		FROM 
			BetTrans_Agent AS ba WITH (NOLOCK)
			INNER JOIN BetTrans AS b WITH (NOLOCK) ON ba.TransId = b.TransId
			INNER JOIN Match AS M WITH (NOLOCK) ON b.MatchID = M.MatchID
		WHERE 
			b.BetType = @BetType
			AND b.StatusId IN (0, 1)
			AND b.MatchId = @MatchId
			AND ba.AgentId = @AgentId
			 -- status is waiting or running
			AND b.Ruben = 0			-- match not yet settle
			AND M.EventStatus = 'running'
		GROUP BY 
			liveindicator,
			b.currency,
			m.MatchID,
			m.homeid,
			m.awayid,
			b.LiveHomeScore,
			b.LiveAwayScore,
			M.ShowTime,
			M.MatchCode,
			isNeutral
		) AS x 
END
