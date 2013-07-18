USE [RepDB]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_Wagers_BK_1_2_3]
@IsSuperView BIT = 0,
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
Task:  Wagers for B.K/NFL/RUGBY - Straight
DB: SVRAGE.REPDB
 
Revisions:    
	- 20130629@Sophia: Add @Sporttypes or Tennis, VB/BDM/TT (=Volleyball, Badminton, Table Tennis), Baseball use 
	- 20130712@Sophia: Add @IsSuperView and calculate Stake after Share
	- 20130718@Sophia: Add Stake berfore Share

Parameters
	@IsDirectMem = 1: Direct Member
				  = 0: All Member
    @IsSuperView =  1: Super view on Main shareholder @LoggedId
				 =	0: @LoggedId view on his line
 
*/
SET NOCOUNT ON 
	SELECT		B.Showtime, B.LiveIndicator,
				B.leagueid, B.MatchId, B.HomeId, B.AwayId,

				SUM(CASE WHEN B.Bettype = 1 AND betteam = 'h' THEN B.StakeBefore ELSE 0 END) AS HomeStakeBeforeHDP,
				SUM(CASE WHEN B.Bettype = 1 AND betteam = 'a' THEN B.StakeBefore ELSE 0 END) AS AwayStakeBeforeHDP,

				SUM(CASE WHEN B.BetType = 2 AND betteam = 'h' THEN B.StakeBefore ELSE 0 END) AS HomeStakeBeforeOE,
				SUM(CASE WHEN B.BetType = 2 AND betteam = 'a' THEN B.StakeBefore ELSE 0 END) AS AwayStakeBeforeOE,

				SUM(CASE WHEN B.Bettype = 3 AND betteam = 'h' THEN B.StakeBefore ELSE 0 END) AS HomeStakeBeforeOU,
				SUM(CASE WHEN B.Bettype = 3 AND betteam = 'a' THEN B.StakeBefore ELSE 0 END) AS AwayStakeBeforeOU,
				--------------
				SUM(CASE WHEN B.Bettype = 1 AND betteam = 'h' THEN B.Stake ELSE 0 END) AS HomeStakeHDP,
				SUM(CASE WHEN B.Bettype = 1 AND betteam = 'a' THEN B.Stake ELSE 0 END) AS AwayStakeHDP,

				SUM(CASE WHEN B.BetType = 2 AND betteam = 'h' THEN B.Stake ELSE 0 END) AS HomeStakeOE,
				SUM(CASE WHEN B.BetType = 2 AND betteam = 'a' THEN B.Stake ELSE 0 END) AS AwayStakeOE,

				SUM(CASE WHEN B.Bettype = 3 AND betteam = 'h' THEN B.Stake ELSE 0 END) AS HomeStakeOU,
				SUM(CASE WHEN B.Bettype = 3 AND betteam = 'a' THEN B.Stake ELSE 0 END) AS AwayStakeOU,
				--------------
				SUM(CASE WHEN B.Bettype = 1 AND betteam = 'h' THEN B.BetCount ELSE 0 END) AS HomeCountHDP,
				SUM(CASE WHEN B.Bettype = 1 AND betteam = 'a' THEN B.BetCount ELSE 0 END) AS AwayCountHDP,

				SUM(CASE WHEN B.Bettype = 2 AND betteam = 'h' THEN B.BetCount ELSE 0 END) AS HomeCountOE,
				SUM(CASE WHEN B.Bettype = 2 AND betteam = 'a' THEN B.BetCount ELSE 0 END) AS AwayCountOE,

				SUM(CASE WHEN B.Bettype = 3 AND betteam = 'h' THEN B.BetCount ELSE 0 END) AS HomeCountOU,
				SUM(CASE WHEN B.Bettype = 3 AND betteam = 'a' THEN B.BetCount ELSE 0 END) AS AwayCountOU,
				--------------
				MAX(CASE WHEN B.Bettype = 1 AND betteam = 'h' THEN 'h' ELSE '0' END) AS HomeBetteamHDP,
				MAX(CASE WHEN B.Bettype = 1 AND betteam = 'a' THEN 'a' ELSE '0' END) AS AwayBetteamHDP,

				MAX(CASE WHEN B.BetType = 2 AND betteam = 'h' THEN 'h' ELSE '0' END) AS HomeBetteamOE,
				MAX(CASE WHEN B.BetType = 2 AND betteam = 'a' THEN 'a' ELSE '0' END) AS AwayBetteamOE,

				MAX(CASE WHEN B.Bettype = 3 AND betteam = 'h' THEN 'h' ELSE '0' END) AS HomeBetteamOU,
				MAX(CASE WHEN B.Bettype = 3 AND betteam = 'a' THEN 'a' ELSE '0' END) AS AwayBetteamOU

	FROM (		
				SELECT		M.ShowTime, B.LiveIndicator,
							M.leagueid, M.MatchId, M.HomeId, M.AwayId, 
							B.Bettype,B.betteam,
							SUM(B.Stake) AS StakeBefore,
							SUM( CASE WHEN @IsSuperView = 1 THEN (1-B.TPositionTaking) ELSE BA.APositionTaking END * B.Stake) AS Stake,
							Count(B.TransID) as BetCount
				FROM		Bettrans B WITH (NOLOCK)
				INNER JOIN	Bettrans_Agent BA WITH (NOLOCK)
					ON		B.TransId = BA.TransId AND BA.AgentID = @LoggedID  AND BA.Bettype IN (1,2,3) AND BA.StatusId IN (0,1)
				INNER JOIN	Match M WITH (NOLOCK)
					ON		M.matchID = B.MatchID
				INNER JOIN  CustInfo C WITH (NOLOCK)
					ON		C.CustID = B.CustID
				WHERE		B.Bettype IN (1,2,3)
							AND B.StatusId IN (0,1)							
							AND B.LiveIndicator = 0
							AND (M.Sporttype IN (SELECT val FROM StrSplit_Key(@Sporttypes, ',')) OR @Sporttypes = '0')
							AND M.Eventdate = @Fromdate
							AND M.EventStatus = 'running'
							AND (M.Leagueid = @LeagueId OR @LeagueId = 0)
							AND (C.UGroup = @UGroup OR @UGroup = 'ALL')
							AND (C.AgentID = @LoggedId OR @IsDirectMem = 0)											 
				GROUP BY	M.ShowTime, B.LiveIndicator,
							M.leagueid, M.MatchId, M.HomeId, M.AwayId, 
							B.Bettype,  B.betteam
				) B

	GROUP BY 	B.ShowTime, B.LiveIndicator,
				B.leagueid, B.MatchId, B.HomeId, B.AwayId
	ORDER BY 	B.ShowTime,B.leagueid, B.MatchId, B.HomeId, B.AwayId
GO
GRANT EXECUTE ON [Age_Wagers_BK_1_2_3] TO [aplweb]

 