CREATE  PROCEDURE [dbo].[Age_Rpt_WinLoss_SuperViewAgent]
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
    */
    
SET NOCOUNT ON

IF @Todate > @MoveBetDay
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
				
					AND (@Sporttypes = '0' OR l.sporttype IN (Select sporttype FROM #SportsList))
		GROUP BY	C.Username, C.AgentID, PT.MaxUpperPositionTaking


	END
	

------------------------------------------------DATA [14] ----------------------------------------------

IF @FromDate <= @MoveBetDay 
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
				
					AND (@Sporttypes = '0' OR l.sporttype IN (Select sporttype FROM #SportsList))
		GROUP BY	C.Username, C.AgentID, PT.MaxUpperPositionTaking


	END
	 

GO
GRANT EXECUTE ON [dbo].[Age_Rpt_WinLoss_SuperViewAgent] TO [aplweb]
GO   



