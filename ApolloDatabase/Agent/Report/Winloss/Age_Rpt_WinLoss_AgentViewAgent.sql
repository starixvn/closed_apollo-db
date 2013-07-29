ALTEr PROCEDURE [dbo].[Age_Rpt_WinLoss_AgentViewAgent]
	@AgentID 	INT,
	@FromDate 	DATE,
	@ToDate 	DATE,	
	@MoveBetDay DATE, 
	@BalanceUpDay DATE,	
	@Sporttypes VARCHAR(MAX) = '0',
	@Bettypes VARCHAR(MAX) = '0'
 	
AS
    /*
    Created	: Sophia
	Date	: 20130726
    Task	: Report Agent Winloss (AgentViewAgent)
    DB		: SVRAGE.RepDB

    Revisions:
        - 201307298@Sophia: Add ActualTOAfter (Effective Stake) 
    */
    
SET NOCOUNT ON

IF @Todate > @MoveBetDay
BEGIN  
	--********************************
	---- Agent Winloss
	--********************************	
		---Sportsbook
	CREATE TABLE #Tmp (Username NVARCHAR(50),  AgentID INT , PositionTaking smallint,
				BetCount INT, TurnOver MONEY, ActualTO MONEY, ActualTOAfter MONEY, AWinlost MONEY,AComm MONEY,
				ATotal MONEY, ChildAComm MONEY, Winlost MONEY, Actual_Stake MONEY) 

	CREATE TABLE #PAgent(TransID bigint , Awinlost money, AComm money, APositionTaking smallmoney,
				Stake money, MOdds smallmoney, StatusID tinyint, 
				matchid int, Winlost money, Actual_Stake money)

	------Sportsbook
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10) OR @Bettypes = '0')	
	BEGIN
			IF (@Bettypes = '0')
			BEGIN
				INSERT INTO  #PAgent 
				SELECT  BP.TransID, BP.AWinlost, BP.AComm, BP.APositionTaking,
						B.Stake, B.MOdds, B.StatusID, 
						B.matchid, B.Winlost, B.Actual_Stake			
				FROM Bettrans_Agent BP WITH (NOLOCK) 
				INNER JOIN Bettrans B (NOLOCK) 
					ON	BP.TransID = B.TransID 
				WHERE 	BP.AgentID = @AgentID ---Parent (k)
						AND BP.Winlostdate BETWEEN @FromDate AND @ToDate 
						AND BP.StatusID NOT IN (0,1)	
						AND BP.Bettype <=19000						
									

				INSERT INTO	#Tmp
				SELECT  C.Username, C.AgentID, PT.MaxUpperPositionTaking as PositionTaking,
							COUNT(B.TransID) BetCount,			 
		   					SUM(ABS(B.Stake)) AS TurnOver,
							SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS ActualTO,
							SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END * B.APositionTaking)  AS ActualTOAfter,
							SUM(B.AWinlost) AS AWinlost,	
							SUM(B.AComm) - SUM(BA.AComm) AS AComm,
							SUM(B.AWinlost) + SUM (B.AComm) - SUM (BA.AComm)  AS ATotal,
							SUM(BA.AComm) ChildAComm  , 
							SUM(B.Winlost) as Winlost,
							SUM(B.Actual_Stake) as Actual_Stake	   
					FROM	#PAgent B				
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
					INNER JOIN  Match m  WITH (NOLOCK) 
							ON m.MatchID = B.MatchID
					WHERE	(@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList))
					GROUP BY C.Username, C.AgentID ,  PT.MaxUpperPositionTaking
			END
			ELSE
			BEGIN
	
				INSERT INTO  #PAgent 
				SELECT  BP.TransID, BP.AWinlost, BP.AComm, BP.APositionTaking,
					B.Stake, B.MOdds, B.StatusID, 
					B.matchid, B.Winlost, B.Actual_Stake			
				FROM Bettrans_Agent BP WITH (NOLOCK) 
				INNER JOIN  Bettrans B (NOLOCK) 
					ON	BP.TransID = B.TransID 
				WHERE 	BP.AgentID = @AgentID ---Parent (k)
					AND BP.Winlostdate BETWEEN @FromDate AND @ToDate 
					AND BP.StatusID NOT IN (0,1)									
					AND BP.Bettype IN (Select bettype FROM #BettypeList)	

				INSERT INTO	#Tmp
				SELECT  C.Username, C.AgentID, PT.MaxUpperPositionTaking as PositionTaking,
							COUNT(B.TransID) BetCount,			 
		   					SUM(ABS(B.Stake)) AS TurnOver,
							SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS ActualTO,
							SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END * B.APositionTaking)  AS ActualTOAfter,
							SUM(B.AWinlost) AS AWinlost,	
							SUM(B.AComm) - SUM(BA.AComm) AS AComm,
							SUM(B.AWinlost) + SUM (B.AComm) - SUM (BA.AComm)  AS ATotal,
							SUM(BA.AComm) ChildAComm  , 
							SUM(B.Winlost) as Winlost,
							SUM(B.Actual_Stake) as Actual_Stake	   
					FROM	#PAgent B				
					INNER JOIN AgentInfo C WITH (NOLOCK) --- Child direct (k+1)
							ON C.ParentID = @AgentID  				
					INNER JOIN AgentPositionTaking PT WITH (NOLOCK) 
							ON PT.AgentID = C.AgentId AND PT.Bettype = 1 AND PT.SportType = 1 AND IsLive = 0
					INNER JOIN Bettrans_Agent BA WITH (NOLOCK) 
							ON  BA.TransID = B.TransID 
							AND C.AgentID = BA.AgentID ---- Child direct (k+1)
							AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
							AND BA.StatusID NOT IN (0,1)						
							AND BA.Bettype IN (Select bettype FROM #BettypeList)	
					INNER JOIN  Match m  WITH (NOLOCK) 
							ON m.MatchID = B.MatchID
					WHERE	(@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList))
					GROUP BY C.Username, C.AgentID ,  PT.MaxUpperPositionTaking
			END						
		

		--INSERT INTO #WinLossAgent
		--SELECT	T.Username, T.AgentID, 1 as IsAgent, T.PositionTaking as PositionTaking,
		--		T.BetCount, T.TurnOver, T.ActualTO, T.AWinlost, T.AComm, T.ATotal ,
		--		SUM(BA.AWINLOST) + (T.Winlost - T.Actual_Stake) + T.ChildAComm  AS GrossTotal,  
		--		-(SUM(BA.AWINLOST) + (T.Winlost - T.Actual_Stake) + T.ChildAComm  + T.ATotal) AS UplineTotal
		--FROM	#Tmp T
		--INNER JOIN AgentInfo P with (nolock) ON  T.AgentID = P.AgentID
		--INNER JOIN AgentInfo C WITH(NOLOCK) ON C.AgentHId.IsDescendantOf(P.AgentHId ) =1  AND C.AgentLevel >= P.AgentLevel  --- Children of k+1 (k+1 -> k+...)		
		--INNER JOIN Bettrans_Agent BA WITH (NOLOCK) ON BA.AgentID = C.AgentID
		--	AND BA.TransId in (select transid from #PAgent)		
		--	--AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
		--	--	AND BA.StatusID NOT IN (0,1)	
		--	--	AND BA.Bettype <=19000				
		--GROUP BY T.AgentID, T.Username,T.PositionTaking, T.TurnOver, T.ActualTO, T.AWinlost, T.AComm, T.ATotal, T.ChildAComm, T.Winlost , T.Actual_Stake, T.BetCount		
	
 	 
		INSERT INTO #WinLossAgent
		SELECT	T.Username, T.AgentID, 1 as IsAgent, T.PositionTaking as PositionTaking,
				T.BetCount, T.TurnOver, T.ActualTO, T.ActualTOAfter, T.AWinlost, T.AComm, T.ATotal, 
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
		GROUP BY T.AgentID, T.Username,T.PositionTaking, T.TurnOver, T.ActualTO, T.ActualTOAfter, T.AWinlost, T.AComm, T.ATotal, T.ChildAComm, T.Winlost , T.Actual_Stake, T.BetCount
	  
		DELETE #Tmp	
		DELETE #PAgent	
	END

	------Parlay	
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29) OR @Bettypes = '0')
	BEGIN 
		INSERT INTO	#Tmp
		SELECT  B.Username, B.AgentID, B.MaxUpperPositionTaking as PositionTaking,
				SUM(B.BetCount) BetCount,			 
		   		SUM(ABS(B.Stake)) AS TurnOver,
				SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS ActualTO,
				SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END * B.APositionTaking)  AS ActualTOAfter,
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
						BP.AWinlost, BP.AComm, BA.AComm as ChildAComm, BP.APositionTaking							
				FROM	Bettrans B WITH (NOLOCK)---, index = IX_Winlostdate_Bettype_StatusId) 
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
						BP.AWinlost, BP.AComm, BP.AWinlost, BA.AComm, BP.APositionTaking
			) B
		GROUP BY B.Username, B.AgentID , B.MaxUpperPositionTaking

		--------------------------------
	
		INSERT INTO #WinLossAgent
		SELECT	T.Username, T.AgentID, 1 as IsAgent, T.PositionTaking as PositionTaking,
				T.BetCount, T.TurnOver, T.ActualTO, T.ActualTOAfter, T.AWinlost, T.AComm, T.ATotal, 
				SUM(T.LineWinLost) + (T.Winlost - T.Actual_Stake) + T.ChildAComm  AS GrossTotal,  
				-(SUM(T.LineWinLost) + (T.Winlost - T.Actual_Stake) + T.ChildAComm  + T.ATotal) AS UplineTotal
		FROM (	
			SELECT  T.Username, T.AgentID, 1 as IsAgent, T.PositionTaking as PositionTaking,
					T.BetCount, T.TurnOver, T.ActualTO, T.ActualTOAfter, T.AWinlost, T.AComm, T.ATotal, 
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
		GROUP BY T.AgentID, T.Username,T.PositionTaking, T.TurnOver, T.ActualTO, T.ActualTOAfter, T.AWinlost, T.AComm, T.ATotal, T.ChildAComm, T.Winlost , T.Actual_Stake, T.BetCount
	 
		DELETE #Tmp 
	END

	-----Outright
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (10) OR @Bettypes = '0')
	BEGIN
		INSERT INTO	#Tmp
		SELECT  C.Username, C.AgentID, PT.MaxUpperPositionTaking as PositionTaking,
				COUNT(B.TransID) BetCount,			 
		   		SUM(ABS(B.Stake)) AS TurnOver,
				SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS ActualTO,
				SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END * BP.APositionTaking)  AS ActualTOAfter,
				SUM(BP.AWinlost) AS AWinlost,	
				SUM(BP.AComm) - SUM(BA.AComm) AS AComm,
				SUM(BP.AWinlost) + SUM (BP.AComm) - SUM (BA.AComm)  AS ATotal,
			    SUM(BA.AComm) ChildAComm  , 
				SUM(B.Winlost) as Winlost,
				SUM(B.Actual_Stake) as Actual_Stake	   
		FROM	Bettrans B WITH (NOLOCK)--- , index = IX_Winlostdate_Bettype_StatusId) 
		INNER JOIN Bettrans_Agent BP WITH (NOLOCK)---, index =IX_WinLostDate_Bettype_StatusId) 
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
		INNER JOIN Bettrans_Agent BA WITH (NOLOCK)---,  index =IX_WinLostDate_Bettype_StatusId) 
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
				T.BetCount, T.TurnOver, T.ActualTO, T.ActualTOAfter, T.AWinlost, T.AComm, T.ATotal, 
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
		GROUP BY T.AgentID, T.Username,T.PositionTaking, T.TurnOver, T.ActualTO, T.ActualTOAfter, T.AWinlost, T.AComm, T.ATotal, T.ChildAComm, T.Winlost , T.Actual_Stake, T.BetCount
	 	
		DELETE #Tmp 
	END
	DROP TABLE #PAgent 
	DROP TABLE #Tmp 
END 
	
------------------------------------------------DATA [14] ----------------------------------------------
 
IF @FromDate <= @MoveBetDay 
BEGIN  
	
	--********************************
	---- Agent Winloss
	--********************************
		CREATE TABLE #Tmp14 (Username VARCHAR(50),  AgentID INT , PositionTaking smallint,
				BetCount INT, TurnOver MONEY, ActualTO MONEY, ActualTOAfter MONEY, AWinlost MONEY,AComm MONEY,
				ATotal MONEY, ChildAComm MONEY, Winlost MONEY, Actual_Stake MONEY) 


		CREATE TABLE #PAgent14(TransID bigint , Awinlost money, AComm money, APositionTaking smallmoney,
				Stake money, MOdds smallmoney, StatusID tinyint, 
				matchid int, Winlost money, Actual_Stake money)

		---Sportsbook
		IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10) OR @Bettypes = '0')
		BEGIN
			IF (@Bettypes = '0')
			BEGIN
				INSERT INTO  #PAgent14 
				SELECT  BP.TransID, BP.AWinlost, BP.AComm, BP.APositionTaking, 
					B.Stake, B.MOdds, B.StatusID, 
					B.matchid, B.Winlost, B.Actual_Stake			
				FROM Bettrans14_Agent BP WITH (NOLOCK) 
					INNER JOIN Bettrans14 B (NOLOCK) 
					ON	BP.TransID = B.TransID 
				WHERE 	BP.AgentID = @AgentID ---Parent (k)
						AND BP.Winlostdate BETWEEN @FromDate AND @ToDate 
						AND BP.StatusID NOT IN (0,1)	
						AND BP.Bettype <=19000						
									

				INSERT INTO	#Tmp14
				SELECT  C.Username, C.AgentID, PT.MaxUpperPositionTaking as PositionTaking,
							COUNT(B.TransID) BetCount,			 
		   					SUM(ABS(B.Stake)) AS TurnOver,
							SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS ActualTO,
							SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END * B.APositionTaking)  AS ActualTOAfter,
							SUM(B.AWinlost) AS AWinlost,	
							SUM(B.AComm) - SUM(BA.AComm) AS AComm,
							SUM(B.AWinlost) + SUM (B.AComm) - SUM (BA.AComm)  AS ATotal,
							SUM(BA.AComm) ChildAComm  , 
							SUM(B.Winlost) as Winlost,
							SUM(B.Actual_Stake) as Actual_Stake	   
					FROM	#PAgent14 B				
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
					INNER JOIN  Match14 m  WITH (NOLOCK) 
							ON m.MatchID = B.MatchID
					WHERE	(@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList))
					GROUP BY C.Username, C.AgentID ,  PT.MaxUpperPositionTaking
			END
			ELSE
			BEGIN
	
				INSERT INTO  #PAgent14 
				SELECT  BP.TransID, BP.AWinlost, BP.AComm, BP.APositionTaking,
					B.Stake, B.MOdds, B.StatusID, 
					B.matchid, B.Winlost, B.Actual_Stake			
				FROM Bettrans14_Agent BP WITH (NOLOCK)
				INNER JOIN Bettrans14 B (NOLOCK) 
					ON	BP.TransID = B.TransID 
				WHERE 	BP.AgentID = @AgentID ---Parent (k)
					AND BP.Winlostdate BETWEEN @FromDate AND @ToDate 
					AND BP.StatusID NOT IN (0,1)									
					AND BP.Bettype IN (Select bettype FROM #BettypeList)	

				INSERT INTO	#Tmp14
				SELECT  C.Username, C.AgentID, PT.MaxUpperPositionTaking as PositionTaking,
							COUNT(B.TransID) BetCount,			 
		   					SUM(ABS(B.Stake)) AS TurnOver,
							SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS ActualTO,
							SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END * B.APositionTaking)  AS ActualTOAfter,
							SUM(B.AWinlost) AS AWinlost,	
							SUM(B.AComm) - SUM(BA.AComm) AS AComm,
							SUM(B.AWinlost) + SUM (B.AComm) - SUM (BA.AComm)  AS ATotal,
							SUM(BA.AComm) ChildAComm  , 
							SUM(B.Winlost) as Winlost,
							SUM(B.Actual_Stake) as Actual_Stake	   
					FROM	#PAgent14 B				
					INNER JOIN AgentInfo C WITH (NOLOCK) --- Child direct (k+1)
							ON C.ParentID = @AgentID  				
					INNER JOIN AgentPositionTaking PT WITH (NOLOCK) 
							ON PT.AgentID = C.AgentId AND PT.Bettype = 1 AND PT.SportType = 1 AND IsLive = 0
					INNER JOIN Bettrans14_Agent BA WITH (NOLOCK) 
							ON  BA.TransID = B.TransID 
							AND C.AgentID = BA.AgentID ---- Child direct (k+1)
							AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
							AND BA.StatusID NOT IN (0,1)						
							AND BA.Bettype IN (Select bettype FROM #BettypeList)	
					INNER JOIN  Match14 m  WITH (NOLOCK) 
							ON m.MatchID = B.MatchID
					WHERE	(@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList))
					GROUP BY C.Username, C.AgentID ,  PT.MaxUpperPositionTaking
			END						
		

	
 	 
		INSERT INTO #WinLossAgent
		SELECT	T.Username, T.AgentID, 1 as IsAgent, T.PositionTaking as PositionTaking,
				T.BetCount, T.TurnOver, T.ActualTO, T.ActualTOAfter, T.AWinlost, T.AComm, T.ATotal, 
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
		GROUP BY T.AgentID, T.Username,T.PositionTaking, T.TurnOver, T.ActualTO, T.ActualTOAfter, T.AWinlost, T.AComm, T.ATotal, T.ChildAComm, T.Winlost , T.Actual_Stake, T.BetCount
	  
		DELETE #Tmp14	
		DELETE #PAgent14	
	END
		 
	------Parlay	
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29) OR @Bettypes = '0')
	BEGIN 
		INSERT INTO	#Tmp14
		SELECT  B.Username, B.AgentID, B.MaxUpperPositionTaking as PositionTaking,
				SUM(B.BetCount) BetCount,			 
		   		SUM(ABS(B.Stake)) AS TurnOver,
				SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS ActualTO,
				SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END *B.APositionTaking)  AS ActualTOAfter,
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
						BP.AWinlost, BP.AComm, BA.AComm as ChildAComm, BP.APositionTaking							
				FROM	Bettrans14 B WITH (NOLOCK)---, index = IX_Winlostdate_Bettype_StatusId) 
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
						BP.AWinlost, BP.AComm, BP.AWinlost, BA.AComm, BP.APositionTaking
			) B
		GROUP BY B.Username, B.AgentID , B.MaxUpperPositionTaking

		--------------------------------
	
		INSERT INTO #WinLossAgent
		SELECT	T.Username, T.AgentID, 1 as IsAgent, T.PositionTaking as PositionTaking,
				T.BetCount, T.TurnOver, T.ActualTO, T.ActualTOAfter, T.AWinlost, T.AComm, T.ATotal, 
				SUM(T.LineWinLost) + (T.Winlost - T.Actual_Stake) + T.ChildAComm  AS GrossTotal,  
				-(SUM(T.LineWinLost) + (T.Winlost - T.Actual_Stake) + T.ChildAComm  + T.ATotal) AS UplineTotal
		FROM (	
			SELECT  T.Username, T.AgentID, 1 as IsAgent, T.PositionTaking as PositionTaking,
					T.BetCount, T.TurnOver, T.ActualTO, T.ActualTOAfter, T.AWinlost, T.AComm, T.ATotal, 
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
		GROUP BY T.AgentID, T.Username,T.PositionTaking, T.TurnOver, T.ActualTO,T.ActualTOAfter, T.AWinlost, T.AComm, T.ATotal, T.ChildAComm, T.Winlost , T.Actual_Stake, T.BetCount
	 
		DELETE  #Tmp14 
	END 

	-----Outright14
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (10) OR @Bettypes = '0')
	BEGIN 
		INSERT INTO	#Tmp14
		SELECT  C.Username, C.AgentID, PT.MaxUpperPositionTaking as PositionTaking,
				COUNT(B.TransID) BetCount,			 
		   		SUM(ABS(B.Stake)) AS TurnOver,
				SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS ActualTO,
				SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END * BP.APositionTaking)  AS ActualTOAfter,

				SUM(BP.AWinlost) AS AWinlost,	
				SUM(BP.AComm) - SUM(BA.AComm) AS AComm,
				SUM(BP.AWinlost) + SUM (BP.AComm) - SUM (BA.AComm)  AS ATotal,
			    SUM(BA.AComm) ChildAComm  , 
				SUM(B.Winlost) as Winlost,
				SUM(B.Actual_Stake) as Actual_Stake	   
		FROM	Bettrans14 B WITH (NOLOCK)--, index = IX_Winlostdate_Bettype_StatusId) 
		INNER JOIN Bettrans14_Agent BP WITH (NOLOCK)---, index =IX_WinLostDate_Bettype_StatusId) 
				ON BP.TransID = B.TransID 
				AND BP.AgentID = @AgentID ---Parent (k)
				AND BP.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND BP.StatusID NOT IN (0,1)	
				AND BP.Bettype = 10
				
		INNER JOIN AgentInfo C WITH (NOLOCK) --- Child direct (k+1)
				ON C.ParentID = @AgentID  
		INNER JOIN AgentPositionTaking PT WITH (NOLOCK) 
				ON PT.AgentID = C.AgentId AND PT.Bettype = 1 AND PT.SportType = 1 AND IsLive = 0
		INNER JOIN Bettrans14_Agent BA WITH (NOLOCK)---,  index =IX_WinLostDate_Bettype_StatusId) 
				ON BA.TransID = B.TransID 
				AND C.AgentID = BA.AgentID ---- Child direct (k+1)
				AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND BA.StatusID NOT IN (0,1)	
				AND BA.Bettype = 10
			
		INNER JOIN  Outright14 m  WITH (NOLOCK) 
				ON  m.orid = B.MatchID
		INNER JOIN  League l WITH (NOLOCK)
				ON	l.leagueID = m.leagueId
		WHERE	B.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND B.StatusID NOT IN (0,1)	
				AND B.Bettype =10
							
				AND (@Sporttypes = '0' OR l.sporttype IN (Select sporttype FROM #SportsList))
		GROUP BY C.Username, C.AgentID ,  PT.MaxUpperPositionTaking
				 
		 
		INSERT INTO #WinLossAgent
		SELECT	T.Username, T.AgentID, 1 as IsAgent, T.PositionTaking as PositionTaking,
				T.BetCount, T.TurnOver, T.ActualTO, T.ActualTOAfter,T.AWinlost, T.AComm, T.ATotal, 
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
		
				AND (@Sporttypes = '0' OR l.sporttype IN (Select sporttype FROM #SportsList))
		GROUP BY T.AgentID, T.Username,T.PositionTaking, T.TurnOver, T.ActualTO,T.ActualTOAfter, T.AWinlost, T.AComm, T.ATotal, T.ChildAComm, T.Winlost , T.Actual_Stake, T.BetCount
	
	END 
	DROP TABLE #Tmp14 
	DROP TABLE #PAgent14
END
 

GO
GRANT EXECUTE ON [dbo].[Age_Rpt_WinLoss_AgentViewAgent] TO [aplweb]
GO   



