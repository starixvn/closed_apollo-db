USE [RepDB]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_Wagers_BK_7_8_12]
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
Task:  Wagers for B.K/NFL/RUGBY - 1st Haft
DB: SVRAGE.REPDB
 
Revisions:    
	- 20130629@Sophia: Add @Sporttypes or Tennis, VB/BDM/TT (=Volleyball, Badminton, Table Tennis), Baseball use 
	- 20130712@Sophia: Add @IsSuperView and calculate Stake after Share

Parameters
	@IsDirectMem : 1: Direct Member
				   0: All Member

    @IsSuperView =  1: Super view on Main shareholder @LoggedId
				 =	0: @LoggedId view on his line
				  
*/
SET NOCOUNT ON 
	SELECT		B.Showtime, B.LiveIndicator,
				B.leagueid, B.MatchId, B.HomeId, B.AwayId, 
				SUM(CASE WHEN B.Bettype = 7 AND betteam = 'h' THEN B.Stake ELSE 0 END) AS HomeStakeHTHDP,
				SUM(CASE WHEN B.Bettype = 7 AND betteam = 'a' THEN B.Stake ELSE 0 END) AS AwayStakeHTHDP,

				SUM(CASE WHEN B.Bettype = 8 AND betteam = 'h' THEN B.Stake ELSE 0 END) AS HomeStakeHTOU,
				SUM(CASE WHEN B.Bettype = 8 AND betteam = 'a' THEN B.Stake ELSE 0 END) AS AwayStakeHTOU,

				SUM(CASE WHEN B.BetType = 12 AND betteam = 'h' THEN B.Stake ELSE 0 END) AS HomeStakeHTOE,
				SUM(CASE WHEN B.BetType = 12 AND betteam = 'a' THEN B.Stake ELSE 0 END) AS AwayStakeHTOE,

				SUM(CASE WHEN B.Bettype = 7 AND betteam = 'h' THEN B.BetCount ELSE 0 END) AS HomeCountHTHDP,
				SUM(CASE WHEN B.Bettype = 7 AND betteam = 'a' THEN B.BetCount ELSE 0 END) AS AwayCountHTHDP,

				SUM(CASE WHEN B.Bettype = 8 AND betteam = 'h' THEN B.BetCount ELSE 0 END) AS HomeCountHTOU,
				SUM(CASE WHEN B.Bettype = 8 AND betteam = 'a' THEN B.BetCount ELSE 0 END) AS AwayCountHTOU,

				SUM(CASE WHEN B.Bettype = 12 AND betteam = 'h' THEN B.BetCount ELSE 0 END) AS HomeCountHTOE,
				SUM(CASE WHEN B.Bettype = 12 AND betteam = 'a' THEN B.BetCount ELSE 0 END) AS AwayCountHTOE,

				MAX(CASE WHEN B.Bettype = 7 AND betteam = 'h' THEN 'h' ELSE '0' END) AS HomeBetteamHTHDP,
				MAX(CASE WHEN B.Bettype = 7 AND betteam = 'a' THEN 'a' ELSE '0' END) AS AwayBetteamHTHDP,

				MAX(CASE WHEN B.Bettype = 8 AND betteam = 'h' THEN 'h' ELSE '0' END) AS HomeBetteamHTOU,
				MAX(CASE WHEN B.Bettype = 8 AND betteam = 'a' THEN 'a' ELSE '0' END) AS AwayBetteamHTOU,

				MAX(CASE WHEN B.Bettype = 12 AND betteam = 'h' THEN 'h' ELSE '0' END) AS HomeBetteamHTOE,
				MAX(CASE WHEN B.Bettype = 12 AND betteam = 'a' THEN 'a' ELSE '0' END) AS AwayBetteamHTOE

	FROM (		
				SELECT		M.ShowTime, B.LiveIndicator,
							M.leagueid, M.MatchId, M.HomeId, M.AwayId, 
							B.Bettype, B.betteam, 
							SUM( CASE WHEN @IsSuperView = 1 THEN (1-B.TPositionTaking) ELSE BA.APositionTaking END * B.Stake) AS Stake,
							Count(B.TransID) as BetCount
				FROM		Bettrans B WITH (NOLOCK)
				INNER JOIN	Bettrans_Agent BA WITH (NOLOCK)
					ON		B.TransId = BA.TransId AND BA.AgentID = @LoggedID  AND BA.Bettype IN (7,8,12) AND BA.StatusId IN (0,1)
				INNER JOIN	Match M WITH (NOLOCK)
					ON		M.matchID = B.MatchID
				INNER JOIN  CustInfo C WITH (NOLOCK)
					ON		C.CustID = B.CustID
				WHERE		B.Bettype IN (7,8,12)
							AND B.StatusId IN (0,1)							
							AND B.LiveIndicator = 0
							AND M.Sporttype IN (SELECT val FROM StrSplit_Key(@Sporttypes, ','))
							AND M.Eventdate = @Fromdate
							AND M.EventStatus = 'running'
							AND (M.Leagueid = @LeagueId OR @LeagueId = 0)
							AND (C.UGroup = @UGroup OR @UGroup = 'ALL')
							AND (C.AgentID = @LoggedId OR @IsDirectMem = 0)											 
				GROUP BY	M.ShowTime, B.LiveIndicator,
							M.leagueid, M.MatchId, M.HomeId, M.AwayId, 
							B.Bettype,B.betteam 
				) B

	GROUP BY 	B.ShowTime, B.LiveIndicator,
				B.leagueid, B.MatchId, B.HomeId, B.AwayId
	ORDER BY 	B.ShowTime,B.leagueid, B.MatchId, B.HomeId, B.AwayId
GO
GRANT EXECUTE ON [Age_Wagers_BK_7_8_12] TO [aplweb]

 