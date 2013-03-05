USE [DB05]
GO
/****** Object:  StoredProcedure [dbo].[Age_Forecast_3_8_GetByMatch]    Script Date: 3/5/2013 10:51:08 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_Forecast_3_8_GetByMatch]
	@MatchId INT,
	@BetType INT = 3,
	@AgentId INT
AS
/**
 * Created by	: Quinn
 * Date			: 20130301
 * Task			: Forecast by Match for OU bettype.
 * DB			: APL.DB05
 * Revisions	:
 *	•
 * Parameters:
 *	@MatchId: Match ID
 *	@BetType: BetType
 *	@AgentId: Agent ID
 */
SET NOCOUNT ON
BEGIN
	SELECT  x.LiveIndicator, x.status, x.score +  x.hdp offset, 
		SUM(x.hometotal * 1) 'ht',
		SUM(x.awaytotal * 1) 'at',
		SUM((x.homewin - x.awaylose) * 1) 'al',
		SUM((x.awaywin - x.homelose) * 1) 'hl'
	FROM
		(
			SELECT
				b.LiveIndicator, 
				b.Status,
				b.Currency, 
				hdp1 hdp, 0 score, 
				SUM(CASE WHEN betteam='h' THEN ba.Stake * (ba.APositionTaking) ELSE 0 END) hometotal,
				SUM(CASE WHEN betteam='a' THEN ba.Stake * (ba.APositionTaking) ELSE 0 END) awaytotal,	
				SUM(CASE WHEN betteam='h' THEN (CASE WHEN odds < 0 THEN 1 ELSE odds END) * ba.Stake * (ba.APositionTaking) ELSE 0 END) homewin,
				SUM(CASE WHEN betteam='a' THEN (CASE WHEN odds < 0 THEN 1 ELSE odds END) * ba.Stake * (ba.APositionTaking) ELSE 0 END) awaywin,
				SUM(CASE WHEN betteam='h' THEN (CASE WHEN odds < 0 THEN ABS(odds) ELSE 1 END)  * ba.Stake * (ba.APositionTaking) ELSE 0 END) homelose,
				SUM(CASE WHEN betteam='a' THEN (CASE WHEN odds < 0 THEN ABS(odds) ELSE 1 END)  * ba.Stake * (ba.APositionTaking) ELSE 0 END) awaylose
			FROM BetTrans_Agent ba WITH (NOLOCK)
				INNER JOIN BetTrans AS b WITH (NOLOCK) ON ba.TransId = b.TransId
			WHERE b.BetType= @BetType
			AND b.MatchId = @MatchId
			AND ba.AgentId = @AgentId
			AND b.StatusId IN (0,1) -- status is waiting or running
			AND b.Ruben = 0	-- match not yet settle
			GROUP BY b.LiveIndicator, b.Status, b.Currency, hdp1, livehomescore + liveawayscore
		)x 
	GROUP BY x.status, x.LiveIndicator, x.score + x.hdp
END
