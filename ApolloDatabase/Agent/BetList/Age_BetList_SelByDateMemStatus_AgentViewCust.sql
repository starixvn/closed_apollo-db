ALTEr PROCEDURE [dbo].[Age_BetList_SelByDateMemStatus_AgentViewCust]
	@LoggedId INT,
	@AgentId INT = -1 ,
	@CustId INT = -1,
	@FromDate SMALLDATETIME, 
	@Todate SMALLDATETIME,
	@StatusIds VARCHAR(1000),
	@Sporttypes VARCHAR(1000) ='0',
	@Bettypes VARCHAR(1000) = '0',
	@RptType TINYINT = 0,
	@MoveBetsDay SMALLDATETIME = NULL


 AS
/*
Created: 20130301@Sophia
Task : Betlist for Outstanding report/ Cancel Bets Report/ Account Info-Betlist -- 1: AgentViewCust
DB:  SVRAGE.RepDB
Original:  
Revisions:

Param's Explanation:  
	@RptType = 0: Normal
			 = 1: Called from Report Transaction
				
*/  
SET NOCOUNT ON


CREATE TABLE #Betlist ( TransId BIGINT, RefNo BIGINT, MatchId INT, MatchCode NVARCHAR(50), 
						HomeId INT, AwayId INT, SportType TINYINT, LeagueId INT, IsNeutral BIT, BetStatus NVARCHAR(50),
						Username NVARCHAR(50), BetType SMALLINT, CustId INT , Hdp1 SMALLMONEY, Hdp2 SMALLMONEY, Odds SMALLMONEY, MOdds SMALLMONEY,
						Status VARCHAR(10), Stake MONEY, Actual_Stake MONEY, TransDate DATETIME, BetTeam VARCHAR(10), BetId BIGINT, 
						PlayerDiscount DECIMAL (9,8), Winlost MONEY, PlayerComm MONEY, 
						APositionTaking SMALLMONEY, ADiscount DECIMAL (9,8), AWinlost MONEY, AComm MONEY,
						LiveHomeScore SMALLINT, LiveAwayScore SMALLINT,LiveIndicator BIT, 
						FinalHomeScore SMALLINT, FinalAwayScore SMALLINT,
						IP VARCHAR(40), OddsType TINYINT, DoubleCommLosing BIT, UGroup VARCHAR(3))

CREATE TABLE #DirectChild ( AgentId INT)

INSERT INTO #DirectChild 
SELECT	AgentId 
FROM	AgentInfo WITH (NOLOCK)
WHERE	ParentId = @LoggedId


DECLARE @LoggedAgentLevel INT
SELECT	@LoggedAgentLevel = AgentLevel
FROM	AgentInfo WITH (NOLOCK)
WHERE	AgentId = @LoggedId

CREATE TABLE #StatusId ( StatusId TINYINT)
INSERT INTO #StatusId
SELECT val FROM dbo.strSplit_Key(@StatusIds,',')

CREATE TABLE #BettypeList (bettype SMALLINT)
INSERT INTO #BettypeList
SELECT val FROM dbo.strSplit_Key(@Bettypes,',')

CREATE TABLE #SportsList (Sporttype TINYINT)
INSERT INTO #SportsList (Sporttype)
SELECT val FROM strSplit_key (@Sporttypes, ',')
		
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
				m.BetStatus,
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
				B.PlayerDiscount,
				B.WinLost - B.Actual_Stake as WinLost,
				B.PlayerComm,
				L.APositionTaking ,
				L.ADiscount ,
				L.AWinlost,
				L.AComm - ISNULL(D.AComm, B.PlayerComm) as AComm,	
				B.LiveHomeScore,
				B.LiveAwayScore,
				B.LiveIndicator,
				m.FinalHomeScore,
				m.FinalAwayScore, 
				B.IP,		
				B.Oddstype,		
				B.DoubleCommLosing,
				C.UGroup
 			FROM 	
				BetTrans AS B  WITH (NOLOCK)				
				INNER JOIN BetTrans_Agent AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
				LEFT JOIN Bettrans_Agent D WITH (NOLOCK) 
						ON D.TransID = B.TransID 
						AND D.AgentID IN (SELECT AgentId FROM #DirectChild)
						AND D.StatusId in (SELECT StatusId FROM #StatusId ) 	
						AND D.TransDate Between @FromDate AND @ToDate	
						AND (	D.bettype < 31 
								OR D.bettype between 121 and 999
								OR D.bettype between 1301 and 1334 				
						)
						AND (@Bettypes = '0' OR D.Bettype IN (Select bettype FROM #BettypeList)) 		 
				INNER JOIN Match m WITH (NOLOCK) ON  B.MatchId = m.MatchId 						
				INNER JOIN CustInfo C  WITH (NOLOCK) ON  C.CustId = B.CustId
			WHERE	B.CustID = @CustId  
				AND B.StatusId in (SELECT StatusId FROM #StatusId ) 	
				AND B.TransDate Between @FromDate AND @ToDate	
				AND (	B.bettype < 31 
						OR B.bettype between 121 and 999
						OR B.bettype between 1301 and 1334 				
				)
				AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList)) 
				
				AND L.StatusId in (SELECT StatusId FROM #StatusId ) 	
				AND L.TransDate Between @FromDate AND @ToDate	
				AND (	L.bettype < 31 
						OR L.bettype between 121 and 999
						OR L.bettype between 1301 and 1334 				
				)
				AND (@Bettypes = '0' OR L.Bettype IN (Select bettype FROM #BettypeList)) 				
				AND (@Sporttypes = '0' OR M.sporttype IN (Select sporttype FROM #SportsList)) 		
				
			
		---- Parlay
		INSERT INTO #Betlist
		SELECT  DISTINCT 
				B.TransId,
				B.RefNo,
				0 as matchid,
				'' matchcode,
				0 as homeID,
				0 as awayID,
				0 as sporttype,
				'' as LeagueId,
				CONVERT(BIT,0) as IsNeutral,
				'' as BetStatus,
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
				B.PlayerDiscount,
				B.WinLost - B.Actual_Stake as WinLost,
				B.PlayerComm,
				L.APositionTaking,
				L.ADiscount,
				L.AWinlost,
				L.AComm - ISNULL(D.AComm, B.PlayerComm) as AComm,
				0 AS LiveHomeScore, 
				0 AS LiveAwayScore,
				0 AS LiveIndicator,
				0 as FinalHomeScore,
				0 as FinalAwayScore,
				B.IP,		
				0 as OddStype,		
				B.DoubleCommLosing,
				C.UGroup	
			FROM BetTrans AS B  WITH (NOLOCK) 		
				INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
				INNER JOIN BetTrans_Agent AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
				LEFT JOIN Bettrans_Agent D WITH (NOLOCK) 
						ON D.TransID = B.TransID
						AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
						AND D.StatusId in (SELECT StatusId FROM #StatusId ) 
						AND D.TransDate Between @FromDate AND @ToDate
						AND D.BetType IN (9,29) 
						AND (@Bettypes = '0' OR D.Bettype IN (Select bettype FROM #BettypeList)) 
				INNER JOIN CustInfo C  WITH (NOLOCK) ON  C.CustId = B.CustId
				INNER JOIN BettransM14 BM WITH (NOLOCK) ON BM.RefNo = B.RefNo
				INNER JOIN Match m WITH (NOLOCK) ON m.MatchID = BM.MatchID
			WHERE   B.CustID = @CustId 				
				AND B.StatusId in (SELECT StatusId FROM #StatusId ) 
				AND B.TransDate Between @FromDate AND @ToDate
				AND B.BetType IN (9,29) 
				AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList)) 
				
				AND BA.StatusId in (SELECT StatusId FROM #StatusId ) 
				AND BA.TransDate Between @FromDate AND @ToDate
				AND BA.BetType IN (9,29) 
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList)) 
				
				AND L.StatusId in (SELECT StatusId FROM #StatusId ) 
				AND L.TransDate Between @FromDate AND @ToDate
				AND L.BetType IN (9,29) 
				AND (@Bettypes = '0' OR L.Bettype IN (Select bettype FROM #BettypeList)) 
								
				AND (@Sporttypes = '0' OR M.sporttype IN (Select sporttype FROM #SportsList)) 		


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
				'' as BetStatus,
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
				B.PlayerDiscount,
				B.WinLost - B.Actual_Stake as WinLost,
				B.PlayerComm,
				L.APositionTaking,
				L.ADiscount,
				L.AWinlost,
				L.AComm - ISNULL(D.AComm, B.PlayerComm) as AComm,		
				B.livehomescore,
				B.liveawayscore,
				B.liveindicator,
				0 AS FinalHomeScore,
				0 AS FinalAwayScore, 
				B.IP as IP,		
				0 as oddstype,		
				B.DoubleCommLosing,
				C.UGroup
			FROM 		
				bettrans B WITH (NOLOCK)
				INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
				INNER JOIN BetTrans_Agent AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
				LEFT JOIN Bettrans_Agent D WITH (NOLOCK) 
						ON D.TransID = B.TransID 
							AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
							AND D.StatusId in (SELECT StatusId FROM #StatusId ) 	
							AND D.TransDate Between @FromDate AND @ToDate
							AND D.bettype = 10
							AND (@Bettypes = '0' OR D.Bettype IN (Select bettype FROM #BettypeList)) 
				INNER JOIN outright as m WITH (NOLOCK) on  B.matchid=m.orid
				INNER JOIN league lg WITH (NOLOCK) on m.leagueid = lg.leagueid	
				INNER JOIN CustInfo C  WITH (NOLOCK) ON  C.CustId = B.CustId
			WHERE  B.CustID = @CustId 				
				AND B.StatusId in (SELECT StatusId FROM #StatusId ) 	
				AND B.TransDate Between @FromDate AND @ToDate
				AND B.bettype = 10
				AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList)) 
				
				AND BA.StatusId in (SELECT StatusId FROM #StatusId ) 	
				AND BA.TransDate Between @FromDate AND @ToDate
				AND BA.bettype = 10
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList)) 
				
				AND L.StatusId in (SELECT StatusId FROM #StatusId ) 	
				AND L.TransDate Between @FromDate AND @ToDate
				AND L.bettype = 10
				AND (@Bettypes = '0' OR L.Bettype IN (Select bettype FROM #BettypeList)) 
								
				AND (@Sporttypes = '0' OR lg.sporttype IN (Select sporttype FROM #SportsList)) 	

IF @RptType = 0
BEGIN 	
	SELECT *, @LoggedAgentLevel as AgentLevel
	FROM #Betlist 
	ORDER BY TransID
END 
ELSE --- Called from report Transaction 
BEGIN
	IF @FromDate <= @MoveBetsDay
	BEGIN 
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
				m.BetStatus,
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
				B.PlayerDiscount,
				B.WinLost - B.Actual_Stake as WinLost,
				B.PlayerComm,
				L.APositionTaking ,
				L.ADiscount ,
				L.AWinlost,
				L.AComm - ISNULL(D.AComm, B.PlayerComm) as AComm,	
				B.LiveHomeScore,
				B.LiveAwayScore,
				B.LiveIndicator,
				m.FinalHomeScore,
				m.FinalAwayScore, 
				B.IP,		
				B.Oddstype,		
				B.DoubleCommLosing,
				C.UGroup
 			FROM 	
				Bettrans14 AS B  WITH (NOLOCK)				
				INNER JOIN Bettrans14_Agent AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
				LEFT JOIN Bettrans14_Agent D WITH (NOLOCK) 
						ON D.TransID = B.TransID 
						AND D.AgentID IN (SELECT AgentId FROM #DirectChild)
						AND D.StatusId in (SELECT StatusId FROM #StatusId ) 	
						AND D.TransDate Between @FromDate AND @ToDate	
						AND (	D.bettype < 31 
								OR D.bettype between 121 and 999
								OR D.bettype between 1301 and 1334 				
						)
						AND (@Bettypes = '0' OR D.Bettype IN (Select bettype FROM #BettypeList)) 		 
				INNER JOIN MatchId m WITH (NOLOCK) ON  B.MatchId = m.MatchId 						
				INNER JOIN CustInfo C  WITH (NOLOCK) ON  C.CustId = B.CustId
			WHERE	B.CustID = @CustId  
				AND B.StatusId in (SELECT StatusId FROM #StatusId ) 	
				AND B.TransDate Between @FromDate AND @ToDate	
				AND (	B.bettype < 31 
						OR B.bettype between 121 and 999
						OR B.bettype between 1301 and 1334 				
				)
				AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList)) 
				
				AND L.StatusId in (SELECT StatusId FROM #StatusId ) 	
				AND L.TransDate Between @FromDate AND @ToDate	
				AND (	L.bettype < 31 
						OR L.bettype between 121 and 999
						OR L.bettype between 1301 and 1334 				
				)
				AND (@Bettypes = '0' OR L.Bettype IN (Select bettype FROM #BettypeList)) 				
				AND (@Sporttypes = '0' OR M.sporttype IN (Select sporttype FROM #SportsList)) 		
				
			
		---- Parlay
		INSERT INTO #Betlist
		SELECT  DISTINCT 
				B.TransId,
				B.RefNo,
				0 as matchid,
				'' matchcode,
				0 as homeID,
				0 as awayID,
				0 as sporttype,
				'' as LeagueId,
				CONVERT(BIT,0) as IsNeutral,
				'' as BetStatus,
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
				B.PlayerDiscount,
				B.WinLost - B.Actual_Stake as WinLost,
				B.PlayerComm,
				L.APositionTaking,
				L.ADiscount,
				L.AWinlost,
				L.AComm - ISNULL(D.AComm, B.PlayerComm) as AComm,
				0 AS LiveHomeScore, 
				0 AS LiveAwayScore,
				0 AS LiveIndicator,
				0 as FinalHomeScore,
				0 as FinalAwayScore,
				B.IP,		
				0 as OddStype,		
				B.DoubleCommLosing,
				C.UGroup	
			FROM Bettrans14 AS B  WITH (NOLOCK) 		
				INNER JOIN Bettrans14_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
				INNER JOIN Bettrans14_Agent AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
				LEFT JOIN Bettrans14_Agent D WITH (NOLOCK) 
						ON D.TransID = B.TransID
						AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
						AND D.StatusId in (SELECT StatusId FROM #StatusId ) 
						AND D.TransDate Between @FromDate AND @ToDate
						AND D.BetType IN (9,29) 
						AND (@Bettypes = '0' OR D.Bettype IN (Select bettype FROM #BettypeList)) 
				INNER JOIN CustInfo C  WITH (NOLOCK) ON  C.CustId = B.CustId
				INNER JOIN BettransM1414 BM WITH (NOLOCK) ON BM.RefNo = B.RefNo
				INNER JOIN MatchId m WITH (NOLOCK) ON m.MatchID = BM.MatchID
			WHERE   B.CustID = @CustId 				
				AND B.StatusId in (SELECT StatusId FROM #StatusId ) 
				AND B.TransDate Between @FromDate AND @ToDate
				AND B.BetType IN (9,29) 
				AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList)) 
				
				AND BA.StatusId in (SELECT StatusId FROM #StatusId ) 
				AND BA.TransDate Between @FromDate AND @ToDate
				AND BA.BetType IN (9,29) 
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList)) 
				
				AND L.StatusId in (SELECT StatusId FROM #StatusId ) 
				AND L.TransDate Between @FromDate AND @ToDate
				AND L.BetType IN (9,29) 
				AND (@Bettypes = '0' OR L.Bettype IN (Select bettype FROM #BettypeList)) 
								
				AND (@Sporttypes = '0' OR M.sporttype IN (Select sporttype FROM #SportsList)) 		


		----- Outright14
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
				'' as BetStatus,
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
				B.PlayerDiscount,
				B.WinLost - B.Actual_Stake as WinLost,
				B.PlayerComm,
				L.APositionTaking,
				L.ADiscount,
				L.AWinlost,
				L.AComm - ISNULL(D.AComm, B.PlayerComm) as AComm,		
				B.livehomescore,
				B.liveawayscore,
				B.liveindicator,
				0 AS FinalHomeScore,
				0 AS FinalAwayScore, 
				B.IP as IP,		
				0 as oddstype,		
				B.DoubleCommLosing,
				C.UGroup
			FROM 		
				Bettrans14 B WITH (NOLOCK)
				INNER JOIN Bettrans14_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
				INNER JOIN Bettrans14_Agent AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
				LEFT JOIN Bettrans14_Agent D WITH (NOLOCK) 
						ON D.TransID = B.TransID 
							AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
							AND D.StatusId in (SELECT StatusId FROM #StatusId ) 	
							AND D.TransDate Between @FromDate AND @ToDate
							AND D.bettype = 10
							AND (@Bettypes = '0' OR D.Bettype IN (Select bettype FROM #BettypeList)) 
				INNER JOIN Outright14 as m WITH (NOLOCK) on  B.matchid=m.orid
				INNER JOIN league lg WITH (NOLOCK) on m.leagueid = lg.leagueid	
				INNER JOIN CustInfo C  WITH (NOLOCK) ON  C.CustId = B.CustId
			WHERE  B.CustID = @CustId 				
				AND B.StatusId in (SELECT StatusId FROM #StatusId ) 	
				AND B.TransDate Between @FromDate AND @ToDate
				AND B.bettype = 10
				AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList)) 
				
				AND BA.StatusId in (SELECT StatusId FROM #StatusId ) 	
				AND BA.TransDate Between @FromDate AND @ToDate
				AND BA.bettype = 10
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList)) 
				
				AND L.StatusId in (SELECT StatusId FROM #StatusId ) 	
				AND L.TransDate Between @FromDate AND @ToDate
				AND L.bettype = 10
				AND (@Bettypes = '0' OR L.Bettype IN (Select bettype FROM #BettypeList)) 
								
				AND (@Sporttypes = '0' OR lg.sporttype IN (Select sporttype FROM #SportsList)) 	
	END
	
	SELECT TOP 1500 *, @LoggedAgentLevel as AgentLevel
	FROM #Betlist 
	ORDER BY TransID DESC	
	
END				


DROP TABLE #Betlist
DROP TABLE #DirectChild
DROP TABLE #StatusId
DROP TABLE #BettypeList
DROP TABLE #SportsList


GO
GRANT EXECUTE ON [dbo].[Age_BetList_SelByDateMemStatus_AgentViewCust] TO [aplweb]
GO 