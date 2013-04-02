USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_ScoreMap_Result]    Script Date: 4/1/2013 4:56:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_ScoreMap_Result]
	@AgentId			INT,
	@MatchIds			VARCHAR(4000)	= '',
	@Bettypes_Live		VARCHAR(500),
	@Bettypes_Dead		VARCHAR(500),
	@HomeBeginScore		INT				= 0,
	@HomeEndScore		INT				= 6,
	@AwayBeginScore		INT				= 0,
	@AwayEndScore		INT				= 6
AS

/**
 * Created by	: Terry.Nguyen
 * Date			: 20130228
 * Task			: Get data for ScoreMap
 * DB			: APL.TransDB
 * Revisions	:
 *	• 20132801@Terry.Nguyen	: Implement
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN

	DECLARE @tmpScores TABLE(
		home INT, 
		away INT)

	DECLARE @tmpBettrans TABLE(
		transid			BIGINT			PRIMARY KEY, 
		betteam			NVARCHAR(10), 
		matchid			INT, 
		custid			INT, 
		bettype			SMALLINT, 
		hdp1			SMALLMONEY, 
		hdp2			SMALLMONEY, 
		odds			SMALLMONEY, 
		stake			MONEY, 
		liveindicator	BIT, 
		livehomescore	SMALLINT, 
		liveawayscore	SMALLINT, 
		apositiontaking SMALLMONEY)

	-- get scores template
	INSERT INTO @tmpScores (home, away) 
	SELECT 
		home, 
		away 
	FROM Scores WITH (NOLOCK) 
	WHERE 
		(home BETWEEN @homeBeginScore AND @homeEndScore) 
		AND (away BETWEEN @awayBeginScore AND @awayEndScore )
	
	-- get member tickets INTO temp TABLE	
	INSERT INTO @tmpBettrans 
	SELECT 
		ba.TransId, 
		BetTeam, 
		b.MatchId, 
		AgentId, 
		ba.BetType, 
		Hdp1, 
		Hdp2, 
		b.Odds, 
		ba.Stake, 
		LiveIndicator, 
		b.LiveHomeScore, 
		b.LiveAwayScore, 
		APositionTaking
	FROM 
		BetTrans_Agent AS ba WITH (NOLOCK) 
		INNER JOIN BetTrans AS b WITH (NOLOCK) ON ba.TransId = b.TransId
	WHERE 
		b.MatchId IN (SELECT val FROM strSplit(@MatchIds, ','))
		AND ba.AgentId = @AgentId
		AND (( ba.BetType IN (SELECT val FROM strSplit(@Bettypes_Live, ',')) AND liveindicator = 1) 
				OR (ba.BetType IN (SELECT val FROM strSplit(@Bettypes_Dead, ',')) AND liveindicator = 0)
			)
		AND b.ruben = 0
		AND ba.StatusId IN (0, 1)
		AND APositionTaking > 0 
		
	SELECT 
		matchid, 
		home, 
		away,
		ISNULL(-SUM(CASE
					WHEN r <= -0.5 AND bt IN (1, 3, 7, 8) THEN 1
					WHEN r < 0 AND bt IN (1, 3, 7, 8, 25) THEN 1 + (r * 2)
					ELSE 0
				END * risk) + 
				SUM(CASE
					WHEN r >= 0.5 AND bt IN (1, 3, 7, 8) THEN 1
					WHEN r > 0 AND bt IN (1, 3, 7, 8) THEN 1 - (r * 2)
					ELSE 0
				END * risk * trueodds), 0) +
				ISNULL(-SUM(CASE
					WHEN r = 0 AND bt IN (2, 4, 5, 6, 12, 13, 15, 24, 26, 27, 28, 30, 123)THEN 1
					WHEN r = 0 AND bt IN (20, 21, 25) AND home <> away THEN 1
					WHEN r = 0 AND bt = 121 THEN CASE WHEN home > away THEN 0 ELSE 1 END
					WHEN r = 0 AND bt = 122 THEN CASE WHEN away > home THEN 0 ELSE 1 END
					ELSE 0
				END * risk)	+ 
				SUM(CASE
					WHEN r = 1 AND bt IN (2, 4, 5, 6, 12, 13, 15, 20, 21, 24, 25, 26, 27, 28, 30, 121, 122, 123)THEN 1
					ELSE 0
				END * risk * trueodds),0) AS total
	FROM
		(
			SELECT 
				matchid, 
				home, 
				away,
				r.risk,
				r.trueodds,
				CASE 
					WHEN betteam = 'h' AND bt IN (1, 7) THEN (home + hc) - away 
					WHEN betteam <> 'h' AND bt IN (1, 7) THEN (away + hc) - home 
					WHEN betteam = 'h' AND bt IN (2, 12) THEN (home + away)&1  
					WHEN betteam <> 'h' AND bt IN (2, 12) THEN 1-( (home + away)&1)
					WHEN betteam = 'h' AND bt IN (3, 8) THEN (home + away) - hc 
					WHEN betteam <> 'h' AND bt IN (3, 8) THEN hc - (home + away)
					WHEN home < 5 AND away < 5 AND hc = home AND hd = away AND bt IN (4, 30) THEN 1  
					WHEN (home >= 5 AND hc = 5 AND home - away >= hc) OR (away >= 5 AND hd = 5 AND away - home >= hd) AND bt IN (4, 30) THEN 1
					WHEN home > away AND betteam = '1' AND bt IN (5, 15) THEN 1 
					WHEN away > home AND betteam = '2' AND bt IN (5, 15) THEN 1
					WHEN home = away AND betteam = 'x' AND bt IN (5, 15) THEN 1 
					WHEN home + away >= hc AND home + away <= hd AND bt = 6 THEN 1
					WHEN betteam = 'hy' AND away = 0 AND bt = 13 THEN 1
					WHEN betteam = 'hn' AND away > 0 AND bt = 13 THEN 1
					WHEN betteam = 'ay' AND home = 0 AND bt = 13 THEN 1
					WHEN betteam = 'an' AND home > 0 AND bt = 13 THEN 1
					WHEN home > away AND betteam = 'h' AND bt IN (20, 21) THEN 1
					WHEN away > home AND betteam = 'a' AND bt IN (20, 21) THEN 1
					WHEN betteam = '1x' AND (home >= away) AND bt = 24 THEN 1
					WHEN betteam = '2x' AND (away >= home) AND bt = 24 THEN 1
					WHEN betteam = '12' AND (home <> away) AND bt = 24 THEN 1
					WHEN betteam = 'h' AND (home > away) AND bt = 25 THEN 1
					WHEN betteam = 'a' AND (away > home) AND bt = 25 THEN 1
					WHEN betteam = 'n' AND home = 0 AND away = 0 AND bt= 26 THEN 1
					WHEN betteam = 'o' AND (home = 0 or away = 0) AND home + away >= 1 AND bt= 26 THEN 1
					WHEN betteam = 'b' AND home + away >= 2 AND home <> 0 AND away <> 0  AND bt= 26 THEN 1
					WHEN betteam = 'h' AND away = 0 AND home >= 1 AND bt = 27 THEN 1
					WHEN betteam = 'a' AND home = 0 AND away >= 1 AND bt = 27 THEN 1
					WHEN betteam = '1' AND hc + home - away > 0 AND  bt = 28 THEN 1 
					WHEN betteam = '2' AND hc + away - home > 0 AND  bt = 28 THEN 1
					WHEN betteam = 'x' AND hc - (home - away) = 0 AND bt = 28 THEN 1
					WHEN betteam = 'x' AND home = away AND bt = 121 THEN 1
					WHEN betteam = 'a' AND away > home AND bt = 121 THEN 1
					WHEN betteam = 'h' AND home > away AND bt = 122 THEN 1
					WHEN betteam = 'x' AND home = away AND bt = 122 THEN 1
					WHEN betteam = 'h' AND home = away AND bt = 123 THEN 1
					WHEN betteam = 'a' AND home <> away AND bt = 123 THEN 1
					ELSE 0
				END AS r,
				bt
		FROM 
			@tmpScores CROSS JOIN 
			(
				SELECT
					matchid, 
					betteam,
					SUM((stake * apositiontaking * CASE WHEN odds < 0 THEN -odds ELSE 1 END) * CASE WHEN odds < 0 THEN 1/-CAST(odds AS FLOAT) ELSE odds END ) / SUM(stake * apositiontaking * CASE WHEN odds < 0 THEN -odds ELSE 1 END) AS trueodds,
					SUM(stake * apositiontaking * CASE WHEN odds < 0 THEN -odds ELSE 1 END) AS risk,
					CASE 
						WHEN betteam = 'h' AND liveindicator = 1 THEN (hdp2 + liveawayscore) - (hdp1 + livehomescore)
						WHEN betteam = 'h' AND liveindicator <> 1 THEN hdp2 - hdp1
						WHEN betteam <> 'h' AND liveindicator = 1 THEN (hdp1 + livehomescore) - (hdp2 + liveawayscore) 
						ELSE hdp1 - hdp2	 
					END AS hc,
					0 AS hd,
					bettype AS bt
				FROM @tmpBettrans
				WHERE bettype IN (1, 7)
				GROUP BY 
					betteam, 
					bettype, 
					hdp1, 
					hdp2, 
					liveindicator, 
					livehomescore, 
					liveawayscore,
					matchid
				
				UNION ALL
				
				SELECT
					matchid, 
					betteam,
					SUM( (stake * apositiontaking * CASE WHEN odds < 0 THEN -odds ELSE 1 END ) * CASE WHEN odds <0 THEN 1/-CAST(odds AS FLOAT) ELSE odds END ) / SUM(stake * apositiontaking * CASE WHEN odds < 0 THEN -odds ELSE 1 END) trueodds,
					SUM(stake * apositiontaking * CASE WHEN odds < 0 THEN -odds ELSE 1 END) AS risk,
					0 AS hc,
					0 AS hd,
					bettype AS bt
				FROM @tmpBettrans b 
				WHERE bettype IN (2, 12)
				GROUP BY 
					betteam, 
					bettype, 
					hdp1, 
					matchid

				UNION ALL

				SELECT
					matchid, 
					betteam,
					SUM((stake * apositiontaking * CASE WHEN odds < 0 THEN -odds ELSE 1 END) * CASE WHEN odds < 0 THEN 1/-CAST(odds AS FLOAT) ELSE odds END ) / SUM( (stake * apositiontaking *CASE WHEN odds < 0 THEN -odds ELSE 1 END) ) trueodds,
					SUM(stake * apositiontaking * CASE WHEN odds < 0 THEN -odds ELSE 1 END) AS risk,
					hdp1,
					0 AS hd,
					bettype AS bt
				FROM @tmpBettrans b 
				WHERE bettype IN (3, 8)
				GROUP BY 
					betteam, 
					bettype, 
					hdp1, 
					liveindicator, 
					livehomescore, 
					liveawayscore, 
					matchid

				UNION ALL

				SELECT
					matchid, 
					betteam,
					SUM(stake * apositiontaking * (odds - 1)) / SUM(stake * apositiontaking) AS trueodds,
					SUM(stake * apositiontaking) AS risk,
					hdp1,
					hdp2,
					bettype AS bt
				FROM @tmpBettrans
				WHERE bettype IN (4, 30)
				GROUP BY 
					betteam, 
					bettype, 
					hdp1,
					hdp2, 
					matchid

				UNION ALL

				SELECT
					matchid, 
					betteam,
					SUM(stake * apositiontaking * (odds - 1)) / SUM(stake * apositiontaking) AS trueodds,
					SUM(stake * apositiontaking) AS risk,
					0 AS hc,
					0 AS hd,
					bettype AS bt
				FROM @tmpBettrans 
				WHERE bettype IN (5, 15)
				GROUP BY 
					betteam, 
					bettype, 
					matchid

				UNION ALL

				SELECT
					matchid, 
					betteam, 
					SUM(stake * apositiontaking * (odds - 1)) / SUM(stake * apositiontaking) AS trueodds,
					SUM(stake * apositiontaking) AS risk,
					CAST(LEFT(betteam, 1) AS INT) AS hc,
					CASE RIGHT(betteam, 1) 
						WHEN 'r' THEN 999
						ELSE CAST(RIGHT(betteam, 1) AS INT) 
					END AS hd,
					6 AS bt
				FROM @tmpBettrans
				WHERE bettype = 6
				GROUP BY 
					betteam, 
					matchid
							
				UNION ALL

				SELECT
					matchid, 
					betteam, 
					SUM(stake * apositiontaking * (odds - 1)) / SUM(stake * apositiontaking) AS trueodds,
					SUM(stake * apositiontaking) AS risk,
					0 AS hc,
					0 AS hd,
					13 AS bt
				FROM @tmpBettrans
				WHERE bettype = 13
				GROUP BY 
					betteam, 
					matchid

				UNION ALL

				SELECT
					matchid, 
					betteam,
					SUM((stake * apositiontaking * CASE WHEN odds < 0 THEN -odds ELSE 1 END ) * CASE WHEN odds < 0 THEN 1/-CAST(odds AS FLOAT) ELSE odds END ) / SUM(stake * apositiontaking * CASE WHEN odds < 0 THEN -odds ELSE 1 END) AS trueodds,
					SUM(stake * apositiontaking * CASE WHEN odds < 0 THEN -odds ELSE 1 END) AS risk,
					0 AS hc,
					0 AS hd,
					bettype AS bt
				FROM @tmpBettrans
				WHERE bettype IN (20, 21)
				GROUP BY 
					betteam, 
					bettype, 
					matchid

				UNION ALL

				SELECT
					matchid, 
					betteam, 
					SUM(stake * apositiontaking * (odds - 1)) / SUM(stake * apositiontaking) AS trueodds,
					SUM(stake * apositiontaking) AS risk,
					0 AS hc,
					0 AS hd,
					24 AS bt
				FROM @tmpBettrans
				WHERE bettype = 24
				GROUP BY 
					betteam, 
					matchid

				UNION ALL

				SELECT
					matchid, 
					betteam, 
					SUM(stake * apositiontaking * (odds - 1)) / SUM(stake * apositiontaking) AS trueodds,
					SUM(stake * apositiontaking ) AS risk,
					0 AS hc,
					0 AS hd,
					25 AS bt
				FROM @tmpBettrans
				WHERE bettype = 25
				GROUP BY 
					betteam, 
					matchid

				UNION ALL

				SELECT
					matchid, 
					betteam, 
					SUM(stake * apositiontaking * (odds - 1)) / SUM(stake * apositiontaking) AS trueodds,
					SUM(stake * apositiontaking) AS risk,
					0 AS hc,
					0 AS hd,
					26 AS bt
				FROM @tmpBettrans
				WHERE bettype = 26
				GROUP BY 
					betteam, 
					matchid

				UNION ALL

				SELECT
					matchid, 
					betteam, 
					SUM(stake * apositiontaking * (odds - 1)) / SUM(stake * apositiontaking) AS trueodds,
					SUM(stake * apositiontaking) AS risk,
					0 AS hc,
					0 AS hd,
					27 AS bt
				FROM @tmpBettrans
				WHERE bettype = 27
				GROUP BY 
					betteam, 
					matchid 

				UNION ALL

				SELECT
					matchid, 
					betteam, 
					SUM(stake * apositiontaking * (odds - 1)) / SUM(stake * apositiontaking) AS trueodds,
					SUM(stake * apositiontaking) AS risk,
					CASE 
						WHEN betteam = '1' THEN hdp2 - hdp1
						ELSE hdp1 - hdp2	 
					END AS hc,
					0 AS hd,
					28 AS bt
				FROM @tmpBettrans
				WHERE bettype = 28
				GROUP BY 
					betteam, 
					hdp1, 
					hdp2, 
					matchid

				UNION ALL

				SELECT	
					matchid, 
					betteam,
					SUM(stake * apositiontaking * (odds - 1)) / SUM(stake * apositiontaking) AS trueodds,
					SUM(stake * apositiontaking) AS risk,
					0 AS hc,
					0 AS hd,
					bettype AS bt
				FROM @tmpBettrans
				WHERE bettype IN (121, 122, 123)
				GROUP BY 
					betteam, 
					bettype,
					matchid
			) AS r
		) AS u
	GROUP BY 
		home, 
		away, 
		matchid
	ORDER BY 
		matchid,
		away, 
		home
	
		-- get matchs to refer in score map
	SELECT 
		matchid, 
		homeid, 
		awayid
	FROM match WITH (NOLOCK)
	WHERE 
		eventstatus <> 'completed'
		AND matchid IN (SELECT val FROM strSplit(@matchids, ','))

END

