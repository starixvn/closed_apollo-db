USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Forecast_1_3_7_8_GetByLeague]    Script Date: 4/26/2013 1:04:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Forecast_1_3_7_8_GetByLeague]
	@BaseOffsetHDP		INT,
	@BaseOffsetOU		INT,
	@BaseOffsetHTHDP	INT,
	@BaseOffsetHTOU		INT,
	@LeagueID			INT,
	@AgentId			INT,
	@LoggedID			INT = 0
AS

/**
 * Created by	: Quinn
 * Date			: 20130301
 * Task			: Forecast for HDP/OU bettype
 * DB			: SVRAGE.RepDB
 * Revisions	:
  - 20130514@Sophia: Add super view
  - 20130708@Sophia: Change SuperId from 0 to 1 (@AgentID = 1)
 * Parameters:
 *	
 */

SET NOCOUNT ON

DECLARE 
	@BetTypeHDP		INT, 
	@BetTypeOU		INT, 
	@VScoreHDP		SMALLMONEY, 
	@VScoreOU		SMALLMONEY, 
	@BetTypeHTHDP	INT, 
	@BetTypeHTOU	INT

SELECT 
	@BetTypeHDP = 1, 
	@BetTypeOU = 3, 
	@BetTypeHTHDP = 7, 
	@BetTypeHTOU = 8

--Declare @Result TABLE (ForecastID int, bettype int, liveindicator bit, status varchar(10), offset smallmoney, hometotal money, awaytotal money, homelose money, awaylose money, betcount int, BaseOffset smallmoney, WinLostStatus int, MatchID int, FOffset smallmoney)
--WinlostStatus: 
--	1: home win 1/2
--	2: home win 1
--	3: home lose 1/2
--	2: home lose 1
--	5: draw

SELECT 
	R.MatchID,
	m.homeid,
	m.awayid,	
	R.liveindicator, 
	ISNULL(M.LiveHomeScore, 0) AS LiveHomeScore, 
	ISNULL(M.LiveAwayScore, 0) AS LiveAwayScore,
	M.ShowTime,
	M.MatchCode,

	SUM(CASE WHEN R.bettype = @BettypeHDP AND R.FOffset = -1 THEN CASE R.WinLostStatus WHEN 1 THEN R.AwayLose/2 WHEN 2 THEN R.AwayLose WHEN 3 THEN R.HomeLose/2 WHEN 4 THEN R.HomeLose ELSE 0 END ELSE 0 END) AS WinLost_M1_HDP,
	SUM(CASE WHEN R.bettype = @BettypeHDP AND R.FOffset = 0 THEN CASE R.WinLostStatus WHEN 1 THEN R.AwayLose/2 WHEN 2 THEN R.AwayLose WHEN 3 THEN R.HomeLose/2 WHEN 4 THEN R.HomeLose ELSE 0 END ELSE 0 END) AS WinLost_0_HDP,
	SUM(CASE WHEN R.bettype = @BettypeHDP AND R.FOffset = 1 THEN CASE R.WinLostStatus WHEN 1 THEN R.AwayLose/2 WHEN 2 THEN R.AwayLose WHEN 3 THEN R.HomeLose/2 WHEN 4 THEN R.HomeLose ELSE 0 END ELSE 0 END) AS WinLost_1_HDP,

	SUM(CASE WHEN R.bettype = @BettypeOU AND R.FOffset = 0 THEN CASE R.WinLostStatus WHEN 1 THEN R.AwayLose/2 WHEN 2 THEN R.AwayLose WHEN 3 THEN R.HomeLose/2 WHEN 4 THEN R.HomeLose ELSE 0 END END) AS WinLost_0_OU,
	SUM(CASE WHEN R.bettype = @BettypeOU AND R.FOffset = 1 THEN CASE R.WinLostStatus WHEN 1 THEN R.AwayLose/2 WHEN 2 THEN R.AwayLose WHEN 3 THEN R.HomeLose/2 WHEN 4 THEN R.HomeLose ELSE 0 END END) AS WinLost_1_OU,
	SUM(CASE WHEN R.bettype = @BettypeOU AND R.FOffset = 2 THEN CASE R.WinLostStatus WHEN 1 THEN R.AwayLose/2 WHEN 2 THEN R.AwayLose WHEN 3 THEN R.HomeLose/2 WHEN 4 THEN R.HomeLose ELSE 0 END END) AS WinLost_2_OU,

	SUM(CASE WHEN R.bettype = @BettypeHTHDP AND R.FOffset = -1 THEN CASE R.WinLostStatus WHEN 1 THEN R.AwayLose/2 WHEN 2 THEN R.AwayLose WHEN 3 THEN R.HomeLose/2 WHEN 4 THEN R.HomeLose ELSE 0 END ELSE 0 END) AS WinLost_M1_HTHDP,
	SUM(CASE WHEN R.bettype = @BettypeHTHDP AND R.FOffset = 0 THEN CASE R.WinLostStatus WHEN 1 THEN R.AwayLose/2 WHEN 2 THEN R.AwayLose WHEN 3 THEN R.HomeLose/2 WHEN 4 THEN R.HomeLose ELSE 0 END ELSE 0 END) AS WinLost_0_HTHDP,
	SUM(CASE WHEN R.bettype = @BettypeHTHDP AND R.FOffset = 1 THEN CASE R.WinLostStatus WHEN 1 THEN R.AwayLose/2 WHEN 2 THEN R.AwayLose WHEN 3 THEN R.HomeLose/2 WHEN 4 THEN R.HomeLose ELSE 0 END ELSE 0 END) AS WinLost_1_HTHDP,

	SUM(CASE WHEN R.bettype = @BettypeHTOU AND R.FOffset = 0 THEN CASE R.WinLostStatus WHEN 1 THEN R.AwayLose/2 WHEN 2 THEN R.AwayLose WHEN 3 THEN R.HomeLose/2 WHEN 4 THEN R.HomeLose ELSE 0 END END) AS WinLost_0_HTOU,
	SUM(CASE WHEN R.bettype = @BettypeHTOU AND R.FOffset = 1 THEN CASE R.WinLostStatus WHEN 1 THEN R.AwayLose/2 WHEN 2 THEN R.AwayLose WHEN 3 THEN R.HomeLose/2 WHEN 4 THEN R.HomeLose ELSE 0 END END) AS WinLost_1_HTOU,
	SUM(CASE WHEN R.bettype = @BettypeHTOU AND R.FOffset = 2 THEN CASE R.WinLostStatus WHEN 1 THEN R.AwayLose/2 WHEN 2 THEN R.AwayLose WHEN 3 THEN R.HomeLose/2 WHEN 4 THEN R.HomeLose ELSE 0 END END) AS WinLost_2_HTOU,

	ISNULL(m.isNeutral, CONVERT(BIT, 0)) AS IsNeutral
FROM 	
	(
		SELECT 
			1 AS ForecastID, 
			F.bettype, 
			liveindicator, 
			'' AS status, 
			F.offset, 
			homelose, 
			awaylose, 
			BaseOffset + ForecastOffset.offset AS BaseOffset, 
			CASE 
				WHEN F.BetType IN (@BetTypeHDP, @BetTypeHTHDP) THEN
					CASE 
						WHEN F.VScoreHDP + BaseOffset + ForecastOffset.offset - F.Offset > 0 AND F.VScoreHDP + BaseOffset + ForecastOffset.offset - F.Offset < 0.5 THEN 1
						WHEN F.VScoreHDP + BaseOffset + ForecastOffset.offset - F.Offset > 0.25 THEN 2
						WHEN F.VScoreHDP + BaseOffset + ForecastOffset.offset - F.Offset < 0 AND F.VScoreHDP + BaseOffset + ForecastOffset.offset - F.Offset > -0.5 THEN 3
						WHEN F.VScoreHDP + BaseOffset + ForecastOffset.offset - F.Offset < -0.25 THEN 4
						ELSE 5
					END
				WHEN F.BetType IN (@BetTypeOU, @BetTypeHTOU) THEN
					CASE 
						WHEN F.VScoreOU + BaseOffset + ForecastOffset.offset - F.Offset = 0.25 THEN 1
						WHEN F.VScoreOU + BaseOffset + ForecastOffset.offset - F.Offset > 0.25 THEN 2
						WHEN F.VScoreOU + BaseOffset + ForecastOffset.offset - F.Offset = -0.25 THEN 3
						WHEN F.VScoreOU + BaseOffset + ForecastOffset.offset - F.Offset < -0.25 THEN 4
						ELSE 5
					END
			END AS WinlostStatus,
			F.MatchID, 
			ForecastOffset.Offset AS fOffset
		FROM (
				SELECT  
					@BetTypeHDP AS bettype, 
					x.LiveIndicator, 
					-x.hdp + score AS offset, 
					SUM(x.homewin - x.awaylose) AS AwayLose,
					SUM(x.awaywin - x.homelose) AS HomeLose,
					@BaseOffsetHDP AS BaseOffset,
					MatchID,
					VScoreHDP,
					VScoreOU
				FROM 
					(
						SELECT 
							b.currency, 
							b.hdp2 - b.hdp1 AS hdp, 
							b.livehomescore - b.liveawayscore AS score, 
							b.liveindicator,
							SUM(CASE WHEN betteam = 'h' THEN (CASE WHEN odds < 0 THEN 1 ELSE odds END) * b.Stake * (CASE WHEN @LoggedId = 1 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END) ELSE 0 END) AS homewin,
							SUM(CASE WHEN betteam = 'a' THEN (CASE WHEN odds < 0 THEN 1 ELSE odds END) * b.Stake * (CASE WHEN @LoggedId = 1 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END) ELSE 0 END) AS awaywin,
							SUM(CASE WHEN betteam = 'h' THEN (CASE WHEN odds < 0 THEN ABS(odds) ELSE 1 END) * b.Stake * (CASE WHEN @LoggedId = 1 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END) ELSE 0 END) AS homelose,
							SUM(CASE WHEN betteam = 'a' THEN (CASE WHEN odds < 0 THEN ABS(odds) ELSE 1 END) * b.Stake * (CASE WHEN @LoggedId = 1 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END) ELSE 0 END) AS awaylose,
							M.MatchID,
							ISNULL(o.livehomescore, 0) - ISNULL(o.liveawayscore, 0) AS VScoreHDP,
							ISNULL(o.livehomescore, 0) + ISNULL(o.liveawayscore, 0) AS VScoreOU
						FROM
							BetTrans_Agent AS ba WITH (NOLOCK)
							INNER JOIN BetTrans AS b WITH (NOLOCK) ON ba.TransId = b.TransId
							INNER JOIN Match AS M WITH (NOLOCK) ON b.MatchID = M.MatchID
							INNER JOIN Odds AS O WITH (NOLOCK) ON b.OddsID = O.OddsID
							INNER JOIN League AS L WITH (NOLOCK) ON M.LeagueID = L.LeagueID
						WHERE 
							ba.AgentId = @AgentId
							AND b.BetType = @BetTypeHDP
							AND b.StatusId IN (0, 1) -- status is waiting or running
							AND b.Ruben = 0	-- match not yet settle
							AND L.LeagueID = @LeagueID
						GROUP BY 
							b.Currency, 
							b.Hdp2 - b.Hdp1, 
							b.LiveHomeScore - b.LiveAwayScore, 
							b.LiveIndicator, 
							M.MatchId, 
							o.LiveHomeScore, 
							o.LiveAwayScore
					) AS x 
				GROUP BY 
					-x.hdp + score, 
					x.LiveIndicator, 
					MatchID, 
					VScoreHDP, 
					VScoreOU
				
				UNION ALL

				SELECT 
					@BetTypeOU AS bettype, 
					x.liveindicator, 
					x.hdp + score AS offset, 
					SUM(x.homewin - x.awaylose) AS AwayLose,
					SUM(x.awaywin - x.homelose) AS HomeLose,
					@BaseOffsetOU AS BaseOffset,
					MatchID,
					VScoreHDP,
					VScoreOU
				FROM 
					(
						SELECT 
							b.LiveIndicator,  
							b.Currency, 
							b.Hdp1 AS hdp, 
							0 AS score,
							SUM(CASE WHEN betteam = 'h' THEN (CASE WHEN odds < 0 THEN 1 ELSE odds END) * b.Stake * (CASE WHEN @LoggedId = 1 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END) ELSE 0 END) AS homewin,
							SUM(CASE WHEN betteam = 'a' THEN (CASE WHEN odds < 0 THEN 1 ELSE odds END) * b.Stake * (CASE WHEN @LoggedId = 1 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END) ELSE 0 END) AS awaywin,
							SUM(CASE WHEN betteam = 'h' THEN (CASE WHEN odds < 0 THEN ABS(odds) ELSE 1 END) * b.Stake * (CASE WHEN @LoggedId = 1 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END) ELSE 0 END) AS homelose,
							SUM(CASE WHEN betteam = 'a' THEN (CASE WHEN odds < 0 THEN ABS(odds) ELSE 1 END) * b.Stake * (CASE WHEN @LoggedId = 1 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END) ELSE 0 END) AS awaylose,
							M.MatchID,
							ISNULL(o.livehomescore, 0) - ISNULL(o.liveawayscore, 0) AS VScoreHDP,
							ISNULL(o.livehomescore, 0) + ISNULL(o.liveawayscore, 0) AS VScoreOU
						FROM 
							BetTrans_Agent AS ba WITH (NOLOCK)
							INNER JOIN BetTrans AS b WITH (NOLOCK) ON ba.TransId = b.TransId
							INNER JOIN Match AS M WITH (NOLOCK) ON b.MatchID = M.MatchID
							INNER JOIN Odds AS O WITH (NOLOCK) ON b.OddsID = O.OddsID
							INNER JOIN League AS L WITH (NOLOCK) ON M.LeagueID = L.LeagueID
						WHERE 
							ba.AgentId = @AgentId
							AND b.bettype = @BetTypeOU
							AND b.statusID IN (0, 1)	-- status is waiting or running
							AND b.ruben = 0	-- match not yet settle
							AND M.EventStatus = 'running'
							 AND L.LeagueID = @LeagueID
						GROUP BY 
							b.currency, 
							b.hdp1, 
							b.liveindicator, 
							M.MatchID, 
							o.livehomescore, 
							o.liveawayscore
					) AS x 
				GROUP BY 
					liveindicator, 
					x.score, 
					x.hdp, 
					MatchID, 
					VScoreHDP, 
					VScoreOU
--FIRST HALF HERE--------------------------------------------------------------------------------
				UNION ALL

				SELECT  
					@BetTypeHTHDP AS bettype, 
					x.liveindicator, 
					-x.hdp + score AS offset, 
					SUM(x.homewin - x.awaylose) AS AwayLose,
					SUM(x.awaywin - x.homelose) AS HomeLose,
					@BaseOffsetHTHDP AS BaseOffset,
					MatchID,
					VScoreHDP,
					VScoreOU
				FROM 
					(
						SELECT 
							b.currency, b.hdp2 - b.hdp1 hdp, b.livehomescore - b.liveawayscore AS score, b.liveindicator,
							SUM(CASE WHEN betteam = 'h' THEN (CASE WHEN odds < 0 THEN 1 ELSE odds END) * b.Stake * (CASE WHEN @LoggedId = 1 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END) ELSE 0 END) AS homewin,
							SUM(CASE WHEN betteam = 'a' THEN (CASE WHEN odds < 0 THEN 1 ELSE odds END) * b.Stake * (CASE WHEN @LoggedId = 1 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END) ELSE 0 END) AS awaywin,
							SUM(CASE WHEN betteam = 'h' THEN (CASE WHEN odds < 0 THEN ABS(odds) ELSE 1 END) * b.Stake * (CASE WHEN @LoggedId = 1 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END) ELSE 0 END) AS homelose,
							SUM(CASE WHEN betteam = 'a' THEN (CASE WHEN odds < 0 THEN ABS(odds) ELSE 1 END) * b.Stake * (CASE WHEN @LoggedId = 1 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END) ELSE 0 END) AS awaylose,
							M.MatchID,
							ISNULL(o.livehomescore, 0) - ISNULL(o.liveawayscore, 0) AS VScoreHDP,
							ISNULL(o.livehomescore, 0) + ISNULL(o.liveawayscore, 0) AS VScoreOU
						FROM 
							BetTrans_Agent AS ba WITH (NOLOCK)
							INNER JOIN BetTrans AS b WITH (NOLOCK) ON ba.TransId = b.TransId
							INNER JOIN Match AS M WITH (NOLOCK) ON b.MatchID = M.MatchID
							INNER JOIN Odds AS O WITH (NOLOCK) ON b.OddsID = O.OddsID
							INNER JOIN League AS L WITH (NOLOCK) ON M.LeagueID = L.LeagueID
						WHERE 
							ba.AgentId = @AgentId
							AND b.BetType = @BetTypeHTHDP
							AND b.StatusId IN (0, 1)	-- status is waiting or running
							AND b.Ruben = 0	-- match not yet settle
							AND L.LeagueID = @LeagueID
						GROUP BY
							b.currency, 
							b.hdp2 - b.hdp1, 
							b.livehomescore - b.liveawayscore, 
							b.liveindicator, 
							M.MatchID, 
							o.livehomescore, 
							o.liveawayscore
					) AS x 
				GROUP BY 
					-x.hdp + score, 
					x.liveindicator, 
					MatchID, 
					VScoreHDP, 
					VScoreOU
				
				UNION ALL

				SELECT 
					@BetTypeHTOU AS bettype, 
					x.liveindicator, 
					x.hdp + score AS offset, 
					SUM(x.homewin - x.awaylose) AS AwayLose,
					SUM(x.awaywin - x.homelose) AS HomeLose,
					@BaseOffsetHTOU AS BaseOffset,
					MatchID,
					VScoreHDP,
					VScoreOU
				FROM 
					(
						SELECT 
							b.liveindicator,
							b.currency, 
							b.hdp1 AS hdp, 
							0 AS score,
							SUM(CASE WHEN betteam = 'h' THEN (CASE WHEN odds < 0 THEN 1 ELSE odds END) * b.Stake * (CASE WHEN @LoggedId = 1 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END) ELSE 0 END) AS homewin,
							SUM(CASE WHEN betteam = 'a' THEN (CASE WHEN odds < 0 THEN 1 ELSE odds END) * b.Stake * (CASE WHEN @LoggedId = 1 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END) ELSE 0 END) AS awaywin,
							SUM(CASE WHEN betteam = 'h' THEN (CASE WHEN odds < 0 THEN ABS(odds) ELSE 1 END) * b.Stake * (CASE WHEN @LoggedId = 1 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END) ELSE 0 END) AS homelose,
							SUM(CASE WHEN betteam = 'a' THEN (CASE WHEN odds < 0 THEN ABS(odds) ELSE 1 END) * b.Stake * (CASE WHEN @LoggedId = 1 THEN (1-b.TPositionTaking) ELSE ba.APositionTaking END) ELSE 0 END) AS awaylose,
							M.MatchID,
							ISNULL(o.livehomescore, 0) - ISNULL(o.liveawayscore, 0) AS VScoreHDP,
							ISNULL(o.livehomescore, 0) + ISNULL(o.liveawayscore, 0) AS VScoreOU
						FROM 
							BetTrans_Agent AS ba WITH (NOLOCK)
							INNER JOIN BetTrans AS b WITH (NOLOCK) ON ba.TransId = b.TransId
							INNER JOIN Match AS M WITH (NOLOCK) ON b.MatchID = M.MatchID
							INNER JOIN Odds AS O WITH (NOLOCK) ON b.OddsID = O.OddsID
							INNER JOIN League AS L WITH (NOLOCK) ON M.LeagueID = L.LeagueID
						WHERE 
							ba.AgentId = @AgentId
							AND b.bettype = @BetTypeHTOU
							AND b.statusID IN (0, 1)	-- status is waiting or running
							AND b.ruben = 0	-- match not yet settle
							AND M.EventStatus = 'running'
							AND L.LeagueID = @LeagueID
						GROUP BY 
							b.currency, 
							b.hdp1, 
							b.liveindicator, 
							M.MatchID, 
							o.livehomescore, 
							o.liveawayscore
					) AS x 
				GROUP BY 
					liveindicator, 
					x.score, 
					x.hdp, 
					MatchID, 
					VScoreHDP, 
					VScoreOU
			) AS F 
			INNER JOIN 	(
				SELECT 1 AS bettype, -1 AS offset UNION ALL
				SELECT 1 AS bettype, 0 AS offset UNION ALL
				SELECT 1 AS bettype, 1 AS offset UNION ALL
				SELECT 3 AS bettype, 0 AS offset UNION ALL
				SELECT 3 AS bettype, 1 AS offset UNION ALL
				SELECT 3 AS bettype, 2 AS offset UNION ALL
				SELECT 7 AS bettype, -1 AS offset UNION ALL
				SELECT 7 AS bettype, 0 AS offset UNION ALL
				SELECT 7 AS bettype, 1 AS offset UNION ALL
				SELECT 8 AS bettype, 0 AS offset UNION ALL
				SELECT 8 AS bettype, 1 AS offset UNION ALL
				SELECT 8 AS bettype, 2 AS offset
			) AS ForecastOffset ON F.bettype = ForecastOffset.bettype
	) AS R 
	INNER JOIN Match AS M WITH (NOLOCK) ON R.MatchID = M.MatchID
GROUP BY 
	R.MatchID,
	R.liveindicator, 
	m.homeid,
	m.awayid,
	M.LiveHomeScore, 
	M.LiveAwayScore, 
	M.ShowTime, 
	M.MatchCode,
	m.isNeutral
ORDER BY 
	R.LiveIndicator DESC, 
	M.MatchCode

