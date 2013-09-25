ALTER PROCEDURE [dbo].[Age_Rpt_WinLoss_AgentViewAgent]
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
		- 20130910@Sophia: revise Outright
		- 20130924@Sophia: .Use link server to call table AgentPositionTaking
						   .Change the formula of CommBase Parlay and Outright
		- 20130925@Sophia: Change to way to get Share
    */
    
SET NOCOUNT ON

IF @Todate > @MoveBetDay
BEGIN  
	--********************************
	---- Agent Winloss
	--********************************	
		---Sportsbook
	CREATE TABLE #Tmp (Username NVARCHAR(50),  AgentID INT, TransID BIGINT, APositionTaking smallmoney,  
				BetAmount MONEY, CommBase MONEY, Winlost MONEY, PlayerComm MONEY, MemberTotal MONEY, 
				AWinlost MONEY,AComm MONEY,	ATotal MONEY, ChildAComm MONEY, Actual_Stake MONEY) 

	CREATE TABLE #PAgent(TransID bigint , Awinlost money, AComm money, APositionTaking smallmoney,
				Stake money, MOdds smallmoney, StatusID tinyint, matchid int, 
				Winlost money, Actual_Stake money, PlayerComm MONEY)

	------Sportsbook
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10) OR @Bettypes = '0')	
	BEGIN
			IF (@Bettypes = '0')
			BEGIN
				INSERT INTO  #PAgent 
				SELECT  BP.TransID, BP.AWinlost, BP.AComm, BP.APositionTaking,
						B.Stake, B.MOdds, B.StatusID, B.Matchid, 
						B.Winlost, B.Actual_Stake, B.PlayerComm			
				FROM Bettrans_Agent BP WITH (NOLOCK) 
				INNER JOIN Bettrans B (NOLOCK) 
					ON	BP.TransID = B.TransID 
				WHERE 	BP.AgentID = @AgentID ---Parent (k)
						AND BP.Winlostdate BETWEEN @FromDate AND @ToDate 
						AND BP.StatusID NOT IN (0,1)	
						AND BP.Bettype <=19000						
 						

				INSERT INTO	#Tmp
				SELECT		C.Username, C.AgentID, BA.TransID,
							SUM (B.APositionTaking) as APositionTaking ,									 
		   					SUM(ABS(B.Stake)) AS BetAmount,
							SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS CommBase,
							SUM(B.Winlost - B.Actual_Stake) AS Winlost,	
							SUM(B.PlayerComm) as PlayerComm, 
							SUM(B.Winlost - B.Actual_Stake + B.PlayerComm) AS MemberTotal,

							SUM(B.AWinlost) AS AWinlost,	
							SUM(B.AComm) - SUM(BA.AComm) AS AComm,
							SUM(B.AWinlost) + SUM (B.AComm) - SUM (BA.AComm)  AS ATotal,

							SUM(BA.AComm) ChildAComm,
							SUM(B.Actual_stake) as Actual_stake  	   
					FROM	#PAgent B				
					INNER JOIN AgentInfo C WITH (NOLOCK) --- Child direct (k+1)
							ON C.ParentID = @AgentID		
					INNER JOIN Bettrans_Agent BA WITH (NOLOCK) 
							ON  BA.TransID = B.TransID 
							AND C.AgentID = BA.AgentID ---- Child direct (k+1)
							AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
							AND BA.StatusID NOT IN (0,1)	
							AND BA.Bettype <=19000				
					INNER JOIN  Match m  WITH (NOLOCK) 
							ON m.MatchID = B.MatchID
					WHERE	(@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList))
					GROUP BY C.Username, C.AgentID,  BA.TransID
			END
			ELSE
			BEGIN

				INSERT INTO  #PAgent 
				SELECT  BP.TransID, BP.AWinlost, BP.AComm, BP.APositionTaking,  
						B.Stake, B.MOdds, B.StatusID, B.Matchid, 
						B.Winlost, B.Actual_Stake, B.PlayerComm			
				FROM Bettrans_Agent BP WITH (NOLOCK) 
				INNER JOIN  Bettrans B (NOLOCK) 
					ON	BP.TransID = B.TransID 
				WHERE 	BP.AgentID = @AgentID ---Parent (k)
					AND BP.Winlostdate BETWEEN @FromDate AND @ToDate 
					AND BP.StatusID NOT IN (0,1)									
					AND BP.Bettype IN (Select bettype FROM #BettypeList)	

 
				INSERT INTO	#Tmp
				SELECT		C.Username, C.AgentID, BA.TransID,
							SUM (B.APositionTaking) as APositionTaking ,								 
		   					SUM(ABS(B.Stake)) AS BetAmount,
							SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS CommBase,
							SUM(B.Winlost - B.Actual_Stake) AS Winlost,	
							SUM(B.PlayerComm) as PlayerComm, 
							SUM(B.Winlost - B.Actual_Stake + B.PlayerComm) AS MemberTotal,

							SUM(B.AWinlost) AS AWinlost,	
							SUM(B.AComm) - SUM(BA.AComm) AS AComm,
							SUM(B.AWinlost) + SUM (B.AComm) - SUM (BA.AComm)  AS ATotal,

							SUM(BA.AComm) ChildAComm,
							SUM(B.Actual_stake) as Actual_stake 
					FROM	#PAgent B				
					INNER JOIN AgentInfo C WITH (NOLOCK) --- Child direct (k+1)
							ON C.ParentID = @AgentID
					INNER JOIN Bettrans_Agent BA WITH (NOLOCK) 
							ON  BA.TransID = B.TransID 
							AND C.AgentID = BA.AgentID ---- Child direct (k+1)
							AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
							AND BA.StatusID NOT IN (0,1)						
							AND BA.Bettype IN (Select bettype FROM #BettypeList)	
					INNER JOIN  Match m  WITH (NOLOCK) 
							ON m.MatchID = B.MatchID
					WHERE	(@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList))
					GROUP BY C.Username, C.AgentID,  BA.TransID
			END						
 
 
		------------------------------------

		INSERT INTO #WinLossAgent
		SELECT	T.Username, T.AgentID, 1 as IsAgent, 
				1 as Betcount, T.BetAmount, T.CommBase, 
				T.Winlost, T.PlayerComm, T.MemberTotal,
				T.AWinlost, T.AComm, T.ATotal, 
				 
				(1 - SUM (BA.APositionTaking)) * T.CommBase as DownlineEffStake,		
				SUM(BA.AWINLOST) + T.Winlost  + T.ChildAComm  AS GrossTotal,  
				
				((1 - SUM (BA.APositionTaking)) - T.APositionTaking) * T.CommBase as UplineEffStake,
				-(SUM(BA.AWINLOST) + T.Winlost + T.ChildAComm  + T.ATotal) AS UplineTotal
		FROM	#Tmp T
		INNER JOIN AgentInfo P with (nolock) ON  T.AgentID = P.AgentID
		INNER JOIN AgentInfo C WITH(NOLOCK) ON C.AgentHId.IsDescendantOf(P.AgentHId ) =1  AND C.AgentLevel >= P.AgentLevel  --- Children of k+1 (k+1 -> k+...)
		INNER JOIN Bettrans_Agent BA WITH (NOLOCK) ON BA.AgentID = C.AgentID AND BA.TransID = T.TransID
		WHERE   BA.Winlostdate BETWEEN @FromDate AND @ToDate
				AND BA.StatusID NOT IN (0,1) 				 
				AND BA.Bettype <= 19000
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))	
		GROUP BY T.Username, T.AgentID, 
				T.TransID, T.BetAmount, T.CommBase, 
				T.Winlost, T.PlayerComm, T.MemberTotal,
				T.AWinlost, T.AComm, T.ATotal,T.ChildAComm , 
				T.APositionTaking,T.Actual_Stake
	  
		DELETE #Tmp	
		DELETE #PAgent	
	END
		 
	------Parlay	
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29) OR @Bettypes = '0')
	BEGIN 
		INSERT INTO	#Tmp
		SELECT  C.Username, C.AgentID, B.TransID,				
				SUM (BP.APositionTaking) as APositionTaking ,						 
		   		SUM(ABS(B.Stake)) AS BetAmount,
				SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END)  AS CommBase,
				SUM(B.Winlost - B.Actual_Stake) AS Winlost,	
				SUM(B.PlayerComm) as PlayerComm, 
				SUM(B.Winlost - B.Actual_Stake + B.PlayerComm) AS MemberTotal,

				SUM(BP.AWinlost) AS AWinlost,	
				SUM(BP.AComm) - SUM(BP.AComm) AS AComm,
				SUM(BP.AWinlost) + SUM (BP.AComm) - SUM (BP.AComm)  AS ATotal,

				SUM(BA.AComm) as ChildAComm,
				SUM(B.Actual_stake) as Actual_stake 
					
		FROM	Bettrans B WITH (NOLOCK) 
				INNER JOIN Bettrans_Agent BP WITH (NOLOCK) 
						ON BP.TransID = B.TransID 
						AND BP.AgentID = @AgentID ---Parent (k)
						AND BP.Winlostdate BETWEEN @FromDate AND @ToDate 
						AND BP.StatusID NOT IN (0,1)	
						AND BP.Bettype IN (9,29)
						AND (@Bettypes = '0' OR BP.Bettype IN (Select bettype FROM #BettypeList))

				INNER JOIN AgentInfo C WITH (NOLOCK) --- Child direct (k+1)
						ON C.ParentID = @AgentID  
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
				GROUP BY C.Username, C.AgentID, B.TransID
 
		--------------------------------
	
		INSERT INTO #WinLossAgent
		SELECT	T.Username, T.AgentID, 1 as IsAgent,
				1 as Betcount, T.BetAmount, T.CommBase, 
				T.Winlost, T.PlayerComm, T.MemberTotal,
				T.AWinlost, T.AComm, T.ATotal, 		
						
				(1-SUM (T.LinePositionTaking)) * T.CommBase as DownlineEffStake,
				SUM(T.LineWinLost)  + T.ChildAComm + T.Winlost  AS GrossTotal,		
				((1-SUM (T.LinePositionTaking)) - T.APositionTaking) * T.CommBase as UplineEffStake,
				-(SUM(T.LineWinLost)  + T.ChildAComm + T.Winlost + T.ATotal) AS UplineTotal
		FROM (	
			SELECT  T.Username, T.AgentID,T.APositionTaking, 
					T.TransID, T.BetAmount, T.CommBase, 
					T.Winlost, T.PlayerComm, T.MemberTotal,
					T.AWinlost, T.AComm, T.ATotal, T.ChildAComm, T.Actual_Stake,	
					BA.AWINLOST as LineWinLost,	BA.APositionTaking as LinePositionTaking	 		
			FROM #Tmp T
			INNER JOIN AgentInfo P with (nolock) ON  T.AgentID = P.AgentID
			INNER JOIN AgentInfo C WITH(NOLOCK) ON C.AgentHId.IsDescendantOf(P.AgentHId ) =1  AND C.AgentLevel >= P.AgentLevel  --- Children of k+1 (k+1 -> k+...)
			INNER JOIN Bettrans_Agent BA WITH (NOLOCK) ON BA.AgentID = C.AgentID and BA.TransID = T.TransID
			WHERE	BA.Winlostdate BETWEEN @FromDate AND @ToDate
					AND BA.StatusID NOT IN (0,1) 				 
					AND BA.Bettype IN (9,29)
					AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList)) 							
			) T
		GROUP BY	T.Username, T.AgentID,
					T.TransID, T.BetAmount, T.CommBase, 
					T.Winlost, T.PlayerComm, T.MemberTotal,
					T.AWinlost, T.AComm, T.ATotal, T.ChildAComm , 
					T.APositionTaking, T.Actual_Stake
	 
		DELETE #Tmp 
	END

	-----Outright
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (10) OR @Bettypes = '0')
	BEGIN
		INSERT INTO	#Tmp
		SELECT  C.Username, C.AgentID, B.TransID,
				SUM(BP.APositionTaking) as APositionTaking , 				 
		   		SUM(ABS(B.Stake)) AS BetAmount,
				SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END)  AS CommBase,
				
				SUM(B.Winlost - B.Actual_Stake) AS Winlost,	
				SUM(B.PlayerComm) AS PlayerComm,
				SUM(B.Winlost - B.Actual_Stake + B.PlayerComm)  AS MemberTotal,

				SUM(BP.AWinlost) AS AWinlost,	
				SUM(BP.AComm) - SUM(BA.AComm) AS AComm,
				SUM(BP.AWinlost) + SUM (BP.AComm) - SUM (BA.AComm)  AS ATotal,

			    SUM(BA.AComm) ChildAComm ,
				SUM(B.Actual_stake) as Actual_stake  
							
		FROM	Bettrans B WITH (NOLOCK) 
		INNER JOIN Bettrans_Agent BP WITH (NOLOCK) 
				ON BP.TransID = B.TransID 
				AND BP.AgentID = @AgentID ---Parent (k)
				AND BP.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND BP.StatusID NOT IN (0,1)	
				AND BP.Bettype = 10
				AND (@Bettypes = '0' OR BP.Bettype IN (Select bettype FROM #BettypeList))
		INNER JOIN AgentInfo C WITH (NOLOCK) --- Child direct (k+1)
				ON C.ParentID = @AgentID 
		INNER JOIN Bettrans_Agent BA WITH (NOLOCK) 
				ON BA.TransID = B.TransID 
				AND C.AgentID = BA.AgentID ---- Child direct (k+1)
				AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND BA.StatusID NOT IN (0,1)	
				AND BA.Bettype = 10
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))
		WHERE	B.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND B.StatusID NOT IN (0,1)	
				AND B.Bettype =10
				AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))					
			
				AND (@Sporttypes = '0' 
						OR EXISTS (	SELECT	1 
									FROM Outright m  WITH (NOLOCK) 									
									INNER JOIN  League l WITH (NOLOCK)
											ON	l.leagueID = m.leagueId
											AND (l.sporttype IN (Select sporttype FROM #SportsList))							
									WHERE	m.orid = B.MatchID
									)				
						)
		GROUP BY C.Username, C.AgentID, B.TransID
				 
		 
		INSERT INTO #WinLossAgent
		SELECT	T.Username, T.AgentID, 1 as IsAgent,				 
				1 as Betcount, T.BetAmount, T.CommBase, 
				T.Winlost, T.PlayerComm, T.MemberTotal,
				T.AWinlost, T.AComm, T.ATotal, 
				(1-SUM (BA.APositionTaking)) * T.CommBase as DownlineEffStake,		
				SUM(BA.AWINLOST) + T.Winlost + T.ChildAComm  AS GrossTotal,  

				((1-SUM (BA.APositionTaking))  - T.APositionTaking) * T.CommBase as UplineEffStake,
				-(SUM(BA.AWINLOST) + T.Winlost  + T.ChildAComm  + T.ATotal) AS UplineTotal
				 
		FROM #Tmp T
		INNER JOIN AgentInfo P with (nolock) ON  T.AgentID = P.AgentID
		INNER JOIN AgentInfo C WITH(NOLOCK) ON C.AgentHId.IsDescendantOf(P.AgentHId ) =1  AND C.AgentLevel >= P.AgentLevel  --- Children of k+1 (k+1 -> k+...)
		INNER JOIN Bettrans_Agent BA WITH (NOLOCK) ON BA.AgentID = C.AgentID AND BA.TransID = T.TransID
		WHERE	BA.Winlostdate BETWEEN @FromDate AND @ToDate
				AND BA.StatusID NOT IN (0,1) 				 
				AND BA.Bettype = 10
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))		
				
		GROUP BY T.Username, T.AgentID, 
				T.TransID, T.BetAmount, T.CommBase, 
				T.Winlost, T.PlayerComm, T.MemberTotal,
				T.AWinlost, T.AComm, T.ATotal,
				T.Actual_Stake, T.ChildAComm,  T.APositionTaking
	 	
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
		---Sportsbook
	CREATE TABLE #Tmp14 (Username NVARCHAR(50),  AgentID INT , TransID BIGINT, APositionTaking smallmoney,  
				BetAmount MONEY, CommBase MONEY, Winlost MONEY, PlayerComm MONEY, MemberTotal MONEY, 
				AWinlost MONEY,AComm MONEY,	ATotal MONEY, ChildAComm MONEY, Actual_Stake MONEY) 

	CREATE TABLE #PAgent14(TransID bigint , Awinlost money, AComm money, APositionTaking smallmoney,
				Stake money, MOdds smallmoney, StatusID tinyint, matchid int, 
				Winlost money, Actual_Stake money, PlayerComm MONEY)

	------Sportsbook
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10) OR @Bettypes = '0')	
	BEGIN
			IF (@Bettypes = '0')
			BEGIN
				INSERT INTO  #PAgent14 
				SELECT  BP.TransID, BP.AWinlost, BP.AComm, BP.APositionTaking,
						B.Stake, B.MOdds, B.StatusID, B.Matchid, 
						B.Winlost, B.Actual_Stake, B.PlayerComm			
				FROM Bettrans14_Agent BP WITH (NOLOCK) 
				INNER JOIN Bettrans14 B (NOLOCK) 
					ON	BP.TransID = B.TransID 
				WHERE 	BP.AgentID = @AgentID ---Parent (k)
						AND BP.Winlostdate BETWEEN @FromDate AND @ToDate 
						AND BP.StatusID NOT IN (0,1)	
						AND BP.Bettype <=19000						
									

				INSERT INTO	#Tmp14
				SELECT		C.Username, C.AgentID,BA.TransID,
							SUM (B.APositionTaking) as APositionTaking ,								 
		   					SUM(ABS(B.Stake)) AS BetAmount,
							SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS CommBase,
							SUM(B.Winlost - B.Actual_Stake) AS Winlost,	
							SUM(B.PlayerComm) as PlayerComm, 
							SUM(B.Winlost - B.Actual_Stake + B.PlayerComm) AS MemberTotal,

							SUM(B.AWinlost) AS AWinlost,	
							SUM(B.AComm) - SUM(BA.AComm) AS AComm,
							SUM(B.AWinlost) + SUM (B.AComm) - SUM (BA.AComm)  AS ATotal,

							SUM(BA.AComm) ChildAComm,
							SUM(B.Actual_stake) as Actual_stake  	   
					FROM	#PAgent14 B				
					INNER JOIN AgentInfo C WITH (NOLOCK) --- Child direct (k+1)
							ON C.ParentID = @AgentID  				
					INNER JOIN Bettrans14_Agent BA WITH (NOLOCK) 
							ON  BA.TransID = B.TransID 
							AND C.AgentID = BA.AgentID ---- Child direct (k+1)
							AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
							AND BA.StatusID NOT IN (0,1)	
							AND BA.Bettype <=19000				
					INNER JOIN  Match14 m  WITH (NOLOCK) 
							ON m.MatchID = B.MatchID
					WHERE	(@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList))
					GROUP BY C.Username, C.AgentID, BA.TransID
			END
			ELSE
			BEGIN

				INSERT INTO  #PAgent14 
				SELECT  BP.TransID, BP.AWinlost, BP.AComm, BP.APositionTaking,  
						B.Stake, B.MOdds, B.StatusID, B.Matchid, 
						B.Winlost, B.Actual_Stake, B.PlayerComm			
				FROM Bettrans14_Agent BP WITH (NOLOCK) 
				INNER JOIN  Bettrans14 B (NOLOCK) 
					ON	BP.TransID = B.TransID 
				WHERE 	BP.AgentID = @AgentID ---Parent (k)
					AND BP.Winlostdate BETWEEN @FromDate AND @ToDate 
					AND BP.StatusID NOT IN (0,1)									
					AND BP.Bettype IN (Select bettype FROM #BettypeList)	

				INSERT INTO	#Tmp14
				SELECT		C.Username, C.AgentID, BA.TransID,
							SUM (B.APositionTaking) as APositionTaking ,							 
		   					SUM(ABS(B.Stake)) AS BetAmount,
							SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS CommBase,
							SUM(B.Winlost - B.Actual_Stake) AS Winlost,	
							SUM(B.PlayerComm) as PlayerComm, 
							SUM(B.Winlost - B.Actual_Stake + B.PlayerComm) AS MemberTotal,

							SUM(B.AWinlost) AS AWinlost,	
							SUM(B.AComm) - SUM(BA.AComm) AS AComm,
							SUM(B.AWinlost) + SUM (B.AComm) - SUM (BA.AComm)  AS ATotal,

							SUM(BA.AComm) ChildAComm,
							SUM(B.Actual_stake) as Actual_stake 
					FROM	#PAgent14 B				
					INNER JOIN AgentInfo C WITH (NOLOCK) --- Child direct (k+1)
							ON C.ParentID = @AgentID  				
					INNER JOIN Bettrans14_Agent BA WITH (NOLOCK) 
							ON  BA.TransID = B.TransID 
							AND C.AgentID = BA.AgentID ---- Child direct (k+1)
							AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
							AND BA.StatusID NOT IN (0,1)						
							AND BA.Bettype IN (Select bettype FROM #BettypeList)	
					INNER JOIN  Match14 m  WITH (NOLOCK) 
							ON m.MatchID = B.MatchID
					WHERE	(@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList))
					GROUP BY C.Username, C.AgentID, BA.TransID
			END						

		------------------------------------
		
		INSERT INTO #WinLossAgent
		SELECT	T.Username, T.AgentID, 1 as IsAgent,
				1 as Betcount, T.BetAmount, T.CommBase, 
				T.Winlost, T.PlayerComm, T.MemberTotal,
				T.AWinlost, T.AComm, T.ATotal, 
				 
				(1 - SUM (BA.APositionTaking)) * T.CommBase as DownlineEffStake,		
				SUM(BA.AWINLOST) + T.Winlost  + T.ChildAComm  AS GrossTotal,  
				
				((1 - SUM (BA.APositionTaking)) - T.APositionTaking) * T.CommBase as UplineEffStake,
				-(SUM(BA.AWINLOST) + T.Winlost + T.ChildAComm  + T.ATotal) AS UplineTotal
		FROM	#Tmp14 T
		INNER JOIN AgentInfo P with (nolock) ON  T.AgentID = P.AgentID
		INNER JOIN AgentInfo C WITH(NOLOCK) ON C.AgentHId.IsDescendantOf(P.AgentHId ) =1  AND C.AgentLevel >= P.AgentLevel  --- Children of k+1 (k+1 -> k+...)
		INNER JOIN Bettrans14_Agent BA WITH (NOLOCK) ON BA.AgentID = C.AgentID AND BA.TransID = T.TransID
		WHERE   BA.Winlostdate BETWEEN @FromDate AND @ToDate
				AND BA.StatusID NOT IN (0,1) 				 
				AND BA.Bettype <= 19000
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))					
		GROUP BY T.Username, T.AgentID, 
				T.TransID, T.BetAmount, T.CommBase, 
				T.Winlost, T.PlayerComm, T.MemberTotal,
				T.AWinlost, T.AComm, T.ATotal,T.ChildAComm , 
				T.APositionTaking,T.Actual_Stake
	  
		DELETE #Tmp14	
		DELETE #PAgent14	
	END


  
	------Parlay	
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29) OR @Bettypes = '0')
	BEGIN 
		INSERT INTO	#Tmp14
		SELECT  C.Username, C.AgentID, B.TransID,				
				SUM (BP.APositionTaking) as APositionTaking ,						 
		   		SUM(ABS(B.Stake)) AS BetAmount,
				SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END)  AS CommBase,
				SUM(B.Winlost - B.Actual_Stake) AS Winlost,	
				SUM(B.PlayerComm) as PlayerComm, 
				SUM(B.Winlost - B.Actual_Stake + B.PlayerComm) AS MemberTotal,

				SUM(BP.AWinlost) AS AWinlost,	
				SUM(BP.AComm) - SUM(BP.AComm) AS AComm,
				SUM(BP.AWinlost) + SUM (BP.AComm) - SUM (BP.AComm)  AS ATotal,

				SUM(BA.AComm) ChildAComm,
				SUM(B.Actual_stake) as Actual_stake 
					
		FROM	Bettrans14 B WITH (NOLOCK) 
				INNER JOIN Bettrans14_Agent BP WITH (NOLOCK) 
						ON BP.TransID = B.TransID 
						AND BP.AgentID = @AgentID ---Parent (k)
						AND BP.Winlostdate BETWEEN @FromDate AND @ToDate 
						AND BP.StatusID NOT IN (0,1)	
						AND BP.Bettype IN (9,29)
						AND (@Bettypes = '0' OR BP.Bettype IN (Select bettype FROM #BettypeList))

				INNER JOIN AgentInfo C WITH (NOLOCK) --- Child direct (k+1)
						ON C.ParentID = @AgentID  
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
				GROUP BY C.Username, C.AgentID, B.TransID
 
		--------------------------------
	
		INSERT INTO #WinLossAgent
		SELECT	T.Username, T.AgentID, 1 as IsAgent,
				1 as Betcount, T.BetAmount, T.CommBase, 
				T.Winlost, T.PlayerComm, T.MemberTotal,
				T.AWinlost, T.AComm, T.ATotal, 		
						
				(1-SUM (T.LinePositionTaking)) * T.CommBase as DownlineEffStake,
				SUM(T.LineWinLost)  + T.ChildAComm + T.Winlost  AS GrossTotal,		
				((1-SUM (T.LinePositionTaking)) - T.APositionTaking) * T.CommBase as UplineEffStake,
				-(SUM(T.LineWinLost)  + T.ChildAComm + T.Winlost + T.ATotal) AS UplineTotal
		FROM (	
			SELECT  T.Username, T.AgentID, T.APositionTaking, 
					T.TransID, T.BetAmount, T.CommBase, 
					T.Winlost, T.PlayerComm, T.MemberTotal,
					T.AWinlost, T.AComm, T.ATotal, T.ChildAComm, T.Actual_Stake,	
					BA.AWINLOST as LineWinLost,	BA.APositionTaking as LinePositionTaking	 		
			FROM #Tmp14 T
			INNER JOIN AgentInfo P with (nolock) ON  T.AgentID = P.AgentID
			INNER JOIN AgentInfo C WITH(NOLOCK) ON C.AgentHId.IsDescendantOf(P.AgentHId ) =1  AND C.AgentLevel >= P.AgentLevel  --- Children of k+1 (k+1 -> k+...)
			INNER JOIN Bettrans14_Agent BA WITH (NOLOCK) ON BA.AgentID = C.AgentID and BA.TransID = T.TransID
			WHERE	BA.Winlostdate BETWEEN @FromDate AND @ToDate
					AND BA.StatusID NOT IN (0,1) 				 
					AND BA.Bettype IN (9,29)
					AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList)) 
						
			) T
		GROUP BY	T.Username, T.AgentID, 
				   T.TransID, T.BetAmount, T.CommBase, 
					T.Winlost, T.PlayerComm, T.MemberTotal,
					T.AWinlost, T.AComm, T.ATotal, T.ChildAComm , 
					T.APositionTaking, T.Actual_Stake
	 
		DELETE #Tmp14 
	END

	-----Outright
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (10) OR @Bettypes = '0')
	BEGIN
		INSERT INTO	#Tmp14
		SELECT  C.Username, C.AgentID, B.TransID,
				SUM(BP.APositionTaking) as APositionTaking , 				 
		   		SUM(ABS(B.Stake)) AS BetAmount,
				SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END)  AS CommBase,
				
				SUM(B.Winlost - B.Actual_Stake) AS Winlost,	
				SUM(B.PlayerComm) AS PlayerComm,
				SUM(B.Winlost - B.Actual_Stake + B.PlayerComm)  AS MemberTotal,

				SUM(BP.AWinlost) AS AWinlost,	
				SUM(BP.AComm) - SUM(BA.AComm) AS AComm,
				SUM(BP.AWinlost) + SUM (BP.AComm) - SUM (BA.AComm)  AS ATotal,

			    SUM(BA.AComm) ChildAComm ,
				SUM(B.Actual_stake) as Actual_stake  
							
		FROM	Bettrans14 B WITH (NOLOCK) 
		INNER JOIN Bettrans14_Agent BP WITH (NOLOCK) 
				ON BP.TransID = B.TransID 
				AND BP.AgentID = @AgentID ---Parent (k)
				AND BP.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND BP.StatusID NOT IN (0,1)	
				AND BP.Bettype = 10
				AND (@Bettypes = '0' OR BP.Bettype IN (Select bettype FROM #BettypeList))
		INNER JOIN AgentInfo C WITH (NOLOCK) --- Child direct (k+1)
				ON C.ParentID = @AgentID	
		INNER JOIN Bettrans14_Agent BA WITH (NOLOCK) 
				ON BA.TransID = B.TransID 
				AND C.AgentID = BA.AgentID ---- Child direct (k+1)
				AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND BA.StatusID NOT IN (0,1)	
				AND BA.Bettype = 10
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))
		WHERE	B.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND B.StatusID NOT IN (0,1)	
				AND B.Bettype =10
				AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))
							
				--AND (@Sporttypes = '0' OR l.sporttype IN (Select sporttype FROM #SportsList))
				AND (@Sporttypes = '0' 
						OR EXISTS (	SELECT	1 
									FROM Outright14 m  WITH (NOLOCK) 									
									INNER JOIN  League l WITH (NOLOCK)
											ON	l.leagueID = m.leagueId
											AND (l.sporttype IN (Select sporttype FROM #SportsList))							
									WHERE	m.orid = B.MatchID
									)				
						)
		GROUP BY C.Username, C.AgentID, B.TransID
				 
		 
		INSERT INTO #WinLossAgent
		SELECT	T.Username, T.AgentID, 1 as IsAgent, 			 
				1 as Betcount, T.BetAmount, T.CommBase, 
				T.Winlost, T.PlayerComm, T.MemberTotal,
				T.AWinlost, T.AComm, T.ATotal, 
				(1-SUM (BA.APositionTaking)) * T.CommBase as DownlineEffStake,		
				SUM(BA.AWINLOST) + T.Winlost + T.ChildAComm  AS GrossTotal,  

				((1-SUM (BA.APositionTaking))  - T.APositionTaking) * T.CommBase as UplineEffStake,
				-(SUM(BA.AWINLOST) + T.Winlost  + T.ChildAComm  + T.ATotal) AS UplineTotal
				 
		FROM #Tmp14 T
		INNER JOIN AgentInfo P with (nolock) ON  T.AgentID = P.AgentID
		INNER JOIN AgentInfo C WITH(NOLOCK) ON C.AgentHId.IsDescendantOf(P.AgentHId ) =1  AND C.AgentLevel >= P.AgentLevel  --- Children of k+1 (k+1 -> k+...)
		INNER JOIN Bettrans14_Agent BA WITH (NOLOCK) ON BA.AgentID = C.AgentID AND BA.TransID = T.TransID
		WHERE	BA.Winlostdate BETWEEN @FromDate AND @ToDate
				AND BA.StatusID NOT IN (0,1) 				 
				AND BA.Bettype = 10
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))	
			
		GROUP BY T.Username, T.AgentID, 
				T.TransID, T.BetAmount, T.CommBase, 
				T.Winlost, T.PlayerComm, T.MemberTotal,
				T.AWinlost, T.AComm, T.ATotal,
				T.Actual_Stake, T.ChildAComm,  T.APositionTaking
	 	
		DELETE #Tmp14 
	END
	DROP TABLE #PAgent14 
	DROP TABLE #Tmp14 
END 
	
GO
GRANT EXECUTE ON [dbo].[Age_Rpt_WinLoss_AgentViewAgent] TO [aplweb]
GO   


