ALTER PROCEDURE [dbo].[Age_BetList_SelByDateMemStatus_SuperViewAgent]
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
Task : Betlist for Outstanding report/ Cancel Bets Report/ Account Info-Betlist -- 2: SuperViewAgent
DB:  SVRAGE.RepDB
Original:  
Revisions:
	- 20130724@Sophia: Add @RptType
	- 20131014@Sophia: add hthomescore,htawayscore
	- 20131231@Sophia: Get Parlay detail

Param's Explanation:  
	@RptType: = 0: Called from Account Info-Betlist
			  = 1: Called from Transaction report
			  = 2: Called from Outstanding Report (Super View Agent No need)
			  = 3: Called from ticket cancel report
				
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
						IP VARCHAR(40), OddsType TINYINT, DoubleCommLosing BIT, UGroup VARCHAR(3))

CREATE TABLE #DirectChild ( AgentId INT)

INSERT INTO #DirectChild 
SELECT	AgentId 
FROM	AgentInfo WITH (NOLOCK)
WHERE	ParentId = @LoggedId
 

CREATE TABLE #StatusId ( StatusId TINYINT)
INSERT INTO #StatusId
SELECT val FROM dbo.strSplit_Key(@StatusIds,',')

CREATE TABLE #BettypeList (bettype SMALLINT)
IF @Bettypes <> '0' 
	INSERT INTO #BettypeList
	SELECT val FROM dbo.strSplit_Key(@Bettypes,',')

CREATE TABLE #SportsList (Sporttype TINYINT)
INSERT INTO #SportsList (Sporttype)
SELECT val FROM strSplit_key (@Sporttypes, ',')

BEGIN
		--Sportsbook
		IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10) ) OR @Bettypes = '0'	
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
				B.DoubleCommLosing,
				C.UGroup
			FROM 	
				BetTrans AS B  WITH (NOLOCK) 
				INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId  
				INNER JOIN Match m WITH (NOLOCK) ON  B.MatchId = m.MatchId					
				INNER JOIN CustInfo C  WITH (NOLOCK) ON  C.CustId = B.CustId
			WHERE 
				BA.AgentId = @AgentId 
				AND BA.StatusId in (SELECT StatusId FROM #StatusId ) 
				AND BA.TransDate Between @FromDate AND @ToDate	
				AND (	BA.bettype < 31 
						OR BA.bettype between 121 and 999
						OR BA.bettype between 1301 and 1334 											
					)
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))
				
				AND B.StatusId in (SELECT StatusId FROM #StatusId ) 
				AND B.TransDate Between @FromDate AND @ToDate	
				AND (	B.bettype < 31 
						OR B.bettype between 121 and 999
						OR B.bettype between 1301 and 1334 							 				
					)
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList)) 
				 
				AND (@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList)) 		
				

		---Parlay
		IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29) ) OR @Bettypes = '0'
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
				B.DoubleCommLosing,
				C.UGroup	
		FROM BetTrans AS B  WITH (NOLOCK)				
		INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId 
		INNER JOIN CustInfo C  WITH (NOLOCK) ON  C.CustId = B.CustId
		WHERE	BA.AgentId = @AgentId 			
			AND BA.StatusId in (SELECT StatusId FROM #StatusId ) 
			AND BA.TransDate Between @FromDate AND @ToDate
			AND BA.BetType IN (9,29) 
			AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList)) 
			
			AND B.StatusId in (SELECT StatusId FROM #StatusId ) 
			AND B.TransDate Between @FromDate AND @ToDate
			AND B.BetType IN (9,29) 
			AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList)) 
		 				


		----- Outright
		IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype = 10 ) OR @Bettypes = '0'
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
				0 as hthomescore,
				0 as htawayscore,
				0 AS FinalHomeScore,
				0 AS FinalAwayScore, 
				B.IP as IP,		
				0 as oddstype,		
				B.DoubleCommLosing,
				C.UGroup
		FROM	bettrans B WITH (NOLOCK)
			INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
			INNER JOIN outright as m WITH (NOLOCK) on  B.matchid=m.orid
			INNER JOIN league lg WITH (NOLOCK) on m.leagueid = lg.leagueid	
			INNER JOIN CustInfo C  WITH (NOLOCK) ON  C.CustId = B.CustId
		WHERE 	BA.AgentId = @AgentId 		
			AND BA.StatusId in (SELECT StatusId FROM #StatusId ) 	
			AND BA.TransDate Between @FromDate AND @ToDate
			AND BA.bettype = 10
			
			AND B.StatusId in (SELECT StatusId FROM #StatusId ) 	
			AND B.TransDate Between @FromDate AND @ToDate
			AND B.bettype = 10
			
			AND (@Sporttypes = '0' OR lg.sporttype IN (Select sporttype FROM #SportsList))				
	
			 	
	----Call from  Account Info Betlist: Filter by TransDate and StatusID
	IF @RptType = 0
	BEGIN 	
		-- Get Betlist
		SELECT * 
		FROM #Betlist 
		ORDER BY TransID				
	END 
	
	--- Called from Ticket Canceled report : Get data more on Bettrans14
	IF @RptType = 3
	BEGIN 
		IF @FromDate <= @MoveBetsDay 
		BEGIN 
				--sportsbook
				IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10) ) OR @Bettypes = '0'
				INSERT INTO #Betlist
				SELECT 	
						B.TransId,
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
						B.DoubleCommLosing,
						C.UGroup
 					FROM 	
						Bettrans14 AS B  WITH (NOLOCK) 
						INNER JOIN Bettrans14_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId  
						INNER JOIN Match14 m WITH (NOLOCK) ON  B.MatchId = m.MatchId					
						INNER JOIN CustInfo C  WITH (NOLOCK) ON  C.CustId = B.CustId
					WHERE 
						BA.AgentId = @AgentId  
						AND BA.TransDate Between @FromDate AND @ToDate	
						AND BA.StatusID IN (101,102)
						AND (	BA.bettype < 31 
								OR BA.bettype between 121 and 999
								OR BA.bettype between 1301 and 1334 											
							)
						AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))
					 
						AND B.TransDate Between @FromDate AND @ToDate
						AND B.StatusID IN (101,102)	
						AND (	B.bettype < 31 
								OR B.bettype between 121 and 999
								OR B.bettype between 1301 and 1334 							 				
							)
						AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList)) 
					 
						AND (@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList)) 		
					

				---Parlay
				IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29) ) OR @Bettypes = '0'
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
						B.DoubleCommLosing,
						C.UGroup	
				FROM Bettrans14 AS B  WITH (NOLOCK) 
	--			INNER JOIN BettransM14 BM WITH (NOLOCK) ON BM.RefNo = B.RefNo
	--			INNER JOIN Match14 m WITH (NOLOCK) ON m.MatchID = BM.MatchID		
				INNER JOIN Bettrans14_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId 
				INNER JOIN CustInfo C  WITH (NOLOCK) ON  C.CustId = B.CustId
				WHERE	BA.AgentId = @AgentId 			 
					AND BA.TransDate Between @FromDate AND @ToDate
					AND BA.StatusID IN (101,102)
					AND BA.BetType IN (9,29) 
					AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList)) 
				
					AND B.TransDate Between @FromDate AND @ToDate
					AND B.StatusID IN (101,102)
					AND B.BetType IN (9,29) 
					AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList)) 
				 
					--AND (@Sporttypes = '0' 
					--			OR EXISTS (	SELECT	1 
					--						FROM	BettransM14 BM WITH (NOLOCK, index=IX_RefNo) 
					--						INNER JOIN Match14 M WITH (NOLOCK) 
					--							ON	 M.matchID = BM.MatchId 
					--							AND (M.sporttype IN (Select sporttype FROM #SportsList))							
					--						WHERE	BM.RefNo = B.RefNo
					--						)				
					--		)			


			----- Outright14
			IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype =10 ) OR @Bettypes = '0'
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
						0 as hthomescore,
						0 as htawayscore,
						0 AS FinalHomeScore,
						0 AS FinalAwayScore, 
						B.IP as IP,		
						0 as oddstype,		
						B.DoubleCommLosing,
						C.UGroup
				FROM	Bettrans14 B WITH (NOLOCK)
					INNER JOIN Bettrans14_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
					INNER JOIN Outright14 as m WITH (NOLOCK) on  B.matchid=m.orid
					INNER JOIN league lg WITH (NOLOCK) on m.leagueid = lg.leagueid	
					INNER JOIN CustInfo C  WITH (NOLOCK) ON  C.CustId = B.CustId
				WHERE 	BA.AgentId = @AgentId 			
					AND BA.TransDate Between @FromDate AND @ToDate
					AND BA.StatusID IN (101,102)
					AND BA.bettype = 10
									
					AND B.TransDate Between @FromDate AND @ToDate
					AND B.StatusID IN (101,102)
					AND B.bettype = 10
					
					AND (@Sporttypes = '0' OR lg.sporttype IN (Select sporttype FROM #SportsList))				
	
		END
	
		SELECT  *
		FROM #Betlist 
		ORDER BY TransID DESC	
	END

	--- Called from report Transaction: get more data on Bettrans14 and select top 200 row
	IF @RptType = 1 
	BEGIN 
		--- Check total of rows on Bettrans table
		DECLARE @RowCount INT

		SELECT @RowCount = COUNT (1)
		FROM #Betlist 
		
		IF @RowCount < 200
		SELECT @RowCount = 200 - @RowCount

		BEGIN 		
				--sportsbook
				IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10) ) OR @Bettypes = '0'
				INSERT INTO #Betlist
				SELECT 	TOP (@Rowcount) 
						B.TransId,
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
						B.DoubleCommLosing,
						C.UGroup
 					FROM 	
						Bettrans14 AS B  WITH (NOLOCK) 
						INNER JOIN Bettrans14_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId  
						INNER JOIN Match14 m WITH (NOLOCK) ON  B.MatchId = m.MatchId					
						INNER JOIN CustInfo C  WITH (NOLOCK) ON  C.CustId = B.CustId
					WHERE 
						BA.AgentId = @AgentId  
						AND BA.TransDate Between @FromDate AND @ToDate	
						AND (	BA.bettype < 31 
								OR BA.bettype between 121 and 999
								OR BA.bettype between 1301 and 1334 											
							)
						AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))
					 
						AND B.TransDate Between @FromDate AND @ToDate	
						AND (	B.bettype < 31 
								OR B.bettype between 121 and 999
								OR B.bettype between 1301 and 1334 							 				
							)
						AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList)) 
					 
						AND (@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList)) 		
					

				---Parlay
				IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29) ) OR @Bettypes = '0'
				INSERT INTO #Betlist
				SELECT  TOP (@Rowcount) 
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
						B.DoubleCommLosing,
						C.UGroup	
				FROM Bettrans14 AS B  WITH (NOLOCK) 
	--			INNER JOIN BettransM14 BM WITH (NOLOCK) ON BM.RefNo = B.RefNo
	--			INNER JOIN Match14 m WITH (NOLOCK) ON m.MatchID = BM.MatchID		
				INNER JOIN Bettrans14_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId 
				INNER JOIN CustInfo C  WITH (NOLOCK) ON  C.CustId = B.CustId
				WHERE	BA.AgentId = @AgentId 			 
					AND BA.TransDate Between @FromDate AND @ToDate
					AND BA.BetType IN (9,29) 
					AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList)) 
				
					AND B.TransDate Between @FromDate AND @ToDate
					AND B.BetType IN (9,29) 
					AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList)) 
				 
					--AND (@Sporttypes = '0' 
					--			OR EXISTS (	SELECT	1 
					--						FROM	BettransM14 BM WITH (NOLOCK, index=IX_RefNo) 
					--						INNER JOIN Match14 M WITH (NOLOCK) 
					--							ON	 M.matchID = BM.MatchId 
					--							AND (M.sporttype IN (Select sporttype FROM #SportsList))							
					--						WHERE	BM.RefNo = B.RefNo
					--						)				
					--		)			


			----- Outright14
			IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype =10 ) OR @Bettypes = '0'
			INSERT INTO #Betlist
			SELECT		TOP (@Rowcount) 
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
						0 as hthomescore,
						0 as htawayscore,
						0 AS FinalHomeScore,
						0 AS FinalAwayScore, 
						B.IP as IP,		
						0 as oddstype,		
						B.DoubleCommLosing,
						C.UGroup
				FROM	Bettrans14 B WITH (NOLOCK)
					INNER JOIN Bettrans14_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
					INNER JOIN Outright14 as m WITH (NOLOCK) on  B.matchid=m.orid
					INNER JOIN league lg WITH (NOLOCK) on m.leagueid = lg.leagueid	
					INNER JOIN CustInfo C  WITH (NOLOCK) ON  C.CustId = B.CustId
				WHERE 	BA.AgentId = @AgentId 			
					AND BA.TransDate Between @FromDate AND @ToDate
					AND BA.bettype = 10
									
					AND B.TransDate Between @FromDate AND @ToDate
					AND B.bettype = 10
					
					AND (@Sporttypes = '0' OR lg.sporttype IN (Select sporttype FROM #SportsList))				
	
		END
	
		SELECT TOP 200 * 
		FROM #Betlist 
		ORDER BY TransID DESC	
	END
END	


---------------------------------

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

	IF EXISTS (SELECT 1 FROM bettransm WITH (NOLOCK) WHERE refno IN (SELECT RefNo FROM #Betlist WHERE Bettype IN (9,29)))
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
		FROM(	SELECT	RefNo,
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
				FROM	BettransM with (nolock)
						WHERE refno IN (SELECT RefNo FROM #Betlist WHERE Bettype IN (9,29))         
			) AS b		
				inner join match as m with (nolock) on b.matchid=m.matchid
	END


	IF EXISTS (SELECT 1 FROM bettransm14 WITH (NOLOCK) WHERE refno IN (SELECT RefNo FROM #Betlist WHERE Bettype IN (9,29)))
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
		FROM(	SELECT	RefNo,
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
				FROM	BettransM14 with (nolock)
						WHERE refno IN (SELECT RefNo FROM #Betlist WHERE Bettype IN (9,29))             
			) AS b		
				inner join match14 as m with (nolock) on b.matchid=m.matchid
	END


	IF EXISTS (SELECT 1 FROM SVRARC.ArchiveDB.dbo.BettransM WITH (NOLOCK) WHERE refno IN (SELECT RefNo FROM #Betlist WHERE Bettype IN (9,29)))
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
END

 
SELECT DISTINCT * FROM @tmpParlay
ORDER BY transID DESC
---------------

DROP TABLE #Betlist
DROP TABLE #DirectChild
DROP TABLE #StatusId
DROP TABLE #BettypeList
DROP TABLE #SportsList


GO
GRANT EXECUTE ON [dbo].[Age_BetList_SelByDateMemStatus_SuperViewAgent] TO [aplweb]
GO 