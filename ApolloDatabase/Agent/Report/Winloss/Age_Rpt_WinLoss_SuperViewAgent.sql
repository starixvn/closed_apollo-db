ALTER  PROCEDURE [dbo].[Age_Rpt_WinLoss_SuperViewAgent]
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
    Task	: Report Agent Winloss (SuperView)
    DB		: SVRAGE.RepDB
    Original SP:[Age_Rpt_WinLoss_Ag]
   

    Revisions: 
		- 20130924@Sophia: .Use link server to call table AgentPositionTaking
						   .Change the formula of CommBase Parlay and Outright
		- 20130925@Sophia: Change to way to get Share

    */
    
SET NOCOUNT ON

IF @Todate >= @BalanceUpDay
BEGIN  
	
	--********************************
	----Super view
	--********************************
		
		IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10) OR @Bettypes = '0')
		----Sportsbook
		INSERT INTO #WinLossAgent
		SELECT  C.Username, C.AgentID, 1 as IsAgent,
				COUNT(B.TransID) BetCount,			
		   		SUM(ABS(B.Stake)) AS BetAmount,
				SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS CommBase,				
				SUM (B.WinLost - B.Actual_Stake) as Winlost,
				SUM (B.PlayerComm) as PlayerComm,
				SUM (B.WinLost - B.Actual_Stake+ B.PlayerComm) as MemberTotal,

				- SUM(B.Winlost - B.Actual_Stake + B.TWinlost) AS AWinlost,	
				- SUM (B.TComm) AS AComm,
				- (SUM(B.Winlost - B.Actual_Stake + B.TWinlost) + SUM (B.TComm)) AS ATotal,

				SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END * (1-B.TPositionTaking))  AS DownlineEffStake , 
				(SUM(B.Winlost - B.Actual_Stake + B.TWinlost) + SUM (B.TComm)) AS GrossTotal,
											
				0 AS UplineEffStake ,
				0 AS UplineTotal
			
		FROM		AgentInfo C WITH (NOLOCK)
		INNER JOIN	BetTrans_Agent BA WITH (NOLOCK)
				ON	BA.AgentID = C.AgentID
					AND BA.Winlostdate BETWEEN @FromDate AND @ToDate
					AND BA.StatusID NOT IN (0,1)
					AND BA.Bettype <=19000 AND BA.bettype NOT IN (9,29,10)
					AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))							
		INNER JOIN	Bettrans B WITH (NOLOCK) 
				ON	B.TransID = BA.TransID			
		WHERE		C.ParentId = @AgentID 
					AND B.Winlostdate BETWEEN @FromDate AND @ToDate
					AND B.StatusID NOT IN (0,1)
					AND B.Bettype <=19000 AND B.bettype NOT IN (9,29,10)
					AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))					
					
					AND (@Sporttypes = '0' 
						 OR EXISTS ( SELECT 1 FROM match (NOLOCK) 
									 WHERE matchid = b.matchid AND sporttype IN (SELECT sporttype FROM #SportsList)
									)
						)	 
		GROUP BY	C.Username, C.AgentID


		----Parlay
		IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29) OR @Bettypes = '0')
		INSERT INTO #WinLossAgent
		SELECT  C.Username, C.AgentID, 1 as IsAgent,			
				COUNT(B.TransID) BetCount,		
		   		SUM(ABS(B.Stake)) AS BetAmount,
				SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END)  AS CommBase,				
				SUM (B.WinLost - B.Actual_Stake) as Winlost,
				SUM (B.PlayerComm) as PlayerComm,
				SUM (B.WinLost - B.Actual_Stake+ B.PlayerComm) as MemberTotal,

				- SUM(B.Winlost - B.Actual_Stake + B.TWinlost) AS AWinlost,	
				- SUM (B.TComm) AS AComm,
				- (SUM(B.Winlost - B.Actual_Stake + B.TWinlost) + SUM (B.TComm)) AS ATotal,

				SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END * (1-B.TPositionTaking))  AS DownlineEffStake , 
				(SUM(B.Winlost - B.Actual_Stake + B.TWinlost) + SUM (B.TComm)) AS GrossTotal,
											
				0 AS UplineEffStake ,
				0 AS UplineTotal
		FROM	AgentInfo C WITH (NOLOCK)
		INNER JOIN	BetTrans_Agent BA WITH (NOLOCK)
				ON	BA.AgentID = C.AgentID	
					AND BA.Winlostdate BETWEEN @FromDate AND @ToDate
					AND BA.StatusID NOT IN (0,1)
					AND BA.Bettype IN (9,29)
					AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))								
		INNER JOIN	Bettrans B WITH (NOLOCK) 
				ON	B.TransID = BA.TransID
		WHERE		C.ParentId = @AgentID 
				AND B.Winlostdate BETWEEN @FromDate AND @ToDate
				AND B.StatusID NOT IN (0,1)
				AND B.Bettype IN (9,29)
				AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))						
				
				-------- Parlay not to care Sporttype, it means All Sports
				--AND (@Sporttypes = '0' 
				--OR EXISTS (	SELECT	1 
				--			FROM	BettransM BM WITH (NOLOCK, index=IX_RefNo) 
				--			INNER JOIN Match M WITH (NOLOCK) 
				--				ON	 M.matchID = BM.MatchId 
				--				AND (M.sporttype IN (Select sporttype FROM #SportsList))							
				--			WHERE	BM.RefNo = B.RefNo
				--			)				
				--		)	
		GROUP BY	C.Username, C.AgentID

	
	----Outright
		IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (10) OR @Bettypes = '0')
		INSERT INTO #WinLossAgent
		SELECT  C.Username, C.AgentID, 1 as IsAgent,				
				COUNT(B.TransID) BetCount,			
		   		SUM(ABS(B.Stake)) AS BetAmount,
				SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END)  AS CommBase,
				SUM (B.WinLost - B.Actual_Stake) as Winlost,
				SUM (B.PlayerComm) as PlayerComm,
				SUM (B.WinLost - B.Actual_Stake+ B.PlayerComm) as MemberTotal,

				- SUM(B.Winlost - B.Actual_Stake + B.TWinlost) AS AWinlost,	
				- SUM (B.TComm) AS AComm,
				- (SUM(B.Winlost - B.Actual_Stake + B.TWinlost) + SUM (B.TComm)) AS ATotal,

				SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END * (1-B.TPositionTaking))  AS DownlineEffStake , 
				(SUM(B.Winlost - B.Actual_Stake + B.TWinlost) + SUM (B.TComm)) AS GrossTotal,
											
				0 AS UplineEffStake ,
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
		WHERE		C.ParentId = @AgentID 
					AND B.Winlostdate BETWEEN @FromDate AND @ToDate
					AND B.StatusID NOT IN (0,1)
					AND B.Bettype = 10				
					AND (@Sporttypes = '0' 
						OR EXISTS (	SELECT	1 
									FROM Outright m  WITH (NOLOCK) 									
									INNER JOIN  League l WITH (NOLOCK)
											ON	l.leagueID = m.leagueId
											AND (l.sporttype IN (Select sporttype FROM #SportsList))							
									WHERE	m.orid = B.MatchID
									)				
						)
		GROUP BY	C.Username, C.AgentID


	
------------------------------------------------DATA [14] ----------------------------------------------

	 --if this case occurs then there is no data from sum_winloss_old      	
		INSERT INTO #WinLossAgent
	    SELECT	A.AgentUsername as Username, A.AgentId, 1 as IsAgent,		
				SUM(BetCount) as BetCount, 
				SUm(BetAmount) as BetAmount,		  
				SUM(CommBase) as CommBase,				
				
				SUM(Winlost) as WinLost,
				SUM(PlayerComm) as PlayerComm,
				SUM(Winlost) + SUM(PlayerComm) AS MemberTotal,	

				SUM(UplineWinlost) as AWinLost,
				SUM(UplineComm - AComm) as AComm,
				SUM(UplineWinlost) + SUM(UplineComm) AS ATotal,
				
				SUM(DownlineEffStake) as DownlineEffStake,
				SUM(GrossTotal) as GrossTotal,
				0 as UplineEffStake,
				0 as UplineTotal

	    FROM	Sum_WinLoss_Agent A WITH(NOLOCK)		
		WHERE	ParentID = @AgentId 
				AND WinLostDate BETWEEN @FromDate AND @ToDate 
				AND (@Sporttypes = '0' OR A.sporttype IN (Select sporttype FROM #SportsList))
				AND (@Bettypes = '0' OR A.Bettype IN (Select bettype FROM #BettypeList))		 
	    GROUP BY AgentUsername, A.AgentId

END 
------------------------------------------------DATA [BK] ----------------------------------------------
	
IF @FromDate < @BalanceUpDay --if this case occurs then there is no data from sum_winloss_old
 BEGIN    	
		IF @todate >= DATEADD(dd, -1, @BalanceUpDay)
		SELECT @ToDate = DATEADD(dd, -1, @BalanceUpDay)

		INSERT INTO #WinLossAgent
	    SELECT	A.AgentUsername as Username, A.AgentId, 1 as IsAgent,		
				SUM(BetCount) as BetCount, 
				SUm(BetAmount) as BetAmount,		  
				SUM(CommBase) as CommBase,				
				
				SUM(Winlost) as WinLost,
				SUM(PlayerComm) as PlayerComm,
				SUM(Winlost) + SUM(PlayerComm) AS MemberTotal,	

				SUM(UplineWinlost) as AWinLost,
				SUM(UplineComm - AComm) as AComm,
				SUM(UplineWinlost) + SUM(UplineComm) AS ATotal,
								
				SUM(DownlineEffStake) as DownlineEffStake,
				SUM(GrossTotal) as GrossTotal,
				0 as UplineEffStake,
				0 as UplineTotal
	    FROM	SummaryDB.dbo.Sum_WinLoss_Agent_Old A WITH(NOLOCK)		
		WHERE	ParentID = @AgentId 
				AND WinLostDate BETWEEN @FromDate AND @ToDate 
				AND (@Sporttypes = '0' OR A.sporttype IN (Select sporttype FROM #SportsList))
				AND (@Bettypes = '0' OR A.Bettype IN (Select bettype FROM #BettypeList))	
	    GROUP BY AgentUsername, A.AgentId

	END 

GO
GRANT EXECUTE ON [dbo].[Age_Rpt_WinLoss_SuperViewAgent] TO [aplweb]
GO   
 