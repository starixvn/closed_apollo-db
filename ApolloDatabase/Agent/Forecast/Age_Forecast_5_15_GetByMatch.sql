USE [DB05]
GO
/****** Object:  StoredProcedure [dbo].[Age_Forecast_5_15_GetByMatch]    Script Date: 3/1/2013 6:21:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_Forecast_5_15_GetByMatch]
	@MatchId INT,
	@BetType INT,
	@AgentId INT
AS
/**
 * Created by	: Quinn
 * Date			: 20130301
 * Task			: Forecast by Match for 1x2 bettype
 * DB			: APL.DB05
 * Revisions	:
 *	•
 * Parameters:
 *	@MatchId: Match ID
 *	@BetType: BetType
 *	@AgentId: Agent ID
 */
SET NOCOUNT ON
DECLARE @BetType1x2 SMALLINT, @BetTypeHT1x2 SMALLINT
SELECT @BetType1x2 = 5, @BetTypeHT1x2 = 15
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
		(x.awaywin - x.homelose - x.drawlose) 'al',
		(x.homewin - x.awaylose - x.drawlose) 'hl',
		(x.drawwin - x.awaylose - x.homelose) 'dl',
	
		(x.ht_awaywin - x.ht_drawlose - x.ht_homelose) 'ht_al',
		(x.ht_homewin - x.ht_drawlose - x.ht_awaylose) 'ht_hl',
		(x.ht_drawwin - x.ht_awaylose - x.ht_homelose) 'ht_dl'
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
			ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,
			SUM(CASE WHEN betteam='1' AND b.BetType = @BetType1x2 THEN (CASE WHEN odds < 0 THEN 1 ELSE odds - 1 END) * ba.Stake * (ba.APositionTaking) ELSE 0 END) homewin,
			SUM(CASE WHEN betteam='2' AND b.BetType = @BetType1x2 THEN (CASE WHEN odds < 0 THEN 1 ELSE odds - 1 END) * ba.Stake * (ba.APositionTaking) ELSE 0 END) awaywin,
			SUM(CASE WHEN betteam='x' AND b.BetType = @BetType1x2 THEN (CASE WHEN odds < 0 THEN 1 ELSE odds - 1 END) * ba.Stake * (ba.APositionTaking) ELSE 0 END) drawwin,

			SUM(CASE WHEN betteam='1' AND b.BetType = @BetType1x2 THEN (CASE WHEN odds < 0 THEN ABS(odds - 1) ELSE 1 END)  * ba.Stake * (ba.APositionTaking) ELSE 0 END) homelose,
			SUM(CASE WHEN betteam='2' AND b.BetType = @BetType1x2 THEN (CASE WHEN odds < 0 THEN ABS(odds - 1) ELSE 1 END)  * ba.Stake * (ba.APositionTaking) ELSE 0 END) awaylose,
			SUM(CASE WHEN betteam='x' AND b.BetType = @BetType1x2 THEN (CASE WHEN odds < 0 THEN ABS(odds - 1) ELSE 1 END)  * ba.Stake * (ba.APositionTaking) ELSE 0 END) drawlose,

			SUM(CASE WHEN betteam='1' AND b.BetType = @BetTypeHT1x2 THEN (CASE WHEN odds < 0 THEN 1 ELSE odds - 1 END) * ba.Stake * (ba.APositionTaking) ELSE 0 END) ht_homewin,
			SUM(CASE WHEN betteam='2' AND b.BetType = @BetTypeHT1x2 THEN (CASE WHEN odds < 0 THEN 1 ELSE odds - 1 END) * ba.Stake * (ba.APositionTaking) ELSE 0 END) ht_awaywin,
			SUM(CASE WHEN betteam='x' AND b.BetType = @BetTypeHT1x2 THEN (CASE WHEN odds < 0 THEN 1 ELSE odds - 1 END) * ba.Stake * (ba.APositionTaking) ELSE 0 END) ht_drawwin,

			SUM(CASE WHEN betteam='1' AND b.BetType = @BetTypeHT1x2 THEN (CASE WHEN odds < 0 THEN ABS(odds - 1) ELSE 1 END)  * ba.Stake * (ba.APositionTaking) ELSE 0 END) ht_homelose,
			SUM(CASE WHEN betteam='2' AND b.BetType = @BetTypeHT1x2 THEN (CASE WHEN odds < 0 THEN ABS(odds - 1) ELSE 1 END)  * ba.Stake * (ba.APositionTaking) ELSE 0 END) ht_awaylose,
			SUM(CASE WHEN betteam='x' AND b.BetType = @BetTypeHT1x2 THEN (CASE WHEN odds < 0 THEN ABS(odds - 1) ELSE 1 END)  * ba.Stake * (ba.APositionTaking) ELSE 0 END) ht_drawlose
		FROM BetTrans_Agent ba WITH (NOLOCK)
			INNER JOIN BetTrans AS b WITH (NOLOCK) ON ba.TransId = b.TransId
			INNER JOIN Match M WITH (NOLOCK) ON b.MatchID = M.MatchID AND M.EventStatus = 'running'
		WHERE b.BetType = @BetType
			AND b.MatchId = @MatchId
			AND ba.AgentId = @AgentId
			AND b.StatusId IN (0,1)
			AND b.Ruben = 0
		GROUP BY liveindicator, b.currency ,m.MatchID, m.homeid, m.awayid,	
			b.liveindicator, b.LiveHomeScore,b.LiveAwayScore,M.ShowTime,M.MatchCode,isNeutral
		)x 
END



