USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Wagers_1_3_5]    Script Date: 6/29/2013 8:34:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_Wagers_SC_1_3_5]
@LoggedId INT = 0,
@FromDate Date,
@UGroup varchar(3) = 'ALL',
@IsDirectMem BIT = 0,
@LeagueId INT
AS

/*
Created:  Sophia
Date: 20130628
Task:  Wagers for Soccer - Straight
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

				SUM(CASE WHEN B.Bettype = 3 AND betteam = 'h' THEN B.Stake ELSE 0 END) AS HomeStakeOU,
				SUM(CASE WHEN B.Bettype = 3 AND betteam = 'a' THEN B.Stake ELSE 0 END) AS AwayStakeOU,

				SUM(CASE WHEN B.Bettype = 5 AND betteam = '1' THEN B.Stake ELSE 0 END) AS Stake1,
				SUM(CASE WHEN B.Bettype = 5 AND betteam = 'x' THEN B.Stake ELSE 0 END) AS StakeX,
				SUM(CASE WHEN B.Bettype = 5 AND betteam = '2' THEN B.Stake ELSE 0 END) AS Stake2,

				SUM(CASE WHEN B.Bettype = 1 AND betteam = 'h' THEN B.BetCount ELSE 0 END) AS HomeCountHDP,
				SUM(CASE WHEN B.Bettype = 1 AND betteam = 'a' THEN B.BetCount ELSE 0 END) AS AwayCountHDP,

				SUM(CASE WHEN B.Bettype = 3 AND betteam = 'h' THEN B.BetCount ELSE 0 END) AS HomeCountOU,
				SUM(CASE WHEN B.Bettype = 3 AND betteam = 'a' THEN B.BetCount ELSE 0 END) AS AwayCountOU,

				SUM(CASE WHEN B.Bettype = 5 AND betteam = '1' THEN B.BetCount ELSE 0 END) AS Count1,
				SUM(CASE WHEN B.Bettype = 5 AND betteam = 'x' THEN B.BetCount ELSE 0 END) AS CountX,
				SUM(CASE WHEN B.Bettype = 5 AND betteam = '2' THEN B.BetCount ELSE 0 END) AS Count2

	FROM (		
				SELECT		M.ShowTime, B.LiveIndicator,
							M.leagueid, M.matchcode, M.HomeId, M.AwayId, 
							B.Bettype, B.Stake, B.betteam, C.UGroup,
							Count(B.TransID) as BetCount
				FROM		Bettrans B WITH (NOLOCK)
				INNER JOIN	Bettrans_Agent BA WITH (NOLOCK)
					ON		B.TransId = BA.TransId AND BA.AgentID = @LoggedID  AND BA.Bettype IN (1,3,5) AND BA.StatusId IN (0,1)
				INNER JOIN	Match M WITH (NOLOCK)
					ON		M.matchID = B.MatchID
				INNER JOIN  CustInfo C WITH (NOLOCK)
					ON		C.CustID = B.CustID
				WHERE		B.Bettype IN (1,3,5)
							AND B.StatusId IN (0,1)							
							AND B.LiveIndicator = 0
							AND M.Sporttype = 1	
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
GRANT EXECUTE ON [Age_Wagers_SC_1_3_5] TO [aplweb]

		 