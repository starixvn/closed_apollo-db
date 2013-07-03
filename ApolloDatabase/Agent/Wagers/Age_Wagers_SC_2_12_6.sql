USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Wagers_2_12_6]    Script Date: 6/29/2013 8:34:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_Wagers_SC_2_12_6]
@LoggedId INT = 0,
@FromDate Date,
@UGroup varchar(3) = 'ALL',
@IsDirectMem BIT = 0,
@LeagueId INT
AS

/*
Created:  Sophia
Date: 20130628
Task:  Wagers for Soccer - Total
DB: SVRAGE.REPDB
 
Revisions:    

Parameters
	@IsDirectMem : 1: Direct Member
				   0: All Member
 
*/
SET NOCOUNT ON 
	SELECT		B.Showtime, B.LiveIndicator,
				B.leagueid, B.MatchId, B.HomeId, B.AwayId,
				SUM(CASE WHEN B.BetType = 2 AND betteam = 'h' THEN B.Stake ELSE 0 END) AS HomeStakeOE,
				SUM(CASE WHEN B.BetType = 2 AND betteam = 'a' THEN B.Stake ELSE 0 END) AS AwayStakeOE,

				SUM(CASE WHEN B.BetType = 12 AND betteam = 'h' THEN B.Stake ELSE 0 END) AS HomeStakeHTOE,
				SUM(CASE WHEN B.BetType = 12 AND betteam = 'a' THEN B.Stake ELSE 0 END) AS AwayStakeHTOE,

				SUM(CASE WHEN B.BetType = 6 AND betteam = '0-1' THEN B.Stake ELSE 0 END) AS Total01Stake,
				SUM(CASE WHEN B.BetType = 6 AND betteam = '2-3' THEN B.Stake ELSE 0 END) AS Total23Stake,
				SUM(CASE WHEN B.BetType = 6 AND betteam = '4-6' THEN B.Stake ELSE 0 END) AS Total46Stake,
				SUM(CASE WHEN B.BetType = 6 AND betteam = '7-over' THEN B.Stake ELSE 0 END) AS Total7OverStake,


				SUM(CASE WHEN B.Bettype = 2 AND betteam = 'h' THEN B.BetCount ELSE 0 END) AS HomeCountOE,
				SUM(CASE WHEN B.Bettype = 2 AND betteam = 'a' THEN B.BetCount ELSE 0 END) AS AwayCountOE,

				SUM(CASE WHEN B.Bettype = 12 AND betteam = 'h' THEN B.BetCount ELSE 0 END) AS HomeCountHTOE,
				SUM(CASE WHEN B.Bettype = 12 AND betteam = 'a' THEN B.BetCount ELSE 0 END) AS AwayCountHTOE,

				SUM(CASE WHEN B.BetType = 6 AND betteam = '0-1' THEN B.BetCount ELSE 0 END) AS Total01Count,
				SUM(CASE WHEN B.BetType = 6 AND betteam = '2-3' THEN B.BetCount ELSE 0 END) AS Total23Count,
				SUM(CASE WHEN B.BetType = 6 AND betteam = '4-6' THEN B.BetCount ELSE 0 END) AS Total46Count,
				SUM(CASE WHEN B.BetType = 6 AND betteam = '7-over' THEN B.BetCount ELSE 0 END) AS Total7OverCount,

				MAX(CASE WHEN B.Bettype = 2 AND betteam = 'h' THEN 'h' ELSE '0' END) AS HomeBetteamOE,
				MAX(CASE WHEN B.Bettype = 2 AND betteam = 'a' THEN 'a' ELSE '0' END) AS AwayBetteamOE,

				MAX(CASE WHEN B.Bettype = 12 AND betteam = 'h' THEN 'h' ELSE '0' END) AS HomeBetteamHTOE,
				MAX(CASE WHEN B.Bettype = 12 AND betteam = 'a' THEN 'a' ELSE '0' END) AS AwayBetteamHTOE,

				MAX(CASE WHEN B.BetType = 6 AND betteam = '0-1' THEN '0-1' ELSE '0' END) AS Total01Betteam,
				MAX(CASE WHEN B.BetType = 6 AND betteam = '2-3' THEN '2-3' ELSE '0' END) AS Total23Betteam,
				MAX(CASE WHEN B.BetType = 6 AND betteam = '4-6' THEN '4-6' ELSE '0' END) AS Total46Betteam,
				MAX(CASE WHEN B.BetType = 6 AND betteam = '7-over' THEN '7-over' ELSE '0' END) AS Total7OverBetteam

	FROM (		
				SELECT		M.ShowTime, B.LiveIndicator,
							M.leagueid, M.MatchId, M.HomeId, M.AwayId, 
							B.Bettype, B.Stake, B.betteam, 
							Count(B.TransID) as BetCount
				FROM		Bettrans B WITH (NOLOCK)
				INNER JOIN	Bettrans_Agent BA WITH (NOLOCK)
					ON		B.TransId = BA.TransId AND BA.AgentID = @LoggedID  AND BA.Bettype IN (2,12,6) AND BA.StatusId IN (0,1)
				INNER JOIN	Match M WITH (NOLOCK)
					ON		M.matchID = B.MatchID
				INNER JOIN  CustInfo C WITH (NOLOCK)
					ON		C.CustID = B.CustID
				WHERE		B.Bettype IN (2,12,6)
							AND B.StatusId IN (0,1)							
							AND B.LiveIndicator = 0
							AND M.Sporttype = 1	
							AND M.Eventdate = @Fromdate
							AND M.EventStatus = 'running'
							AND (M.Leagueid = @LeagueId OR @LeagueId = 0)
							AND (C.UGroup = @UGroup OR @UGroup = 'ALL')
							AND (C.AgentID = @LoggedId OR @IsDirectMem = 0)											 
				GROUP BY	M.ShowTime, B.LiveIndicator,
							M.leagueid, M.MatchId, M.HomeId, M.AwayId, 
							B.Bettype, B.Stake, B.betteam
				) B

	GROUP BY 	B.ShowTime, B.LiveIndicator,
				B.leagueid, B.MatchId, B.HomeId, B.AwayId 
	ORDER BY 	B.ShowTime,B.leagueid, B.MatchId, B.HomeId, B.AwayId
GO
GRANT EXECUTE ON [Age_Wagers_SC_2_12_6] TO [aplweb]

		 