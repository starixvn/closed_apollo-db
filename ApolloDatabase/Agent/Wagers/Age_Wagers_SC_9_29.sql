ALTER  PROCEDURE [dbo].[Age_Wagers_SC_9_29]
@LoggedId INT = 0,
@FromDate Date,
@UGroup varchar(3) = 'ALL',
@IsDirectMem BIT = 0,
@LeagueId INT
AS

/*
Created:  Sophia
Date: 20130701
Task:  Wagers for soccer - Parlay
DB: SVRAGE.REPDB
 
Revisions:    
	

Parameters
	@IsDirectMem : 1: Direct Member
				   0: All Member
 
*/
SET NOCOUNT ON 
	SELECT		B.Showtime, B.LiveIndicator,
				B.leagueid, B.matchcode, B.HomeId, B.AwayId,
				
				SUM(CASE WHEN B.Bettype = 9 THEN B.Stake ELSE 0 END) AS Stake9,
				SUM(CASE WHEN B.BetType = 29 THEN B.Stake ELSE 0 END) AS Stake29,

				SUM(CASE WHEN B.Bettype = 9 THEN B.BetCount ELSE 0 END) AS Count9,
				SUM(CASE WHEN B.Bettype = 29 THEN B.BetCount ELSE 0 END) AS Count29
				
	FROM (		
				SELECT		M.ShowTime, B.LiveIndicator,
							M.leagueid, M.matchcode, M.HomeId, M.AwayId, 
							B.Bettype, B.Stake,  
							Count(DISTINCT B.TransID) as BetCount
				FROM		Bettrans B WITH (NOLOCK)
				INNER JOIN	Bettrans_Agent BA WITH (NOLOCK)
					ON		B.TransId = BA.TransId AND BA.AgentID = @LoggedId  AND BA.Bettype IN (9,29) AND BA.StatusId IN (0,1)
				INNER JOIN  BetTransM BM WITH (NOLOCK) 
					ON		BM.Refno = B.RefNo
				INNER JOIN	Match M WITH (NOLOCK)
					ON		M.matchID = BM.MatchID
				INNER JOIN  CustInfo C WITH (NOLOCK)
					ON		C.CustID = B.CustID
				WHERE		B.Bettype IN (9,29)
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
							B.Bettype, B.Stake 
				) B

	GROUP BY 	B.ShowTime, B.LiveIndicator,
				B.leagueid, B.matchcode, B.HomeId, B.AwayId  
	ORDER BY 	B.ShowTime,B.leagueid, B.matchcode, B.HomeId, B.AwayId

	
GO
GRANT EXECUTE ON [Age_Wagers_SC_9_29] TO [aplweb]

 