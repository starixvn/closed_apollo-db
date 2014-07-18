
ALTER PROCEDURE [dbo].[Age_BetList_TotalBets_SelRunningByBettypeMatch]
	@MatchID int,
	@LoggedId int,
	@AgentId int,
	@Bettype int,
	@liveindicator int = 0,
	@Betteam nvarchar(20) = NULL
AS

/*
Created	: 20130311@Sophia
Task	: Betlist of totalbets
DB		: SVRAGE.RepDB
Original:  Age_BetList_SelRunningByBettypeMatch_Ag
Revisions:    
	- 20130507@Sophia: Add @AgentID for Super view total bets of Main shareholder
    - 20130627@Sophia: Add UGroup for Singbet
	- 20130708@Sophia: Change SuperId from 0 to 1 (@AgentID = 1)
	- 20140718@Sophia: Get BetFrom
*/

SET NOCOUNT ON
 
IF @LoggedId = 1
BEGIN 
	IF @bettype = 10
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
			(1-B.TPositionTaking) as APositionTaking,  		
			NULL as ADiscount ,
			B.IP as IP,
			CONVERT(BIT,0) as isNeutral,
			0 as oddstype,
			B.betid,
			'' as showtime,
			B.refno,
			B.DoubleCommLosing,
			C.UGroup, 
			B.PlayerDiscount,
			B.BetFrom
		FROM Bettrans B WITH (NOLOCK)
		INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK) 
			ON B.TransID = BA.TransID
		INNER JOIN outright m WITH (NOLOCK) 
			ON B.matchid=m.orid
		INNER JOIN league l WITH (NOLOCK) 
			ON m.leagueid = l.leagueid
		INNER JOIN CustInfo C  WITH (NOLOCK) 
			ON  C.CustId = B.CustId	
		WHERE
			BA.AgentId = @AgentId and
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
			(1-B.TPositionTaking) as APositionTaking,  		
			NULL as ADiscount ,
			B.IP as IP,
			isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
			B.OddsType,
			B.betid,
			m.showtime,
			B.refno,
			B.DoubleCommLosing,
			C.UGroup,
			B.PlayerDiscount,
			B.BetFrom
		FROM Bettrans B WITH (NOLOCK)
		INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK) 
			ON B.TransID = BA.TransID
		INNER JOIN Match m  WITH (NOLOCK) 
			ON B.matchid=m.matchid
		INNER JOIN CustInfo C  WITH (NOLOCK) 
			ON  C.CustId = B.CustId	
		WHERE
			BA.AgentId = @AgentId AND 
			B.matchid=@matchid and 
			B.bettype=@bettype and
			B.statusID in (0,1)  
			---B.Liveindicator= CASE WHEN m.sporttype = 161 THEN @liveindicator ELSE B.liveindicator END AND
			---ISNULL(B.betteam,'') = CASE WHEN m.sporttype = 161 AND ISNULL(@Betteam, '') <> '' THEN @betteam ELSE ISNULL(B.betteam,'') END
		END
END
ELSE 
BEGIN 
	if @bettype = 10
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
			BA.APositionTaking,  		
			BA.ADiscount ,
			B.IP as IP,
			CONVERT(BIT,0) as isNeutral,
			0 as oddstype,
			B.betid,
			'' as showtime,
			B.refno,
			B.DoubleCommLosing,
			C.UGroup,
			B.PlayerDiscount,
			B.BetFrom
		FROM Bettrans B WITH (NOLOCK)
		INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK) 
			ON B.TransID = BA.TransID
		INNER JOIN outright m WITH (NOLOCK) 
			ON B.matchid=m.orid
		INNER JOIN league l WITH (NOLOCK) 
			ON m.leagueid = l.leagueid
		INNER JOIN CustInfo C  WITH (NOLOCK) 
			ON  C.CustId = B.CustId		
		WHERE
			BA.AgentId = @AgentId and
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
			BA.APositionTaking,	
			BA.ADiscount ,
			B.IP as IP,
			isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
			B.OddsType,
			B.betid,
			m.showtime,
			B.refno,
			B.DoubleCommLosing,
			C.UGroup,
			B.PlayerDiscount,
			B.BetFrom
		FROM Bettrans B WITH (NOLOCK)
		INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK) 
			ON B.TransID = BA.TransID
		INNER JOIN Match m  WITH (NOLOCK) 
			ON B.matchid=m.matchid
		INNER JOIN CustInfo C  WITH (NOLOCK) 
			ON  C.CustId = B.CustId
		WHERE
			BA.AgentId = @AgentId AND 
			B.matchid=@matchid and 
			B.bettype=@bettype and
			B.statusID in (0,1)  
			---B.Liveindicator= CASE WHEN m.sporttype = 161 THEN @liveindicator ELSE B.liveindicator END AND
			---ISNULL(B.betteam,'') = CASE WHEN m.sporttype = 161 AND ISNULL(@Betteam, '') <> '' THEN @betteam ELSE ISNULL(B.betteam,'') END
		END 
END




GO
GRANT EXECUTE ON [dbo].[Age_BetList_TotalBets_SelRunningByBettypeMatch] TO [aplweb]
GO
 

 

