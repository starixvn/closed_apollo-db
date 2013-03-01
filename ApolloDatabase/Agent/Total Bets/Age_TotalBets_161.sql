USE [DB05]
GO
/****** Object:  StoredProcedure [dbo].[Age_TotalBets_161]    Script Date: 3/1/2013 6:26:09 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[Age_TotalBets_161]
	@AgentId		INT

/**
 * Created by	: Terry.Nguyen
 * Date			: 20130228
 * TASk			: Get Total Bets(Number Game) data for Agent
 * DB			: APL.TransDB
 * Revisions	:
 *	• 20132801@Terry.Nguyen	: Implement
 * Parameters:
 *	•
 *	•
 *  
 */

AS
BEGIN
	SELECT 
		m.showtime, m.leagueID,	m.matchcode, m.matchid,
		SUM( over_1stBall) over_1stBall,
		SUM( under_1stBall) under_1stBall,
		SUM( over_lastBall) over_lastBall,
		SUM( under_lastBall) under_lastBall,
		SUM( odd_1stBall) odd_1stBall,
		SUM( even_1stBall) even_1stBall,
		SUM( odd_lastBall) odd_lastBall,
		SUM( even_lastBall) even_lastBall,
		SUM( odd_fullTime) odd_fullTime,
		SUM( even_fullTime) even_fullTime,
		SUM( over_next) over_next,
		SUM( under_next) under_next,
		SUM( odd_next) odd_next,
		SUM( even_next) even_next,		
		SUM( high) high,
		SUM( low) low,
		SUM( Warrior_2ndBall) Warrior_2ndBall,
		SUM( Warrior_3rdBall) Warrior_3rdBall,
		SUM( NextCombo_OverOdd) NextCombo_OverOdd,
		SUM( NextCombo_OverEven) NextCombo_OverEven,
		SUM( NextCombo_UnderOdd) NextCombo_UnderOdd ,
		SUM( NextCombo_UnderEven) NextCombo_UnderEven,
		SUM( NumberGroupPre) NumberGroupPre,
		SUM( NumberGroupLive) NumberGroupLive,
		
		SUM( betCOUNT_OU1stBall) betCOUNT_OU1stBall,
		SUM( betCOUNT_OULastBall) betCOUNT_OULastBall,
		SUM( betCOUNT_OE1stBall) betCOUNT_OE1stBall,
		SUM( betCOUNT_OElastBall) betCOUNT_OElastBall,		
		SUM( betCOUNT_OEfullTime) betCOUNT_OEfullTime,		
		SUM( betCOUNT_OUNext) betCOUNT_OUNext,
		SUM( betCOUNT_OENext) betCOUNT_OENext,
		SUM( betCOUNT_highlow) betCOUNT_highlow,
		SUM( betCOUNT_Warrior_2ndBall) betCOUNT_Warrior_2ndBall,
		SUM( betCOUNT_Warrior_3rdBall) betCOUNT_Warrior_3rdBall,
		SUM( betCOUNT_NextCombo_OverOdd) betCOUNT_NextCombo_OverOdd,
		SUM( betCOUNT_NextCombo_OverEven) betCOUNT_NextCombo_OverEven,
	    SUM( betCOUNT_NextCombo_UnderOdd) betCOUNT_NextCombo_UnderOdd,
		SUM( betCOUNT_NextCombo_UnderEven) betCOUNT_NextCombo_UnderEven,
		SUM( betCOUNT_NumberGroupPre) betCOUNT_NumberGroupPre,
		SUM( betCOUNT_NumberGroupLive) betCOUNT_NumberGroupLive
FROM (

		SELECT
			m.showtime, 
			m.leagueID,
			m.matchcode,
			bb.liveindicator,
			m.matchid,
				SUM(CASE WHEN bettype=81 AND betteam = 'h' THEN Stake ELSE 0 End) AS over_1stBall,
				SUM(CASE WHEN bettype=81 AND betteam = 'a' THEN Stake ELSE 0 End) AS under_1stBall,
				SUM(CASE WHEN bettype=82 AND betteam = 'h' THEN Stake ELSE 0 End) AS over_lastBall,
				SUM(CASE WHEN bettype=82 AND betteam = 'a' THEN Stake ELSE 0 End) AS under_lastBall,
				SUM(CASE WHEN bettype=83 AND betteam = 'h' THEN Stake ELSE 0 End) AS odd_1stBall,
				SUM(CASE WHEN bettype=83 AND betteam = 'a' THEN Stake ELSE 0 End) AS even_1stBall,
				SUM(CASE WHEN bettype=84 AND betteam = 'h' THEN Stake ELSE 0 End) AS odd_lastBall,
				SUM(CASE WHEN bettype=84 AND betteam = 'a' THEN Stake ELSE 0 End) AS even_lastBall,			
		
				SUM(CASE WHEN bettype=86 AND betteam = 'h' AND bb.liveindicator=0 THEN Stake ELSE 0 End) AS odd_fullTime,
				SUM(CASE WHEN bettype=86 AND betteam = 'a' AND bb.liveindicator=0 THEN Stake ELSE 0 End) AS even_fullTime,
				
				SUM(CASE WHEN bettype=85 AND betteam = 'h' AND bb.liveindicator=1 THEN Stake ELSE 0 End) AS over_next,
				SUM(CASE WHEN bettype=85 AND betteam = 'a' AND bb.liveindicator=1 THEN Stake ELSE 0 End) AS under_next,
				SUM(CASE WHEN bettype=86 AND betteam = 'h' AND bb.liveindicator=1 THEN Stake ELSE 0 End) AS odd_next,
				SUM(CASE WHEN bettype=86 AND betteam = 'a' AND bb.liveindicator=1 THEN Stake ELSE 0 End) AS even_next,		
				SUM(CASE WHEN bettype=87 AND betteam = 'h' THEN Stake ELSE 0 End) AS high,
				SUM(CASE WHEN bettype=87 AND betteam = 'a' THEN Stake ELSE 0 End) AS low,

				SUM(CASE WHEN bettype=88 AND betteam = 'h' THEN Stake ELSE 0 End) AS Warrior_2ndBall,
				SUM(CASE WHEN bettype=88 AND betteam = 'a' THEN Stake ELSE 0 End) AS Warrior_3rdBall,

				SUM(CASE WHEN bettype=89 AND betteam = '1:1' THEN Stake ELSE 0 End) AS NextCombo_OverOdd ,
				SUM(CASE WHEN bettype=89 AND betteam = '1:2' THEN Stake ELSE 0 End) AS NextCombo_OverEven,
				SUM(CASE WHEN bettype=89 AND betteam = '2:1' THEN Stake ELSE 0 End) AS NextCombo_UnderOdd ,
				SUM(CASE WHEN bettype=89 AND betteam = '2:2' THEN Stake ELSE 0 End) AS NextCombo_UnderEven,	
							
				SUM(CASE WHEN bettype=90 AND bb.liveindicator=0 THEN Stake ELSE 0 End) AS NumberGroupPre,	
				SUM(CASE WHEN bettype=90 AND bb.liveindicator=1 THEN Stake ELSE 0 End) AS NumberGroupLive,					
				
				SUM(CASE WHEN bettype=81 THEN BetCOUNT ELSE 0 End) AS betCOUNT_OU1stBall,
				SUM(CASE WHEN bettype=82 THEN BetCOUNT ELSE 0 End) AS betCOUNT_OULastBall,
				SUM(CASE WHEN bettype=83 THEN BetCOUNT ELSE 0 End) AS betCOUNT_OE1stBall,
				SUM(CASE WHEN bettype=84 THEN BetCOUNT ELSE 0 End) AS betCOUNT_OElastBall,
		
				SUM(CASE WHEN bettype=86 AND bb.liveindicator=0 THEN BetCOUNT ELSE 0 End) AS betCOUNT_OEfullTime,
				
				SUM(CASE WHEN bettype=85 AND bb.liveindicator=1 THEN BetCOUNT ELSE 0 End) AS betCOUNT_OUNext,
				SUM(CASE WHEN bettype=86 AND bb.liveindicator=1 THEN BetCOUNT ELSE 0 End) AS betCOUNT_OENext,
				SUM(CASE WHEN bettype=87 THEN BetCOUNT ELSE 0 End) AS betCOUNT_highlow,

				SUM(CASE WHEN bettype=88 AND betteam = 'h' THEN BetCOUNT ELSE 0 End) AS betCOUNT_Warrior_2ndBall,
				SUM(CASE WHEN bettype=88 AND betteam = 'a' THEN BetCOUNT ELSE 0 End) AS betCOUNT_Warrior_3rdBall,
				SUM(CASE WHEN bettype=89 AND betteam = '1:1' THEN BetCOUNT ELSE 0 End) AS betCOUNT_NextCombo_OverOdd,
				SUM(CASE WHEN bettype=89 AND betteam = '1:2' THEN BetCOUNT ELSE 0 End) AS betCOUNT_NextCombo_OverEven,
				SUM(CASE WHEN bettype=89 AND betteam = '2:1' THEN BetCOUNT ELSE 0 End) AS betCOUNT_NextCombo_UnderOdd,
				SUM(CASE WHEN bettype=89 AND betteam = '2:2' THEN BetCOUNT ELSE 0 End) AS betCOUNT_NextCombo_UnderEven,		
										
				SUM(CASE WHEN bettype=90 AND bb.liveindicator=0 THEN BetCOUNT ELSE 0 End) AS betCOUNT_NumberGroupPre,
				SUM(CASE WHEN bettype=90 AND bb.liveindicator=1 THEN BetCOUNT ELSE 0 End) AS betCOUNT_NumberGroupLive
		FROM
			(SELECT ba.MatchId , 
					ba.BetType, 
					betteam,
					liveindicator,
					SUM(ba.APositionTaking * ba.Stake * CASE WHEN ABS(b.Odds) <1 THEN 1 ELSE ABS(b.Odds) END) AS Stake,
					COUNT(1) AS BetCOUNT
			FROM 
				BetTrans_Agent ba WITH (NOLOCK) INNER JOIN 
				BetTrans b WITH (NOLOCK) ON ba.TransId = b.TransId
			WHERE
					ba.BetType between 81 AND 120
					AND ba.AgentId = @AgentId
					AND ba.StatusId in (0,1)
					AND b.Ruben = 0
			GROUP BY ba.MatchId , 
					ba.BetType, 
					betteam,
					liveindicator) AS bb
			INNER JOIN match m WITH (NOLOCK) ON m.matchid = bb.MatchId
		WHERE	
			m.eventstatus = 'running'
		GROUP BY
			m.showtime, 
			m.leagueID,
			m.matchcode,
			bb.LiveIndicator,
			m.matchid) m

GROUP BY	m.showtime, 
			m.leagueID,
			m.matchcode,
			m.matchid
ORDER BY	m.matchcode
END
