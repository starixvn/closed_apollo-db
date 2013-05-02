USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Forecast_1_7_GetByMatch]    Script Date: 5/2/2013 12:45:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_Forecast_1_7_GetByMatch]
	@MatchId INT,
	@BetType INT = 1,
	@AgentId INT
AS
/**
 * Created by	: Quinn
 * Date			: 20130301
 * Task			: Forecast by Match for HDP bettype.
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	•
 * Parameters:
 *	@MatchId: Match ID
 *	@BetType: BetType
 *	@AgentId: Agent ID
 */
SET NOCOUNT ON

BEGIN
	SELECT  
		-x.hdp + score AS offset, 
		SUM(x.hometotal) AS ht,
		SUM(x.awaytotal) AS at,
		SUM(x.homewin - x.awaylose) AS al,
		SUM(x.awaywin - x.homelose) AS hl
	FROM
		(
			SELECT 
				b.currency, 
				hdp2 - hdp1 AS hdp, 
				livehomescore - liveawayscore AS score,
				SUM(CASE WHEN betteam = 'h' THEN ba.Stake * ba.APositionTaking ELSE 0 END) AS hometotal,
				SUM(CASE WHEN betteam = 'a' THEN ba.Stake * ba.APositionTaking ELSE 0 END) AS awaytotal,	
				SUM(CASE WHEN betteam = 'h' THEN (CASE WHEN odds < 0 THEN 1 ELSE odds END) * ba.Stake * ba.APositionTaking ELSE 0 END) AS homewin,
				SUM(CASE WHEN betteam = 'a' THEN (CASE WHEN odds < 0 THEN 1 ELSE odds END) * ba.Stake * ba.APositionTaking ELSE 0 END) AS awaywin,
				SUM(CASE WHEN betteam = 'h' THEN (CASE WHEN odds < 0 THEN ABS(odds) ELSE 1 END) * ba.Stake * ba.APositionTaking ELSE 0 END) AS homelose,
				SUM(CASE WHEN betteam = 'a' THEN (CASE WHEN odds < 0 THEN ABS(odds) ELSE 1 END) * ba.Stake * ba.APositionTaking ELSE 0 END) AS awaylose
			FROM 
				BetTrans_Agent AS ba WITH (NOLOCK)
				INNER JOIN BetTrans AS b WITH (NOLOCK) ON ba.TransId = b.TransId
			WHERE 
				b.BetType = @BetType
				AND b.MatchId = @MatchId
				AND ba.AgentId = @AgentId
				AND b.StatusId IN (0, 1) -- status is waiting or running
				AND b.Ruben = 0	-- match not yet settle
			GROUP BY 
				b.Currency, 
				hdp2 - hdp1, 
				livehomescore - liveawayscore
		) AS x 
	GROUP BY -x.hdp + score
END
