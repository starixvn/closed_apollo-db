USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Rpt_WinLoss_AgentViewCust]    Script Date: 2/25/2014 12:29:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Age_Rpt_WinLoss_AgentViewCust    Script Date: 10/23/2013 4:33:32 PM ******/
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
	   - 20130718@Sophia: Remove OutStanding
	   - 20130910@Sophia: revise Outright
	   - 20130924@Sophia: Change the formula of CommBase Parlay and Outright
	   - 20140225@Sophia: Check condition filter of parlay
	   - 20140226@Sophia: Get CommBase by function
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
			COUNT(B.TransID) BetCount,			
		   	SUM(ABS(B.Stake)) as BetAmount,
			--SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  as CommBase,
			SUM (CASE WHEN B.StatusID IN (112,113) THEN dbo.[F_GetCommBase] (B.Stake, B.Odds, B.Bettype, B.MOdds) ELSE 0 END) as CommBase,

			SUM (B.Winlost - B.Actual_Stake) as Winlost,
			SUM (B.PlayerComm) as PlayerComm,
			SUM (B.Winlost - B.Actual_Stake + B.PlayerComm) as MemberTotal,

			SUM(BA.AWinLost) as AWinlost,	
			SUM(BA.AComm) - SUM (B.PlayerComm) as AComm,
			SUM(BA.AWinLost) + SUM(BA.AComm) - SUM (B.PlayerComm) AS ATotal,

			0 as DownlineEffStake, 
			0 as GrossTotal,

			--SUM(CASE WHEN ABS(B.MOdds)<> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) = 0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END * (1-BA.APositionTaking))  as UplineEffStake,
			SUM(CASE WHEN B.StatusID IN (112,113) THEN dbo.[F_GetCommBase] (B.Stake, B.Odds, B.Bettype, B.MOdds) ELSE 0 END * (1-BA.APositionTaking))  as UplineEffStake,
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
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29)) OR (@Bettypes = '0' AND @Sporttypes = '0')
	INSERT INTO #WinLossMember  
	SELECT	'' as Username, 0 as AgentId, 0 as IsAgent,			
			COUNT(B.TransID) BetCount,	
		   	SUM(ABS(B.Stake)) as BetAmount,
			---SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END)  as CommBase,
			SUM (CASE WHEN B.StatusID IN (112,113) THEN dbo.[F_GetCommBase] (B.Stake, B.Odds, B.Bettype, B.MOdds) ELSE 0 END) as CommBase,

			SUM (B.Winlost - B.Actual_Stake) as Winlost,
			SUM (B.PlayerComm) as PlayerComm,
			SUM (B.Winlost - B.Actual_Stake + B.PlayerComm) as MemberTotal,

			SUM(BA.AWinLost) as AWinlost,	
			SUM(BA.AComm) - SUM (B.PlayerComm) as AComm,
			SUM(BA.AWinLost) + SUM(BA.AComm) - SUM (B.PlayerComm) AS ATotal,

			0 as DownlineEffStake, 
			0 as GrossTotal,

			--SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END * (1-BA.APositionTaking))  as UplineEffStake,	
			SUM(CASE WHEN B.StatusID IN (112,113) THEN dbo.[F_GetCommBase] (B.Stake, B.Odds, B.Bettype, B.MOdds) ELSE 0 END * (1-BA.APositionTaking))  as UplineEffStake,				
			
			-(SUM (B.Winlost - B.Actual_Stake ) + SUM(BA.AWinLost) + SUM(BA.AComm)) UplineTotal	
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

			--AND (@Sporttypes = '0' 
			--		OR EXISTS (	SELECT	1 
			--					FROM	BettransM BM WITH (NOLOCK, index=IX_RefNo) 
			--					INNER JOIN Match M WITH (NOLOCK) 
			--						ON	 M.matchID = BM.MatchId 
			--						AND (M.sporttype IN (Select sporttype FROM #SportsList))							
			--					WHERE	BM.RefNo = B.RefNo
			--					)
			--		)


	-----Outright
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (10) OR @Bettypes = '0')
	INSERT INTO #WinLossMember  
	SELECT	'' as Username, 0 as AgentId, 0 as IsAgent,
			COUNT(B.TransID) BetCount,			
		   	SUM(ABS(B.Stake)) as BetAmount,
			--SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END)  as CommBase,
			SUM (CASE WHEN B.StatusID IN (112,113) THEN dbo.[F_GetCommBase] (B.Stake, B.Odds, B.Bettype, B.MOdds) ELSE 0 END) as CommBase,
			
			SUM (B.Winlost - B.Actual_Stake) as Winlost,
			SUM (B.PlayerComm) as PlayerComm,
			SUM (B.Winlost - B.Actual_Stake + B.PlayerComm) as MemberTotal,

			SUM(BA.AWinLost) as AWinlost,	
			SUM(BA.AComm) - SUM (B.PlayerComm) as AComm,
			SUM(BA.AWinLost) + SUM(BA.AComm) - SUM (B.PlayerComm) AS ATotal,

			0 as DownlineEffStake, 
			0 as GrossTotal,

			--SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END * (1-BA.APositionTaking))  as UplineEffStake,
			SUM(CASE WHEN B.StatusID IN (112,113) THEN dbo.[F_GetCommBase] (B.Stake, B.Odds, B.Bettype, B.MOdds) ELSE 0 END * (1-BA.APositionTaking))  as UplineEffStake,
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
	WHERE   B.Winlostdate BETWEEN @FromDate AND @ToDate 
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

END
 

 
	 
------------------------------------------------DATA [14] ----------------------------------------------
  IF @FromDate <= @MoveBetDay 
	 BEGIN
		DECLARE @tmpdate DATE  

		IF @FromDate < @BalanceUpDay 
			SET @tmpdate = @BalanceUpDay
		ELSE 
			SET @tmpdate = @FromDate
  	


		INSERT INTO #WinLossMember
		SELECT '' as Username, 0 as AgentId, 0 as IsAgent,				
				SUM(BetCount) as BetCount, 
				SUM(BetAmount) as BetAmount,		  
				SUM(CommBase) as CommBase,				
				
				SUM(Winlost) as WinLost,
				SUM(PlayerComm) as PlayerComm,
				SUM(Winlost) + SUM(PlayerComm) AS MemberTotal,	
					
				SUM(UplineWinlost) as AWinlost,
				SUM(UplineComm - PlayerComm) as AComm,
				SUM(UplineWinlost) + SUM(UplineComm - PlayerComm) AS ATotal,

				0 as DownlineEffStake,
				0 as GrossTotal,

				SUM(UplineEffStake) as UplineEffStake, 				 
				- (SUM(WinLost + PlayerComm) + SUM(UplineWinlost) + SUM(UplineComm - PlayerComm))as UplineTotal
	    FROM	Sum_WinLoss_Cust A WITH(NOLOCK)		
		WHERE	AgentId = @AgentId 
				AND WinLostDate BETWEEN @tmpdate AND @ToDate 
				AND (@Sporttypes = '0' OR A.sporttype IN (Select sporttype FROM #SportsList))
				AND (@Bettypes = '0' OR A.Bettype IN (Select bettype FROM #BettypeList))		 
 
 END
  
	
------------------------------------------------DATA [BK] ----------------------------------------------
	
IF @FromDate < @BalanceUpDay 
 BEGIN    	
		IF @todate >= DATEADD(dd, -1, @BalanceUpDay)
		SELECT @ToDate = DATEADD(dd, -1, @BalanceUpDay)

		INSERT INTO #WinLossMember
		SELECT '' as Username, 0 as AgentId, 0 as IsAgent,				
				SUM(BetCount) as BetCount, 
				SUM(BetAmount) as BetAmount,		  
				SUM(CommBase) as CommBase,				
				
				SUM(Winlost) as WinLost,
				SUM(PlayerComm) as PlayerComm,
				SUM(Winlost) + SUM(PlayerComm) AS MemberTotal,	
					
				SUM(UplineWinlost) as AWinlost,
				SUM(UplineComm - PlayerComm) as AComm,
				SUM(UplineWinlost) + SUM(UplineComm - PlayerComm) AS ATotal,
				
				0 as DownlineEffStake,
				0 as GrossTotal,

				SUM(UplineEffStake) as UplineEffStake, 				 
				- (SUM(WinLost + PlayerComm) + SUM(UplineWinlost) + SUM(UplineComm - PlayerComm))as UplineTotal
	    FROM	SummaryDB.dbo.Sum_WinLoss_Cust_Old A WITH(NOLOCK)		
		WHERE	AgentId = @AgentId 
				AND WinLostDate BETWEEN @FromDate AND @ToDate 
				AND (@Sporttypes = '0' OR A.sporttype IN (Select sporttype FROM #SportsList))
				AND (@Bettypes = '0' OR A.Bettype IN (Select bettype FROM #BettypeList))		 
 
 END
 
GO
GRANT EXECUTE ON [dbo].[Age_Rpt_WinLoss_AgentViewCust] TO [aplweb]
 GO
