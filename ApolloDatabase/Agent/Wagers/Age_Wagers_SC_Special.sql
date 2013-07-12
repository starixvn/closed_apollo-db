USE [RepDB]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_Wagers_SC_Special]
@IsSuperView BIT = 0,
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
	 - 20130712@Sophia: Add @IsSuperView and calculate Stake after Share
Parameters
	@IsDirectMem : 1: Direct Member
				   0: All Member
	@IsSuperView =  1: Super view on Main shareholder @LoggedId
				 =	0: @LoggedId view on his line
 
 
*/
SET NOCOUNT ON
CREATE TABLE #SpecialWager (Showtime nvarchar(50), LiveIndicator BIT, leagueid INT, MatchId INT, HomeId INT , AwayId INT, 
							bettype INT, betteam VARCHAR(10), Stake MONEY, Count BIGINT) 

------------------------Others

INSERT INTO #SpecialWager 
SELECT		B.Showtime, B.LiveIndicator,
			B.leagueid, B.MatchId, B.HomeId, B.AwayId, B.bettype, '0' as Betteam, 
			SUM(B.Stake) AS Stake,							 
			SUM(B.BetCount) AS Count
			
FROM (		
			SELECT		M.ShowTime, B.LiveIndicator,
						M.leagueid, M.MatchId, M.HomeId, M.AwayId, 
						B.Bettype,
						SUM( CASE WHEN @IsSuperView = 1 THEN (1-B.TPositionTaking) ELSE BA.APositionTaking END * B.Stake) Stake,  
						Count(B.TransID) as BetCount
			FROM		Bettrans B WITH (NOLOCK)
			INNER JOIN	Bettrans_Agent BA WITH (NOLOCK)
				ON		B.TransId = BA.TransId 
						AND BA.AgentID = @LoggedID  
						AND BA.Bettype NOT IN (1,2,3,4,5,6,7,8,9,10,12,15,16,29,30) 
						AND BA.Bettype <=19000
						AND BA.StatusId IN (0,1)
			INNER JOIN	Match M WITH (NOLOCK)
				ON		M.matchID = B.MatchID
			INNER JOIN  CustInfo C WITH (NOLOCK)
				ON		C.CustID = B.CustID
			WHERE		B.Bettype NOT IN (1,2,3,4,5,6,7,8,9,10,12,15,16,29,30)
						AND B.Bettype <=19000
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
						B.Bettype 
			) B
GROUP BY 	B.ShowTime, B.LiveIndicator, B.Bettype, 
			B.leagueid, B.MatchId, B.HomeId, B.AwayId

SELECT	* 
FROM	#SpecialWager 
ORDER BY ShowTime, leagueid,HomeId, AwayId


GO
GRANT EXECUTE ON [Age_Wagers_SC_Special] TO [aplweb]

 