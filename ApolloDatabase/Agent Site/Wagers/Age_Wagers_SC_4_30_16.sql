USE [RepDB]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_Wagers_SC_4_30_16]
@IsSuperView BIT = 0,
@LoggedId INT = 0,
@FromDate Date,
@UGroup varchar(3) = 'ALL',
@Bettype INT,
@IsDirectMem BIT = 0,
@LeagueId INT
AS

/*
Created:  Sophia
Date: 20130628
Task:  Wagers for Soccer - Correct Score (4)/HT Correct Score (30)/HT/FT (16)
DB: SVRAGE.REPDB
 
Revisions:    
	- 20130712@Sophia: Add @IsSuperView and calculate Stake after Share
	- 20130718@Sophia: Add Stake berfore Share

Parameters
	@IsDirectMem : 1: Direct Member
				   0: All Member
	@IsSuperView =  1: Super view on Main shareholder @LoggedId
				 =	0: @LoggedId view on his line
 
*/
SET NOCOUNT ON 
		
		SELECT		M.ShowTime, B.LiveIndicator,
					M.leagueid, M.MatchId, M.HomeId, M.AwayId, 
					B.Bettype, 
					SUM( B.Stake) AS StakeBefore,
					SUM( CASE WHEN @IsSuperView = 1 THEN (1-B.TPositionTaking) ELSE BA.APositionTaking END * B.Stake) AS Stake,
					Count(*) as BetCount
		FROM		Bettrans B WITH (NOLOCK)
		INNER JOIN	Bettrans_Agent BA WITH (NOLOCK)
			ON		B.TransId = BA.TransId AND BA.AgentID = @LoggedID  AND BA.Bettype = @Bettype AND BA.StatusId IN (0,1)
		INNER JOIN	Match M WITH (NOLOCK)
			ON		M.matchID = B.MatchID
		INNER JOIN  CustInfo C WITH (NOLOCK)
			ON		C.CustID = B.CustID
		WHERE		B.Bettype = @Bettype
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

	
GO
GRANT EXECUTE ON [Age_Wagers_SC_4_30_16] TO [aplweb]

		 