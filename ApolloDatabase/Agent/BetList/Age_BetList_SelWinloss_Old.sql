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
						m.league_BKId, 
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
						(1 - B.TPositionTaking) AS APositionTaking,
						NULL AS ADiscount,
						- (B.Winlost - B.Actual_Stake + B.TWinlost) as AWinLost,				
						- (B.TComm) AS AComm,	
						B.LiveHomeScore,
						B.LiveAwayScore,
						B.LiveIndicator, 
						B.IP,		
						B.Oddstype,		
						B.DoubleCommLosing
 				FROM 	BetTrans_BK AS B  WITH (NOLOCK) 
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
						'' as league_BKId,
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
						(1 - B.TPositionTaking) AS APositionTaking,
						NULL AS ADiscount,
						- (B.Winlost - B.Actual_Stake + B.TWinlost) as AWinLost,				
						- (B.TComm) AS AComm,	
						0 AS LiveHomeScore, 
						0 AS LiveAwayScore,
						0 AS LiveIndicator ,
						B.IP,		
						0 as OddStype,		
						B.DoubleCommLosing	
				FROM BetTrans_BK AS B  WITH (NOLOCK) 
				WHERE  B.StatusId in (SELECT StatusId FROM #StatusId ) 
						AND B.WinLostDate Between @FromDate AND @ToDate
						AND B.BetType IN (9,29)


				----- outright_BK
				INSERT INTO #Betlist
				SELECT 				
						B.transid,
						B.refno,
						0 as matchid,
						m.matchcode,
						m.teamID as homeID,
						0 as awayID,
						lg.sporttype,
						m.league_BKID,
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
						(1 - B.TPositionTaking) AS APositionTaking,
						NULL AS ADiscount,
						- (B.Winlost - B.Actual_Stake + B.TWinlost) as AWinLost,				
						- (B.TComm) AS AComm,		
						B.livehomescore,
						B.liveawayscore,
						B.liveindicator, 
						B.IP as IP,		
						0 as oddstype,		
						B.DoubleCommLosing
				FROM 	BetTrans_BK B WITH (NOLOCK)
				INNER JOIN outright_BK as m WITH (NOLOCK) on  B.matchid=m.orid
				INNER JOIN league_BK lg WITH (NOLOCK) on m.league_BKid = lg.league_BKid	
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
						m.league_BKId, 
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
						(1 - B.TPositionTaking) AS APositionTaking,
						NULL AS ADiscount,
						- (B.Winlost - B.Actual_Stake + B.TWinlost) as AWinLost,				
						- (B.TComm) AS AComm,	
						B.LiveHomeScore,
						B.LiveAwayScore,
						B.LiveIndicator, 
						B.IP,		
						B.Oddstype,		
						B.DoubleCommLosing
 					FROM 	
						BetTrans_BK AS B  WITH (NOLOCK) 
						INNER JOIN BetTrans_Agent_BK AS BA WITH (NOLOCK) ON BA.TransId = B.TransId  
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
						'' as league_BKId,
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
						(1 - B.TPositionTaking) AS APositionTaking,
						NULL AS ADiscount,
						- (B.Winlost - B.Actual_Stake + B.TWinlost) as AWinLost,				
						- (B.TComm) AS AComm,	
						0 AS LiveHomeScore, 
						0 AS LiveAwayScore,
						0 AS LiveIndicator ,
						B.IP,		
						0 as OddStype,		
						B.DoubleCommLosing	
				FROM BetTrans_BK AS B  WITH (NOLOCK) 		
				INNER JOIN BetTrans_Agent_BK AS BA WITH (NOLOCK) ON BA.TransId = B.TransId 
				WHERE	BA.AgentId = @AgentId 			
					AND B.StatusId in (SELECT StatusId FROM #StatusId ) 
					AND B.WinLostDate Between @FromDate AND @ToDate
					AND B.BetType IN (9,29) 


			----- outright_BK
			INSERT INTO #Betlist
			SELECT		B.transid,
						B.refno,
						0 as matchid,
						m.matchcode,
						m.teamID as homeID,
						0 as awayID,
						lg.sporttype,
						m.league_BKID,
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
						(1 - B.TPositionTaking) AS APositionTaking,
						NULL AS ADiscount,
						- (B.Winlost - B.Actual_Stake + B.TWinlost) as AWinLost,				
						- (B.TComm) AS AComm,			
						B.livehomescore,
						B.liveawayscore,
						B.liveindicator, 
						B.IP as IP,		
						0 as oddstype,		
						B.DoubleCommLosing
				FROM	BetTrans_BK B WITH (NOLOCK)
					INNER JOIN BetTrans_Agent_BK AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
					INNER JOIN outright_BK as m WITH (NOLOCK) on  B.matchid=m.orid
					INNER JOIN league_BK lg WITH (NOLOCK) on m.league_BKid = lg.league_BKid	
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
					m.league_BKId, 
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
					(1 - B.TPositionTaking) AS APositionTaking,
					NULL AS ADiscount,
					- (B.Winlost - B.Actual_Stake + B.TWinlost) as AWinLost,				
					- (B.TComm) AS AComm,	
					B.LiveHomeScore,
					B.LiveAwayScore,
					B.LiveIndicator, 
					B.IP,		
					B.Oddstype,		
					B.DoubleCommLosing
 				FROM 
					BetTrans_BK AS B  WITH (NOLOCK) 				
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
					'' as league_BKId,
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
					(1 - B.TPositionTaking) AS APositionTaking,
					NULL AS ADiscount,
					- (B.Winlost - B.Actual_Stake + B.TWinlost) as AWinLost,				
					- (B.TComm) AS AComm,	
					0 AS LiveHomeScore, 
					0 AS LiveAwayScore,
					0 AS LiveIndicator ,
					B.IP,		
					0 as OddStype,		
					B.DoubleCommLosing	
				FROM BetTrans_BK AS B  WITH (NOLOCK) 
				WHERE B.CustID = @CustId  				
					AND B.StatusId in (SELECT StatusId FROM #StatusId ) 	
					AND B.WinLostDate Between @FromDate AND @ToDate
					AND B.BetType IN (9,29) 


			----- outright_BK
			INSERT INTO #Betlist
			SELECT  B.transid,
					B.refno,
					0 as matchid,
					m.matchcode,
					m.teamID as homeID,
					0 as awayID,
					lg.sporttype,
					m.league_BKID,
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
					(1 - B.TPositionTaking) AS APositionTaking,
					NULL AS ADiscount,
					- (B.Winlost - B.Actual_Stake + B.TWinlost) as AWinLost,				
					- (B.TComm) AS AComm,		
					B.livehomescore,
					B.liveawayscore,
					B.liveindicator, 
					B.IP as IP,		
					0 as oddstype,		
					B.DoubleCommLosing
				FROM 		
					BetTrans_BK B WITH (NOLOCK)
					INNER JOIN outright_BK as m WITH (NOLOCK) on  B.matchid=m.orid
					INNER JOIN league_BK lg WITH (NOLOCK) on m.league_BKid = lg.league_BKid	
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
					m.league_BKId, 
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
					L.APositionTaking ,
					L.ADiscount ,
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
					INNER JOIN BetTrans_Agent_BK AS BA WITH (NOLOCK) ON BA.TransId = B.TransId 				
					INNER JOIN BetTrans_Agent_BK AS L WITH (NOLOCK )  ON B.TransId = L.TransId AND L.AgentID = @LoggedId
					LEFT JOIN BetTrans_Agent_BK D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
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
					'' as league_BKId,
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
					INNER JOIN BetTrans_Agent_BK AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
					INNER JOIN BetTrans_Agent_BK AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
					LEFT JOIN BetTrans_Agent_BK D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
				WHERE BA.AgentId =  @AgentId				
					AND B.StatusId in (SELECT StatusId FROM #StatusId )  	
					AND B.WinLostDate Between @FromDate AND @ToDate
					AND B.BetType IN (9,29) 

			----- outright_BK
			INSERT INTO #Betlist
			SELECT 				
					B.transid,
					B.refno,
					0 as matchid,
					m.matchcode,
					m.teamID as homeID,
					0 as awayID,
					lg.sporttype,
					m.league_BKID,
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
					BetTrans_BK B WITH (NOLOCK)
					INNER JOIN BetTrans_Agent_BK AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
					INNER JOIN BetTrans_Agent_BK AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
					LEFT JOIN BetTrans_Agent_BK D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
					INNER JOIN outright_BK as m WITH (NOLOCK) on  B.matchid=m.orid
					INNER JOIN league_BK lg WITH (NOLOCK) on m.league_BKid = lg.league_BKid	
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
					m.league_BKId, 
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
					L.APositionTaking ,
					L.ADiscount ,
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
					LEFT JOIN BetTrans_Agent_BK D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
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
					'' as league_BKId,
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
					INNER JOIN BetTrans_Agent_BK AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
					INNER JOIN BetTrans_Agent_BK AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
					LEFT JOIN BetTrans_Agent_BK D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
				WHERE   B.CustID = @CustId 				
					AND B.StatusId in (SELECT StatusId FROM #StatusId ) 
					AND B.WinLostDate Between @FromDate AND @ToDate
					AND B.BetType IN (9,29) 


			----- outright_BK
			INSERT INTO #Betlist
			SELECT 				
					B.transid,
					B.refno,
					0 as matchid,
					m.matchcode,
					m.teamID as homeID,
					0 as awayID,
					lg.sporttype,
					m.league_BKID,
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
					BetTrans_BK B WITH (NOLOCK)
					INNER JOIN BetTrans_Agent_BK AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
					INNER JOIN BetTrans_Agent_BK AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
					LEFT JOIN BetTrans_Agent_BK D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
					INNER JOIN outright_BK as m WITH (NOLOCK) on  B.matchid=m.orid
					INNER JOIN league_BK lg WITH (NOLOCK) on m.league_BKid = lg.league_BKid	
				WHERE  B.CustID = @CustId 				
					AND B.StatusId in (SELECT StatusId FROM #StatusId ) 	
					AND B.WinLostDate Between @FromDate AND @ToDate
					AND B.bettype = 10

		END 
	END


SELECT	* , @LoggedAgentLevel
FROM	#Betlist 
ORDER BY TransID DESC 


DROP TABLE #Betlist
DROP TABLE #DirectChild
DROP TABLE #StatusId

GO
GRANT EXECUTE ON [dbo].[Age_BetList_SelWinloss_Old] TO [aplweb]

