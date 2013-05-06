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
  
Param''s Explanation:  

EX: Exec [Age_BetList_SelWinloss_Old] 3,-1, 35, '2013-01-01' , '2013-04-09', '0^1^101^103^111^112'

				
*/  
SET NOCOUNT ON


DECLARE @S VARCHAR(8000)
DECLARE @S1 VARCHAR(8000)
DECLARE @S2 VARCHAR(8000)
DECLARE @S3 VARCHAR(8000)
DECLARE @S4 VARCHAR(8000)
DECLARE @S5 VARCHAR(8000)
DECLARE @S6 VARCHAR(8000)

SET @S = '	
CREATE TABLE #DirectChild ( AgentId INT)

INSERT INTO #DirectChild 
SELECT * 
FROM OPENQUERY (SVRCUST, '' SELECT	AgentId
							FROM	CustDB.dbo.AgentInfo WITH (NOLOCK)
							WHERE	ParentId = ' + CONVERT (VARCHAR(5),@LoggedId) +''')
 

DECLARE @LoggedAgentLevel INT
SELECT	@LoggedAgentLevel = AgentLevel
FROM	OPENQUERY (SVRCUST, ''	SELECT	AgentLevel
								FROM	CustDB.dbo.AgentInfo WITH (NOLOCK)
								WHERE	AgentId = ' + CONVERT (VARCHAR(5),@LoggedId) +''')  


CREATE TABLE #StatusId ( StatusId TINYINT)
INSERT INTO #StatusId
SELECT val FROM dbo.strSplit_Key(''' + CONVERT (VARCHAR(200),@StatusIds) +''',''^'')
'

SET @S1 = ' 
CREATE TABLE #Betlist  (TransId BIGINT, RefNo BIGINT, MatchId INT, MatchCode NVARCHAR(50), 
						HomeId INT, AwayId INT, SportType TINYINT, LeagueId INT, IsNeutral BIT, BetStatus NVARCHAR(50),
						Username NVARCHAR(50), BetType SMALLINT, CustId INT , Hdp1 SMALLMONEY, Hdp2 SMALLMONEY, Odds SMALLMONEY, MOdds SMALLMONEY,
						Status VARCHAR(10), Stake MONEY, Actual_Stake MONEY, TransDate DATETIME, WinLostDate SMALLDATETIME,	BetTeam VARCHAR(10), BetId BIGINT, 
						PlayerDiscount DECIMAL (9,8), Winlost MONEY, PlayerComm MONEY, 
						APositionTaking SMALLMONEY, ADiscount DECIMAL (9,8), AWinlost MONEY, AComm MONEY,
						LiveHomeScore SMALLINT, LiveAwayScore SMALLINT,LiveIndicator BIT, 
						IP VARCHAR(40), OddsType TINYINT, DoubleCommLosing BIT)


	---*****************************  Super View ***************************--
	IF '+ CONVERT(VARCHAR(10),@LoggedId) +' = 0 
	BEGIN 
		----By Agent
		IF '+ CONVERT(VARCHAR(10),@AgentId) +' <> -1 AND '+ CONVERT(VARCHAR(10),@CustId) +' = -1
		BEGIN 
			----- 1: Super View by Super
			IF '+ CONVERT(VARCHAR(10),@AgentId) +' = 0 
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
						m.leagueId, 
						m.IsNeutral,
						ISNULL(e.BetStatus,'') AS BetStatus,
						B.Username,
						B.BetType,
						B.CustId,
						B.Hdp1, 
						B.Hdp2, 
						B.Odds,
						B.MOdds,
						CASE WHEN B.Status = ''running'' AND IsNull(B.SecAcceptFlag, 0) = 1 AND IsNull(B.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN ''waiting''
									ELSE B.Status 
									END as Status,
						B.Stake,
						B.Actual_Stake,
						B.TransDate,	
						B.WinlostDate,	
						B.BetTeam,
						B.BetId,
						B.PlayerDiscount,
						B.WinLost,
						B.PlayerComm,
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
						INNER JOIN Match_BK m WITH (NOLOCK) ON  B.MatchId = m.MatchId	
						LEFT JOIN SVRPRO.ProdDB.dbo.Match_remark_ex e WITH (NOLOCK) ON e.MatchId = m.MatchId				
				WHERE 	B.StatusId in (SELECT StatusId FROM #StatusId ) 
						AND	B.WinLostDate Between '''+ Convert(varchar(20),@Fromdate )+''' AND '''+ Convert(varchar(20),@Todate )+''' 	
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
						'''' matchcode,
						0 as homeID,
						0 as awayID,
						0 as sporttype,
						'''' as leagueId,
						CONVERT(BIT,0) as IsNeutral,
						'''' as BetStatus,
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
						B.WinlostDate,		
						B.BetTeam,
						B.BetId,
						B.PlayerDiscount,
						B.WinLost,
						B.PlayerComm,
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
						AND B.WinLostDate Between '''+ Convert(varchar(20),@Fromdate )+''' AND '''+ Convert(varchar(20),@Todate )+''' 
						AND B.BetType IN (9,29)
					'
SET @S2 = '
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
						m.leagueID,
						CONVERT(BIT,0) as IsNeutral,
						'''' as BetStatus,
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
						B.WinlostDate,	
						B.betteam,
						B.betID,
						B.PlayerDiscount,
						B.WinLost,
						B.PlayerComm,
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
				INNER JOIN SVRPRO.ProdDB.dbo.League lg WITH (NOLOCK) on m.leagueid = lg.leagueid	
				WHERE 	B.StatusId in (SELECT StatusId FROM #StatusId ) 		
						AND B.WinLostDate Between '''+ Convert(varchar(20),@Fromdate )+''' AND '''+ Convert(varchar(20),@Todate )+''' 
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
						m.leagueId, 
						m.IsNeutral,
						ISNULL(e.BetStatus,'') AS BetStatus,
						B.Username,
						B.BetType,
						B.CustId,
						B.Hdp1, 
						B.Hdp2, 
						B.Odds,
						B.MOdds,
						CASE WHEN B.Status = ''running'' AND IsNull(B.SecAcceptFlag, 0) = 1 AND IsNull(B.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN ''waiting''
									ELSE B.Status 
									END as Status,
						B.Stake,
						B.Actual_Stake,
						B.TransDate,	
						B.WinlostDate,	
						B.BetTeam,
						B.BetId,
						B.PlayerDiscount,
						B.WinLost,
						B.PlayerComm,
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
						INNER JOIN Match_BK m WITH (NOLOCK) ON  B.MatchId = m.MatchId
						LEFT JOIN SVRPRO.ProdDB.dbo.Match_remark_ex e WITH (NOLOCK) ON e.MatchId = m.MatchId
					WHERE 
						BA.AgentId = '+ CONVERT(VARCHAR(10),@AgentId) +'
						AND BA.StatusId in (SELECT StatusId FROM #StatusId ) 
						AND BA.WinLostDate Between'''+ Convert(varchar(20),@Fromdate )+''' AND '''+ Convert(varchar(20),@Todate )+''' 	
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
						'''' matchcode,
						0 as homeID,
						0 as awayID,
						0 as sporttype,
						'''' as leagueId,
						CONVERT(BIT,0) as IsNeutral,
						'''' as BetStatus,
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
						B.WinlostDate,	
						B.BetTeam,
						B.BetId,
						B.PlayerDiscount,
						B.WinLost,
						B.PlayerComm,
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
				WHERE	BA.AgentId = '+ CONVERT(VARCHAR(10),@AgentId) +'			
					AND B.StatusId in (SELECT StatusId FROM #StatusId ) 
					AND B.WinLostDate Between'''+ Convert(varchar(20),@Fromdate )+''' AND '''+ Convert(varchar(20),@Todate )+''' 
					AND B.BetType IN (9,29) 
'
SET @S3 = '

			----- outright_BK
			INSERT INTO #Betlist
			SELECT		B.transid,
						B.refno,
						0 as matchid,
						m.matchcode,
						m.teamID as homeID,
						0 as awayID,
						lg.sporttype,
						m.leagueID,
						CONVERT(BIT,0) as IsNeutral,
						'''' as BetStatus,
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
						B.WinlostDate,	
						B.betteam,
						B.betID,
						B.PlayerDiscount,
						B.WinLost,
						B.PlayerComm,
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
					INNER JOIN SVRPRO.ProdDB.dbo.League lg WITH (NOLOCK) on m.leagueid = lg.leagueid	
				WHERE 	BA.AgentId = '+ CONVERT(VARCHAR(10),@AgentId) +' 		
					AND B.StatusId in (SELECT StatusId FROM #StatusId ) 	
					AND B.WinLostDate Between'''+ Convert(varchar(20),@Fromdate )+''' AND '''+ Convert(varchar(20),@Todate )+''' 
					AND B.bettype = 10
			END
						
		END
 
		ELSE
		---- 3: Super View By Member
		IF '+ CONVERT(VARCHAR(10),@CustId) +' <> -1 AND '+ CONVERT(VARCHAR(10),@AgentId) +' = -1
		BEGIN 
			INSERT INTO #Betlist
			SELECT 	B.TransId,
					B.RefNo,
					m.MatchId,
					m.MatchCode ,
					m.HomeId,
					m.AwayId,
					m.SportType,
					m.leagueId, 
					m.IsNeutral,
					ISNULL(e.BetStatus,'') AS BetStatus,
					B.Username,
					B.BetType,
					B.CustId,
					B.Hdp1, 
					B.Hdp2, 
					B.Odds,
					B.MOdds,
					CASE WHEN B.Status = ''running'' AND IsNull(B.SecAcceptFlag, 0) = 1 AND IsNull(B.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN ''waiting''
								ELSE B.Status 
								END as Status,
					B.Stake,
					B.Actual_Stake,
					B.TransDate,	
					B.WinlostDate,	
					B.BetTeam,
					B.BetId,
					B.PlayerDiscount,
					B.WinLost,
					B.PlayerComm,
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
					INNER JOIN Match_BK m WITH (NOLOCK) ON  B.MatchId = m.MatchId 			
					LEFT JOIN SVRPRO.ProdDB.dbo.Match_remark_ex e WITH (NOLOCK) ON e.MatchId = m.MatchId
				WHERE 
					B.CustID = '+ CONVERT(VARCHAR(10),@CustId) +'
					AND B.StatusId in (SELECT StatusId FROM #StatusId )   	
					AND B.WinLostDate Between'''+ Convert(varchar(20),@Fromdate )+''' AND '''+ Convert(varchar(20),@Todate )+''' 	
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
					'''' matchcode,
					0 as homeID,
					0 as awayID,
					0 as sporttype,
					'''' as leagueId,
					CONVERT(BIT,0) as IsNeutral,
					'''' as BetStatus,
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
					B.WinlostDate,	
					B.BetTeam,
					B.BetId,
					B.PlayerDiscount,
					B.WinLost,
					B.PlayerComm,
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
				WHERE B.CustID = '+ CONVERT(VARCHAR(10),@CustId) +'  				
					AND B.StatusId in (SELECT StatusId FROM #StatusId ) 	
					AND B.WinLostDate Between'''+ Convert(varchar(20),@Fromdate )+''' AND '''+ Convert(varchar(20),@Todate )+''' 
					AND B.BetType IN (9,29) 
'
SET @S4= '

			----- outright_BK
			INSERT INTO #Betlist
			SELECT  B.transid,
					B.refno,
					0 as matchid,
					m.matchcode,
					m.teamID as homeID,
					0 as awayID,
					lg.sporttype,
					m.leagueID,
					CONVERT(BIT,0) as IsNeutral,
					'''' as BetStatus,
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
					B.WinlostDate,		
					B.betteam,
					B.betID,
					B.PlayerDiscount,
					B.WinLost,
					B.PlayerComm,
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
					INNER JOIN SVRPRO.ProdDB.dbo.League lg WITH (NOLOCK) on m.leagueid = lg.leagueid	
				WHERE 
					B.CustID ='+ CONVERT(VARCHAR(10),@CustId) +' 				
					AND B.StatusId in (SELECT StatusId FROM #StatusId ) 
					AND B.WinLostDate Between'''+ Convert(varchar(20),@Fromdate )+''' AND '''+ Convert(varchar(20),@Todate )+''' 
					AND B.bettype = 10
					
		END
	END 
	ELSE 
	--****************** 2: Agent View******************---
	BEGIN 
		----4: Agent view By Agent
		IF '+ CONVERT(VARCHAR(10),@AgentId) +' <> -1 AND '+ CONVERT(VARCHAR(10),@CustId) +' = -1
		BEGIN 
		INSERT INTO #Betlist
			SELECT 	B.TransId,
					B.RefNo,
					m.MatchId,
					m.MatchCode ,
					m.HomeId,
					m.AwayId,
					m.SportType,
					m.leagueId, 
					m.IsNeutral,
					ISNULL(e.BetStatus,'') AS BetStatus,
					B.Username,
					B.BetType,
					B.CustId,
					B.Hdp1, 
					B.Hdp2, 
					B.Odds,
					B.MOdds,
					CASE WHEN B.Status = ''running'' AND IsNull(B.SecAcceptFlag, 0) = 1 AND IsNull(B.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN ''waiting''
								ELSE B.Status 
								END as Status,
					B.Stake,
					B.Actual_Stake,
					B.TransDate,	
					B.WinlostDate,	
					B.BetTeam,
					B.BetId,
					B.PlayerDiscount,
					B.WinLost,
					B.PlayerComm,
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
					INNER JOIN BetTrans_Agent_BK AS L WITH (NOLOCK )  ON B.TransId = L.TransId AND L.AgentID = '+ CONVERT(VARCHAR(10),@LoggedId) +'
					LEFT JOIN BetTrans_Agent_BK D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
					INNER JOIN Match_BK m WITH (NOLOCK) ON  B.MatchId = m.MatchId 						
					LEFT JOIN SVRPRO.ProdDB.dbo.Match_remark_ex e WITH (NOLOCK) ON e.MatchId = m.MatchId
				WHERE BA.AgentId =  '+ CONVERT(VARCHAR(10),@AgentId) +'
					AND B.StatusId in (SELECT StatusId FROM #StatusId )  
					AND B.WinLostDate Between'''+ Convert(varchar(20),@Fromdate )+''' AND '''+ Convert(varchar(20),@Todate )+''' 	
					AND (	B.bettype < 31 
							OR B.bettype between 121 and 999
							OR B.bettype between 1301 and 1334 
							OR B.bettype BETWEEN 81 AND 120 				
						) 			
	'
SET @S5 = '		

			-----Parlay
			INSERT INTO #Betlist
			SELECT 	B.TransId,
					B.RefNo,
					0 as matchid,
					'''' matchcode,
					0 as homeID,
					0 as awayID,
					0 as sporttype,
					'''' as leagueId,
					CONVERT(BIT,0) as IsNeutral,
					'''' as BetStatus,
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
					B.WinlostDate,	
					B.BetTeam,
					B.BetId,
					B.PlayerDiscount,
					B.WinLost,
					B.PlayerComm,
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
					INNER JOIN BetTrans_Agent_BK AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = '+ CONVERT(VARCHAR(10),@LoggedId) +'
					LEFT JOIN BetTrans_Agent_BK D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
				WHERE BA.AgentId = '+ CONVERT(VARCHAR(10),@AgentId) +'				
					AND B.StatusId in (SELECT StatusId FROM #StatusId )  	
					AND B.WinLostDate Between'''+ Convert(varchar(20),@Fromdate )+''' AND '''+ Convert(varchar(20),@Todate )+''' 
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
					m.leagueID,
					CONVERT(BIT,0) as IsNeutral,
					'''' as BetStatus,
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
					B.WinlostDate,	
					B.betteam,
					B.betID,
					B.PlayerDiscount,
					B.WinLost,
					B.PlayerComm,
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
					INNER JOIN BetTrans_Agent_BK AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = '+ CONVERT(VARCHAR(10),@LoggedId) +'
					LEFT JOIN BetTrans_Agent_BK D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
					INNER JOIN outright_BK as m WITH (NOLOCK) on  B.matchid=m.orid
					INNER JOIN SVRPRO.ProdDB.dbo.League lg WITH (NOLOCK) on m.leagueid = lg.leagueid	
				WHERE 
					BA.AgentId = '+ CONVERT(VARCHAR(10),@AgentId) +'
					AND B.StatusId in (SELECT StatusId FROM #StatusId )  
					AND B.WinLostDate Between'''+ Convert(varchar(20),@Fromdate )+''' AND '''+ Convert(varchar(20),@Todate )+''' 
					AND B.bettype = 10

		END'
	
SET @S6 = '
		ELSE
		----- 5: Agent view By Member
		IF '+ CONVERT(VARCHAR(10),@CustId) +' <> -1 AND '+ CONVERT(VARCHAR(10),@AgentId) +' = -1
		BEGIN 
			INSERT INTO #Betlist
			SELECT 	B.TransId,
					B.RefNo,
					m.MatchId,
					m.MatchCode ,
					m.HomeId,
					m.AwayId,
					m.SportType,
					m.leagueId, 
					m.IsNeutral,
					ISNULL(e.BetStatus,'') AS BetStatus,
					B.Username,
					B.BetType,
					B.CustId,
					B.Hdp1, 
					B.Hdp2, 
					B.Odds,
					B.MOdds,
					CASE WHEN B.Status = ''running'' AND IsNull(B.SecAcceptFlag, 0) = 1 AND IsNull(B.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN ''waiting''
								ELSE B.Status 
								END as Status,
					B.Stake,
					B.Actual_Stake,
					B.TransDate,	
					B.WinlostDate,	
					B.BetTeam,
					B.BetId,
					B.PlayerDiscount,
					B.WinLost,
					B.PlayerComm,
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
					INNER JOIN BetTrans_Agent_BK AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = '+ CONVERT(VARCHAR(10),@LoggedId) +'
					LEFT JOIN BetTrans_Agent_BK D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
					INNER JOIN Match_BK m WITH (NOLOCK) ON  B.MatchId = m.MatchId 		
					LEFT JOIN SVRPRO.ProdDB.dbo.Match_remark_ex e WITH (NOLOCK) ON e.MatchId = m.MatchId
				WHERE	B.CustID = '+ CONVERT(VARCHAR(10),@CustId) +'
					AND B.StatusId in (SELECT StatusId FROM #StatusId ) 	
					AND B.WinLostDate Between'''+ Convert(varchar(20),@Fromdate )+''' AND '''+ Convert(varchar(20),@Todate )+''' 	
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
					'''' matchcode,
					0 as homeID,
					0 as awayID,
					0 as sporttype,
					'''' as leagueId,
					CONVERT(BIT,0) as IsNeutral,
					'''' as BetStatus,
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
					B.WinlostDate,	
					B.BetTeam,
					B.BetId,
					B.PlayerDiscount,
					B.WinLost,
					B.PlayerComm,
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
					INNER JOIN BetTrans_Agent_BK AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = '+ CONVERT(VARCHAR(10),@LoggedId) +'
					LEFT JOIN BetTrans_Agent_BK D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
				WHERE   B.CustID = '+ CONVERT(VARCHAR(10),@CustId) +'			
					AND B.StatusId in (SELECT StatusId FROM #StatusId ) 
					AND B.WinLostDate Between'''+ Convert(varchar(20),@Fromdate )+''' AND '''+ Convert(varchar(20),@Todate )+''' 
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
					m.leagueID,
					CONVERT(BIT,0) as IsNeutral,
					'''' as BetStatus,
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
					B.WinlostDate,	
					B.betteam,
					B.betID,
					B.PlayerDiscount,
					B.WinLost,
					B.PlayerComm,
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
					INNER JOIN BetTrans_Agent_BK AS L WITH (NOLOCK) ON B.TransId = L.TransId AND L.AgentID = '+ CONVERT(VARCHAR(10),@LoggedId) +'
					LEFT JOIN BetTrans_Agent_BK D WITH (NOLOCK) ON D.TransID = B.TransID AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
					INNER JOIN outright_BK as m WITH (NOLOCK) on  B.matchid=m.orid
					INNER JOIN SVRPRO.ProdDB.dbo.League lg WITH (NOLOCK) on m.leagueid = lg.leagueid	
				WHERE  B.CustID = '+ CONVERT(VARCHAR(10),@CustId) +' 				
					AND B.StatusId in (SELECT StatusId FROM #StatusId ) 	
					AND B.WinLostDate Between'''+ Convert(varchar(20),@Fromdate )+''' AND '''+ Convert(varchar(20),@Todate )+''' 
					AND B.bettype = 10

		END 
	END


SELECT	* , @LoggedAgentLevel
FROM	#Betlist 
ORDER BY TransID DESC 


DROP TABLE #Betlist
DROP TABLE #DirectChild
DROP TABLE #StatusId

'
PRINT @S 
PRINT @S1
PRINT @S2
PRINT @S3
PRINT @S4
PRINT @S5
PRINT @S6
EXEC (@S+@S1+@S2+@S3+@S4+@S5+@S6)

GO
GRANT EXECUTE ON [dbo].[Age_BetList_SelWinloss_Old] TO [aplweb]

