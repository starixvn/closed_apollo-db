ALTER PROCEDURE [dbo].[Age_BetList_SelByDateMemStatus]
	@LoggedId INT,
	@AgentId INT = -1 ,
	@CustId INT = -1,
	@FromDate SMALLDATETIME, 
	@Todate SMALLDATETIME,
	@StatusIds VARCHAR(200)

 AS
/*
Created: 20130301@Sophia
Task : Betlist for Outstanding report/ Cancel Bets Report/ Account Info-Betlist
DB:  SVRAGE.RepDB
Original:  

Revisions:
  
EX:
 Exec [Age_BetList_SelByDateMemStatus] 3,-1, 63967, '2013-01-01' , '2013-04-09', '0^1^101^103' 
 Exec [Age_BetList_SelByDateMemStatus] 3,99, -1, '2012-01-01' , '2013-04-15', '0^1^101^102^103^111^112^113'

Param's Explanation:  
	+ @IsAgent = 1 : by Agent's Username,
			   = 0 : by Member's Username
				
*/  
SET NOCOUNT ON


DECLARE @Betlist TABLE (TransId BIGINT, RefNo BIGINT, MatchId INT, MatchCode NVARCHAR(50), 
						HomeId INT, AwayId INT, SportType TINYINT, LeagueId INT, IsNeutral BIT, Showtime NVARCHAR(50),
						Username NVARCHAR(50), BetType SMALLINT, CustId INT , Hdp1 SMALLMONEY, Hdp2 SMALLMONEY, Odds SMALLMONEY, MOdds SMALLMONEY,
						Status VARCHAR(10), Stake MONEY, Actual_Stake MONEY, TransDate DATETIME, BetTeam VARCHAR(10), BetId BIGINT, 
						APositionTaking SMALLMONEY, ADiscount DECIMAL (9,8), AWinlost MONEY, AComm MONEY,
						LiveHomeScore SMALLINT, LiveAwayScore SMALLINT,LiveIndicator BIT, 
						IP VARCHAR(40), OddsType TINYINT, DoubleCommLosing BIT)

DECLARE @DirectChild TABLE ( AgentId INT)

INSERT INTO @DirectChild 
SELECT	AgentId 
FROM	AgentInfo WITH (NOLOCK)
WHERE	ParentId = @LoggedId
 

INSERT INTO @Betlist
SELECT 	B.TransId,
		B.RefNo,
		m.MatchId,
		m.MatchCode ,
		m.HomeId,
		m.AwayId,
		m.SportType,
		m.LeagueId, 
		m.IsNeutral,
		m.ShowTime,
		B.Username,
		B.BetType,
		B.CustId,
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
		L.APositionTaking,
		L.ADiscount,
		L.AWinlost,
		L.AComm - ISNULL(D.AComm, B.PlayerComm) as AComm,
		B.LiveHomeScore,
		B.LiveAwayScore,
		B.LiveIndicator, 
		B.IP,		
		B.Oddstype,		
		B.DoubleCommLosing
 	FROM 	
		BetTrans AS B  WITH (NOLOCK) 
		INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId 
		INNER JOIN BetTrans_Agent AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
		LEFT JOIN Bettrans_Agent D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM @DirectChild) 
		INNER JOIN Match m WITH (NOLOCK) ON  B.MatchId = m.MatchId 				
	WHERE 
		BA.AgentId = CASE WHEN @AgentId = -1 THEN BA.AgentId ELSE @AgentId END 
		AND B.CustID = CASE WHEN @CustId = -1 THEN B.CustId ELSE @CustId END 		
		AND (	B.bettype < 31 
				OR B.bettype between 121 and 999
				OR B.bettype between 1301 and 1334 
				OR B.bettype BETWEEN 81 AND 120 				
			) 		
		AND B.StatusId in ( SELECT convert(int,val) FROM dbo.strSplit_Key(@StatusIds,'^') ) 		
		AND B.TransDate Between @FromDate AND @ToDate


----- Mix parlay AND Combination mix parlay
INSERT INTO @Betlist
	SELECT 
		
		B.TransId,
		B.RefNo,
		0 as matchid,
		'' matchcode,
		0 as homeID,
		0 as awayID,
		0 as sporttype,
		'' as LeagueId,
		CONVERT(BIT,0) as IsNeutral,
		'' as ShowTime,
		B.Username,				
		B.BetType,
		B.CustId,
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
		L.APositionTaking,
		L.ADiscount,
		L.AWinlost,
		L.AComm - ISNULL(D.AComm, B.PlayerComm) as AComm,
		0 AS LiveHomeScore, 
		0 AS LiveAwayScore,
		0 AS LiveIndicator ,
		B.IP,		
		0 as OddStype,		
		B.DoubleCommLosing	
	FROM BetTrans AS B  WITH (NOLOCK) 		
		INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
		INNER JOIN BetTrans_Agent AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
		LEFT JOIN Bettrans_Agent D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM @DirectChild) 
	WHERE
		BA.AgentId = CASE WHEN @AgentId = -1 THEN BA.AgentId ELSE @AgentId END 
		AND B.CustID = CASE WHEN @CustId = -1 THEN B.CustId ELSE @CustId END 
		AND B.BetType IN (9,29) 
		AND B.StatusId in ( SELECT convert(int,val) FROM dbo.strSplit_Key(@StatusIds,'^') ) 		
		AND B.TransDate Between @FromDate AND @ToDate


----- Outright
INSERT INTO @Betlist
SELECT 				
		B.transid,
		B.refno,
		0 as matchid,
		m.matchcode,
		m.teamID as homeID,
		0 as awayID,
		lg.sporttype,
		m.LeagueID,
		CONVERT(BIT,0) as IsNeutral,
		'' as showtime,
		B.username,
		B.bettype,	
		B.custid,
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
		L.APositionTaking,
		L.ADiscount,
		L.AWinlost,
		L.AComm - ISNULL(D.AComm, B.PlayerComm) as AComm,		
		B.livehomescore,
		B.liveawayscore,
		B.liveindicator, 
		B.IP as IP,		
		0 as oddstype,		
		B.DoubleCommLosing
	FROM 		
		bettrans B WITH (NOLOCK)
		INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
		INNER JOIN BetTrans_Agent AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
		LEFT JOIN Bettrans_Agent D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM @DirectChild) 
		INNER JOIN outright as m WITH (NOLOCK) on  B.matchid=m.orid
		INNER JOIN league lg WITH (NOLOCK) on m.leagueid = lg.leagueid	
	WHERE 
		BA.AgentId = CASE WHEN @AgentId = -1 THEN BA.AgentId ELSE @AgentId END 
		AND B.CustID = CASE WHEN @CustId = -1 THEN B.CustId ELSE @CustId END 		
		AND B.bettype = 10
		AND B.StatusId in ( SELECT convert(int,val) FROM dbo.strSplit_Key(@StatusIds,'^') ) 		
		AND B.TransDate Between @FromDate AND @ToDate

SELECT DISTINCT * FROM @Betlist 
ORDER BY TransID

GO
GRANT EXECUTE ON [dbo].[Age_BetList_SelByDateMemStatus] TO [aplweb]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_BetList_SelByDateMemStatus] TO [vnteam]
