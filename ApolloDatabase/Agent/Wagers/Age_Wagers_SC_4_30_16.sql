USE [RepDB]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_Wagers_SC_4_30_16]
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
Task:  Wagers for Soccer - Correct Score
DB: SVRAGE.REPDB
 
Revisions:    

Parameters
	@IsDirectMem : 1: Direct Member
				   0: All Member
 
*/
SET NOCOUNT ON 
		
		SELECT		M.ShowTime, B.LiveIndicator,
					M.leagueid, M.matchcode, M.HomeId, M.AwayId, 
					B.Bettype, C.UGroup,
					SUM (B.Stake) as Stake,
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
					AND B.LiveIndicator = 1
					AND M.Sporttype = 1	
					AND M.Eventdate = @Fromdate
					AND M.EventStatus = 'running'
					AND (M.Leagueid = @LeagueId OR @LeagueId = 0)
					AND (C.UGroup = @UGroup OR @UGroup = 'ALL')
					AND (C.AgentID = @LoggedId OR @IsDirectMem = 0)											 
		GROUP BY	M.ShowTime, B.LiveIndicator,
					M.leagueid, M.matchcode, M.HomeId, M.AwayId, 
					B.Bettype, B.Stake, C.UGroup			

	
GO
GRANT EXECUTE ON [Age_Wagers_SC_4_30_16] TO [aplweb]

		 