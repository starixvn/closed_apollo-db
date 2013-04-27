
ALTER PROCEDURE [dbo].[Age_BetList_TotalBets_SelRunningByBettypeMatch]
	@MatchID int,
	@LoggedId int,
	@Bettype int,
	@liveindicator int = 0,
	@Betteam nvarchar(20) = NULL
AS

/*
Created: 20130311@Sophia
Task : Betlist
DB: SVRAGE.RepDB
Original:  Age_BetList_SelRunningByBettypeMatch_Ag
Revisions:    
   
*/

SET NOCOUNT ON


DECLARE @AgentLevel INT
SELECT	@AgentLevel = AgentLevel
FROM	AgentInfo WITH (NOLOCK)
WHERE	AgentId = @LoggedId


if @bettype in (10)
BEGIN
	SELECT 
		l.Sporttype,
		B.Username,      		
		B.Bettype,     
		B.TransID,  
		0 as matchid,   
		m.Matchcode, 
		m.GroupMatch as Race,
		m.leagueid,
		m.TeamID as HomeID,
		0 as AwayID, 
		0 as hdp1, 
		0 as hdp2, 
		B.odds,   
		B.modds,
		B.status, 
		B.stake,  
		B.actual_stake,
		B.Transdate, 		
		'' as Betteam, 
		0 as Liveindicator, 
		0 as Livehomescore, 
		0 as Liveawayscore, 		 				
		ISNULL(BA.APositionTaking, 1-B.TPositionTaking) AS APositionTaking,  		
		BA.ADiscount ,
		B.IP as IP,
		CONVERT(BIT,0) as isNeutral,
		0 as oddstype,
		B.betid,
		'' as showtime,
		B.refno,
		B.DoubleCommLosing,
		@AgentLevel as AgentLevel
	FROM Bettrans B WITH (NOLOCK)
	LEFT JOIN BetTrans_Agent AS BA WITH (NOLOCK) 
		ON B.TransID = BA.TransID
	INNER JOIN outright m WITH (NOLOCK) 
		ON B.matchid=m.orid
	INNER JOIN league l WITH (NOLOCK) 
		ON m.leagueid = l.leagueid		
	WHERE
		(BA.AgentId = @LoggedId OR @LoggedId = 0) and
		B.matchid=@matchid and 
		B.bettype=@bettype and
		B.statusID = 0		
	
END
ELSE
IF @bettype< 19001
BEGIN
	SELECT 
		m.sporttype,
		B.Username,      		
		B.Bettype,     
		B.TransID,     
		m.matchid,
		m.Matchcode,   
		'' as Race,
		m.leagueid, 
		m.HomeID,
		m.AwayID, 
		convert(float, B.hdp1) as hdp1, 
		convert(float, B.hdp2) as hdp2, 
		B.odds,
		B.modds,
		CASE WHEN B.status = 'running' AND IsNull(B.SecAcceptFlag, 0) = 1 and IsNull(B.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
				 ELSE B.status 
				 END as status,    
		B.stake,  
		B.actual_stake,
		B.Transdate,   		
		B.Betteam,    
		B.Liveindicator,
		B.Livehomescore, 
		B.Liveawayscore, 		 	
		ISNULL(BA.APositionTaking, 1-B.TPositionTaking) AS APositionTaking,	
		BA.ADiscount ,
		B.IP as IP,
		isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
		B.OddsType,
		B.betid,
		m.showtime,
		B.refno,
		B.DoubleCommLosing,
		@AgentLevel	as AgentLevel
	FROM Bettrans B WITH (NOLOCK)
	LEFT JOIN BetTrans_Agent AS BA WITH (NOLOCK) 
		ON B.TransID = BA.TransID
	INNER JOIN Match m  WITH (NOLOCK) ON B.matchid=m.matchid 	
	WHERE
		(BA.AgentId = @LoggedId OR @LoggedId = 0) AND 
		B.matchid=@matchid and 
		B.bettype=@bettype and
		B.statusID in (0,1) and 
		B.Liveindicator= CASE WHEN m.sporttype = 161 THEN @liveindicator ELSE B.liveindicator END AND
		ISNULL(B.betteam,'') = CASE WHEN m.sporttype = 161 AND ISNULL(@Betteam, '') <> '' THEN @betteam ELSE ISNULL(B.betteam,'') END

END

GO
GRANT EXECUTE ON [dbo].[Age_BetList_TotalBets_SelRunningByBettypeMatch] TO [aplweb]
GO
--GRANT VIEW DEFINITION ON [dbo].[Age_BetList_TotalBets_SelRunningByBettypeMatch] TO [vnteam]
 

 

