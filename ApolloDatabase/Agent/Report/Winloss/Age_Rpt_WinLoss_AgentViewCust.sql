ALTER PROCEDURE [dbo].[Age_Rpt_WinLoss_AgentViewCust]
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
    Task	: Report Agent Winloss
    DB		: SVRAGE.RepDB
    Original SP:[Age_Rpt_WinLoss_Ag]
    

    Revisions: 

    */
    
SET NOCOUNT ON


IF @Todate > @MoveBetDay
BEGIN  
	 

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
			SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END *BA.APositionTaking)  as ActualTOAfter,
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
			SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END * B.APositionTaking)  as ActualTOAfter,
			SUM(B.AWinLost) as AWinlost,	
			SUM(B.AComm) - SUM (B.PlayerComm) as AComm,
			SUM(B.AWinLost) + SUM(B.AComm) - SUM (B.PlayerComm) AS ATotal,
			SUM (B.Winlost - B.Actual_Stake + B.PlayerComm) GrossTotal,
			-(SUM (B.Winlost - B.Actual_Stake ) + SUM(B.AWinLost) + SUM(B.AComm)) UplineTotal
	FROM (
			SELECT DISTINCT 
					COUNT(B.TransID) BetCount,	   			
					B.MOdds,B.StatusID,	BA.AWinLost, BA.AComm, BA.APositionTaking,
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
			GROUP BY B.MOdds,B.StatusID,	BA.AWinLost, BA.AComm,APositionTaking,
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
			SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END * BA.APositionTaking)  as ActualTOAtter,
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
			
	INNER JOIN CustInfo C WITH (NOLOCK)
		ON	B.CustID = C.CustID AND C.AgentId = @AgentID
	INNER JOIN  Outright m WITH (NOLOCK) 
		ON  m.orid = B.MatchID
	INNER JOIN  League l WITH (NOLOCK)
		ON	l.leagueID = m.leagueId
	WHERE   B.Winlostdate BETWEEN @FromDate AND @ToDate 
			AND B.StatusID NOT IN (0,1)
			AND B.Bettype = 10
			AND (@Sporttypes = '0' OR l.sporttype IN (Select sporttype FROM #SportsList))

END
 

------------------------------------------------DATA [14] ----------------------------------------------

IF @FromDate <= @MoveBetDay 
BEGIN  
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
			SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END * BA.APositionTaking)  as ActualTOAtter,
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
			SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END * B.APositionTaking)  as ActualTOAtter,
			SUM(B.AWinLost) as AWinlost,	
			SUM(B.AComm) - SUM (B.PlayerComm) as AComm,
			SUM(B.AWinLost) + SUM(B.AComm) - SUM (B.PlayerComm) AS ATotal,
			SUM (B.Winlost - B.Actual_Stake + B.PlayerComm) GrossTotal,
			-(SUM (B.Winlost - B.Actual_Stake ) + SUM(B.AWinLost) + SUM(B.AComm)) UplineTotal
	FROM (
			SELECT DISTINCT 
					COUNT(B.TransID) BetCount,	   			
					B.MOdds,B.StatusID,	BA.AWinLost, BA.AComm,BA.APositionTaking, 
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
			GROUP BY B.MOdds,B.StatusID,	BA.AWinLost, BA.AComm,BA.APositionTaking, 
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
			SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END * BA.APositionTaking)  as ActualTOAtter,
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
	INNER JOIN CustInfo C WITH (NOLOCK)
		ON	B.CustID = C.CustID AND C.AgentId = @AgentID
	INNER JOIN  Outright14 m WITH (NOLOCK) 
		ON  m.orid = B.MatchID
	INNER JOIN  League l WITH (NOLOCK)
		ON	l.leagueID = m.leagueId
	WHERE   B.Winlostdate BETWEEN @FromDate AND @ToDate 
			AND B.StatusID NOT IN (0,1)
			AND B.Bettype = 10
			AND (@Sporttypes = '0' OR l.sporttype IN (Select sporttype FROM #SportsList))
END

GO
GRANT EXECUTE ON [dbo].[Age_Rpt_WinLoss_AgentViewCust] TO [aplweb]
GO 