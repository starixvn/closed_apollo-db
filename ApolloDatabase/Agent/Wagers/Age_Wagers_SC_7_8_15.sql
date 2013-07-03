USE [RepDB]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_Wagers_SC_7_8_15]
@LoggedId INT = 0,
@FromDate Date,
@UGroup varchar(3) = 'ALL',
@IsDirectMem BIT = 0,
@LeagueId INT
AS

/*
Created:  Sophia
Date: 20130628
Task:  Wagers for Soccer - 1st Half
DB: SVRAGE.REPDB
 
Revisions:    

Parameters
	@IsDirectMem : 1: Direct Member
				   0: All Member
 
*/
SET NOCOUNT ON 
	SELECT		B.Showtime, B.LiveIndicator,
				B.leagueid, B.matchcode, B.HomeId, B.AwayId,  
				SUM(CASE WHEN B.Bettype = 7 AND betteam = 'h' THEN B.Stake ELSE 0 END) AS HomeStakeHTHDP,
				SUM(CASE WHEN B.Bettype = 7 AND betteam = 'a' THEN B.Stake ELSE 0 END) AS AwayStakeHTHDP,

				SUM(CASE WHEN B.Bettype = 8 AND betteam = 'h' THEN B.Stake ELSE 0 END) AS HomeStakeHTOU,
				SUM(CASE WHEN B.Bettype = 8 AND betteam = 'a' THEN B.Stake ELSE 0 END) AS AwayStakeHTOU,

				SUM(CASE WHEN B.Bettype = 15 AND betteam = '1' THEN B.Stake ELSE 0 END) AS StakeHT1,
				SUM(CASE WHEN B.Bettype = 15 AND betteam = 'x' THEN B.Stake ELSE 0 END) AS StakeHTX,
				SUM(CASE WHEN B.Bettype = 15 AND betteam = '2' THEN B.Stake ELSE 0 END) AS StakeHT2,

				SUM(CASE WHEN B.Bettype = 7 AND betteam = 'h' THEN B.BetCount ELSE 0 END) AS HomeCountHTHDP,
				SUM(CASE WHEN B.Bettype = 7 AND betteam = 'a' THEN B.BetCount ELSE 0 END) AS AwayCountHTHDP,

				SUM(CASE WHEN B.Bettype = 8 AND betteam = 'h' THEN B.BetCount ELSE 0 END) AS HomeCountHTOU,
				SUM(CASE WHEN B.Bettype = 8 AND betteam = 'a' THEN B.BetCount ELSE 0 END) AS AwayCountHTOU,

				SUM(CASE WHEN B.Bettype = 15 AND betteam = '1' THEN B.BetCount ELSE 0 END) AS CountHT1,
				SUM(CASE WHEN B.Bettype = 15 AND betteam = 'x' THEN B.BetCount ELSE 0 END) AS CountHTX,
				SUM(CASE WHEN B.Bettype = 15 AND betteam = '2' THEN B.BetCount ELSE 0 END) AS CountHT2,

				MAX(CASE WHEN B.Bettype = 7 AND betteam = 'h' THEN 'h' ELSE '0' END) AS HomeBetteamHTHDP,
				MAX(CASE WHEN B.Bettype = 7 AND betteam = 'a' THEN 'a' ELSE '0' END) AS AwayBetteamHTHDP,

				MAX(CASE WHEN B.Bettype = 8 AND betteam = 'h' THEN 'h' ELSE '0' END) AS HomeBetteamHTOU,
				MAX(CASE WHEN B.Bettype = 8 AND betteam = 'a' THEN 'a' ELSE '0' END) AS AwayBetteamHTOU,

				MAX(CASE WHEN B.Bettype = 15 AND betteam = '1' THEN '1' ELSE '0' END) AS BetteamHT1,
				MAX(CASE WHEN B.Bettype = 15 AND betteam = 'x' THEN 'x' ELSE '0' END) AS BetteamHTX,
				MAX(CASE WHEN B.Bettype = 15 AND betteam = '2' THEN '2' ELSE '0' END) AS BetteamHT2

	FROM (		
				SELECT		M.Showtime, B.LiveIndicator,
							M.leagueid, M.matchcode, M.HomeId, M.AwayId, 
							B.Bettype, B.Stake, B.betteam, 
							Count(B.TransID) as BetCount
				FROM		Bettrans B WITH (NOLOCK)
				INNER JOIN	Bettrans_Agent BA WITH (NOLOCK)
					ON		B.TransId = BA.TransId AND BA.AgentID = @LoggedID  AND BA.Bettype IN (7,8,15) AND BA.StatusId IN (0,1)
				INNER JOIN	Match M WITH (NOLOCK)
					ON		M.matchID = B.MatchID
				INNER JOIN  CustInfo C WITH (NOLOCK)
					ON		C.CustID = B.CustID
				WHERE		B.Bettype IN (7,8,15)
							AND B.StatusId IN (0,1)							
							AND B.LiveIndicator = 0
							AND M.Sporttype = 1	
							AND M.Eventdate = @Fromdate
							AND M.EventStatus = 'running'
							AND (M.Leagueid = @LeagueId OR @LeagueId = 0)
							AND (C.UGroup = @UGroup OR @UGroup = 'ALL')
							AND (C.AgentID = @LoggedId OR @IsDirectMem = 0)											 
				GROUP BY	M.Showtime, B.LiveIndicator,
							M.leagueid, M.matchcode, M.HomeId, M.AwayId, 
							B.Bettype, B.Stake, B.betteam 
				) B

	GROUP BY 	B.Showtime, B.LiveIndicator,
				B.leagueid, B.matchcode, B.HomeId, B.AwayId 
	ORDER BY 	B.Showtime,B.leagueid, B.matchcode, B.HomeId, B.AwayId
GO
GRANT EXECUTE ON [Age_Wagers_SC_7_8_15] TO [aplweb]

		 