USE [RepDB]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_Wagers_TN_1_2_3]
@LoggedId INT = 0,
@FromDate Date,
@UGroup varchar(3) = 'ALL',
@IsDirectMem BIT = 0,
@LeagueId INT
AS

/*
Created:  Sophia
Date: 20130628
Task:  Wagers for Tennis - Straight
DB: SVRAGE.REPDB
 
Revisions:    

Parameters
	@IsDirectMem : 1: Direct Member
				   0: All Member
 
*/
SET NOCOUNT ON 
	SELECT		B.Showtime, B.LiveIndicator,
				B.leagueid, B.matchcode, B.HomeId, B.AwayId, B.UGroup,
				SUM(CASE WHEN B.Bettype = 1 AND betteam = 'h' THEN B.Stake ELSE 0 END) AS HomeStakeHDP,
				SUM(CASE WHEN B.Bettype = 1 AND betteam = 'a' THEN B.Stake ELSE 0 END) AS AwayStakeHDP,

				SUM(CASE WHEN B.BetType = 2 AND betteam = 'h' THEN B.Stake ELSE 0 END) AS HomeStakeOE,
				SUM(CASE WHEN B.BetType = 2 AND betteam = 'a' THEN B.Stake ELSE 0 END) AS AwayStakeOE,

				SUM(CASE WHEN B.Bettype = 3 AND betteam = 'h' THEN B.Stake ELSE 0 END) AS HomeStakeOU,
				SUM(CASE WHEN B.Bettype = 3 AND betteam = 'a' THEN B.Stake ELSE 0 END) AS AwayStakeOU,

				SUM(CASE WHEN B.Bettype = 1 AND betteam = 'h' THEN B.BetCount ELSE 0 END) AS HomeCountHDP,
				SUM(CASE WHEN B.Bettype = 1 AND betteam = 'a' THEN B.BetCount ELSE 0 END) AS AwayCountHDP,

				SUM(CASE WHEN B.Bettype = 2 AND betteam = 'h' THEN B.BetCount ELSE 0 END) AS HomeCountOE,
				SUM(CASE WHEN B.Bettype = 2 AND betteam = 'a' THEN B.BetCount ELSE 0 END) AS AwayCountOE,

				SUM(CASE WHEN B.Bettype = 3 AND betteam = 'h' THEN B.BetCount ELSE 0 END) AS HomeCountOU,
				SUM(CASE WHEN B.Bettype = 3 AND betteam = 'a' THEN B.BetCount ELSE 0 END) AS AwayCountOU

	FROM (		
				SELECT		M.ShowTime, B.LiveIndicator,
							M.leagueid, M.matchcode, M.HomeId, M.AwayId, 
							B.Bettype, B.Stake, B.betteam, C.UGroup,
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
							AND M.Sporttype = 5
							AND M.Eventdate = @Fromdate
							AND M.EventStatus = 'running'
							AND (M.Leagueid = @LeagueId OR @LeagueId = 0)
							AND (C.UGroup = @UGroup OR @UGroup = 'ALL')
							AND (C.AgentID = @LoggedId OR @IsDirectMem = 0)											 
				GROUP BY	M.ShowTime, B.LiveIndicator,
							M.leagueid, M.matchcode, M.HomeId, M.AwayId, 
							B.Bettype, B.Stake, B.betteam, C.UGroup
				) B

	GROUP BY 	B.ShowTime, B.LiveIndicator,
				B.leagueid, B.matchcode, B.HomeId, B.AwayId, B.UGroup	 
	ORDER BY 	B.ShowTime,B.leagueid, B.matchcode, B.HomeId, B.AwayId
GO
GRANT EXECUTE ON [Age_Wagers_TN_1_2_3] TO [aplweb]

 