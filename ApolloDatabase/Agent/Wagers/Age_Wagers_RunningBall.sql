USE [RepDB]
GO 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTEr PROCEDURE [dbo].[Age_Wagers_RunningBall]
@LoggedId INT = 0,
@FromDate Date,
@Sporttypes VARCHAR(MAX),
@UGroup varchar(3) = 'ALL',
@IsDirectMem BIT = 0,
@LeagueId INT
AS

/*
Created:  Sophia
Date: 20130628
Task:  Wagers running ball
DB: SVRAGE.REPDB
 
Revisions:    

Parameters
	@IsDirectMem : 1: Direct Member
				   0: All Member
 
*/
SET NOCOUNT ON 
	SELECT		B.ShowTime, B.LiveIndicator,
				B.leagueid, B.MatchId, B.HomeId, B.AwayId, B.UGroup,
				SUM(CASE WHEN B.Bettype = 1 AND betteam = 'h' THEN B.Stake ELSE 0 END) AS HomeStakeHDP,
				SUM(CASE WHEN B.Bettype = 1 AND betteam = 'a' THEN B.Stake ELSE 0 END) AS AwayStakeHDP,

				SUM(CASE WHEN B.BetType = 2 AND betteam = 'h' THEN B.Stake ELSE 0 END) AS HomeStakeOE,
				SUM(CASE WHEN B.BetType = 2 AND betteam = 'a' THEN B.Stake ELSE 0 END) AS AwayStakeOE,

				SUM(CASE WHEN B.Bettype = 3 AND betteam = 'h' THEN B.Stake ELSE 0 END) AS HomeStakeOU,
				SUM(CASE WHEN B.Bettype = 3 AND betteam = 'a' THEN B.Stake ELSE 0 END) AS AwayStakeOU,

				SUM(CASE WHEN B.Bettype = 5 AND betteam = '1' THEN B.Stake ELSE 0 END) AS Stake1,
				SUM(CASE WHEN B.Bettype = 5 AND betteam = 'x' THEN B.Stake ELSE 0 END) AS StakeX,
				SUM(CASE WHEN B.Bettype = 5 AND betteam = '2' THEN B.Stake ELSE 0 END) AS Stake2,
				
				SUM(CASE WHEN B.Bettype = 7 AND betteam = 'h' THEN B.Stake ELSE 0 END) AS HomeStakeHTHDP,
				SUM(CASE WHEN B.Bettype = 7 AND betteam = 'a' THEN B.Stake ELSE 0 END) AS AwayStakeHTHDP,

				SUM(CASE WHEN B.Bettype = 8 AND betteam = 'h' THEN B.Stake ELSE 0 END) AS HomeStakeHTOU,
				SUM(CASE WHEN B.Bettype = 8 AND betteam = 'a' THEN B.Stake ELSE 0 END) AS AwayStakeHTOU,

				SUM(CASE WHEN B.BetType = 12 AND betteam = 'h' THEN B.Stake ELSE 0 END) AS HomeStakeHTOE,
				SUM(CASE WHEN B.BetType = 12 AND betteam = 'a' THEN B.Stake ELSE 0 END) AS AwayStakeHTOE,

				SUM(CASE WHEN B.Bettype = 15 AND betteam = '1' THEN B.Stake ELSE 0 END) AS StakeHT1,
				SUM(CASE WHEN B.Bettype = 15 AND betteam = 'x' THEN B.Stake ELSE 0 END) AS StakeHTX,
				SUM(CASE WHEN B.Bettype = 15 AND betteam = '2' THEN B.Stake ELSE 0 END) AS StakeHT2,

				SUM(CASE WHEN B.Bettype = 20 AND betteam = 'h' THEN B.Stake ELSE 0 END) AS HomeStakeMoney,
				SUM(CASE WHEN B.Bettype = 20 AND betteam = 'a' THEN B.Stake ELSE 0 END) AS AwayStakeMoney,

				SUM(CASE WHEN B.Bettype = 1 AND betteam = 'h' THEN B.BetCount ELSE 0 END) AS HomeCountHDP,
				SUM(CASE WHEN B.Bettype = 1 AND betteam = 'a' THEN B.BetCount ELSE 0 END) AS AwayCountHDP,

				SUM(CASE WHEN B.Bettype = 2 AND betteam = 'h' THEN B.BetCount ELSE 0 END) AS HomeCountOE,
				SUM(CASE WHEN B.Bettype = 2 AND betteam = 'a' THEN B.BetCount ELSE 0 END) AS AwayCountOE,

				SUM(CASE WHEN B.Bettype = 3 AND betteam = 'h' THEN B.BetCount ELSE 0 END) AS HomeCountOU,
				SUM(CASE WHEN B.Bettype = 3 AND betteam = 'a' THEN B.BetCount ELSE 0 END) AS AwayCountOU,

				SUM(CASE WHEN B.Bettype = 5 AND betteam = '1' THEN B.BetCount ELSE 0 END) AS Count1,
				SUM(CASE WHEN B.Bettype = 5 AND betteam = 'x' THEN B.BetCount ELSE 0 END) AS CountX,
				SUM(CASE WHEN B.Bettype = 5 AND betteam = '2' THEN B.BetCount ELSE 0 END) AS Count2,

				SUM(CASE WHEN B.Bettype = 7 AND betteam = 'h' THEN B.BetCount ELSE 0 END) AS HomeCountHTHDP,
				SUM(CASE WHEN B.Bettype = 7 AND betteam = 'a' THEN B.BetCount ELSE 0 END) AS AwayCountHTHDP,

				SUM(CASE WHEN B.Bettype = 8 AND betteam = 'h' THEN B.BetCount ELSE 0 END) AS HomeCountHTOU,
				SUM(CASE WHEN B.Bettype = 8 AND betteam = 'a' THEN B.BetCount ELSE 0 END) AS AwayCountHTOU,

				SUM(CASE WHEN B.Bettype = 12 AND betteam = 'h' THEN B.BetCount ELSE 0 END) AS HomeCountHTOE,
				SUM(CASE WHEN B.Bettype = 12 AND betteam = 'a' THEN B.BetCount ELSE 0 END) AS AwayCountHTOE,

				SUM(CASE WHEN B.Bettype = 15 AND betteam = '1' THEN B.BetCount ELSE 0 END) AS CountHT1,
				SUM(CASE WHEN B.Bettype = 15 AND betteam = 'x' THEN B.BetCount ELSE 0 END) AS CountHTX,
				SUM(CASE WHEN B.Bettype = 15 AND betteam = '2' THEN B.BetCount ELSE 0 END) AS CountHT2,

				SUM(CASE WHEN B.Bettype = 20 AND betteam = 'h' THEN B.BetCount ELSE 0 END) AS HomeCountMoney,
				SUM(CASE WHEN B.Bettype = 20 AND betteam = 'a' THEN B.BetCount ELSE 0 END) AS AwayCountMoney,


				MAX(CASE WHEN B.Bettype = 1 AND betteam = 'h' THEN 'h' ELSE '0' END) AS HomeBetteamHDP,
				MAX(CASE WHEN B.Bettype = 1 AND betteam = 'a' THEN 'a' ELSE '0' END) AS AwayBetteamHDP,

				MAX(CASE WHEN B.BetType = 2 AND betteam = 'h' THEN 'h' ELSE '0' END) AS HomeBetteamOE,
				MAX(CASE WHEN B.BetType = 2 AND betteam = 'a' THEN 'a' ELSE '0' END) AS AwayBetteamOE,

				MAX(CASE WHEN B.Bettype = 3 AND betteam = 'h' THEN 'h' ELSE '0' END) AS HomeBetteamOU,
				MAX(CASE WHEN B.Bettype = 3 AND betteam = 'a' THEN 'a' ELSE '0' END) AS AwayBetteamOU,

				MAX(CASE WHEN B.Bettype = 7 AND betteam = 'h' THEN 'h' ELSE '0' END) AS HomeBetteamHTHDP,
				MAX(CASE WHEN B.Bettype = 7 AND betteam = 'a' THEN 'a' ELSE '0' END) AS AwayBetteamHTHDP,

				MAX(CASE WHEN B.Bettype = 8 AND betteam = 'h' THEN 'h' ELSE '0' END) AS HomeBetteamHTOU,
				MAX(CASE WHEN B.Bettype = 8 AND betteam = 'a' THEN 'a' ELSE '0' END) AS AwayBetteamHTOU,

				MAX(CASE WHEN B.Bettype = 12 AND betteam = 'h' THEN 'h' ELSE '0' END) AS HomeBetteamHTOE,
				MAX(CASE WHEN B.Bettype = 12 AND betteam = 'a' THEN 'a' ELSE '0' END) AS AwayBetteamHTOE,

				MAX(CASE WHEN B.Bettype = 15 AND betteam = '1' THEN '1' ELSE '0' END) AS BetteamHT1,
				MAX(CASE WHEN B.Bettype = 15 AND betteam = 'x' THEN 'x' ELSE '0' END) AS BetteamHTX,
				MAX(CASE WHEN B.Bettype = 15 AND betteam = '2' THEN '2' ELSE '0' END) AS BetteamHT2,

				MAX(CASE WHEN B.BetType = 20 AND betteam = 'h' THEN 'h' ELSE '0' END) AS HomeBetteamMoney,
				MAX(CASE WHEN B.BetType = 20 AND betteam = 'a' THEN 'a' ELSE '0' END) AS AwayBetteamMoney
	FROM (		
				SELECT		M.ShowTime, B.LiveIndicator,
							M.leagueid, M.MatchId, M.HomeId, M.AwayId, 
							B.Bettype, B.betteam, C.UGroup,
							SUM(B.Stake) Stake ,
							Count(B.TransID) as BetCount
				FROM		Bettrans B WITH (NOLOCK)
				INNER JOIN	Bettrans_Agent BA WITH (NOLOCK)
					ON		B.TransId = BA.TransId AND BA.AgentID = @LoggedID  AND BA.Bettype IN (1,2,3,5,7,8,12,15,20) AND BA.StatusId IN (0,1)
				INNER JOIN	Match M WITH (NOLOCK)
					ON		M.matchID = B.MatchID
				INNER JOIN  CustInfo C WITH (NOLOCK)
					ON		C.CustID = B.CustID
				WHERE		B.Bettype IN (1,2,3,5,7,8,12,15,20)
							AND B.StatusId IN (0,1)							
							AND B.LiveIndicator = 1
							AND M.Sporttype IN (SELECT val FROM StrSplit_Key(@Sporttypes, ','))
							AND M.Sporttype = 1	
							AND M.Eventdate = @Fromdate
							AND M.EventStatus = 'running'
							AND (M.Leagueid = @LeagueId OR @LeagueId = 0)
							AND (C.UGroup = @UGroup OR @UGroup = 'ALL')
							AND (C.AgentID = @LoggedId OR @IsDirectMem = 0)											 
				GROUP BY	M.ShowTime, B.LiveIndicator,
							M.leagueid, M.MatchId, M.HomeId, M.AwayId, 
							B.Bettype, B.betteam, C.UGroup
				) B

	GROUP BY 	B.ShowTime, B.LiveIndicator,
				B.leagueid, B.MatchId, B.HomeId, B.AwayId, B.UGroup	 
	ORDER BY 	B.ShowTime,B.leagueid, B.MatchId, B.HomeId, B.AwayId
GO
GRANT EXECUTE ON [Age_Wagers_RunningBall] TO [aplweb]
 

		 