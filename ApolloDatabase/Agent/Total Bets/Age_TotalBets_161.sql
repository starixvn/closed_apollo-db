USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_TotalBets_161]    Script Date: 4/26/2013 11:18:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_TotalBets_161]
	@AgentId	INT
AS

/**
 * Created by	: Terry.Nguyen
 * Date			: 20130228
 * TASk			: Get Total Bets(Number Game) data for Agent
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	• 20132801@Terry.Nguyen	: Implement
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN

	SET NOCOUNT ON

	SELECT 
		m.showtime, 
		m.leagueID,
		m.matchcode, 
		m.matchid,

		SUM(over_1stBall) AS Over1stBall,
		SUM(under_1stBall) AS Under1stBall,
		SUM(over_lastBall) AS OverLastBall,
		SUM(under_lastBall) AS UnderLastBall,
		SUM(odd_1stBall) AS Odd1stBall,
		SUM(even_1stBall) AS Even1stBall,
		SUM(odd_lastBall) AS OddLastBall,
		SUM(even_lastBall) AS EvenLastBall,
		SUM(odd_fullTime) AS OddFullTime,
		SUM(even_fullTime) AS EvenFullTime,
		SUM(over_next) AS OverNext,
		SUM(under_next) AS UnderNext,
		SUM(odd_next) AS OddNext,
		SUM(even_next) AS EvenNext,
		SUM(high) AS high,
		SUM(low) AS low,
		SUM(Warrior_2ndBall) AS Warrior2ndBall,
		SUM(Warrior_3rdBall) AS Warrior3rdBall,
		SUM(NextCombo_OverOdd) AS NextComboOverOdd,
		SUM(NextCombo_OverEven) AS NextComboOverEven,
		SUM(NextCombo_UnderOdd) AS NextComboUnderOdd ,
		SUM(NextCombo_UnderEven) AS NextComboUnderEven,
		SUM(NumberGroupPre) AS NumberGroupPre,
		SUM(NumberGroupLive) AS NumberGroupLive,
		
		SUM(betCOUNT_OU1stBall) AS BetCountOU1stBall,
		SUM(betCOUNT_OULastBall) AS BetCountOULastBall,
		SUM(betCOUNT_OE1stBall) AS BetCountOE1stBall,
		SUM(betCOUNT_OElastBall) AS BetCountOELastBall,
		SUM(betCOUNT_OEfullTime) AS BetCountOEFullTime,
		SUM(betCOUNT_OUNext) AS BetCountOUNext,
		SUM(betCOUNT_OENext) AS BetCountOENext,
		SUM(betCOUNT_highlow) AS BetCountHighLow,
		SUM(betCOUNT_Warrior_2ndBall) AS BetCountWarrior2ndBall,
		SUM(betCOUNT_Warrior_3rdBall) AS BetCountWarrior3rdBall,
		SUM(betCOUNT_NextCombo_OverOdd) AS BetCountNextComboOverOdd,
		SUM(betCOUNT_NextCombo_OverEven) AS BetCountNextComboOverEven,
		SUM(betCOUNT_NextCombo_UnderOdd) AS BetCountNextComboUnderOdd,
		SUM(betCOUNT_NextCombo_UnderEven) AS BetCountNextComboUnderEven,
		SUM(betCOUNT_NumberGroupPre) AS BetCountNumberGroupPre,
		SUM(betCOUNT_NumberGroupLive) AS BetCountNumberGroupLive
	FROM (
		SELECT
			m.showtime, 
			m.leagueID,
			m.matchcode,
			bb.liveindicator,
			m.matchid,

			SUM(CASE WHEN bettype = 81 AND betteam = 'h' THEN Stake ELSE 0 END) AS over_1stBall,
			SUM(CASE WHEN bettype = 81 AND betteam = 'a' THEN Stake ELSE 0 END) AS under_1stBall,
			SUM(CASE WHEN bettype = 82 AND betteam = 'h' THEN Stake ELSE 0 END) AS over_lastBall,
			SUM(CASE WHEN bettype = 82 AND betteam = 'a' THEN Stake ELSE 0 END) AS under_lastBall,
			SUM(CASE WHEN bettype = 83 AND betteam = 'h' THEN Stake ELSE 0 END) AS odd_1stBall,
			SUM(CASE WHEN bettype = 83 AND betteam = 'a' THEN Stake ELSE 0 END) AS even_1stBall,
			SUM(CASE WHEN bettype = 84 AND betteam = 'h' THEN Stake ELSE 0 END) AS odd_lastBall,
			SUM(CASE WHEN bettype = 84 AND betteam = 'a' THEN Stake ELSE 0 END) AS even_lastBall,
		
			SUM(CASE WHEN bettype = 86 AND betteam = 'h' AND bb.liveindicator = 0 THEN Stake ELSE 0 END) AS odd_fullTime,
			SUM(CASE WHEN bettype = 86 AND betteam = 'a' AND bb.liveindicator = 0 THEN Stake ELSE 0 END) AS even_fullTime,

			SUM(CASE WHEN bettype = 85 AND betteam = 'h' AND bb.liveindicator = 1 THEN Stake ELSE 0 END) AS over_next,
			SUM(CASE WHEN bettype = 85 AND betteam = 'a' AND bb.liveindicator = 1 THEN Stake ELSE 0 END) AS under_next,
			SUM(CASE WHEN bettype = 86 AND betteam = 'h' AND bb.liveindicator = 1 THEN Stake ELSE 0 END) AS odd_next,
			SUM(CASE WHEN bettype = 86 AND betteam = 'a' AND bb.liveindicator = 1 THEN Stake ELSE 0 END) AS even_next,
			SUM(CASE WHEN bettype = 87 AND betteam = 'h' THEN Stake ELSE 0 END) AS high,
			SUM(CASE WHEN bettype = 87 AND betteam = 'a' THEN Stake ELSE 0 END) AS low,

			SUM(CASE WHEN bettype = 88 AND betteam = 'h' THEN Stake ELSE 0 END) AS Warrior_2ndBall,
			SUM(CASE WHEN bettype = 88 AND betteam = 'a' THEN Stake ELSE 0 END) AS Warrior_3rdBall,

			SUM(CASE WHEN bettype = 89 AND betteam = '1:1' THEN Stake ELSE 0 END) AS NextCombo_OverOdd ,
			SUM(CASE WHEN bettype = 89 AND betteam = '1:2' THEN Stake ELSE 0 END) AS NextCombo_OverEven,
			SUM(CASE WHEN bettype = 89 AND betteam = '2:1' THEN Stake ELSE 0 END) AS NextCombo_UnderOdd ,
			SUM(CASE WHEN bettype = 89 AND betteam = '2:2' THEN Stake ELSE 0 END) AS NextCombo_UnderEven,

			SUM(CASE WHEN bettype = 90 AND bb.liveindicator = 0 THEN Stake ELSE 0 END) AS NumberGroupPre,
			SUM(CASE WHEN bettype = 90 AND bb.liveindicator = 1 THEN Stake ELSE 0 END) AS NumberGroupLive,

			SUM(CASE WHEN bettype = 81 THEN BetCOUNT ELSE 0 END) AS betCOUNT_OU1stBall,
			SUM(CASE WHEN bettype = 82 THEN BetCOUNT ELSE 0 END) AS betCOUNT_OULastBall,
			SUM(CASE WHEN bettype = 83 THEN BetCOUNT ELSE 0 END) AS betCOUNT_OE1stBall,
			SUM(CASE WHEN bettype = 84 THEN BetCOUNT ELSE 0 END) AS betCOUNT_OElastBall,

			SUM(CASE WHEN bettype = 86 AND bb.liveindicator = 0 THEN BetCOUNT ELSE 0 END) AS betCOUNT_OEfullTime,

			SUM(CASE WHEN bettype = 85 AND bb.liveindicator = 1 THEN BetCOUNT ELSE 0 END) AS betCOUNT_OUNext,
			SUM(CASE WHEN bettype = 86 AND bb.liveindicator = 1 THEN BetCOUNT ELSE 0 END) AS betCOUNT_OENext,
			SUM(CASE WHEN bettype = 87 THEN BetCOUNT ELSE 0 END) AS betCOUNT_highlow,

			SUM(CASE WHEN bettype = 88 AND betteam = 'h' THEN BetCOUNT ELSE 0 END) AS betCOUNT_Warrior_2ndBall,
			SUM(CASE WHEN bettype = 88 AND betteam = 'a' THEN BetCOUNT ELSE 0 END) AS betCOUNT_Warrior_3rdBall,
			SUM(CASE WHEN bettype = 89 AND betteam = '1:1' THEN BetCOUNT ELSE 0 END) AS betCOUNT_NextCombo_OverOdd,
			SUM(CASE WHEN bettype = 89 AND betteam = '1:2' THEN BetCOUNT ELSE 0 END) AS betCOUNT_NextCombo_OverEven,
			SUM(CASE WHEN bettype = 89 AND betteam = '2:1' THEN BetCOUNT ELSE 0 END) AS betCOUNT_NextCombo_UnderOdd,
			SUM(CASE WHEN bettype = 89 AND betteam = '2:2' THEN BetCOUNT ELSE 0 END) AS betCOUNT_NextCombo_UnderEven,

			SUM(CASE WHEN bettype = 90 AND bb.liveindicator = 0 THEN BetCOUNT ELSE 0 END) AS betCOUNT_NumberGroupPre,
			SUM(CASE WHEN bettype = 90 AND bb.liveindicator = 1 THEN BetCOUNT ELSE 0 END) AS betCOUNT_NumberGroupLive
		FROM
			(SELECT 
				ba.MatchId, 
				ba.BetType, 
				betteam,
				liveindicator,
				SUM(ba.APositionTaking * ba.Stake * CASE WHEN ABS(b.Odds) < 1 THEN 1 ELSE ABS(b.Odds) END) AS Stake,
				COUNT(1) AS BetCOUNT
			FROM 
				BetTrans_Agent AS ba WITH (NOLOCK) 
				INNER JOIN BetTrans AS b WITH (NOLOCK) ON ba.TransId = b.TransId
			WHERE
				ba.BetType BETWEEN 81 AND 120
				AND ba.AgentId = @AgentId
				AND ba.StatusId IN (0, 1)
				AND b.Ruben = 0
			GROUP BY 
				ba.MatchId, 
				ba.BetType, 
				betteam,
				liveindicator) AS bb
			INNER JOIN match AS m WITH (NOLOCK) ON m.matchid = bb.MatchId
		WHERE m.eventstatus = 'running'
		GROUP BY
			m.showtime, 
			m.leagueID,
			m.matchcode,
			bb.LiveIndicator,
			m.matchid) AS m
	GROUP BY	
		m.showtime, 
		m.leagueID,
		m.matchcode,
		m.matchid
	ORDER BY m.matchcode

END

