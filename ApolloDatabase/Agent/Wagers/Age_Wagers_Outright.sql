ALTER PROCEDURE [dbo].[Age_Wagers_Outright]
@IsSuperView BIT = 0,
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
	-- 20130712@Sophia: Add @IsSuperView and calculate Stake after Share

Parameters
	@IsDirectMem : 1: Direct Member
				   0: All Member
	@IsSuperView =  1: Super view on Main shareholder @LoggedId
				 =	0: @LoggedId view on his line
*/
SET NOCOUNT ON 
	SELECT	DISTINCT M.EventDate, 
					M.leagueid, M.TeamId, M.Orid as MatchID, M.Status,
					B.Bettype, '0' as betteam, 							
					Count(B.TransID) as BetCount,
					SUM( CASE WHEN @IsSuperView = 1 THEN (1-B.TPositionTaking) ELSE BA.APositionTaking END * B.Stake) AS Stake						
		FROM		Bettrans B WITH (NOLOCK)
		INNER JOIN	Bettrans_Agent BA WITH (NOLOCK)
			ON		B.TransId = BA.TransId AND BA.AgentID = @LoggedID  AND BA.Bettype = 10 AND BA.StatusId IN (0,1)
		INNER JOIN	Outright M WITH (NOLOCK)
			ON		M.orid = B.MatchID
		INNER JOIN  League L WITH (NOLOCK) 
			ON		L.LeagueId = M.LeagueId	
		INNER JOIN  CustInfo C WITH (NOLOCK)
			ON		C.CustID = B.CustID
		WHERE		B.Bettype = 10
					AND B.StatusId IN (0,1)														
					AND (@Sporttypes = '0' OR L.Sporttype IN (SELECT val FROM StrSplit_Key(@Sporttypes, ',')))
					AND M.Eventdate BETWEEN @Fromdate AND @ToDate
					AND M.OddsStatus = 'running'
					AND (M.Leagueid = @LeagueId OR @LeagueId = 0)							
					AND (C.AgentID = @LoggedId OR @IsDirectMem = 0)										 
		GROUP BY	M.EventDate, B.bettype,
					M.leagueid, M.TeamId, M.Orid, M.Status
			 
		ORDER BY 	M.EventDate, M.leagueid, M.Status, M.TeamId
 


  
  GO
GRANT EXECUTE ON [Age_Wagers_Outright] TO [aplweb]
