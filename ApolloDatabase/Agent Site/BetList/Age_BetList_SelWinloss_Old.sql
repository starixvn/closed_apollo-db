ALTER PROCEDURE [dbo].[Age_BetList_SelWinloss_Old]
	@LoggedId INT,
	@AgentId INT = -1 ,
	@CustId INT = -1,
	@FromDate DATE, 
	@Todate DATE,
	@StatusIds VARCHAR(1000),
	@Sporttypes VARCHAR(1000) = '0',
	@Bettypes VARCHAR(1000) = '0'

 AS
/*
Created: 20131008@Sophia
Task : Betlist for Winloss report for Archive DB
DB:  SVRARC.ArchiveDB
Original:  

Revisions:
	- 20131014@Sophia: add hthomescore,htawayscore
    - 20131223@Sophia: Get detail for Parlay

Param's Explanation:  
				
*/  
SET NOCOUNT ON

CREATE TABLE #Betlist ( TransId BIGINT, RefNo BIGINT, MatchId INT, MatchCode NVARCHAR(50), 
						HomeId INT, AwayId INT, SportType TINYINT, LeagueId INT, IsNeutral BIT, BetStatus NVARCHAR(50),
						Username NVARCHAR(50), BetType SMALLINT, CustId INT , Hdp1 SMALLMONEY, Hdp2 SMALLMONEY, Odds SMALLMONEY, MOdds SMALLMONEY,
						Status VARCHAR(10), Stake MONEY, Actual_Stake MONEY, TransDate DATETIME, BetTeam VARCHAR(10), BetId BIGINT, 
						PlayerDiscount DECIMAL (9,8), Winlost MONEY, PlayerComm MONEY, 
						APositionTaking SMALLMONEY, ADiscount DECIMAL (9,8), AWinlost MONEY, AComm MONEY,
						LiveHomeScore SMALLINT, LiveAwayScore SMALLINT,LiveIndicator BIT, 
						hthomescore SMALLINT,htawayscore SMALLINT, FinalHomeScore SMALLINT, FinalAwayScore SMALLINT,
						IP VARCHAR(40), OddsType TINYINT, DoubleCommLosing BIT)

CREATE TABLE #DirectChild ( AgentId INT)

INSERT INTO #DirectChild 
SELECT	AgentId 
FROM	RepDB.dbo.AgentInfo WITH (NOLOCK)
WHERE	ParentId = @LoggedId

CREATE TABLE #BettypeList (bettype SMALLINT)
INSERT INTO #BettypeList
SELECT val FROM dbo.strSplit_Key(@Bettypes,',')

CREATE TABLE #SportsList (Sporttype TINYINT)
INSERT INTO #SportsList (Sporttype)
SELECT val FROM strSplit_key (@Sporttypes, ',')


	---*****************************  Super View ***************************--
	IF @LoggedId = 1 
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
					(1 - B.TPositionTaking) AS APositionTaking,
					NULL AS ADiscount,
					- (B.Winlost - B.Actual_Stake + B.TWinlost) as AWinLost,				
					- (B.TComm) AS AComm,	
					B.LiveHomeScore,
					B.LiveAwayScore,
					B.LiveIndicator, 
					m.hthomescore,
					m.htawayscore,
					m.FinalHomeScore,
					m.FinalAwayScore,
					B.IP,		
					B.Oddstype,		
					B.DoubleCommLosing
 				FROM BetTrans_BK AS B  WITH (NOLOCK)		
				INNER JOIN Match_BK m WITH (NOLOCK) ON  B.MatchId = m.MatchId 							
				WHERE 
					B.CustID = @CustId 
					AND B.StatusId NOT IN (0,1)   	
					AND B.WinLostDate Between @FromDate AND @ToDate	
					AND (	B.bettype < 31 
							OR B.bettype between 121 and 999
							OR B.bettype between 1301 and 1334 											
						) 				
					AND B.Bettype NOT IN (9,29,10)
					AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList)) 
					AND (@Sporttypes = '0' OR M.sporttype IN (Select sporttype FROM #SportsList)) 		

				
			-----Parlay
			INSERT INTO #Betlist
			SELECT DISTINCT
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
					(1 - B.TPositionTaking) AS APositionTaking,
					NULL AS ADiscount,
					- (B.Winlost - B.Actual_Stake + B.TWinlost) as AWinLost,				
					- (B.TComm) AS AComm,	
					0 AS LiveHomeScore, 
					0 AS LiveAwayScore,
					0 AS LiveIndicator,
					0 as hthomescore,
					0 as htawayscore,
					0 AS FinalHomeScore,
					0 AS FinalAwayScore,
					B.IP,		
					0 as OddStype,		
					B.DoubleCommLosing	
			FROM	BetTrans_BK AS B  WITH (NOLOCK)			
			WHERE	B.CustID = @CustId  				
					AND B.StatusId NOT IN (0,1) 	
					AND B.WinLostDate Between @FromDate AND @ToDate
					AND B.BetType IN (9,29) 
					AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList)) 
					-----AND (@Sporttypes = '0' OR M.sporttype IN (Select sporttype FROM #SportsList)) 	 : Not to care Sporttype of Parlay , it means all sport


			----- Outright
			INSERT INTO #Betlist
			SELECT  B.transid,
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
					(1 - B.TPositionTaking) AS APositionTaking,
					NULL AS ADiscount,
					- (B.Winlost - B.Actual_Stake + B.TWinlost) as AWinLost,				
					- (B.TComm) AS AComm,		
					B.livehomescore,
					B.liveawayscore,
					B.liveindicator, 
					0 as hthomescore,
					0 as htawayscore,
					0 AS FinalHomeScore,
					0 AS FinalAwayScore,
					B.IP as IP,		
					0 as oddstype,		
					B.DoubleCommLosing
			FROM	BetTrans_BK B WITH (NOLOCK)	
			INNER JOIN outright_BK as m WITH (NOLOCK) on  B.matchid = m.orid
			INNER JOIN RepDB.dbo.league lg WITH (NOLOCK) on m.leagueid = lg.leagueid			
			WHERE 	B.CustID = @CustId  				
					AND B.StatusId NOT IN (0,1) 
					AND B.WinLostDate Between @FromDate AND @ToDate
					AND B.bettype = 10
					AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList)) 
					AND (@Sporttypes = '0' OR lg.sporttype IN (Select sporttype FROM #SportsList)) 	
	
  
			
	END 
	ELSE 
	--****************** 2: Agent View******************---
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
					m.hthomescore,
					m.htawayscore,
					m.FinalHomeScore,
					m.FinalAwayScore, 
					B.IP,		
					B.Oddstype,		
					B.DoubleCommLosing
 				FROM 	
					BetTrans_BK AS B  WITH (NOLOCK)				
					INNER JOIN BetTrans_Agent_BK AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
					LEFT JOIN BetTrans_Agent_BK D WITH (NOLOCK) 
							ON D.TransID = B.TransID 
							AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
							AND D.StatusId NOT IN (0,1)
							AND D.WinLostDate Between @FromDate AND @ToDate	
							AND (	D.bettype < 31 
									OR D.bettype between 121 and 999
									OR D.bettype between 1301 and 1334 
								 			
								)
							AND D.Bettype NOT IN (9,29,10)
							AND (@Bettypes = '0' OR D.Bettype IN (Select bettype FROM #BettypeList))
					INNER JOIN Match_BK m WITH (NOLOCK) ON  B.MatchId = m.MatchId 							
				WHERE	B.CustID = @CustId  
					AND B.StatusId  NOT IN (0,1)
					AND B.WinLostDate Between @FromDate AND @ToDate	
					AND (	B.bettype < 31 
							OR B.bettype between 121 and 999
							OR B.bettype between 1301 and 1334  			
						)
					AND B.Bettype NOT IN (9,29,10)
					AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList)) 

					AND L.StatusId  NOT IN (0,1)
					AND L.WinLostDate Between @FromDate AND @ToDate	
					AND (	L.bettype < 31 
							OR L.bettype between 121 and 999
							OR L.bettype between 1301 and 1334  			
						)
					AND L.Bettype NOT IN (9,29,10)
					AND (@Bettypes = '0' OR L.Bettype IN (Select bettype FROM #BettypeList)) 
			 
					AND (@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList))  		
				
			
			---- Parlay
			INSERT INTO #Betlist
			SELECT  DISTINCT B.TransId,
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
					0 as hthomescore,
					0 as htawayscore,
					0 AS FinalHomeScore,
					0 AS FinalAwayScore,
					B.IP,		
					0 as OddStype,		
					B.DoubleCommLosing	
				FROM BetTrans_BK AS B  WITH (NOLOCK)		
					INNER JOIN BetTrans_Agent_BK AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
					LEFT JOIN BetTrans_Agent_BK D WITH (NOLOCK) 
							ON	D.TransID = B.TransID 
								AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
								AND D.StatusId NOT IN (0,1)
								AND D.WinLostDate Between @FromDate AND @ToDate
								AND D.BetType IN (9,29) 
								AND (@Bettypes = '0' OR D.Bettype IN (Select bettype FROM #BettypeList)) 
				WHERE   B.CustID = @CustId 				
					AND B.StatusId NOT IN (0,1)
					AND B.WinLostDate Between @FromDate AND @ToDate
					AND B.BetType IN (9,29) 
					AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList)) 

					AND L.StatusId NOT IN (0,1)
					AND L.WinLostDate Between @FromDate AND @ToDate
					AND L.BetType IN (9,29) 
					AND (@Bettypes = '0' OR L.Bettype IN (Select bettype FROM #BettypeList)) 					
					----AND (@Sporttypes = '0' OR M.sporttype IN (Select sporttype FROM #SportsList))  : Not care Sporttype of Parlay
					

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
					0 as hthomescore,
					0 as htawayscore,
					0 AS FinalHomeScore,
					0 AS FinalAwayScore,
					B.IP as IP,		
					0 as oddstype,		
					B.DoubleCommLosing
				FROM 		
					BetTrans_BK B WITH (NOLOCK)
					INNER JOIN BetTrans_Agent_BK AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
					LEFT JOIN BetTrans_Agent_BK D WITH (NOLOCK) 
							ON D.TransID = B.TransID 
								AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
								AND D.StatusId NOT IN (0,1)
								AND D.WinLostDate Between @FromDate AND @ToDate
								AND D.bettype = 10
								AND (@Bettypes = '0' OR D.Bettype IN (Select bettype FROM #BettypeList))
					INNER JOIN Outright_BK as m WITH (NOLOCK) on  B.matchid = m.orid
					INNER JOIN RepDB.dbo.league lg WITH (NOLOCK) on m.leagueid = lg.leagueid	
				WHERE  B.CustID = @CustId 				
					AND B.StatusId NOT IN (0,1)
					AND B.WinLostDate Between @FromDate AND @ToDate
					AND B.bettype = 10
					AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))					
				
					AND L.StatusId NOT IN (0,1)	
					AND L.WinLostDate Between @FromDate AND @ToDate
					AND L.bettype = 10
					AND (@Bettypes = '0' OR L.Bettype IN (Select bettype FROM #BettypeList))				
										 
					AND (@Sporttypes = '0' OR lg.sporttype IN (Select sporttype FROM #SportsList)) 	
	

	END
	
SELECT DISTINCT * 
FROM #Betlist 
ORDER BY TransID



-------------------------------

---- Detail Parlay 
DECLARE	@tmpParlay	TABLE(
	RefNo		BIGINT,
	transid		BIGINT,
	sporttype	TINYINT,
	leagueid	INT,
	bettype		INT,
	MatchId		INT,
	homeid		INT,
	awayid		INT,
	hdp1		FLOAT,
	hdp2		FLOAT,
	odds		SMALLMONEY,
	betteam		NVARCHAR(50),
	statusid	INT,
	livehomescore	SMALLINT,
	liveawayscore	SMALLINT,
	liveindicator	BIT,
	HtHomeScore	SMALLINT,
	HtAwayScore	SMALLINT,
	FinalHomeScore	SMALLINT,
	FinalAwayScore	SMALLINT,
	betstatus	NVARCHAR(50),
	isNeutral	BIT
)	

IF EXISTS  (SELECT 1 FROM #Betlist WHERE Bettype IN (9,29))
BEGIN
		INSERT INTO @tmpParlay (
			RefNo,
			transid,
			sporttype,
			leagueid,
			bettype,
			MatchId,
			homeid,
			awayid,
			hdp1,
			hdp2,
			odds,
			betteam,
			statusid,
			livehomescore,
			liveawayscore,
			liveindicator,
			HtHomeScore,
			HtAwayScore,
			FinalHomeScore,
			FinalAwayScore,
			betstatus,
			isNeutral
		)
		SELECT
			b.RefNo,
			b.transid,
			m.Sporttype,
			m.LeagueID,		
			b.Bettype ,
			m.MatchId,
			m.homeID,
			m.awayID,
			convert(float, b.hdp1) as Hdp1, 
			convert(float, b.hdp2) as Hdp2, 
			b.odds,
			b.Betteam,
			b.statusid,
			b.livehomescore,
			b.liveawayscore,
			b.liveindicator,
			m.HtHomeScore,
			m.HtAwayScore,
			m.FinalHomeScore,
			m.FinalAwayScore,
			m.betstatus,
			m.isNeutral
		FROM(	SELECT  RefNo,
						transid,
						matchid,  
						Bettype, 
						hdp1, 
						hdp2, 
						odds, 
						betteam, 
						statusid,
						livehomescore,
						liveawayscore,
						liveindicator
				FROM	SVRARC.ArchiveDB.dbo.BettransM with (nolock)
						WHERE refno IN (SELECT RefNo FROM #Betlist WHERE Bettype IN (9,29))         
			) AS b		
				inner join SVRARC.ArchiveDB.dbo.match_bk as m with (nolock) on b.matchid=m.matchid	
	
END

 
SELECT DISTINCT * FROM @tmpParlay
ORDER BY transID DESC
---------------


DROP TABLE #Betlist
DROP TABLE #DirectChild
DROP TABLE #BettypeList
DROP TABLE #SportsList

GO
GRANT EXECUTE ON [dbo].[Age_BetList_SelWinloss_Old] TO [aplweb]
GO 