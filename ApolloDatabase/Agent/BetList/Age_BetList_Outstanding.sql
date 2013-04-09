ALTER PROC [dbo].[Age_BetList_Outstanding]
	@AgentId INT,
	@CustId INT
 AS
/*
Created: 20130301@Sophia
Task : Betlist for Outstanding
DB:  SVRAGE.RepDB
Original:  

Revisions:
  
*/ 
 
SET NOCOUNT ON
DECLARE @Betlist TABLE (SportType tinyint, Username NVARCHAR(50), BetType smallint, CustId INT ,TransId BIGINT, RefNo BIGINT,
						MatchId INT, MatchCode nvarchar(50), HomeId INT, AwayId INT, Hdp1 smallmoney, Hdp2 smallmoney, Odds smallmoney, MOdds smallmoney,
						Status varchar(10), Stake MONEY, Actual_Stake MONEY, TransDate datetime, BetTeam varchar(10), BetId bigint, 
						APositionTaking smallmoney, ADiscount decimal (9,8), LeagueId INT, LiveHomeScore smallint, LiveAwayScore smallint,LiveIndicator bit, 
						IP varchar(40), IsNeutral BIT, Oddstype tinyint, ShowTime nvarchar(50),	DoubleCommLosing BIT)

INSERT INTO @Betlist
SELECT 
		m.SportType,
		B.Username,
		B.BetType,
		B.CustId,		
		B.TransId,
		B.RefNo,
		m.MatchId,
		Convert(nvarchar(50),m.MatchCode) as MatchCode ,
		m.HomeId,
		m.AwayId,
		B.Hdp1, 
		B.Hdp2, 
		B.Odds,
		B.MOdds,
		CASE WHEN B.Status = 'running' AND IsNull(B.SecAcceptFlag, 0) = 1 AND IsNull(B.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
				 ELSE B.Status 
				 END as Status,
		B.Stake,
		B.Actual_Stake,
		B.TransDate,		
		B.BetTeam,
		B.BetId,
		BA.APositionTaking,
		BA.ADiscount,
		m.LeagueId, 
		B.LiveHomeScore,
		B.LiveAwayScore,
		B.LiveIndicator, 
		B.IP,
		M.IsNeutral,
		B.Oddstype,
		m.ShowTime,
		DoubleCommLosing
 	from 	
		BetTrans AS b  WITH (NOLOCK) 
		INNER JOIN BetTrans_Agent AS ba WITH (NOLOCK) ON BA.TransId = B.TransId
		INNER JOIN  Match m WITH (NOLOCK) ON  B.MatchId = m.MatchId 				
	where 
		BA.AgentId = @AgentId 
		AND B.CustID = @CustId
		AND (	B.bettype < 31 
					OR B.bettype between 121 and 999
					OR B.bettype between 1301 and 1334 
					OR B.bettype BETWEEN 81 AND 120 				
			) 		
		AND B.StatusId in (0,1)		


----- mix parlay AND Combination mix parlay
INSERT INTO @Betlist
	SELECT 
		0 as sporttype,
		B.Username,				
		B.BetType,
		B.CustId,
		B.TransId,
		B.RefNo,
		0 as matchid,
		'' matchcode,
		0 as homeID,
		0 as awayID,
		0 as hdp1,
		0 as hdp2,
		B.Odds,
		B.MOdds,
		B.Status,
		B.Stake,
		B.Actual_Stake,
		B.TransDate,		
		B.BetTeam,
		B.BetId,
		BA.APositionTaking,
		BA.ADiscount,
		'' as LeagueId,
		0 AS LiveHomeScore, 
		0 AS LiveAwayScore,
		0 AS LiveIndicator ,
		B.IP,
		CONVERT(BIT,0) as IsNeutral,
		0 as OddStype,
		'' as ShowTime,
		B.DoubleCommLosing	
	FROM BetTrans AS B  WITH (NOLOCK) 
		INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
	WHERE
		BA.AgentId = @AgentId 	
		AND B.CustID = @CustId  
		AND B.matchid IN (9,29) 
		AND B.BetType IN (9,29) 
		AND B.statusID IN (0,1)	 



----- Outright
INSERT INTO @Betlist
select 
		l.sporttype,
		B.username,
		B.bettype,	
		B.custid,			
		B.transid,
		B.refno,
		0 as matchid,
		m.matchcode,
		m.teamID as homeID,
		0 as awayID,
		B.hdp1, 
		B.hdp2, 
		B.odds,
		B.modds,
		B.status,
		B.stake,
		B.actual_stake,
		B.transdate,		
		B.betteam,
		B.betID,
		BA.APositionTaking,
		BA.ADiscount,
		m.LeagueID,
		B.livehomescore,
		B.liveawayscore,
		B.liveindicator, 
		B.IP as IP,
		CONVERT(BIT,0) as IsNeutral,
		0 as oddstype,
		'' as showtime,
		B.DoubleCommLosing
	from 		
		bettrans b with (nolock)
		INNER JOIN BetTrans_Agent AS ba WITH (NOLOCK) ON BA.TransId = B.TransId
		INNER JOIN SVRPRO.ProdDB.dbo.outright as m with (nolock) on  B.matchid=m.orid
		INNER JOIN SVRPRO.ProdDB.dbo.league l with (nolock) on m.leagueid = l.leagueid	
	where 
		BA.AgentId = @AgentId 	
		AND B.CustId = @CustId
		AND B.bettype = 10
		AND B.statusID=0 			 
 

SELECT * FROM @Betlist 
ORDER BY TransID

GO
GRANT VIEW DEFINITION ON [dbo].[Age_BetList_Outstanding] TO [aplweb]

