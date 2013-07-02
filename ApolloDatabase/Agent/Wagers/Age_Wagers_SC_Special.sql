USE [RepDB]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_Wagers_SC_Special]
@LoggedId INT = 0,
@FromDate Date,
@UGroup varchar(3) = 'ALL',
@IsDirectMem BIT = 0,
@LeagueId INT
AS

/*
Created:  Sophia
Date: 20130628
Task:  Wagers for Soccer - Special
DB: SVRAGE.REPDB

Revisions:    
	 
Parameters
	@IsDirectMem : 1: Direct Member
				   0: All Member
 
*/
SET NOCOUNT ON
CREATE TABLE #SpecialWager (Showtime nvarchar(50), LiveIndicator BIT, leagueid INT, MatchId INT, HomeId INT , AwayId INT, UGroup varchar (3),
							bettype INT, betteam VARCHAR(10), Stake MONEY, Count BIGINT, Type TINYINT)	----Type : 0 Total, 1 : Home, 2: Away, 3: Draw


INSERT INTO #SpecialWager 
SELECT		B.Showtime, B.LiveIndicator,
			B.leagueid, B.MatchId, B.HomeId, B.AwayId, B.UGroup, B.bettype, B.betteam,
			SUM(B.Stake) AS Stake,							 
			SUM(B.BetCount) AS Count,
			1 as Type 
FROM (		
			SELECT		M.ShowTime, B.LiveIndicator,
						M.leagueid, M.MatchId, M.HomeId, M.AwayId, 
						B.Bettype, B.Betteam, B.Stake, C.UGroup,
						Count(B.TransID) as BetCount
			FROM		Bettrans B WITH (NOLOCK)
			INNER JOIN	Bettrans_Agent BA WITH (NOLOCK)
				ON		B.TransId = BA.TransId AND BA.AgentID = @LoggedID  AND BA.Bettype IN (20,21,25,27,122,123) AND BA.StatusId IN (0,1)
			INNER JOIN	Match M WITH (NOLOCK)
				ON		M.matchID = B.MatchID
			INNER JOIN  CustInfo C WITH (NOLOCK)
				ON		C.CustID = B.CustID
			WHERE		B.Bettype IN (20,21,25,27,122,123)
						AND B.betteam = 'h'
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
						B.Bettype, B.Betteam, B.Stake, C.UGroup
			) B
GROUP BY 	B.ShowTime, B.LiveIndicator, B.Bettype,B.Betteam, 
			B.leagueid, B.MatchId, B.HomeId, B.AwayId, B.UGroup	 

UNION ALL
SELECT		B.Showtime, B.LiveIndicator,
			B.leagueid, B.MatchId, B.HomeId, B.AwayId, B.UGroup, B.bettype,B.Betteam, 
			SUM(B.Stake) AS Stake,							 
			SUM(B.BetCount) AS Count,
			2 as Type 
FROM (		
			SELECT		M.ShowTime, B.LiveIndicator,
						M.leagueid, M.MatchId, M.HomeId, M.AwayId, 
						B.Bettype, B.Betteam, B.Stake, C.UGroup,
						Count(B.TransID) as BetCount
			FROM		Bettrans B WITH (NOLOCK)
			INNER JOIN	Bettrans_Agent BA WITH (NOLOCK)
				ON		B.TransId = BA.TransId AND BA.AgentID = @LoggedID  AND BA.Bettype IN (20,21,25,27,121,123)AND BA.StatusId IN (0,1)
			INNER JOIN	Match M WITH (NOLOCK)
				ON		M.matchID = B.MatchID
			INNER JOIN  CustInfo C WITH (NOLOCK)
				ON		C.CustID = B.CustID
			WHERE		B.Bettype IN (20,21,25,27,121,123)
						AND B.betteam = 'a'
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
						B.Bettype, B.Betteam, B.Stake, C.UGroup
			) B
GROUP BY 	B.ShowTime, B.LiveIndicator, B.Bettype,B.Betteam, 
			B.leagueid, B.MatchId, B.HomeId, B.AwayId, B.UGroup	 

UNION ALL
SELECT		B.Showtime, B.LiveIndicator,
			B.leagueid, B.MatchId, B.HomeId, B.AwayId, B.UGroup, B.bettype,B.Betteam, 
			SUM(B.Stake) AS Stake,							 
			SUM(B.BetCount) AS Count,
			3 as Type 
FROM (		
			SELECT		M.ShowTime, B.LiveIndicator,
						M.leagueid, M.MatchId, M.HomeId, M.AwayId, 
						B.Bettype, B.Betteam, B.Stake, C.UGroup,
						Count(B.TransID) as BetCount
			FROM		Bettrans B WITH (NOLOCK)
			INNER JOIN	Bettrans_Agent BA WITH (NOLOCK)
				ON		B.TransId = BA.TransId AND BA.AgentID = @LoggedID  AND BA.Bettype IN (121,122)AND BA.StatusId IN (0,1)
			INNER JOIN	Match M WITH (NOLOCK)
				ON		M.matchID = B.MatchID
			INNER JOIN  CustInfo C WITH (NOLOCK)
				ON		C.CustID = B.CustID
			WHERE		B.Bettype IN (121,122)
						AND B.betteam = 'x'
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
						B.Bettype,B.Betteam,  B.Stake, C.UGroup
			) B
GROUP BY 	B.ShowTime, B.LiveIndicator, B.Bettype,B.Betteam, 
			B.leagueid, B.MatchId, B.HomeId, B.AwayId, B.UGroup	 

------------------------Others

INSERT INTO #SpecialWager 
SELECT		B.Showtime, B.LiveIndicator,
			B.leagueid, B.MatchId, B.HomeId, B.AwayId, B.UGroup, B.bettype, '0' as Betteam, 
			SUM(B.Stake) AS Stake,							 
			SUM(B.BetCount) AS Count,
			0 as Type 
FROM (		
			SELECT		M.ShowTime, B.LiveIndicator,
						M.leagueid, M.MatchId, M.HomeId, M.AwayId, 
						B.Bettype, B.Stake, C.UGroup,
						Count(B.TransID) as BetCount
			FROM		Bettrans B WITH (NOLOCK)
			INNER JOIN	Bettrans_Agent BA WITH (NOLOCK)
				ON		B.TransId = BA.TransId AND BA.AgentID = @LoggedID  AND BA.Bettype NOT IN (1,2,3,4,5,6,7,8,9,12,15,16,29,30,20,21,25,27,121,122,123) AND BA.StatusId IN (0,1)
			INNER JOIN	Match M WITH (NOLOCK)
				ON		M.matchID = B.MatchID
			INNER JOIN  CustInfo C WITH (NOLOCK)
				ON		C.CustID = B.CustID
			WHERE		B.Bettype NOT IN (1,2,3,4,5,6,7,8,9,12,15,16,29,30,20,21,25,27,121,122,123)
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
						B.Bettype, B.Stake, C.UGroup
			) B
GROUP BY 	B.ShowTime, B.LiveIndicator, B.Bettype, 
			B.leagueid, B.MatchId, B.HomeId, B.AwayId, B.UGroup

SELECT	* 
FROM	#SpecialWager 
ORDER BY ShowTime, leagueid,HomeId, AwayId


GO
GRANT EXECUTE ON [Age_Wagers_SC_Special] TO [aplweb]

 