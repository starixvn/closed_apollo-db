ALTER PROCEDURE [dbo].[Age_Rpt_WinLoss]
	@AgentID 	INT,
	@FromDate 	DATE,
	@ToDate 	DATE,	
	@MoveBetDay DATE, 
	@BalanceUpDay DATE,	
	@Sporttypes VARCHAR(MAX) = '0',
	@Bettypes VARCHAR(MAX) = '0'
WITh RECOMPILE  	
AS
    /*
    Created	: Sophia
	Date	: 20130401
    Task	: Report Agent Winloss
    DB		: SVRAGE.RepDB
    Original SP:[Age_Rpt_WinLoss_Ag]
    EX: EXEC Age_Rpt_WinLoss @AgentId =99, @FromDate = '2013-01-01',  @ToDate = '2013-05-10', @BalanceUpDay = '2013-03-01'

    Revisions:
       - 20130625@Sophia: Modify for Singbet
	   - 20130708@Sophia: Change SuperId from 0 to 1 (@AgentID = 1)
						  Sort by PositionTaking
	   - 20130712@Sophia: add OutStanding
    */
    
SET NOCOUNT ON


CREATE TABLE #WinLossAgent ( Username NVARCHAR(50), AgentID INT, IsAgent BIT, PositionTaking SMALLINT, BetCount BIGINT, TurnOver MONEY, ActualTO MONEY, AWinLost MONEY, AComm MONEY, ATotal MONEY, GrossTotal MONEY, UplineTotal MONEY)
CREATE TABLE #WinLossMember ( Username NVARCHAR(50), AgentID INT, IsAgent BIT,  PositionTaking SMALLINT, BetCount BIGINT, TurnOver MONEY, ActualTO MONEY, AWinLost MONEY, AComm MONEY, ATotal MONEY, GrossTotal MONEY, UplineTotal MONEY)

CREATE TABLE #BettypeList (bettype SMALLINT)
INSERT INTO #BettypeList
SELECT val FROM dbo.strSplit_Key(@Bettypes,',')

CREATE TABLE #SportsList (Sporttype TINYINT)
INSERT INTO #SportsList (Sporttype)
SELECT val FROM strSplit_key (@Sporttypes, ',')

IF @Todate > @MoveBetDay
BEGIN  
	IF @AgentId = 1
	BEGIN 
	--********************************
	----Super view
	--********************************
		
		IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10) OR @Bettypes = '0')
		----Sportsbook
		INSERT INTO #WinLossAgent
		SELECT  C.Username, C.AgentID, 1 as IsAgent,
				PT.MaxUpperPositionTaking as PositionTaking,	
				COUNT(B.TransID) BetCount,			
		   		SUM(ABS(B.Stake)) AS TurnOver,
				SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS ActualTO,
				- SUM(B.Winlost - B.Actual_Stake + B.TWinlost) AS AWinlost,	
				- SUM (B.TComm) AS AComm,
				- (SUM(B.Winlost - B.Actual_Stake + B.TWinlost) + SUM (B.TComm)) AS ATotal,
				0 AS GrossTotal,
				0 AS UplineTotal	
		FROM		AgentInfo C WITH (NOLOCK)
		INNER JOIN	BetTrans_Agent BA WITH (NOLOCK)
				ON	BA.AgentID = C.AgentID
					AND BA.Winlostdate BETWEEN @FromDate AND @ToDate
					AND BA.StatusID NOT IN (0,1)
					AND BA.Bettype <=19000
					AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))							
		INNER JOIN	Bettrans B WITH (NOLOCK) 
				ON	B.TransID = BA.TransID		
		INNER JOIN  AgentPositionTaking PT WITH (NOLOCK) 
				ON  PT.AgentID = C.AgentId AND PT.Bettype = 1 AND PT.SportType = 1 AND IsLive = 0
		INNER JOIN  Match m  WITH (NOLOCK) 
				ON m.MatchID = B.MatchID
		WHERE		C.ParentId = @AgentID 
					AND B.Winlostdate BETWEEN @FromDate AND @ToDate
					AND B.StatusID NOT IN (0,1)
					AND B.Bettype <=19000
					AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))					

					AND (@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList))
		GROUP BY	C.Username, C.AgentID, PT.MaxUpperPositionTaking


		----Parlay
		IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29) OR @Bettypes = '0')
		INSERT INTO #WinLossAgent
		SELECT  B.Username, B.AgentID, 1 as IsAgent,
				B.MaxUpperPositionTaking as PositionTaking,	
				SUM(B.BetCount) BetCount,			
		   		SUM(ABS(B.Stake)) AS TurnOver,
				SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS ActualTO,
				- SUM(B.Winlost - B.Actual_Stake + B.TWinlost) AS AWinlost,	
				- SUM (B.TComm) AS AComm,
				- (SUM(B.Winlost - B.Actual_Stake + B.TWinlost) + SUM (B.TComm)) AS ATotal,
				0 AS GrossTotal,
				0 AS UplineTotal
		FROM (
				SELECT		DISTINCT
							C.Username, C.AgentID, PT.MaxUpperPositionTaking,	
							COUNT(B.TransID) BetCount,
							B.Stake, B.TransID,
							B.MOdds,B.StatusID,	 
							B.Winlost,B.Actual_Stake ,B.TWinlost, B.TComm	
				FROM		AgentInfo C WITH (NOLOCK)
				INNER JOIN	BetTrans_Agent BA WITH (NOLOCK)
						ON	BA.AgentID = C.AgentID	
							AND BA.Winlostdate BETWEEN @FromDate AND @ToDate
							AND BA.StatusID NOT IN (0,1)
							AND BA.Bettype IN (9,29)
							AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))								
				INNER JOIN	Bettrans B WITH (NOLOCK) 
						ON	B.TransID = BA.TransID		
				INNER JOIN  AgentPositionTaking PT WITH (NOLOCK) 
						ON  PT.AgentID = C.AgentId AND PT.Bettype = 1 AND PT.SportType = 1 AND IsLive = 0
				INNER JOIN  BettransM BM WITH (NOLOCK) 
						ON  BM.RefNo = B.RefNo
				INNER JOIN  Match M  WITH (NOLOCK) 
						ON	M.MatchID = BM.MatchID
				WHERE		C.ParentId = @AgentID 
							AND B.Winlostdate BETWEEN @FromDate AND @ToDate
							AND B.StatusID NOT IN (0,1)
							AND B.Bettype IN (9,29)
							AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))						

							AND (@Sporttypes = '0' 
							OR EXISTS (	SELECT	1 
										FROM	BettransM BM WITH (NOLOCK, index=IX_RefNo) 
										INNER JOIN Match M WITH (NOLOCK) 
											ON	 M.matchID = BM.MatchId 
											AND (M.sporttype IN (Select sporttype FROM #SportsList))							
										WHERE	BM.RefNo = B.RefNo
										)				
						)	
				GROUP BY	C.Username, C.AgentID, PT.MaxUpperPositionTaking, 
							B.MOdds,B.StatusID,	B.Stake, B.TransID,
							B.Winlost,B.Actual_Stake ,B.TWinlost, B.TComm,B.Stake
			 ) B
		GROUP BY	B.Username, B.AgentID, B.MaxUpperPositionTaking  

	
	----Outright
		IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (10) OR @Bettypes = '0')
		INSERT INTO #WinLossAgent
		SELECT  C.Username, C.AgentID, 1 as IsAgent,
				PT.MaxUpperPositionTaking as PositionTaking,	
				COUNT(B.TransID) BetCount,			
		   		SUM(ABS(B.Stake)) AS TurnOver,
				SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS ActualTO,
				- SUM(B.Winlost - B.Actual_Stake + B.TWinlost) AS AWinlost,	
				- SUM (B.TComm) AS AComm,
				- (SUM(B.Winlost - B.Actual_Stake + B.TWinlost) + SUM (B.TComm)) AS ATotal,
				0 AS GrossTotal,
				0 AS UplineTotal	
		FROM		AgentInfo C WITH (NOLOCK)
		INNER JOIN	BetTrans_Agent BA WITH (NOLOCK)
				ON	BA.AgentID = C.AgentID			
					AND BA.Winlostdate BETWEEN @FromDate AND @ToDate
					AND BA.StatusID NOT IN (0,1)
					AND BA.Bettype = 10
					AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))						
		INNER JOIN	Bettrans B WITH (NOLOCK) 
				ON	B.TransID = BA.TransID		
		INNER JOIN  AgentPositionTaking PT WITH (NOLOCK) 
				ON  PT.AgentID = C.AgentId AND PT.Bettype = 1 AND PT.SportType = 1 AND IsLive = 0
		INNER JOIN  Outright m  WITH (NOLOCK) 
				ON  m.orid = B.MatchID
		INNER JOIN  League l WITH (NOLOCK)
				ON	l.leagueID = m.leagueId
		WHERE		C.ParentId = @AgentID 
					AND B.Winlostdate BETWEEN @FromDate AND @ToDate
					AND B.StatusID NOT IN (0,1)
					AND B.Bettype = 10
					AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))

					AND (@Sporttypes = '0' OR l.sporttype IN (Select sporttype FROM #SportsList))
		GROUP BY	C.Username, C.AgentID, PT.MaxUpperPositionTaking


	END
	ELSE 
	BEGIN
	--********************************
	---- Agent Winloss
	--********************************
		---Sportsbook
		CREATE TABLE #Tmp (Username VARCHAR(50),  AgentID INT , PositionTaking smallint,
				BetCount INT, TurnOver MONEY, ActualTO MONEY, AWinlost MONEY,AComm MONEY,
				ATotal MONEY, ChildAComm MONEY, Winlost MONEY, Actual_Stake MONEY) 

		---Sportsbook
		IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10) OR @Bettypes = '0')
		INSERT INTO	#Tmp
		SELECT  C.Username, C.AgentID, PT.MaxUpperPositionTaking as PositionTaking,
				COUNT(B.TransID) BetCount,			 
		   		SUM(ABS(B.Stake)) AS TurnOver,
				SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS ActualTO,
				SUM(BP.AWinlost) AS AWinlost,	
				SUM(BP.AComm) - SUM(BA.AComm) AS AComm,
				SUM(BP.AWinlost) + SUM (BP.AComm) - SUM (BA.AComm)  AS ATotal,
			    SUM(BA.AComm) ChildAComm  , 
				SUM(B.Winlost) as Winlost,
				SUM(B.Actual_Stake) as Actual_Stake	   
		FROM		Bettrans B WITH (NOLOCK) 
		INNER JOIN	Bettrans_Agent BP WITH (NOLOCK) 
				ON	BP.TransID = B.TransID 
					AND BP.AgentID = @AgentID ---Parent (k)
					AND BP.Winlostdate BETWEEN @FromDate AND @ToDate 
					AND BP.StatusID NOT IN (0,1)	
					AND BP.Bettype <=19000
					AND (@Bettypes = '0' OR BP.Bettype IN (Select bettype FROM #BettypeList))
		INNER JOIN AgentInfo C WITH (NOLOCK) --- Child direct (k+1)
				ON C.ParentID = @AgentID  
		INNER JOIN AgentPositionTaking PT WITH (NOLOCK) 
				ON PT.AgentID = C.AgentId AND PT.Bettype = 1 AND PT.SportType = 1 AND IsLive = 0
		INNER JOIN Bettrans_Agent BA WITH (NOLOCK) 
				ON  BA.TransID = B.TransID 
				AND C.AgentID = BA.AgentID ---- Child direct (k+1)
				AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND BA.StatusID NOT IN (0,1)	
				AND BA.Bettype <=19000
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))
		INNER JOIN  Match m  WITH (NOLOCK) 
				ON m.MatchID = B.MatchID
		WHERE	B.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND B.StatusID NOT IN (0,1)	
				AND B.Bettype <=19000
				AND (@Bettypes =  '0' OR B.Bettype IN (Select bettype FROM #BettypeList))	
				AND (@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList))
		GROUP BY C.Username, C.AgentID ,  PT.MaxUpperPositionTaking

 	 
		INSERT INTO #WinLossAgent
		SELECT	T.Username, T.AgentID, 1 as IsAgent, T.PositionTaking as PositionTaking,
				T.BetCount, T.TurnOver, T.ActualTO, T.AWinlost, T.AComm, T.ATotal, 
				SUM(BA.AWINLOST) + (T.Winlost - T.Actual_Stake) + T.ChildAComm  AS GrossTotal,  
				-(SUM(BA.AWINLOST) + (T.Winlost - T.Actual_Stake) + T.ChildAComm  + T.ATotal) AS UplineTotal
		FROM	#Tmp T
		INNER JOIN AgentInfo P with (nolock) ON  T.AgentID = P.AgentID
		INNER JOIN AgentInfo C WITH(NOLOCK) ON C.AgentHId.IsDescendantOf(P.AgentHId ) =1  AND C.AgentLevel >= P.AgentLevel  --- Children of k+1 (k+1 -> k+...)
		INNER JOIN Bettrans_Agent BA WITH (NOLOCK) ON BA.AgentID = C.AgentID
		INNER JOIN Match M WITH (NOLOCK) ON M.matchID = BA.MatchId
		WHERE   BA.Winlostdate BETWEEN @FromDate AND @ToDate
				AND BA.StatusID NOT IN (0,1) 				 
				AND BA.Bettype <= 19000
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

				AND (@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList))			
		GROUP BY T.AgentID, T.Username,T.PositionTaking, T.TurnOver, T.ActualTO, T.AWinlost, T.AComm, T.ATotal, T.ChildAComm, T.Winlost , T.Actual_Stake, T.BetCount
	 
		TRUNCATE TABLE #Tmp
		 
		------Parlay	
		IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29) OR @Bettypes = '0')
		INSERT INTO	#Tmp
		SELECT  B.Username, B.AgentID, B.MaxUpperPositionTaking as PositionTaking,
				SUM(B.BetCount) BetCount,			 
		   		SUM(ABS(B.Stake)) AS TurnOver,
				SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS ActualTO,
				SUM(B.AWinlost) AS AWinlost,	
				SUM(B.AComm) - SUM(B.ChildAComm) AS AComm,
				SUM(B.AWinlost) + SUM (B.AComm) - SUM (B.ChildAComm)  AS ATotal,
			    SUM(B.ChildAComm) ChildAComm  , 
				SUM(B.Winlost) as Winlost,
				SUM(B.Actual_Stake) as Actual_Stake
		FROM	(	
				SELECT  DISTINCT 
						C.Username, C.AgentID, PT.MaxUpperPositionTaking,
						COUNT(B.TransId) BetCount,			 
		   				B.Stake, B.TransID,
						B.Winlost,B.Actual_Stake,
						B.MOdds,B.StatusID,
						BP.AWinlost, BP.AComm, BA.AComm as ChildAComm							
				FROM	Bettrans B WITH (NOLOCK, index = IX_Winlostdate_Bettype_StatusId) 
				INNER JOIN Bettrans_Agent BP WITH (NOLOCK) 
						ON BP.TransID = B.TransID 
						AND BP.AgentID = @AgentID ---Parent (k)
						AND BP.Winlostdate BETWEEN @FromDate AND @ToDate 
						AND BP.StatusID NOT IN (0,1)	
						AND BP.Bettype IN (9,29)
						AND (@Bettypes = '0' OR BP.Bettype IN (Select bettype FROM #BettypeList))

				INNER JOIN AgentInfo C WITH (NOLOCK) --- Child direct (k+1)
						ON C.ParentID = @AgentID  
				INNER JOIN AgentPositionTaking PT WITH (NOLOCK) 
						ON PT.AgentID = C.AgentId AND PT.Bettype = 1 AND PT.SportType = 1 AND IsLive = 0
				INNER JOIN Bettrans_Agent BA WITH (NOLOCK) 
						ON BA.TransID = B.TransID 
						AND BA.AgentID = C.AgentID ---- Child direct (k+1)
						AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
						AND BA.StatusID NOT IN (0,1)	
						AND BA.Bettype IN (9,29)
						AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))				
				WHERE	B.Winlostdate BETWEEN @FromDate AND @ToDate 
						AND B.StatusID NOT IN (0,1)	
						AND B.Bettype IN (9,29)
						AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))	
								
						AND (@Sporttypes = '0' 
							OR EXISTS (	SELECT	1 
										FROM	BettransM BM WITH (NOLOCK, index=IX_RefNo) 
										INNER JOIN Match M WITH (NOLOCK) 
											ON	 M.matchID = BM.MatchId 
											AND (M.sporttype IN (Select sporttype FROM #SportsList))							
										WHERE	BM.RefNo = B.RefNo
										)				
						)	
				GROUP BY C.Username, C.AgentID, PT.MaxUpperPositionTaking,						
		   				B.Winlost,B.Actual_Stake,
						B.MOdds,B.StatusID,B.Stake,B.TransID,
						BP.AWinlost, BP.AComm, BP.AWinlost, BA.AComm
			) B
		GROUP BY B.Username, B.AgentID , B.MaxUpperPositionTaking

		--------------------------------
	
		INSERT INTO #WinLossAgent
		SELECT	T.Username, T.AgentID, 1 as IsAgent, T.PositionTaking as PositionTaking,
				T.BetCount, T.TurnOver, T.ActualTO, T.AWinlost, T.AComm, T.ATotal, 
				SUM(T.LineWinLost) + (T.Winlost - T.Actual_Stake) + T.ChildAComm  AS GrossTotal,  
				-(SUM(T.LineWinLost) + (T.Winlost - T.Actual_Stake) + T.ChildAComm  + T.ATotal) AS UplineTotal
		FROM (	
			SELECT  T.Username, T.AgentID, 1 as IsAgent, T.PositionTaking as PositionTaking,
					T.BetCount, T.TurnOver, T.ActualTO, T.AWinlost, T.AComm, T.ATotal, 
					BA.AWINLOST as LineWinLost, T.Winlost,T.Actual_Stake, T.ChildAComm			 		
			FROM #Tmp T
			INNER JOIN AgentInfo P with (nolock) ON  T.AgentID = P.AgentID
			INNER JOIN AgentInfo C WITH(NOLOCK) ON C.AgentHId.IsDescendantOf(P.AgentHId ) =1  AND C.AgentLevel >= P.AgentLevel  --- Children of k+1 (k+1 -> k+...)
			INNER JOIN Bettrans_Agent BA WITH (NOLOCK) ON BA.AgentID = C.AgentID
			WHERE	BA.Winlostdate BETWEEN @FromDate AND @ToDate
					AND BA.StatusID NOT IN (0,1) 				 
					AND BA.Bettype IN (9,29)
					AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList)) 	

					AND (@Sporttypes = '0' 
						OR EXISTS (	SELECT	1 
									FROM	BettransM BM WITH (NOLOCK, index=IX_RefNo) 
									INNER JOIN Match M WITH (NOLOCK) 
										ON	 M.matchID = BM.MatchId 
										AND (m.sporttype IN (Select sporttype FROM #SportsList))							
									WHERE	BM.RefNo = BA.RefNo
									)				
						)					
			) T
		GROUP BY T.AgentID, T.Username,T.PositionTaking, T.TurnOver, T.ActualTO, T.AWinlost, T.AComm, T.ATotal, T.ChildAComm, T.Winlost , T.Actual_Stake, T.BetCount
	 
		TRUNCATE TABLE #Tmp 


		-----Outright
		IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (10) OR @Bettypes = '0')
		INSERT INTO	#Tmp
		SELECT  C.Username, C.AgentID, PT.MaxUpperPositionTaking as PositionTaking,
				COUNT(B.TransID) BetCount,			 
		   		SUM(ABS(B.Stake)) AS TurnOver,
				SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS ActualTO,
				SUM(BP.AWinlost) AS AWinlost,	
				SUM(BP.AComm) - SUM(BA.AComm) AS AComm,
				SUM(BP.AWinlost) + SUM (BP.AComm) - SUM (BA.AComm)  AS ATotal,
			    SUM(BA.AComm) ChildAComm  , 
				SUM(B.Winlost) as Winlost,
				SUM(B.Actual_Stake) as Actual_Stake	   
		FROM	Bettrans B WITH (NOLOCK , index = IX_Winlostdate_Bettype_StatusId) 
		INNER JOIN Bettrans_Agent BP WITH (NOLOCK, index =IX_WinLostDate_Bettype_StatusId) 
				ON BP.TransID = B.TransID 
				AND BP.AgentID = @AgentID ---Parent (k)
				AND BP.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND BP.StatusID NOT IN (0,1)	
				AND BP.Bettype = 10
				AND (@Bettypes = '0' OR BP.Bettype IN (Select bettype FROM #BettypeList))
		INNER JOIN AgentInfo C WITH (NOLOCK) --- Child direct (k+1)
				ON C.ParentID = @AgentID  
		INNER JOIN AgentPositionTaking PT WITH (NOLOCK) 
				ON PT.AgentID = C.AgentId AND PT.Bettype = 1 AND PT.SportType = 1 AND IsLive = 0
		INNER JOIN Bettrans_Agent BA WITH (NOLOCK,  index =IX_WinLostDate_Bettype_StatusId) 
				ON BA.TransID = B.TransID 
				AND C.AgentID = BA.AgentID ---- Child direct (k+1)
				AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND BA.StatusID NOT IN (0,1)	
				AND BA.Bettype = 10
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

		INNER JOIN  Outright m  WITH (NOLOCK) 
				ON  m.orid = B.MatchID
		INNER JOIN  League l WITH (NOLOCK)
				ON	l.leagueID = m.leagueId
		WHERE	B.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND B.StatusID NOT IN (0,1)	
				AND B.Bettype =10
				AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))
							
				AND (@Sporttypes = '0' OR l.sporttype IN (Select sporttype FROM #SportsList))
		GROUP BY C.Username, C.AgentID ,  PT.MaxUpperPositionTaking
				 
		 
		INSERT INTO #WinLossAgent
		SELECT	T.Username, T.AgentID, 1 as IsAgent, T.PositionTaking as PositionTaking,
				T.BetCount, T.TurnOver, T.ActualTO, T.AWinlost, T.AComm, T.ATotal, 
				SUM(BA.AWINLOST) + (T.Winlost - T.Actual_Stake) + T.ChildAComm  AS GrossTotal,  
				-(SUM(BA.AWINLOST) + (T.Winlost - T.Actual_Stake) + T.ChildAComm  + T.ATotal) AS UplineTotal
		FROM #Tmp T
		INNER JOIN AgentInfo P with (nolock) ON  T.AgentID = P.AgentID
		INNER JOIN AgentInfo C WITH(NOLOCK) ON C.AgentHId.IsDescendantOf(P.AgentHId ) =1  AND C.AgentLevel >= P.AgentLevel  --- Children of k+1 (k+1 -> k+...)
		INNER JOIN Bettrans_Agent BA WITH (NOLOCK) ON BA.AgentID = C.AgentID
		INNER JOIN Outright M WITH (NOLOCK) ON M.OrId = BA.MatchId
		INNER JOIN League L WITH (NOLOCK) ON L.LeagueId = M.leagueId
		WHERE	BA.Winlostdate BETWEEN @FromDate AND @ToDate
				AND BA.StatusID NOT IN (0,1) 				 
				AND BA.Bettype = 10
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))
		
				AND (@Sporttypes = '0' OR l.sporttype IN (Select sporttype FROM #SportsList))
		GROUP BY T.AgentID, T.Username,T.PositionTaking, T.TurnOver, T.ActualTO, T.AWinlost, T.AComm, T.ATotal, T.ChildAComm, T.Winlost , T.Actual_Stake, T.BetCount
	 
		DROP TABLE #Tmp 

	


--********************************
-----Member winloss
--********************************	
	---Sportsbook
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10) OR @Bettypes = '0')
	INSERT INTO #WinLossMember  
	SELECT	'' as Username, 0 as AgentId, 0 as IsAgent,
			0 as PositionTaking,	
			COUNT(B.TransID) BetCount,			
		   	SUM(ABS(B.Stake)) as TurnOver,
			SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  as ActualTO,
			SUM(BA.AWinLost) as AWinlost,	
			SUM(BA.AComm) - SUM (B.PlayerComm) as AComm,
			SUM(BA.AWinLost) + SUM(BA.AComm) - SUM (B.PlayerComm) AS ATotal,
			SUM (B.Winlost - B.Actual_Stake + B.PlayerComm) GrossTotal,
			-(SUM (B.Winlost - B.Actual_Stake + B.PlayerComm) + SUM(BA.AWinLost) + SUM(BA.AComm) - SUM (B.PlayerComm)) UplineTotal
	FROM	Bettrans B WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK ) 
		ON	BA.TransID = B.TransID 
		AND BA.AgentId = @AgentID 
		AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
		AND BA.StatusID NOT IN (0,1)
		AND BA.Bettype <= 19000
		AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))
	INNER JOIN CustInfo C WITH (NOLOCK)
		ON	B.CustID = C.CustID AND C.AgentId = @AgentID
	INNER JOIN  Match m  WITH (NOLOCK) 
		ON m.MatchID = B.MatchID
	WHERE	B.Winlostdate BETWEEN @FromDate AND @ToDate 
			AND B.StatusID NOT IN (0,1)
			AND B.Bettype <= 19000
			AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))

			AND (@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList))
 

	-----Parlay	
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29) OR @Bettypes = '0')
	INSERT INTO #WinLossMember  
	SELECT	'' as Username, 0 as AgentId, 0 as IsAgent,
			0 as PositionTaking,	
			SUM(B.BetCount) BetCount,			
		   	SUM(ABS(B.Stake)) as TurnOver,
			SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  as ActualTO,
			SUM(B.AWinLost) as AWinlost,	
			SUM(B.AComm) - SUM (B.PlayerComm) as AComm,
			SUM(B.AWinLost) + SUM(B.AComm) - SUM (B.PlayerComm) AS ATotal,
			SUM (B.Winlost - B.Actual_Stake + B.PlayerComm) GrossTotal,
			-(SUM (B.Winlost - B.Actual_Stake ) + SUM(B.AWinLost) + SUM(B.AComm)) UplineTotal
	FROM (
			SELECT DISTINCT 
					COUNT(B.TransID) BetCount,	   			
					B.MOdds,B.StatusID,	BA.AWinLost, BA.AComm,
					B.Stake , B.TransID,
					B.Winlost, B.Actual_Stake,B.PlayerComm
					
			FROM	Bettrans B WITH (NOLOCK)
			INNER JOIN BetTrans_Agent BA WITH (NOLOCK ) 
				ON	BA.TransID = B.TransID 
					AND BA.AgentId = @AgentID 
					AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
					AND BA.StatusID NOT IN (0,1)
					AND BA.Bettype IN (9,29)
					AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

			INNER JOIN CustInfo C WITH (NOLOCK)
				ON	B.CustID = C.CustID AND C.AgentId = @AgentID			
			WHERE	B.Winlostdate BETWEEN @FromDate AND @ToDate 
					AND B.StatusID NOT IN (0,1)
					AND B.Bettype IN (9,29)
					AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))

					AND (@Sporttypes = '0' 
							OR EXISTS (	SELECT	1 
										FROM	BettransM BM WITH (NOLOCK, index=IX_RefNo) 
										INNER JOIN Match M WITH (NOLOCK) 
											ON	 M.matchID = BM.MatchId 
											AND (M.sporttype IN (Select sporttype FROM #SportsList))							
										WHERE	BM.RefNo = B.RefNo
										)
						)
			GROUP BY B.MOdds,B.StatusID,	BA.AWinLost, BA.AComm,
					 B.Winlost, B.Actual_Stake,B.PlayerComm, B.Stake , B.TransID
			) B

	-----Outright
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (10) OR @Bettypes = '0')
	INSERT INTO #WinLossMember  
	SELECT	'' as Username, 0 as AgentId, 0 as IsAgent,
			0 as PositionTaking,	
			COUNT(B.TransID) BetCount,			
		   	SUM(ABS(B.Stake)) as TurnOver,
			SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  as ActualTO,
			SUM(BA.AWinLost) as AWinlost,	
			SUM(BA.AComm) - SUM (B.PlayerComm) as AComm,
			SUM(BA.AWinLost) + SUM(BA.AComm) - SUM (B.PlayerComm) AS ATotal,
			SUM (B.Winlost - B.Actual_Stake + B.PlayerComm) GrossTotal,
			-(SUM (B.Winlost - B.Actual_Stake + B.PlayerComm) + SUM(BA.AWinLost) + SUM(BA.AComm) - SUM (B.PlayerComm)) UplineTotal
	FROM	Bettrans B WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK ) 
		ON	BA.TransID = B.TransID
			AND BA.AgentId = @AgentID 
			AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
			AND BA.StatusID NOT IN (0,1)
			AND BA.Bettype = 10
			AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList)) 
	INNER JOIN CustInfo C WITH (NOLOCK)
		ON	B.CustID = C.CustID AND C.AgentId = @AgentID
	INNER JOIN  Outright m WITH (NOLOCK) 
		ON  m.orid = B.MatchID
	INNER JOIN  League l WITH (NOLOCK)
		ON	l.leagueID = m.leagueId
	WHERE   B.Winlostdate BETWEEN @FromDate AND @ToDate 
			AND B.StatusID NOT IN (0,1)
			AND B.Bettype = 10
			AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))

			AND ( @Sporttypes = '0' 
					OR EXISTS (	SELECT	1 
								FROM	BettransM BM WITH (NOLOCK, index=IX_RefNo) 
								INNER JOIN Match M WITH (NOLOCK) 
									ON	 M.matchID = BM.MatchId 
									AND (M.sporttype IN (Select sporttype FROM #SportsList))							
								WHERE	BM.RefNo = B.RefNo
								)
				)

END
END

------------------------------------------------DATA [14] ----------------------------------------------

IF @FromDate <= @MoveBetDay 
BEGIN  
	IF @AgentId = 1
	BEGIN 
	--********************************
	----Super view
	--********************************
		
		IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10) OR @Bettypes = '0')
		----Sportsbook
		INSERT INTO #WinLossAgent
		SELECT  C.Username, C.AgentID, 1 as IsAgent,
				PT.MaxUpperPositionTaking as PositionTaking,	
				COUNT(B.TransID) BetCount,			
		   		SUM(ABS(B.Stake)) AS TurnOver,
				SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS ActualTO,
				- SUM(B.Winlost - B.Actual_Stake + B.TWinlost) AS AWinlost,	
				- SUM (B.TComm) AS AComm,
				- (SUM(B.Winlost - B.Actual_Stake + B.TWinlost) + SUM (B.TComm)) AS ATotal,
				0 AS GrossTotal,
				0 AS UplineTotal	
		FROM		AgentInfo C WITH (NOLOCK)
		INNER JOIN	Bettrans14_Agent BA WITH (NOLOCK)
				ON	BA.AgentID = C.AgentID
					AND BA.Winlostdate BETWEEN @FromDate AND @ToDate
					AND BA.StatusID NOT IN (0,1)
					AND BA.Bettype <=19000
					AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))							
		INNER JOIN	Bettrans14 B WITH (NOLOCK) 
				ON	B.TransID = BA.TransID		
		INNER JOIN  AgentPositionTaking PT WITH (NOLOCK) 
				ON  PT.AgentID = C.AgentId AND PT.Bettype = 1 AND PT.SportType = 1 AND IsLive = 0
		INNER JOIN  Match14 m  WITH (NOLOCK) 
				ON m.MatchID = B.MatchID
		WHERE		C.ParentId = @AgentID 
					AND B.Winlostdate BETWEEN @FromDate AND @ToDate
					AND B.StatusID NOT IN (0,1)
					AND B.Bettype <=19000
					AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))					

					AND (@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList))
		GROUP BY	C.Username, C.AgentID, PT.MaxUpperPositionTaking


		----Parlay
		IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29) OR @Bettypes = '0')
		INSERT INTO #WinLossAgent
		SELECT  B.Username, B.AgentID, 1 as IsAgent,
				B.MaxUpperPositionTaking as PositionTaking,	
				SUM(B.BetCount) BetCount,			
		   		SUM(ABS(B.Stake)) AS TurnOver,
				SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS ActualTO,
				- SUM(B.Winlost - B.Actual_Stake + B.TWinlost) AS AWinlost,	
				- SUM (B.TComm) AS AComm,
				- (SUM(B.Winlost - B.Actual_Stake + B.TWinlost) + SUM (B.TComm)) AS ATotal,
				0 AS GrossTotal,
				0 AS UplineTotal
		FROM (
				SELECT		DISTINCT
							C.Username, C.AgentID, PT.MaxUpperPositionTaking,	
							COUNT(B.TransID) BetCount,
							B.Stake, B.TransID,
							B.MOdds,B.StatusID,	 
							B.Winlost,B.Actual_Stake ,B.TWinlost, B.TComm	
				FROM		AgentInfo C WITH (NOLOCK)
				INNER JOIN	Bettrans14_Agent BA WITH (NOLOCK)
						ON	BA.AgentID = C.AgentID	
							AND BA.Winlostdate BETWEEN @FromDate AND @ToDate
							AND BA.StatusID NOT IN (0,1)
							AND BA.Bettype IN (9,29)
							AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))								
				INNER JOIN	Bettrans14 B WITH (NOLOCK) 
						ON	B.TransID = BA.TransID		
				INNER JOIN  AgentPositionTaking PT WITH (NOLOCK) 
						ON  PT.AgentID = C.AgentId AND PT.Bettype = 1 AND PT.SportType = 1 AND IsLive = 0
				INNER JOIN  BettransM14 BM WITH (NOLOCK) 
						ON  BM.RefNo = B.RefNo
				INNER JOIN  Match14 M  WITH (NOLOCK) 
						ON	M.MatchID = BM.MatchID
				WHERE		C.ParentId = @AgentID 
							AND B.Winlostdate BETWEEN @FromDate AND @ToDate
							AND B.StatusID NOT IN (0,1)
							AND B.Bettype IN (9,29)
							AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))						

							AND (@Sporttypes = '0' 
							OR EXISTS (	SELECT	1 
										FROM	BettransM14 BM WITH (NOLOCK, index=IX_RefNo) 
										INNER JOIN Match14 M WITH (NOLOCK) 
											ON	 M.matchID = BM.MatchId 
											AND (M.sporttype IN (Select sporttype FROM #SportsList))							
										WHERE	BM.RefNo = B.RefNo
										)				
						)	
				GROUP BY	C.Username, C.AgentID, PT.MaxUpperPositionTaking, 
							B.MOdds,B.StatusID,	B.Stake, B.TransID,
							B.Winlost,B.Actual_Stake ,B.TWinlost, B.TComm,B.Stake
			 ) B
		GROUP BY	B.Username, B.AgentID, B.MaxUpperPositionTaking  

	
	----Outright14
		IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (10) OR @Bettypes = '0')
		INSERT INTO #WinLossAgent
		SELECT  C.Username, C.AgentID, 1 as IsAgent,
				PT.MaxUpperPositionTaking as PositionTaking,	
				COUNT(B.TransID) BetCount,			
		   		SUM(ABS(B.Stake)) AS TurnOver,
				SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS ActualTO,
				- SUM(B.Winlost - B.Actual_Stake + B.TWinlost) AS AWinlost,	
				- SUM (B.TComm) AS AComm,
				- (SUM(B.Winlost - B.Actual_Stake + B.TWinlost) + SUM (B.TComm)) AS ATotal,
				0 AS GrossTotal,
				0 AS UplineTotal	
		FROM		AgentInfo C WITH (NOLOCK)
		INNER JOIN	Bettrans14_Agent BA WITH (NOLOCK)
				ON	BA.AgentID = C.AgentID			
					AND BA.Winlostdate BETWEEN @FromDate AND @ToDate
					AND BA.StatusID NOT IN (0,1)
					AND BA.Bettype = 10
					AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))						
		INNER JOIN	Bettrans14 B WITH (NOLOCK) 
				ON	B.TransID = BA.TransID		
		INNER JOIN  AgentPositionTaking PT WITH (NOLOCK) 
				ON  PT.AgentID = C.AgentId AND PT.Bettype = 1 AND PT.SportType = 1 AND IsLive = 0
		INNER JOIN  Outright14 m  WITH (NOLOCK) 
				ON  m.orid = B.MatchID
		INNER JOIN  League l WITH (NOLOCK)
				ON	l.leagueID = m.leagueId
		WHERE		C.ParentId = @AgentID 
					AND B.Winlostdate BETWEEN @FromDate AND @ToDate
					AND B.StatusID NOT IN (0,1)
					AND B.Bettype = 10
					AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))

					AND (@Sporttypes = '0' OR l.sporttype IN (Select sporttype FROM #SportsList))
		GROUP BY	C.Username, C.AgentID, PT.MaxUpperPositionTaking


	END
	ELSE 
	BEGIN
	--********************************
	---- Agent Winloss
	--********************************
		---Sportsbook
		CREATE TABLE #Tmp14 (Username VARCHAR(50),  AgentID INT , PositionTaking smallint,
				BetCount INT, TurnOver MONEY, ActualTO MONEY, AWinlost MONEY,AComm MONEY,
				ATotal MONEY, ChildAComm MONEY, Winlost MONEY, Actual_Stake MONEY) 

		---Sportsbook
		IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10) OR @Bettypes = '0')
		INSERT INTO	#Tmp14
		SELECT  C.Username, C.AgentID, PT.MaxUpperPositionTaking as PositionTaking,
				COUNT(B.TransID) BetCount,			 
		   		SUM(ABS(B.Stake)) AS TurnOver,
				SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS ActualTO,
				SUM(BP.AWinlost) AS AWinlost,	
				SUM(BP.AComm) - SUM(BA.AComm) AS AComm,
				SUM(BP.AWinlost) + SUM (BP.AComm) - SUM (BA.AComm)  AS ATotal,
			    SUM(BA.AComm) ChildAComm  , 
				SUM(B.Winlost) as Winlost,
				SUM(B.Actual_Stake) as Actual_Stake	   
		FROM		Bettrans14 B WITH (NOLOCK) 
		INNER JOIN	Bettrans14_Agent BP WITH (NOLOCK) 
				ON	BP.TransID = B.TransID 
					AND BP.AgentID = @AgentID ---Parent (k)
					AND BP.Winlostdate BETWEEN @FromDate AND @ToDate 
					AND BP.StatusID NOT IN (0,1)	
					AND BP.Bettype <=19000
					AND (@Bettypes = '0' OR BP.Bettype IN (Select bettype FROM #BettypeList))
		INNER JOIN AgentInfo C WITH (NOLOCK) --- Child direct (k+1)
				ON C.ParentID = @AgentID  
		INNER JOIN AgentPositionTaking PT WITH (NOLOCK) 
				ON PT.AgentID = C.AgentId AND PT.Bettype = 1 AND PT.SportType = 1 AND IsLive = 0
		INNER JOIN Bettrans14_Agent BA WITH (NOLOCK) 
				ON  BA.TransID = B.TransID 
				AND C.AgentID = BA.AgentID ---- Child direct (k+1)
				AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND BA.StatusID NOT IN (0,1)	
				AND BA.Bettype <=19000
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))
		INNER JOIN  Match14 m  WITH (NOLOCK) 
				ON m.MatchID = B.MatchID
		WHERE	B.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND B.StatusID NOT IN (0,1)	
				AND B.Bettype <=19000
				AND (@Bettypes =  '0' OR B.Bettype IN (Select bettype FROM #BettypeList))	
				AND (@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList))
		GROUP BY C.Username, C.AgentID ,  PT.MaxUpperPositionTaking

 	 
		INSERT INTO #WinLossAgent
		SELECT	T.Username, T.AgentID, 1 as IsAgent, T.PositionTaking as PositionTaking,
				T.BetCount, T.TurnOver, T.ActualTO, T.AWinlost, T.AComm, T.ATotal, 
				SUM(BA.AWINLOST) + (T.Winlost - T.Actual_Stake) + T.ChildAComm  AS GrossTotal,  
				-(SUM(BA.AWINLOST) + (T.Winlost - T.Actual_Stake) + T.ChildAComm  + T.ATotal) AS UplineTotal
		FROM	#Tmp14 T
		INNER JOIN AgentInfo P with (nolock) ON  T.AgentID = P.AgentID
		INNER JOIN AgentInfo C WITH(NOLOCK) ON C.AgentHId.IsDescendantOf(P.AgentHId ) =1  AND C.AgentLevel >= P.AgentLevel  --- Children of k+1 (k+1 -> k+...)
		INNER JOIN Bettrans14_Agent BA WITH (NOLOCK) ON BA.AgentID = C.AgentID
		INNER JOIN Match14 M WITH (NOLOCK) ON M.matchID = BA.MatchId
		WHERE   BA.Winlostdate BETWEEN @FromDate AND @ToDate
				AND BA.StatusID NOT IN (0,1) 				 
				AND BA.Bettype <= 19000
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

				AND (@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList))			
		GROUP BY T.AgentID, T.Username,T.PositionTaking, T.TurnOver, T.ActualTO, T.AWinlost, T.AComm, T.ATotal, T.ChildAComm, T.Winlost , T.Actual_Stake, T.BetCount
	 
		TRUNCATE TABLE #Tmp14
		 
		------Parlay	
		IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29) OR @Bettypes = '0')
		INSERT INTO	#Tmp14
		SELECT  B.Username, B.AgentID, B.MaxUpperPositionTaking as PositionTaking,
				SUM(B.BetCount) BetCount,			 
		   		SUM(ABS(B.Stake)) AS TurnOver,
				SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS ActualTO,
				SUM(B.AWinlost) AS AWinlost,	
				SUM(B.AComm) - SUM(B.ChildAComm) AS AComm,
				SUM(B.AWinlost) + SUM (B.AComm) - SUM (B.ChildAComm)  AS ATotal,
			    SUM(B.ChildAComm) ChildAComm  , 
				SUM(B.Winlost) as Winlost,
				SUM(B.Actual_Stake) as Actual_Stake
		FROM	(	
				SELECT  DISTINCT 
						C.Username, C.AgentID, PT.MaxUpperPositionTaking,
						COUNT(B.TransId) BetCount,			 
		   				B.Stake, B.TransID,
						B.Winlost,B.Actual_Stake,
						B.MOdds,B.StatusID,
						BP.AWinlost, BP.AComm, BA.AComm as ChildAComm							
				FROM	Bettrans14 B WITH (NOLOCK, index = IX_Winlostdate_Bettype_StatusId) 
				INNER JOIN Bettrans14_Agent BP WITH (NOLOCK) 
						ON BP.TransID = B.TransID 
						AND BP.AgentID = @AgentID ---Parent (k)
						AND BP.Winlostdate BETWEEN @FromDate AND @ToDate 
						AND BP.StatusID NOT IN (0,1)	
						AND BP.Bettype IN (9,29)
						AND (@Bettypes = '0' OR BP.Bettype IN (Select bettype FROM #BettypeList))

				INNER JOIN AgentInfo C WITH (NOLOCK) --- Child direct (k+1)
						ON C.ParentID = @AgentID  
				INNER JOIN AgentPositionTaking PT WITH (NOLOCK) 
						ON PT.AgentID = C.AgentId AND PT.Bettype = 1 AND PT.SportType = 1 AND IsLive = 0
				INNER JOIN Bettrans14_Agent BA WITH (NOLOCK) 
						ON BA.TransID = B.TransID 
						AND BA.AgentID = C.AgentID ---- Child direct (k+1)
						AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
						AND BA.StatusID NOT IN (0,1)	
						AND BA.Bettype IN (9,29)
						AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))				
				WHERE	B.Winlostdate BETWEEN @FromDate AND @ToDate 
						AND B.StatusID NOT IN (0,1)	
						AND B.Bettype IN (9,29)
						AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))	
								
						AND (@Sporttypes = '0' 
							OR EXISTS (	SELECT	1 
										FROM	BettransM14 BM WITH (NOLOCK, index=IX_RefNo) 
										INNER JOIN Match14 M WITH (NOLOCK) 
											ON	 M.matchID = BM.MatchId 
											AND (M.sporttype IN (Select sporttype FROM #SportsList))							
										WHERE	BM.RefNo = B.RefNo
										)				
						)	
				GROUP BY C.Username, C.AgentID, PT.MaxUpperPositionTaking,						
		   				B.Winlost,B.Actual_Stake,
						B.MOdds,B.StatusID,B.Stake,B.TransID,
						BP.AWinlost, BP.AComm, BP.AWinlost, BA.AComm
			) B
		GROUP BY B.Username, B.AgentID , B.MaxUpperPositionTaking

		--------------------------------
	
		INSERT INTO #WinLossAgent
		SELECT	T.Username, T.AgentID, 1 as IsAgent, T.PositionTaking as PositionTaking,
				T.BetCount, T.TurnOver, T.ActualTO, T.AWinlost, T.AComm, T.ATotal, 
				SUM(T.LineWinLost) + (T.Winlost - T.Actual_Stake) + T.ChildAComm  AS GrossTotal,  
				-(SUM(T.LineWinLost) + (T.Winlost - T.Actual_Stake) + T.ChildAComm  + T.ATotal) AS UplineTotal
		FROM (	
			SELECT  T.Username, T.AgentID, 1 as IsAgent, T.PositionTaking as PositionTaking,
					T.BetCount, T.TurnOver, T.ActualTO, T.AWinlost, T.AComm, T.ATotal, 
					BA.AWINLOST as LineWinLost, T.Winlost,T.Actual_Stake, T.ChildAComm			 		
			FROM #Tmp14 T
			INNER JOIN AgentInfo P with (nolock) ON  T.AgentID = P.AgentID
			INNER JOIN AgentInfo C WITH(NOLOCK) ON C.AgentHId.IsDescendantOf(P.AgentHId ) =1  AND C.AgentLevel >= P.AgentLevel  --- Children of k+1 (k+1 -> k+...)
			INNER JOIN Bettrans14_Agent BA WITH (NOLOCK) ON BA.AgentID = C.AgentID
			WHERE	BA.Winlostdate BETWEEN @FromDate AND @ToDate
					AND BA.StatusID NOT IN (0,1) 				 
					AND BA.Bettype IN (9,29)
					AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList)) 	

					AND (@Sporttypes = '0' 
						OR EXISTS (	SELECT	1 
									FROM	BettransM14 BM WITH (NOLOCK, index=IX_RefNo) 
									INNER JOIN Match14 M WITH (NOLOCK) 
										ON	 M.matchID = BM.MatchId 
										AND (m.sporttype IN (Select sporttype FROM #SportsList))							
									WHERE	BM.RefNo = BA.RefNo
									)				
						)					
			) T
		GROUP BY T.AgentID, T.Username,T.PositionTaking, T.TurnOver, T.ActualTO, T.AWinlost, T.AComm, T.ATotal, T.ChildAComm, T.Winlost , T.Actual_Stake, T.BetCount
	 
		TRUNCATE TABLE #Tmp14 


		-----Outright14
		IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (10) OR @Bettypes = '0')
		INSERT INTO	#Tmp14
		SELECT  C.Username, C.AgentID, PT.MaxUpperPositionTaking as PositionTaking,
				COUNT(B.TransID) BetCount,			 
		   		SUM(ABS(B.Stake)) AS TurnOver,
				SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS ActualTO,
				SUM(BP.AWinlost) AS AWinlost,	
				SUM(BP.AComm) - SUM(BA.AComm) AS AComm,
				SUM(BP.AWinlost) + SUM (BP.AComm) - SUM (BA.AComm)  AS ATotal,
			    SUM(BA.AComm) ChildAComm  , 
				SUM(B.Winlost) as Winlost,
				SUM(B.Actual_Stake) as Actual_Stake	   
		FROM	Bettrans14 B WITH (NOLOCK , index = IX_Winlostdate_Bettype_StatusId) 
		INNER JOIN Bettrans14_Agent BP WITH (NOLOCK, index =IX_WinLostDate_Bettype_StatusId) 
				ON BP.TransID = B.TransID 
				AND BP.AgentID = @AgentID ---Parent (k)
				AND BP.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND BP.StatusID NOT IN (0,1)	
				AND BP.Bettype = 10
				AND (@Bettypes = '0' OR BP.Bettype IN (Select bettype FROM #BettypeList))
		INNER JOIN AgentInfo C WITH (NOLOCK) --- Child direct (k+1)
				ON C.ParentID = @AgentID  
		INNER JOIN AgentPositionTaking PT WITH (NOLOCK) 
				ON PT.AgentID = C.AgentId AND PT.Bettype = 1 AND PT.SportType = 1 AND IsLive = 0
		INNER JOIN Bettrans14_Agent BA WITH (NOLOCK,  index =IX_WinLostDate_Bettype_StatusId) 
				ON BA.TransID = B.TransID 
				AND C.AgentID = BA.AgentID ---- Child direct (k+1)
				AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND BA.StatusID NOT IN (0,1)	
				AND BA.Bettype = 10
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

		INNER JOIN  Outright14 m  WITH (NOLOCK) 
				ON  m.orid = B.MatchID
		INNER JOIN  League l WITH (NOLOCK)
				ON	l.leagueID = m.leagueId
		WHERE	B.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND B.StatusID NOT IN (0,1)	
				AND B.Bettype =10
				AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))
							
				AND (@Sporttypes = '0' OR l.sporttype IN (Select sporttype FROM #SportsList))
		GROUP BY C.Username, C.AgentID ,  PT.MaxUpperPositionTaking
				 
		 
		INSERT INTO #WinLossAgent
		SELECT	T.Username, T.AgentID, 1 as IsAgent, T.PositionTaking as PositionTaking,
				T.BetCount, T.TurnOver, T.ActualTO, T.AWinlost, T.AComm, T.ATotal, 
				SUM(BA.AWINLOST) + (T.Winlost - T.Actual_Stake) + T.ChildAComm  AS GrossTotal,  
				-(SUM(BA.AWINLOST) + (T.Winlost - T.Actual_Stake) + T.ChildAComm  + T.ATotal) AS UplineTotal
		FROM #Tmp14 T
		INNER JOIN AgentInfo P with (nolock) ON  T.AgentID = P.AgentID
		INNER JOIN AgentInfo C WITH(NOLOCK) ON C.AgentHId.IsDescendantOf(P.AgentHId ) =1  AND C.AgentLevel >= P.AgentLevel  --- Children of k+1 (k+1 -> k+...)
		INNER JOIN Bettrans14_Agent BA WITH (NOLOCK) ON BA.AgentID = C.AgentID
		INNER JOIN Outright14 M WITH (NOLOCK) ON M.OrId = BA.MatchId
		INNER JOIN League L WITH (NOLOCK) ON L.LeagueId = M.leagueId
		WHERE	BA.Winlostdate BETWEEN @FromDate AND @ToDate
				AND BA.StatusID NOT IN (0,1) 				 
				AND BA.Bettype = 10
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))
		
				AND (@Sporttypes = '0' OR l.sporttype IN (Select sporttype FROM #SportsList))
		GROUP BY T.AgentID, T.Username,T.PositionTaking, T.TurnOver, T.ActualTO, T.AWinlost, T.AComm, T.ATotal, T.ChildAComm, T.Winlost , T.Actual_Stake, T.BetCount
	 
		DROP TABLE #Tmp14 

	


--********************************
-----Member winloss
--********************************	
	---Sportsbook
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10) OR @Bettypes = '0')
	INSERT INTO #WinLossMember  
	SELECT	'' as Username, 0 as AgentId, 0 as IsAgent,
			0 as PositionTaking,	
			COUNT(B.TransID) BetCount,			
		   	SUM(ABS(B.Stake)) as TurnOver,
			SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  as ActualTO,
			SUM(BA.AWinLost) as AWinlost,	
			SUM(BA.AComm) - SUM (B.PlayerComm) as AComm,
			SUM(BA.AWinLost) + SUM(BA.AComm) - SUM (B.PlayerComm) AS ATotal,
			SUM (B.Winlost - B.Actual_Stake + B.PlayerComm) GrossTotal,
			-(SUM (B.Winlost - B.Actual_Stake + B.PlayerComm) + SUM(BA.AWinLost) + SUM(BA.AComm) - SUM (B.PlayerComm)) UplineTotal
	FROM	Bettrans14 B WITH (NOLOCK)
	INNER JOIN Bettrans14_Agent BA WITH (NOLOCK ) 
		ON	BA.TransID = B.TransID 
		AND BA.AgentId = @AgentID 
		AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
		AND BA.StatusID NOT IN (0,1)
		AND BA.Bettype <= 19000
		AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))
	INNER JOIN CustInfo C WITH (NOLOCK)
		ON	B.CustID = C.CustID AND C.AgentId = @AgentID
	INNER JOIN  Match14 m  WITH (NOLOCK) 
		ON m.MatchID = B.MatchID
	WHERE	B.Winlostdate BETWEEN @FromDate AND @ToDate 
			AND B.StatusID NOT IN (0,1)
			AND B.Bettype <= 19000
			AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))

			AND (@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList))
 

	-----Parlay	
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29) OR @Bettypes = '0')
	INSERT INTO #WinLossMember  
	SELECT	'' as Username, 0 as AgentId, 0 as IsAgent,
			0 as PositionTaking,	
			SUM(B.BetCount) BetCount,			
		   	SUM(ABS(B.Stake)) as TurnOver,
			SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  as ActualTO,
			SUM(B.AWinLost) as AWinlost,	
			SUM(B.AComm) - SUM (B.PlayerComm) as AComm,
			SUM(B.AWinLost) + SUM(B.AComm) - SUM (B.PlayerComm) AS ATotal,
			SUM (B.Winlost - B.Actual_Stake + B.PlayerComm) GrossTotal,
			-(SUM (B.Winlost - B.Actual_Stake ) + SUM(B.AWinLost) + SUM(B.AComm)) UplineTotal
	FROM (
			SELECT DISTINCT 
					COUNT(B.TransID) BetCount,	   			
					B.MOdds,B.StatusID,	BA.AWinLost, BA.AComm,
					B.Stake , B.TransID,
					B.Winlost, B.Actual_Stake,B.PlayerComm
					
			FROM	Bettrans14 B WITH (NOLOCK)
			INNER JOIN Bettrans14_Agent BA WITH (NOLOCK ) 
				ON	BA.TransID = B.TransID 
					AND BA.AgentId = @AgentID 
					AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
					AND BA.StatusID NOT IN (0,1)
					AND BA.Bettype IN (9,29)
					AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

			INNER JOIN CustInfo C WITH (NOLOCK)
				ON	B.CustID = C.CustID AND C.AgentId = @AgentID			
			WHERE	B.Winlostdate BETWEEN @FromDate AND @ToDate 
					AND B.StatusID NOT IN (0,1)
					AND B.Bettype IN (9,29)
					AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))

					AND (@Sporttypes = '0' 
							OR EXISTS (	SELECT	1 
										FROM	BettransM14 BM WITH (NOLOCK, index=IX_RefNo) 
										INNER JOIN Match14 M WITH (NOLOCK) 
											ON	 M.matchID = BM.MatchId 
											AND (M.sporttype IN (Select sporttype FROM #SportsList))							
										WHERE	BM.RefNo = B.RefNo
										)
						)
			GROUP BY B.MOdds,B.StatusID,	BA.AWinLost, BA.AComm,
					 B.Winlost, B.Actual_Stake,B.PlayerComm, B.Stake , B.TransID
			) B

	-----Outright14
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (10) OR @Bettypes = '0')
	INSERT INTO #WinLossMember  
	SELECT	'' as Username, 0 as AgentId, 0 as IsAgent,
			0 as PositionTaking,	
			COUNT(B.TransID) BetCount,			
		   	SUM(ABS(B.Stake)) as TurnOver,
			SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  as ActualTO,
			SUM(BA.AWinLost) as AWinlost,	
			SUM(BA.AComm) - SUM (B.PlayerComm) as AComm,
			SUM(BA.AWinLost) + SUM(BA.AComm) - SUM (B.PlayerComm) AS ATotal,
			SUM (B.Winlost - B.Actual_Stake + B.PlayerComm) GrossTotal,
			-(SUM (B.Winlost - B.Actual_Stake + B.PlayerComm) + SUM(BA.AWinLost) + SUM(BA.AComm) - SUM (B.PlayerComm)) UplineTotal
	FROM	Bettrans14 B WITH (NOLOCK)
	INNER JOIN Bettrans14_Agent BA WITH (NOLOCK ) 
		ON	BA.TransID = B.TransID
			AND BA.AgentId = @AgentID 
			AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
			AND BA.StatusID NOT IN (0,1)
			AND BA.Bettype = 10
			AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList)) 
	INNER JOIN CustInfo C WITH (NOLOCK)
		ON	B.CustID = C.CustID AND C.AgentId = @AgentID
	INNER JOIN  Outright14 m WITH (NOLOCK) 
		ON  m.orid = B.MatchID
	INNER JOIN  League l WITH (NOLOCK)
		ON	l.leagueID = m.leagueId
	WHERE   B.Winlostdate BETWEEN @FromDate AND @ToDate 
			AND B.StatusID NOT IN (0,1)
			AND B.Bettype = 10
			AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))

			AND ( @Sporttypes = '0' 
					OR EXISTS (	SELECT	1 
								FROM	BettransM14 BM WITH (NOLOCK, index=IX_RefNo) 
								INNER JOIN Match14 M WITH (NOLOCK) 
									ON	 M.matchID = BM.MatchId 
									AND (M.sporttype IN (Select sporttype FROM #SportsList))							
								WHERE	BM.RefNo = B.RefNo
								)
				)

END
END
-------------------------------------------------

DELETE	#WinLossAgent 
WHERE	TurnOver IS NULL 
		AND ActualTO IS NULL
		AND AWinLost IS NULL
		AND AComm IS NULL
		AND ATotal IS NULL
		AND GrossTotal IS NULL
		AND UplineTotal IS NULL


DELETE	#WinLossMember 
WHERE	TurnOver IS NULL 
		AND ActualTO IS NULL
		AND AWinLost IS NULL
		AND AComm IS NULL
		AND ATotal IS NULL
		AND GrossTotal IS NULL
		AND UplineTotal IS NULL

--################################################# OUTSTANDING SECTION ####################################################--

CREATE TABLE #AgentOutstanding (Username NVARCHAR(50), AgentID INT, IsAgent BIT, Outstanding MONEY, OutstandingShare MONEY)
CREATE TABLE #MemberOutstanding (Username NVARCHAR(50), AgentID INT, IsAgent BIT, Outstanding MONEY, OutstandingShare MONEY)
	 
IF @AgentId = 1
BEGIN 
	----Super view
	--Sportsbook
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10) OR @Bettypes = '0')
	INSERT INTO #AgentOutstanding
	SELECT  C.Username, C.AgentID, 1 as IsAgent,
			ISNULL(SUM (ABS(B.actual_stake)),0) as Outstanding,
			ISNULL(SUM(ABS(B.actual_stake) * (1-B.TPositiontaking)),0) as Positiontaking
	FROM AgentInfo C WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK) -- MAIN SH 
			ON BA.AgentID = C.AgentID		
	INNER JOIN Bettrans B WITH (NOLOCK, index =IX_StatusId_Bettype) 
			ON B.TransID = BA.TransID
	INNER JOIN Match M WITH (NOLOCK) 
			ON M.MatchId = B.MatchId			
	WHERE	C.ParentId = 1 
			AND B.StatusID IN (0,1) 			
			AND (	B.bettype < 31 
					OR B.bettype between 121 and 999
					OR B.bettype between 1301 and 1334 					 				
					) 
			AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))
		
			AND BA.StatusID IN (0,1) 
			AND (	BA.bettype < 31 
					OR BA.bettype between 121 and 999
					OR BA.bettype between 1301 and 1334 					 				
					)
			AND (@Bettypes = '0' OR BA.Bettype in (Select bettype FROM #BettypeList))

			AND (@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList))						
	GROUP BY  C.Username, C.AgentID

	--Parlay
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29) OR @Bettypes = '0')
	INSERT INTO #AgentOutstanding
	SELECT		B.Username, B.AgentID, 1 as IsAgent,
				ISNULL(SUM (ABS(B.actual_stake)),0) as Outstanding,
				ISNULL(SUM(ABS(B.actual_stake) * (1-B.TPositiontaking)),0) as Positiontaking
	FROM (
			SELECT  DISTINCT C.Username, C.AgentID, 1 as IsAgent,
					B.bettype , B.actual_stake, B.TPositiontaking
			FROM AgentInfo C WITH (NOLOCK)
			INNER JOIN BetTrans_Agent BA WITH (NOLOCK) ---Main SH
					ON BA.AgentID = C.AgentID		
			INNER JOIN Bettrans B WITH (NOLOCK) 
					ON B.TransID = BA.TransID		 			
			WHERE	C.ParentId = 1 
					AND BA.StatusID IN (0,1)
					AND BA.Bettype IN (9,29) 					
					AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

					AND B.StatusID IN (0,1)
					AND B.Bettype IN (9,29) 
					AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))

					AND (@Sporttypes = '0' 
							OR EXISTS (	SELECT	1 
										FROM	BettransM BM WITH (NOLOCK, index=IX_RefNo) 
										INNER JOIN Match M WITH (NOLOCK) 
											ON	 M.matchID = BM.MatchId 
											AND (M.sporttype IN (Select sporttype FROM #SportsList))							
										WHERE	BM.RefNo = B.RefNo
										 )	
						)	
			)B	
				 
	GROUP BY  B.Username, B.AgentID


	--Outright
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype=10 OR @Bettypes = '0')
	INSERT INTO #AgentOutstanding
	SELECT  DISTINCT C.Username, C.AgentID, 1 as IsAgent,
			ISNULL(SUM (ABS(B.actual_stake)),0) as Outstanding,
			ISNULL(SUM(ABS(B.actual_stake) * (1-B.TPositiontaking)),0) as Positiontaking
	FROM AgentInfo C WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK)  --- Main SH 
			ON BA.AgentID = C.AgentID		
	INNER JOIN Bettrans B WITH (NOLOCK, index =IX_StatusId_Bettype ) 
			ON B.TransID = BA.TransID						
	WHERE	C.ParentId = @AgentID 
			AND BA.StatusID IN (0,1)
			AND BA.Bettype = 10
			AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

			AND B.StatusID IN (0,1)
			AND B.Bettype = 10
			AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))

			--AND (@Sporttypes = '0' OR l.sporttype IN (Select sporttype FROM #SportsList))					
			AND (@Sporttypes = '0' 
				 OR EXISTS (SELECT	1 
							FROM	Outright M WITH (NOLOCK) 
							INNER JOIN League L WITH (NOLOCK) 
									ON L.leagueid = M.leagueid		
									AND (L.sporttype IN (Select sporttype FROM #SportsList))				
							WHERE	M.orid = B.MatchId
							)	
					)
	GROUP BY  C.Username, C.AgentID

END
ELSE 
BEGIN
	----- Agent Outstanding
	---Sportsbook
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10) OR @Bettypes = '0')
	INSERT INTO #AgentOutstanding
	SELECT  C.Username, C.AgentID, 1 as IsAgent,
			ISNULL(SUM (ABS(BA.actual_stake)),0) as Outstanding,
			ISNULL(SUM(ABS(BA.actual_stake) * BP.APositiontaking),0) as Positiontaking
	FROM	AgentInfo C  WITH (NOLOCK)
	INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK) -- child
			ON BA.AgentID = C.AgentID
	INNER JOIN BetTrans_Agent AS BP WITH (NOLOCK) --- parent
			ON BP.TransID = BA.TransID AND BP.AgentID = @AgentID
	INNER JOIN Match M WITH (NOLOCK) 
			ON M.MatchId = BA.MatchId
	WHERE	C.ParentId = @AgentID 
			AND BA.StatusID IN (0,1)	
			AND BA.Bettype<=19000
			AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))
	
			AND BP.StatusID IN (0,1)
			AND BP.Bettype<=19000	
			AND (@Bettypes = '0' OR BP.Bettype IN (Select bettype FROM #BettypeList))
			AND (@Sporttypes = '0' OR M.sporttype IN (Select sporttype FROM #SportsList))		
	GROUP BY C.Username, C.AgentID


	----- Parlay
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29) OR @Bettypes = '0')
	INSERT INTO #AgentOutstanding 
	SELECT	B.Username, B.AgentID, 1 as IsAgent,
			ISNULL(SUM (ABS(B.actual_stake)),0) as Outstanding,
			ISNULL(SUM(ABS(B.actual_stake) * B.APositiontaking),0) as Positiontaking
	FROM 
	( 
		SELECT  DISTINCT C.Username, C.AgentID,  BP.bettype, BP.actual_stake, BP.APositiontaking  
		FROM	AgentInfo C  WITH (NOLOCK)
		INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK, index =IX_StatusID_AgentID_Bettype)
				ON BA.AgentID = C.AgentID
		INNER JOIN BetTrans_Agent AS BP WITH (NOLOCK)
				ON BP.TransID = BA.TransID AND BP.AgentID = @AgentID
		WHERE	C.ParentId = @AgentID 
				AND BA.StatusID IN (0,1)
				AND BA.Bettype IN (9,29)
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

				AND BP.StatusID IN (0,1)
				AND BP.Bettype IN (9,29)	
				AND (@Bettypes = '0' OR BP.Bettype IN (Select bettype FROM #BettypeList))

				AND (@Sporttypes = '0' 
							OR EXISTS (	SELECT	1 
										FROM	BettransM BM WITH (NOLOCK, index=IX_RefNo) 
										INNER JOIN Match M WITH (NOLOCK) 
											ON	 M.matchID = BM.MatchId 
											AND (M.sporttype IN (Select sporttype FROM #SportsList))							
										WHERE	BM.RefNo = BA.RefNo
										 )	
						)	
		) B	
		GROUP BY B.Username, B.AgentID 

	----- Outright
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype = 10 OR @Bettypes = '0')
	INSERT INTO #AgentOutstanding
	SELECT  C.Username, C.AgentID, 1 as IsAgent,
			ISNULL(SUM (ABS(BP.actual_stake)),0) as Outstanding,
			ISNULL(SUM(ABS(BP.actual_stake) * BP.APositiontaking),0) as Positiontaking
	FROM	AgentInfo C  WITH (NOLOCK)
	INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK)
			ON BA.AgentID = C.AgentID
	INNER JOIN BetTrans_Agent AS BP WITH (NOLOCK)
			ON BP.TransID = BA.TransID AND BP.AgentID = @AgentID	
	WHERE	C.ParentId = @AgentID 
			AND BA.StatusID IN (0,1)	
			AND BA.Bettype = 10
			AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

			AND BP.StatusID IN (0,1)
			AND BP.Bettype = 10
			AND (@Bettypes = '0' OR BP.Bettype IN (Select bettype FROM #BettypeList))

			AND (@Sporttypes = '0' 
				 OR EXISTS (SELECT	1 
							FROM	Outright M WITH (NOLOCK) 
							INNER JOIN League L WITH (NOLOCK) 
									ON L.leagueid = M.leagueid		
									AND (L.sporttype IN (Select sporttype FROM #SportsList))				
							WHERE	M.orid = BA.MatchId
							)	
					)	 
	GROUP BY C.Username, C.AgentID




 

-----Member Outstanding
	-- SportsBook 
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10) OR @Bettypes = '0')
	INSERT INTO #MemberOutstanding 
	SELECT  '', C.AgentId, 0 as IsAgent,
			ISNULL(SUM (ABS(BA.actual_stake)),0) as Outstanding,
			ISNULL(SUM(ABS(BA.actual_stake) * BA.APositiontaking),0) as Positiontaking
	FROM Bettrans B WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK) 
		ON BA.TransID = B.TransID AND BA.AgentId = @AgentID 
	INNER JOIN CustInfo C WITH (NOLOCK)
		ON B.CustID = C.CustID AND C.AgentId =@AgentID
	INNER JOIN Match M WITH (NOLOCK) 
		ON M.MatchId = BA.MatchId 
	WHERE	 BA.StatusId IN (0,1)
			AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))
			
			AND B.StatusId IN (0,1)
			AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))
			AND (@Sporttypes = '0' OR M.sporttype IN (Select sporttype FROM #SportsList))	
	GROUP BY C.AgentId

	-- Parlay 
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29) OR @Bettypes = '0')
	INSERT INTO #MemberOutstanding 
	SELECT  '', B.AgentId, 0 as IsAgent,
			ISNULL(SUM (ABS(B.actual_stake)),0) as Outstanding,
			ISNULL(SUM(ABS(B.actual_stake) * B.APositiontaking),0) as Positiontaking
	FROM (
			SELECT  DISTINCT C.AgentId, BA.bettype, BA.actual_stake, BA.APositiontaking
			FROM Bettrans B WITH (NOLOCK)
			INNER JOIN BetTrans_Agent BA WITH (NOLOCK) 
				ON BA.TransID = B.TransID AND BA.AgentId = @AgentID 				
			INNER JOIN CustInfo C WITH (NOLOCK)
				ON B.CustID = C.CustID AND C.AgentId =@AgentID
			WHERE	BA.StatusId IN (0,1)
					AND BA.Bettype In (9,29)
					AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

					AND B.StatusId IN (0,1)
					AND B.Bettype In (9,29)
					AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))

					AND (@Sporttypes = '0' 
							OR EXISTS (	SELECT	1 
										FROM	BettransM BM WITH (NOLOCK, index=IX_RefNo) 
										INNER JOIN Match M WITH (NOLOCK) 
											ON	 M.matchID = BM.MatchId 
											AND (M.sporttype IN (Select sporttype FROM #SportsList))							
										WHERE	BM.RefNo = B.RefNo
										 )	
						)	
				) B
	GROUP BY B.AgentId

	-- Outright 
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype = 10 OR @Bettypes = '0')
	INSERT INTO #MemberOutstanding 
	SELECT  '', C.AgentId, 0 as IsAgent,
			ISNULL(SUM (ABS(BA.actual_stake)),0) as Outstanding,
			ISNULL(SUM(ABS(BA.actual_stake) * BA.APositiontaking),0) as Positiontaking
	FROM Bettrans B WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK) 
		ON BA.TransID = B.TransID AND BA.AgentId = @AgentID 
	INNER JOIN CustInfo C WITH (NOLOCK)
		ON B.CustID = C.CustID AND C.AgentId =@AgentID	
	WHERE	 BA.StatusId IN (0,1)
			AND BA.Bettype = 10
			AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

			AND B.StatusId IN (0,1)
			AND B.Bettype = 10
			AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))
			
			AND (@Sporttypes = '0' 
				 OR EXISTS (SELECT	1 
							FROM	Outright M WITH (NOLOCK) 
							INNER JOIN League L WITH (NOLOCK) 
									ON L.leagueid = M.leagueid		
									AND (L.sporttype IN (Select sporttype FROM #SportsList))				
							WHERE	M.orid = B.MatchId
							)	
					)

	GROUP BY C.AgentId

END


--################################################# Get Data ####################################################--

SELECT	
		ISNULL(A.Username, B.Username) as Username , 
		ISNULL(A.AgentId, B.AgentId) as AgentId, 
		ISNULL(A.isAgent, B.isAgent) as isAgent, 	
		ISNULL(A.PositionTaking, B.PositionTaking) as PositionTaking,
	---	ISNULL(A.BetCount,0) as BetCount,	
		ISNULL(A.TurnOver,0) as TurnOver,
		ISNULL(A.ActualTO,0) as ActualTO,
		ISNULL(A.GrossTotal,0) as GrossTotal,
		ISNULL(A.AWinLost,0) as AWinLost, 
		ISNULL(A.AComm,0) as AComm,
		ISNULL(A.ATotal,0) as ATotal,
		ISNULL(A.UplineTotal,0) as UplineTotal,
		ISNULL(B.Outstanding,0) as Outstanding,
		ISNULL(B.OutstandingShare,0) as OutstandingShare
FROM 	(
			SELECT	Username, AgentId, isAgent, PositionTaking,
					SUM(BetCount) as BetCount,	
					SUM(TurnOver) as TurnOver,
					SUM(ActualTO) as ActualTO,
					SUM(GrossTotal) as GrossTotal,
					SUM(AWinLost) as  AWinLost, 
					SUM(AComm) as AComm,
					SUM(ATotal) as ATotal,				
					SUM(UplineTotal) as UplineTotal
			FROM	#WinLossAgent
			GROUP BY Username, AgentId, isAgent, PositionTaking
			UNION ALL
			SELECT	Username, AgentId, isAgent, PositionTaking,
					SUM(BetCount) as BetCount,	
					SUM(TurnOver) as TurnOver,
					SUM(ActualTO) as ActualTO,
					SUM(GrossTotal) as GrossTotal,
					SUM(AWinLost) as  AWinLost, 
					SUM(AComm) as AComm,
					SUM(ATotal) as ATotal,		
					SUM(UplineTotal) as UplineTotal
			FROM	#WinLossMember 
			GROUP BY Username, AgentId, isAgent, PositionTaking
		) A
FULL JOIN (	 
			SELECT	Username, A.AgentID, IsAgent,PT.MaxUpperPositionTaking as PositionTaking,
					SUM (Outstanding) as Outstanding, 
					SUM (OutstandingShare) as OutstandingShare
			FROM	#AgentOutstanding A
			INNER JOIN AgentPositionTaking PT WITH (NOLOCK) 
				ON PT.AgentID = A.AgentId AND PT.Bettype = 1 AND PT.SportType = 1 AND IsLive = 0
			GROUP BY Username, A.AgentID, IsAgent,PT.MaxUpperPositionTaking 
			UNION ALL
			SELECT	Username, AgentID, IsAgent, 0 as PositionTaking,
					SUM (Outstanding) as Outstanding,
					SUM (OutstandingShare) as OutstandingShare
			FROM	#MemberOutstanding 
			GROUP BY Username, AgentID, IsAgent 
		) B
	ON	A.AgentID = B.AgentID
ORDER BY IsAgent DESC, PositionTaking ASC, Username ASC


DROP TABLE #WinLossAgent
DROP TABLE #WinLossMember

DROP TABLE #AgentOutstanding
DROP TABLE #MemberOutstanding

DROP TABLE #BettypeList
DROp TABLE #SportsList


GO
GRANT EXECUTE ON [dbo].[Age_Rpt_WinLoss] TO [aplWeb]
Go 



 

