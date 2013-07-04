USE [RepDB]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_Wagers_BK_Special]
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
Task:  Wagers for B.K/NFL/RUGBY - Special
DB: SVRAGE.REPDB

Revisions:    
	- 20130629@Sophia: Add @Sporttypes or Tennis, VB/BDM/TT (=Volleyball, Badminton, Table Tennis), Baseball use 
Parameters
	@IsDirectMem : 1: Direct Member
				   0: All Member
 
*/
SET NOCOUNT ON
CREATE TABLE #SpecialWager (Showtime nvarchar(50), LiveIndicator BIT, leagueid INT, MatchId INT, HomeId INT , AwayId INT, 
							bettype INT, Stake MONEY, Count BIGINT) 


------------------------Others

INSERT INTO #SpecialWager 
SELECT		B.Showtime, B.LiveIndicator,
			B.leagueid, B.MatchId, B.HomeId, B.AwayId,B.bettype,  '0' as Betteam,
			SUM(B.Stake) AS Stake,							 
			SUM(B.BetCount) AS Count
FROM (		
			SELECT		M.ShowTime, B.LiveIndicator,
						M.leagueid, M.MatchId, M.HomeId, M.AwayId, 
						B.Bettype, 
						SUM (B.Stake) Stake ,
						Count(B.TransID) as BetCount
			FROM		Bettrans B WITH (NOLOCK)
			INNER JOIN	Bettrans_Agent BA WITH (NOLOCK)
				ON		B.TransId = BA.TransId AND BA.AgentID = @LoggedID  AND BA.Bettype NOT IN (1,2,3,7,8,12,9,29) AND BA.StatusId IN (0,1)
			INNER JOIN	Match M WITH (NOLOCK)
				ON		M.matchID = B.MatchID
			INNER JOIN  CustInfo C WITH (NOLOCK)
				ON		C.CustID = B.CustID
			WHERE		B.Bettype NOT IN (1,2,3,7,8,12,9,29)
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
						B.Bettype 
			) B
GROUP BY 	B.ShowTime, B.LiveIndicator, B.Bettype,
			B.leagueid, B.MatchId, B.HomeId, B.AwayId

SELECT	* 
FROM	#SpecialWager 
ORDER BY ShowTime, leagueid,HomeId, AwayId


GO
GRANT EXECUTE ON [Age_Wagers_BK_Special] TO [aplweb]

 