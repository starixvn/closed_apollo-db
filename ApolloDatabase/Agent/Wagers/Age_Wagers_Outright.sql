USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Wagers_1_3_5]    Script Date: 6/29/2013 8:34:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_Wagers_Outright]
@LoggedId INT = 0,
@FromDate Date,
@ToDate Date,
@Sporttypes VARCHAR(MAX) = '0',
@IsDirectMem BIT = 0,
@LeagueId INT
AS

/*
Created:  Sophia
Date: 20130628
Task:  Wagers outright
DB: SVRAGE.REPDB
 
Revisions:    

Parameters
	@IsDirectMem : 1: Direct Member
				   0: All Member
 
*/
SET NOCOUNT ON 
				SELECT		M.EventDate, B.LiveIndicator,
							M.leagueid, M.TeamId, M.Orid,
							B.Bettype, B.Stake, B.betteam, 
							B.Status,
							Count(B.TransID) as BetCount,
							SUM(B.Stake) as Stake
				FROM		Bettrans B WITH (NOLOCK)
				INNER JOIN	Bettrans_Agent BA WITH (NOLOCK)
					ON		B.TransId = BA.TransId AND BA.AgentID = @LoggedID  AND BA.Bettype = 10 AND BA.StatusId IN (0,1)
				INNER JOIN	Outright M WITH (NOLOCK)
					ON		M.orid = B.MatchID
				INNER JOIN  League L WITH (NOLOCK) 
					ON		L.LeagueId = M.LeagueId				
				WHERE		B.Bettype = 10
							AND B.StatusId IN (0,1)							
							AND B.LiveIndicator = 0
							AND L.Sporttype IN (SELECT val FROM StrSplit_Key(@Sporttypes, ','))
							AND M.Eventdate BETWEEN @Fromdate AND @ToDate
							AND M.OddsStatus = 'running'
							AND (M.Leagueid = @LeagueId OR @LeagueId = 0)
																 
				GROUP BY	M.EventDate, B.LiveIndicator,
							M.leagueid, M.TeamId, M.Orid,
							B.Bettype, B.Stake, B.betteam, B.Status
			 
				ORDER BY 	M.EventDate, M.leagueid, M.TeamId
GO
GRANT EXECUTE ON [Age_Wagers_Outright] TO [aplweb]

		 