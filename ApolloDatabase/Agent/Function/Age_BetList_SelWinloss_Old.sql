ALTER PROCEDURE [dbo].[Age_BetList_SelWinloss_Old]
	@LoggedId INT,
	@AgentId INT = -1 ,
	@CustId INT = -1,
	@FromDate SMALLDATETIME, 
	@ToDate SMALLDATETIME,
	@StatusIds VARCHAR(200)

 AS
/*
Created: 20130301@Sophia
Task : Betlist for Winloss report (Archive Data)
DB:  SVRARC.ArchiveDB
Original:  

Revisions:
  
Param's Explanation:  

EX: Exec [Age_BetList_SelWinloss_Old] 3,-1, 35, '2013-01-01' , '2013-04-09', '0^1^101^103^111^112'


				
*/  
SET NOCOUNT ON


CREATE TABLE #Betlist  (TransId BIGINT, RefNo BIGINT, MatchId INT, MatchCode NVARCHAR(50), 
						HomeId INT, AwayId INT, SportType TINYINT, LeagueId INT, IsNeutral BIT, Showtime NVARCHAR(50),
						Username NVARCHAR(50), BetType SMALLINT, CustId INT , Hdp1 SMALLMONEY, Hdp2 SMALLMONEY, Odds SMALLMONEY, MOdds SMALLMONEY,
						Status VARCHAR(10), Stake MONEY, Actual_Stake MONEY, TransDate DATETIME, WinLostDate SMALLDATETIME,	BetTeam VARCHAR(10), BetId BIGINT, 
						APositionTaking SMALLMONEY, ADiscount DECIMAL (9,8), AWinlost MONEY, AComm MONEY,
						LiveHomeScore SMALLINT, LiveAwayScore SMALLINT,LiveIndicator BIT, 
						IP VARCHAR(40), OddsType TINYINT, DoubleCommLosing BIT)


CREATE TABLE #DirectChild ( AgentId INT)

INSERT INTO #DirectChild 
SELECT	AgentId 
FROM	AgentInfo WITH (NOLOCK)
WHERE	ParentId = @LoggedId

 
DECLARE @LoggedAgentLevel INT
SELECT	@LoggedAgentLevel = AgentLevel
FROM	AgentInfo WITH (NOLOCK)
WHERE	AgentId = @LoggedId


	INSERT INTO #Betlist
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
			BetTrans_BK AS B  WITH (NOLOCK) 
			INNER JOIN BetTrans_Agent_BK AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
			INNER JOIN BetTrans_Agent_BK AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
			LEFT JOIN Bettrans_Agent_BK D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
			INNER JOIN Match_BK m WITH (NOLOCK) ON  B.MatchId = m.MatchId 				
		WHERE 
			BA.AgentId = CASE WHEN @AgentId = -1 THEN BA.AgentId ELSE @AgentId END 
			AND B.CustID = CASE WHEN @CustId = -1 THEN B.CustId ELSE @CustId END 		
			AND (	B.bettype < 31 
					OR B.bettype between 121 and 999
					OR B.bettype between 1301 and 1334 
					OR B.bettype BETWEEN 81 AND 120 				
				) 		
			AND B.StatusId in ( SELECT convert(int,val) FROM dbo.strSplit_Key(@StatusIds,'^') ) 		
			AND B.WinlostDate Between @FromDate AND @ToDate


	----- Mix parlay AND Combination mix parlay
	INSERT INTO #Betlist
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
		FROM BetTrans_BK AS B  WITH (NOLOCK) 		
			INNER JOIN BetTrans_Agent_BK AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
			INNER JOIN BetTrans_Agent_BK AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
			LEFT JOIN Bettrans_Agent_BK D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
		WHERE
			BA.AgentId = CASE WHEN @AgentId = -1 THEN BA.AgentId ELSE @AgentId END 
			AND B.CustID = CASE WHEN @CustId = -1 THEN B.CustId ELSE @CustId END 
			AND B.BetType IN (9,29) 
			AND B.StatusId in ( SELECT convert(int,val) FROM dbo.strSplit_Key(@StatusIds,'^') ) 		
			AND B.WinlostDate Between @FromDate AND @ToDate


	----- Outright
	INSERT INTO #Betlist
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
			bettrans_BK B WITH (NOLOCK)
			INNER JOIN BetTrans_Agent_BK AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
			INNER JOIN BetTrans_Agent_BK AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
			LEFT JOIN Bettrans_Agent_BK D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
			INNER JOIN outright_BK as m WITH (NOLOCK) on  B.matchid=m.orid
			INNER JOIN league_BK lg WITH (NOLOCK) on m.leagueid = lg.leagueid	
		WHERE 
			BA.AgentId = CASE WHEN @AgentId = -1 THEN BA.AgentId ELSE @AgentId END 
			AND B.CustID = CASE WHEN @CustId = -1 THEN B.CustId ELSE @CustId END 		
			AND B.bettype = 10
			AND B.StatusId in ( SELECT convert(int,val) FROM dbo.strSplit_Key(@StatusIds,'^') ) 		
			AND B.WinlostDate Between @FromDate AND @ToDate

SELECT	* , @LoggedAgentLevel
FROM	#Betlist 
ORDER BY TransID DESC 


DROP TABLE #Betlist
DROP TABLE #DirectChild
DROP TABLE #StatusId

GO
GRANT EXECUTE ON [dbo].[Age_BetList_SelWinloss_Old] TO [aplweb]

