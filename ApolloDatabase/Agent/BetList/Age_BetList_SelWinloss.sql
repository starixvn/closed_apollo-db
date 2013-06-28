ALTER PROCEDURE [dbo].[Age_BetList_SelWinloss]
	@LoggedId INT,
	@AgentId INT = -1 ,
	@CustId INT = -1,
	@FromDate DATE, 
	@Todate DATE,
	@StatusIds VARCHAR(200),
	@MoveBetsDay SMALLDATETIME

 AS
/*
Created: 20130301@Sophia
Task : Betlist for Outstanding report/ Cancel Bets Report/ Account Info-Betlist
DB:  SVRAGE.RepDB
Original:  

Revisions:
     - 20130510@Sophia: Change @splitter of strSplit_Key from '^', to ','
	 - 20130628@Sophia: Add FinalHomeScore, FinalAwayScore

Param's Explanation:  
	+ @IsAgent = 1 : by Agent's Username,
			   = 0 : by Member's Username
				
*/  
SET NOCOUNT ON


CREATE TABLE #Betlist (TransId BIGINT, RefNo BIGINT, MatchId INT, MatchCode NVARCHAR(50), 
						HomeId INT, AwayId INT, SportType TINYINT, LeagueId INT, IsNeutral BIT, BetStatus NVARCHAR(50),
						Username NVARCHAR(50), BetType SMALLINT, CustId INT , Hdp1 SMALLMONEY, Hdp2 SMALLMONEY, Odds SMALLMONEY, MOdds SMALLMONEY,
						Status VARCHAR(10), Stake MONEY, Actual_Stake MONEY, TransDate DATETIME, BetTeam VARCHAR(10), BetId BIGINT, 
						PlayerDiscount DECIMAL (9,8), Winlost MONEY, PlayerComm MONEY, 
						APositionTaking SMALLMONEY, ADiscount DECIMAL (9,8), AWinlost MONEY, AComm MONEY,
						LiveHomeScore SMALLINT, LiveAwayScore SMALLINT,LiveIndicator BIT, 
						FinalHomeScore SMALLINT, FinalAwayScore SMALLINT,
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

CREATE TABLE #StatusId ( StatusId TINYINT)
INSERT INTO #StatusId
SELECT val FROM dbo.strSplit_Key(@StatusIds,',')

IF @Todate > @MoveBetsDay 
BEGIN 

	---*****************************  Super View ***************************--
	IF @LoggedId = 0 
	BEGIN 
		----By Agent
		IF @AgentId <> -1 AND @CustID = -1
		BEGIN 
			----- 1: Super View by Super
			IF @AgentId = 0 
			BEGIN
				----Sportsbook
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
						m.FinalHomeScore,
						m.FinalAwayScore,
						B.IP,		
						B.Oddstype,		
						B.DoubleCommLosing
 				FROM 	BetTrans AS B  WITH (NOLOCK) 
						INNER JOIN Match m WITH (NOLOCK) ON  B.MatchId = m.MatchId							
				WHERE 	B.StatusId in (SELECT StatusId FROM #StatusId ) 
						AND	B.WinLostDate Between @FromDate AND @ToDate	
						AND (	B.bettype < 31 
								OR B.bettype between 121 and 999
								OR B.bettype between 1301 and 1334 
								OR B.bettype BETWEEN 81 AND 120 				
							) 		
					


				----- Parlay
				INSERT INTO #Betlist
				SELECT 	B.TransId,
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
						0 AS LiveIndicator ,
						0 AS FinalHomeScore,
						0 AS FinalAwayScore,
						B.IP,		
						0 as OddStype,		
						B.DoubleCommLosing	
				FROM BetTrans AS B  WITH (NOLOCK) 
				WHERE  B.StatusId in (SELECT StatusId FROM #StatusId ) 
						AND B.WinLostDate Between @FromDate AND @ToDate
						AND B.BetType IN (9,29)


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
						(1 - B.TPositionTaking) AS APositionTaking,
						NULL AS ADiscount,
						- (B.Winlost - B.Actual_Stake + B.TWinlost) as AWinLost,				
						- (B.TComm) AS AComm,		
						B.livehomescore,
						B.liveawayscore,
						B.liveindicator,
						0 AS FinalHomeScore,
						0 AS FinalAwayScore, 
						B.IP as IP,		
						0 as oddstype,		
						B.DoubleCommLosing
				FROM 	bettrans B WITH (NOLOCK)
				INNER JOIN outright as m WITH (NOLOCK) on  B.matchid=m.orid
				INNER JOIN league lg WITH (NOLOCK) on m.leagueid = lg.leagueid	
				WHERE 	B.StatusId in (SELECT StatusId FROM #StatusId ) 		
						AND B.WinLostDate Between @FromDate AND @ToDate
						AND B.bettype = 10
				
			END
			------ 2: Super view by Agent
			ELSE
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
						m.FinalHomeScore,
						m.FinalAwayScore, 
						B.IP,		
						B.Oddstype,		
						B.DoubleCommLosing
 					FROM 	
						BetTrans AS B  WITH (NOLOCK) 
						INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId  
						INNER JOIN Match m WITH (NOLOCK) ON  B.MatchId = m.MatchId					
					
					WHERE 
						BA.AgentId = @AgentId 
						AND BA.StatusId in (SELECT StatusId FROM #StatusId ) 
						AND BA.WinLostDate Between @FromDate AND @ToDate	
						AND (	BA.bettype < 31 
								OR BA.bettype between 121 and 999
								OR BA.bettype between 1301 and 1334 
								OR BA.bettype BETWEEN 81 AND 120 				
							) 		
					

				---Parlay
				INSERT INTO #Betlist
				SELECT  B.TransId,
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
						0 AS LiveIndicator ,
						0 AS FinalHomeScore,
						0 AS FinalAwayScore,
						B.IP,		
						0 as OddStype,		
						B.DoubleCommLosing	
				FROM BetTrans AS B  WITH (NOLOCK) 		
				INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId 
				WHERE	BA.AgentId = @AgentId 			
					AND B.StatusId in (SELECT StatusId FROM #StatusId ) 
					AND B.WinLostDate Between @FromDate AND @ToDate
					AND B.BetType IN (9,29) 


			----- Outright
			INSERT INTO #Betlist
			SELECT		B.transid,
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
						0 AS FinalHomeScore,
						0 AS FinalAwayScore,
						B.IP as IP,		
						0 as oddstype,		
						B.DoubleCommLosing
				FROM	bettrans B WITH (NOLOCK)
					INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
					INNER JOIN outright as m WITH (NOLOCK) on  B.matchid=m.orid
					INNER JOIN league lg WITH (NOLOCK) on m.leagueid = lg.leagueid	
				WHERE 	BA.AgentId = @AgentId 		
					AND B.StatusId in (SELECT StatusId FROM #StatusId ) 	
					AND B.WinLostDate Between @FromDate AND @ToDate
					AND B.bettype = 10
			END
						
		END
		ELSE
		---- 3: Super View By Member
		IF @CustID <> -1 AND @AgentId = -1
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
					m.FinalHomeScore,
					m.FinalAwayScore,
					B.IP,		
					B.Oddstype,		
					B.DoubleCommLosing
 				FROM 
					BetTrans AS B  WITH (NOLOCK) 				
					INNER JOIN Match m WITH (NOLOCK) ON  B.MatchId = m.MatchId 					
				WHERE 
					B.CustID = @CustId 
					AND B.StatusId in (SELECT StatusId FROM #StatusId )   	
					AND B.WinLostDate Between @FromDate AND @ToDate	
					AND (	B.bettype < 31 
							OR B.bettype between 121 and 999
							OR B.bettype between 1301 and 1334 
							OR B.bettype BETWEEN 81 AND 120 				
						) 		
				

				
			-----Parlay
			INSERT INTO #Betlist
			SELECT 	B.TransId,
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
					0 AS FinalHomeScore,
					0 AS FinalAwayScore,
					B.IP,		
					0 as OddStype,		
					B.DoubleCommLosing	
				FROM BetTrans AS B  WITH (NOLOCK) 
				WHERE B.CustID = @CustId  				
					AND B.StatusId in (SELECT StatusId FROM #StatusId ) 	
					AND B.WinLostDate Between @FromDate AND @ToDate
					AND B.BetType IN (9,29) 


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
					0 AS FinalHomeScore,
					0 AS FinalAwayScore,
					B.IP as IP,		
					0 as oddstype,		
					B.DoubleCommLosing
				FROM 		
					bettrans B WITH (NOLOCK)
					INNER JOIN outright as m WITH (NOLOCK) on  B.matchid=m.orid
					INNER JOIN league lg WITH (NOLOCK) on m.leagueid = lg.leagueid	
				WHERE 
					B.CustID = @CustId  				
					AND B.StatusId in (SELECT StatusId FROM #StatusId ) 
					AND B.WinLostDate Between @FromDate AND @ToDate
					AND B.bettype = 10
					
		END
	END 
	ELSE 
	--****************** 2: Agent View******************---
	BEGIN 
		----4: Agent view By Agent
		IF @AgentId <> -1 AND @CustID = -1
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
					B.DoubleCommLosing
 				FROM 	
					BetTrans AS B  WITH (NOLOCK) 
					INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId 				
					INNER JOIN BetTrans_Agent AS L WITH (NOLOCK )  ON B.TransId = L.TransId AND L.AgentID = @LoggedId
					LEFT JOIN Bettrans_Agent D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
					INNER JOIN Match m WITH (NOLOCK) ON  B.MatchId = m.MatchId 					
				WHERE BA.AgentId =  @AgentId
					AND B.StatusId in (SELECT StatusId FROM #StatusId )  
					AND B.WinLostDate Between @FromDate AND @ToDate	
					AND (	B.bettype < 31 
							OR B.bettype between 121 and 999
							OR B.bettype between 1301 and 1334 
							OR B.bettype BETWEEN 81 AND 120 				
						) 			
			

			-----Parlay
			INSERT INTO #Betlist
			SELECT 	B.TransId,
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
					0 AS LiveIndicator ,
					0 AS FinalHomeScore,
					0 AS FinalAwayScore,
					B.IP,		
					0 as OddStype,		
					B.DoubleCommLosing	
				FROM BetTrans AS B  WITH (NOLOCK) 		
					INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
					INNER JOIN BetTrans_Agent AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
					LEFT JOIN Bettrans_Agent D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
				WHERE BA.AgentId =  @AgentId				
					AND B.StatusId in (SELECT StatusId FROM #StatusId )  	
					AND B.WinLostDate Between @FromDate AND @ToDate
					AND B.BetType IN (9,29) 

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
					B.DoubleCommLosing
				FROM 		
					bettrans B WITH (NOLOCK)
					INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
					INNER JOIN BetTrans_Agent AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
					LEFT JOIN Bettrans_Agent D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
					INNER JOIN outright as m WITH (NOLOCK) on  B.matchid=m.orid
					INNER JOIN league lg WITH (NOLOCK) on m.leagueid = lg.leagueid	
				WHERE 
					BA.AgentId = @AgentId 		
					AND B.StatusId in (SELECT StatusId FROM #StatusId )  
					AND B.WinLostDate Between @FromDate AND @ToDate
					AND B.bettype = 10

		END
		ELSE
		----- 5: Agent view By Member
		IF @CustID <> -1 AND @AgentId = -1
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
					B.DoubleCommLosing
 				FROM 	
					BetTrans AS B  WITH (NOLOCK)				
					INNER JOIN BetTrans_Agent AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
					LEFT JOIN Bettrans_Agent D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
					INNER JOIN Match m WITH (NOLOCK) ON  B.MatchId = m.MatchId 							
				WHERE	B.CustID = @CustId  
					AND B.StatusId in (SELECT StatusId FROM #StatusId ) 	
					AND B.WinLostDate Between @FromDate AND @ToDate	
					AND (	B.bettype < 31 
							OR B.bettype between 121 and 999
							OR B.bettype between 1301 and 1334 
							OR B.bettype BETWEEN 81 AND 120 				
						) 		
				
			
			---- Parlay
			INSERT INTO #Betlist
			SELECT  B.TransId,
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
					0 AS FinalHomeScore,
					0 AS FinalAwayScore,
					B.IP,		
					0 as OddStype,		
					B.DoubleCommLosing	
				FROM BetTrans AS B  WITH (NOLOCK) 		
					INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
					INNER JOIN BetTrans_Agent AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
					LEFT JOIN Bettrans_Agent D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
				WHERE   B.CustID = @CustId 				
					AND B.StatusId in (SELECT StatusId FROM #StatusId ) 
					AND B.WinLostDate Between @FromDate AND @ToDate
					AND B.BetType IN (9,29) 


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
					B.DoubleCommLosing
				FROM 		
					bettrans B WITH (NOLOCK)
					INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
					INNER JOIN BetTrans_Agent AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
					LEFT JOIN Bettrans_Agent D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
					INNER JOIN outright as m WITH (NOLOCK) on  B.matchid=m.orid
					INNER JOIN league lg WITH (NOLOCK) on m.leagueid = lg.leagueid	
				WHERE  B.CustID = @CustId 				
					AND B.StatusId in (SELECT StatusId FROM #StatusId ) 	
					AND B.WinLostDate Between @FromDate AND @ToDate
					AND B.bettype = 10

		END 
	END
END

IF @Fromdate <= @MoveBetsDay
BEGIN
 

	---*****************************  Super View ***************************--
	IF @LoggedId = 0 
	BEGIN 
		----By Agent
		IF @AgentId <> -1 AND @CustID = -1
		BEGIN 
			----- 1: Super View by Super
			IF @AgentId = 0 
			BEGIN
				----Sportsbook
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
						ISNULL(m.BetStatus,'') AS BetStatus,
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
						m.FinalHomeScore,
						m.FinalAwayScore, 
						B.IP,		
						B.Oddstype,		
						B.DoubleCommLosing
 				FROM 	BetTrans14 AS B  WITH (NOLOCK) 
						INNER JOIN Match14 m WITH (NOLOCK) ON  B.MatchId = m.MatchId					
				WHERE 	B.StatusId in (SELECT StatusId FROM #StatusId ) 
						AND	B.WinLostDate Between @FromDate AND @ToDate	
						AND (	B.bettype < 31 
								OR B.bettype between 121 and 999
								OR B.bettype between 1301 and 1334 
								OR B.bettype BETWEEN 81 AND 120 				
							) 		
					


				----- Parlay
				INSERT INTO #Betlist
				SELECT 	B.TransId,
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
						0 AS LiveIndicator ,
						0 AS FinalHomeScore,
						0 AS FinalAwayScore,
						B.IP,		
						0 as OddStype,		
						B.DoubleCommLosing	
				FROM BetTrans14 AS B  WITH (NOLOCK) 
				WHERE  B.StatusId in (SELECT StatusId FROM #StatusId ) 
						AND B.WinLostDate Between @FromDate AND @ToDate
						AND B.BetType IN (9,29)


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
						(1 - B.TPositionTaking) AS APositionTaking,
						NULL AS ADiscount,
						- (B.Winlost - B.Actual_Stake + B.TWinlost) as AWinLost,				
						- (B.TComm) AS AComm,		
						B.livehomescore,
						B.liveawayscore,
						B.liveindicator, 
						0 AS FinalHomeScore,
						0 AS FinalAwayScore,
						B.IP as IP,		
						0 as oddstype,		
						B.DoubleCommLosing
				FROM 	BetTrans14 B WITH (NOLOCK)
				INNER JOIN outright14 as m WITH (NOLOCK) on  B.matchid=m.orid
				INNER JOIN league lg WITH (NOLOCK) on m.leagueid = lg.leagueid	
				WHERE 	B.StatusId in (SELECT StatusId FROM #StatusId ) 		
						AND B.WinLostDate Between @FromDate AND @ToDate
						AND B.bettype = 10
				
			END
			------ 2: Super view by Agent
			ELSE
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
						ISNULL(m.BetStatus,'') AS BetStatus,
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
						m.FinalHomeScore,
						m.FinalAwayScore, 
						B.IP,		
						B.Oddstype,		
						B.DoubleCommLosing
 					FROM 	
						BetTrans14 AS B  WITH (NOLOCK) 
						INNER JOIN BetTrans14_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId  
						INNER JOIN Match14 m WITH (NOLOCK) ON  B.MatchId = m.MatchId
					
					WHERE 
						BA.AgentId = @AgentId 
						AND BA.StatusId in (SELECT StatusId FROM #StatusId ) 
						AND BA.WinLostDate Between @FromDate AND @ToDate	
						AND (	BA.bettype < 31 
								OR BA.bettype between 121 and 999
								OR BA.bettype between 1301 and 1334 
								OR BA.bettype BETWEEN 81 AND 120 				
							) 		
					

				---Parlay
				INSERT INTO #Betlist
				SELECT  B.TransId,
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
						0 AS LiveIndicator ,
						0 AS FinalHomeScore,
						0 AS FinalAwayScore,
						B.IP,		
						0 as OddStype,		
						B.DoubleCommLosing	
				FROM BetTrans14 AS B  WITH (NOLOCK) 		
				INNER JOIN BetTrans14_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId 
				WHERE	BA.AgentId = @AgentId 			
					AND B.StatusId in (SELECT StatusId FROM #StatusId ) 
					AND B.WinLostDate Between @FromDate AND @ToDate
					AND B.BetType IN (9,29) 


			----- Outright
			INSERT INTO #Betlist
			SELECT		B.transid,
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
						0 AS FinalHomeScore,
						0 AS FinalAwayScore,
						B.IP as IP,		
						0 as oddstype,		
						B.DoubleCommLosing
				FROM	BetTrans14 B WITH (NOLOCK)
					INNER JOIN BetTrans14_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
					INNER JOIN outright14 as m WITH (NOLOCK) on  B.matchid=m.orid
					INNER JOIN league lg WITH (NOLOCK) on m.leagueid = lg.leagueid	
				WHERE 	BA.AgentId = @AgentId 		
					AND B.StatusId in (SELECT StatusId FROM #StatusId ) 	
					AND B.WinLostDate Between @FromDate AND @ToDate
					AND B.bettype = 10
			END
						
		END
		ELSE
		---- 3: Super View By Member
		IF @CustID <> -1 AND @AgentId = -1
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
					ISNULL(m.BetStatus,'') AS BetStatus,
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
					m.FinalHomeScore,
					m.FinalAwayScore,
					B.IP,		
					B.Oddstype,		
					B.DoubleCommLosing
 				FROM 
					BetTrans14 AS B  WITH (NOLOCK) 				
					INNER JOIN Match14 m WITH (NOLOCK) ON  B.MatchId = m.MatchId 			
				WHERE 
					B.CustID = @CustId 
					AND B.StatusId in (SELECT StatusId FROM #StatusId )   	
					AND B.WinLostDate Between @FromDate AND @ToDate	
					AND (	B.bettype < 31 
							OR B.bettype between 121 and 999
							OR B.bettype between 1301 and 1334 
							OR B.bettype BETWEEN 81 AND 120 				
						) 		
				

				
			-----Parlay
			INSERT INTO #Betlist
			SELECT 	B.TransId,
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
					0 AS LiveIndicator ,
					0 AS FinalHomeScore,
					0 AS FinalAwayScore,
					B.IP,		
					0 as OddStype,		
					B.DoubleCommLosing	
				FROM BetTrans14 AS B  WITH (NOLOCK) 
				WHERE B.CustID = @CustId  				
					AND B.StatusId in (SELECT StatusId FROM #StatusId ) 	
					AND B.WinLostDate Between @FromDate AND @ToDate
					AND B.BetType IN (9,29) 


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
					0 AS FinalHomeScore,
					0 AS FinalAwayScore,
					B.IP as IP,		
					0 as oddstype,		
					B.DoubleCommLosing
				FROM 		
					BetTrans14 B WITH (NOLOCK)
					INNER JOIN outright14 as m WITH (NOLOCK) on  B.matchid=m.orid
					INNER JOIN league lg WITH (NOLOCK) on m.leagueid = lg.leagueid	
				WHERE 
					B.CustID = @CustId  				
					AND B.StatusId in (SELECT StatusId FROM #StatusId ) 
					AND B.WinLostDate Between @FromDate AND @ToDate
					AND B.bettype = 10
					
		END
	END 
	ELSE 
	--****************** 2: Agent View******************---
	BEGIN 
		----4: Agent view By Agent
		IF @AgentId <> -1 AND @CustID = -1
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
					ISNULL(m.BetStatus,'') AS BetStatus,
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
					B.DoubleCommLosing
 				FROM 	
					BetTrans14 AS B  WITH (NOLOCK) 
					INNER JOIN BetTrans14_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId 				
					INNER JOIN BetTrans14_Agent AS L WITH (NOLOCK )  ON B.TransId = L.TransId AND L.AgentID = @LoggedId
					LEFT JOIN BetTrans14_Agent D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
					INNER JOIN Match14 m WITH (NOLOCK) ON  B.MatchId = m.MatchId 						
				WHERE BA.AgentId =  @AgentId
					AND B.StatusId in (SELECT StatusId FROM #StatusId )  
					AND B.WinLostDate Between @FromDate AND @ToDate	
					AND (	B.bettype < 31 
							OR B.bettype between 121 and 999
							OR B.bettype between 1301 and 1334 
							OR B.bettype BETWEEN 81 AND 120 				
						) 			
			

			-----Parlay
			INSERT INTO #Betlist
			SELECT 	B.TransId,
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
					0 AS LiveIndicator ,
					0 AS FinalHomeScore,
					0 AS FinalAwayScore,
					B.IP,		
					0 as OddStype,		
					B.DoubleCommLosing	
				FROM BetTrans14 AS B  WITH (NOLOCK) 		
					INNER JOIN BetTrans14_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
					INNER JOIN BetTrans14_Agent AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
					LEFT JOIN BetTrans14_Agent D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
				WHERE BA.AgentId =  @AgentId				
					AND B.StatusId in (SELECT StatusId FROM #StatusId )  	
					AND B.WinLostDate Between @FromDate AND @ToDate
					AND B.BetType IN (9,29) 

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
					B.DoubleCommLosing
				FROM 		
					BetTrans14 B WITH (NOLOCK)
					INNER JOIN BetTrans14_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
					INNER JOIN BetTrans14_Agent AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
					LEFT JOIN BetTrans14_Agent D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
					INNER JOIN outright14 as m WITH (NOLOCK) on  B.matchid=m.orid
					INNER JOIN league lg WITH (NOLOCK) on m.leagueid = lg.leagueid	
				WHERE 
					BA.AgentId = @AgentId 		
					AND B.StatusId in (SELECT StatusId FROM #StatusId )  
					AND B.WinLostDate Between @FromDate AND @ToDate
					AND B.bettype = 10

		END
		ELSE
		----- 5: Agent view By Member
		IF @CustID <> -1 AND @AgentId = -1
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
					ISNULL(m.BetStatus,'') AS BetStatus,
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
					B.DoubleCommLosing
 				FROM 	
					BetTrans14 AS B  WITH (NOLOCK)				
					INNER JOIN BetTrans14_Agent AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
					LEFT JOIN BetTrans14_Agent D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
					INNER JOIN Match14 m WITH (NOLOCK) ON  B.MatchId = m.MatchId 		
				WHERE	B.CustID = @CustId  
					AND B.StatusId in (SELECT StatusId FROM #StatusId ) 	
					AND B.WinLostDate Between @FromDate AND @ToDate	
					AND (	B.bettype < 31 
							OR B.bettype between 121 and 999
							OR B.bettype between 1301 and 1334 
							OR B.bettype BETWEEN 81 AND 120 				
						) 		
				
			
			---- Parlay
			INSERT INTO #Betlist
			SELECT  B.TransId,
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
					0 AS LiveIndicator ,
					0 AS FinalHomeScore,
					0 AS FinalAwayScore,
					B.IP,		
					0 as OddStype,		
					B.DoubleCommLosing	
				FROM BetTrans14 AS B  WITH (NOLOCK) 		
					INNER JOIN BetTrans14_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
					INNER JOIN BetTrans14_Agent AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
					LEFT JOIN BetTrans14_Agent D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
				WHERE   B.CustID = @CustId 				
					AND B.StatusId in (SELECT StatusId FROM #StatusId ) 
					AND B.WinLostDate Between @FromDate AND @ToDate
					AND B.BetType IN (9,29) 


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
					B.DoubleCommLosing
				FROM 		
					BetTrans14 B WITH (NOLOCK)
					INNER JOIN BetTrans14_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
					INNER JOIN BetTrans14_Agent AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
					LEFT JOIN BetTrans14_Agent D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
					INNER JOIN outright14 as m WITH (NOLOCK) on  B.matchid=m.orid
					INNER JOIN league lg WITH (NOLOCK) on m.leagueid = lg.leagueid	
				WHERE  B.CustID = @CustId 				
					AND B.StatusId in (SELECT StatusId FROM #StatusId ) 	
					AND B.WinLostDate Between @FromDate AND @ToDate
					AND B.bettype = 10

		END 
	END

END

SELECT DISTINCT *, @LoggedAgentLevel as AgentLevel
FROM #Betlist 
ORDER BY TransID


DROP TABLE #Betlist
DROP TABLE #DirectChild
DROP TABLE #StatusId


GO
GRANT EXECUTE ON [dbo].[Age_BetList_SelWinloss] TO [aplweb]
GO 