ALTER PROCEDURE [dbo].[Age_Rpt_WinLoss_Member]
	@AgentID 	INT,
	@FromDate 	DATE,
	@ToDate 	DATE,
	@MovebetDay DATE,	
	@BalanceUpDay DATE,
	@Sporttypes VARCHAR(MAX) = '0',
	@Bettypes VARCHAR(MAX) = '0' 		
as
 /*
    Created: Sophia
	Date: 20130401
    Task : Members detail of Report Agent Winloss
    DB: SVRAGE.RepDB
    Original: Age_Rpt_WinLoss_Ag
    Revisions:
		- 20130627@Sophia: Modify for Singbet: filter by Sporttype and Bettype
		- 20130712@Sophia: add OutStanding
		- 20130726@Sophia: Add ActualTOAfter (Effective Stake)
		- 20130924@Sophia: .Use link server to call table AgentCustPositionTaking
						   .Change the formula of CommBase Parlay and Outright


	EX:  EXEC Age_Rpt_WinLoss_Member @AgentId =3, @FromDate = '2013-01-01',  @ToDate = '2013-04-10', @BalanceUpDay = '2013-03-01'

       
    */
    
SET NOCOUNT ON

 CREATE TABLE #WinLossMember ( Username NVARCHAR(50), CustId INT, BetCount BIGINT, BetAmount MONEY, CommBase MONEY,  
							   Winlost MONEY, PlayerComm MONEY, MemberTotal MONEY, AWinLost MONEY, AComm MONEY, ATotal MONEY, UplineEffStake MONEY, UplineTotal MONEY)


CREATE TABLE #BettypeList (bettype SMALLINT)
INSERT INTO #BettypeList
SELECT val FROM dbo.strSplit_Key(@Bettypes,',')

CREATE TABLE #SportsList (Sporttype TINYINT)
INSERT INTO #SportsList (Sporttype)
SELECT val FROM strSplit_key (@Sporttypes, ',')

IF @Todate > @MovebetDay
BEGIN 
		IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10) OR @Bettypes = '0')
		INSERT INTO #WinLossMember
	    SELECT  C.Username,
				C.CustID, 
				COUNT(B.TransID) as BetCount,
		   		SUM(ABS(B.Stake)) AS BetAmount,
				SUM(CASE WHEN ABS(B.MOdds)<> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) = 0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  as CommBase,
				
				SUM(B.WinLost - B.Actual_Stake) AS WinLost,
				SUM(B.PlayerComm) AS PlayerComm,
				SUM(B.WinLost - B.Actual_Stake) + SUM(B.PlayerComm) AS MemberTotal,
				
				SUM(BA.AWinLost) AS AWinLost,	
				SUM(BA.AComm) - SUM (B.PlayerComm) AS AComm,
				SUM(BA.AWinLost) + SUM(BA.AComm) - SUM (B.PlayerComm) AS ATotal,

				SUM(CASE WHEN ABS(B.MOdds)<> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) = 0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END * (1-BA.APositionTaking))  as UplineEffStake,
				- (SUM(B.WinLost - B.Actual_Stake+ B.PlayerComm)  + SUM(BA.AWinLost) + SUM(BA.AComm - B.PlayerComm)) AS UplineTotal
		FROM		Bettrans B WITH (NOLOCK)
		INNER JOIN	BetTrans_Agent BA WITH (NOLOCK)
				ON	BA.TransID = B.TransID
				AND BA.AgentId = @AgentID
				AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND BA.StatusID NOT IN (0,1)	
				AND BA.bettype <= 19000
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))
		INNER JOIN	CustInfo C WITH (NOLOCK)
				ON	B.CustID = C.CustID AND  C.AgentId = @AgentID		
		WHERE   B.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND B.StatusID NOT IN (0,1)	
				AND B.bettype <= 19000
				AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))
				AND (@Sporttypes = '0' 
					 OR EXISTS (SELECT 1 FROM match (nolock) 
								 WHERE matchid=b.matchid AND sporttype IN (Select sporttype FROM #SportsList)
								)
					)
		GROUP BY C.Username, C.CustID

	----Parlay
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29) OR @Bettypes = '0')
	 INSERT INTO #WinLossMember
	 SELECT		B.Username,
				B.CustID,

				COUNT(B.TransID) as BetCount,
		   		SUM(ABS(B.Stake)) AS BetAmount,
				SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END)  as CommBase,
				
				SUM(B.WinLost - B.Actual_Stake) AS WinLost,
				SUM(B.PlayerComm) AS PlayerComm,
				SUM(B.WinLost - B.Actual_Stake) + SUM(B.PlayerComm) AS MemberTotal,
				
				SUM(B.AWinLost) AS AWinLost,	
				SUM(B.AComm) - SUM (B.PlayerComm) AS AComm,
				SUM(B.AWinLost) + SUM(B.AComm) - SUM (B.PlayerComm) AS ATotal,

				SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END * (1-B.APositionTaking))  as UplineEffStake,
				- (SUM(B.WinLost - B.Actual_Stake+ B.PlayerComm)  + SUM(B.AWinLost) + SUM(B.AComm - B.PlayerComm)) AS UplineTotal

		FROM	(
				SELECT 	DISTINCT C.Username,
						C.CustID, 
						COUNT(DISTINCT B.TransID) as BetCount,
		   				B.Stake, B.MOdds, B.StatusID,
						B.WinLost , B.Actual_Stake,	B.PlayerComm,	
						BA.AWinLost, BA.AComm, B.TransID, BA.APositionTaking
				FROM		Bettrans B WITH (NOLOCK)
				INNER JOIN	BetTrans_Agent BA WITH (NOLOCK)
						ON	BA.TransID = B.TransID
						AND BA.AgentId = @AgentID
						AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
						AND BA.StatusID NOT IN (0,1)	
						AND BA.bettype IN (9,29)
						AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))	
				INNER JOIN	CustInfo C WITH (NOLOCK)
						ON	B.CustID = C.CustID AND  C.AgentId = @AgentID				
				WHERE	 B.Winlostdate BETWEEN @FromDate AND @ToDate 
						AND B.StatusID NOT IN (0,1)	
						AND B.bettype IN (9,29)
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

				GROUP BY	C.Username,C.CustID,			
		   					B.Stake, B.MOdds, B.StatusID,
							B.WinLost , B.Actual_Stake,	B.PlayerComm,	
							BA.AWinLost, BA.AComm, B.TransID, BA.APositionTaking
				) B
		GROUP BY B.Username,B.CustID

----- Outright
	 IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype  IN ( 10) OR @Bettypes = '0')
	 INSERT INTO #WinLossMember
	 SELECT  C.Username,
				C.CustID,				
				COUNT(B.TransID) as BetCount,
		   		SUM(ABS(B.Stake)) AS BetAmount,
				SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END)  as CommBase,
				
				SUM(B.WinLost - B.Actual_Stake) AS WinLost,
				SUM(B.PlayerComm) AS PlayerComm,
				SUM(B.WinLost - B.Actual_Stake) + SUM(B.PlayerComm) AS MemberTotal,
				
				SUM(BA.AWinLost) AS AWinLost,	
				SUM(BA.AComm) - SUM (B.PlayerComm) AS AComm,
				SUM(BA.AWinLost) + SUM(BA.AComm) - SUM (B.PlayerComm) AS ATotal,

				SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END * (1-BA.APositionTaking))  as UplineEffStake,
				- (SUM(B.WinLost - B.Actual_Stake+ B.PlayerComm)  + SUM(BA.AWinLost) + SUM(BA.AComm - B.PlayerComm)) AS UplineTotal
		FROM		Bettrans B WITH (NOLOCK)
		INNER JOIN	BetTrans_Agent BA WITH (NOLOCK)
				ON	BA.TransID = B.TransID
				AND BA.AgentId = @AgentID
				AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND BA.StatusID NOT IN (0,1)	
				AND BA.bettype =10
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))
		INNER JOIN	CustInfo C WITH (NOLOCK)
				ON	B.CustID = C.CustID AND  C.AgentId = @AgentID	
		WHERE	B.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND B.StatusID NOT IN (0,1)	
				AND B.bettype =10
				AND (@Sporttypes = '0' 
						OR EXISTS (	SELECT	1 
									FROM Outright m  WITH (NOLOCK) 									
									INNER JOIN  League l WITH (NOLOCK)
											ON	l.leagueID = m.leagueId
											AND (l.sporttype IN (Select sporttype FROM #SportsList))							
									WHERE	m.orid = B.MatchID
									)				
						)

		GROUP BY C.Username, C.CustID
	 
END

--##############################################
IF @FromDate <= @MovebetDay 
BEGIN 
		IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10) OR @Bettypes = '0')
		INSERT INTO #WinLossMember
	    SELECT  C.Username,
				C.CustID,
				COUNT(B.TransID) as BetCount,
		   		SUM(ABS(B.Stake)) AS BetAmount,
				SUM(CASE WHEN ABS(B.MOdds)<> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) = 0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  as CommBase,
				
				SUM(B.WinLost - B.Actual_Stake) AS WinLost,
				SUM(B.PlayerComm) AS PlayerComm,
				SUM(B.WinLost - B.Actual_Stake) + SUM(B.PlayerComm) AS MemberTotal,
				
				SUM(BA.AWinLost) AS AWinLost,	
				SUM(BA.AComm) - SUM (B.PlayerComm) AS AComm,
				SUM(BA.AWinLost) + SUM(BA.AComm) - SUM (B.PlayerComm) AS ATotal,

				SUM(CASE WHEN ABS(B.MOdds)<> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) = 0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END * (1-BA.APositionTaking))   as UplineEffStake,
				- (SUM(B.WinLost - B.Actual_Stake+ B.PlayerComm)  + SUM(BA.AWinLost) + SUM(BA.AComm - B.PlayerComm)) AS UplineTotal
		FROM		Bettrans14 B WITH (NOLOCK)
		INNER JOIN	BetTrans14_Agent BA WITH (NOLOCK)
				ON	BA.TransID = B.TransID
				AND BA.AgentId = @AgentID
				AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND BA.StatusID NOT IN (0,1)	
				AND BA.bettype <= 19000
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))
		INNER JOIN	CustInfo C WITH (NOLOCK)
				ON	B.CustID = C.CustID AND  C.AgentId = @AgentID	
		WHERE   B.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND B.StatusID NOT IN (0,1)	
				AND B.bettype <= 19000
				AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))
				
				AND (@Sporttypes = '0' 
					OR EXISTS (SELECT 1 FROM match14 (NOLOCK) 
								WHERE matchid=b.matchid AND sporttype IN (SELECT sporttype FROM #SportsList)
								)
					)

		GROUP BY C.Username, C.CustID

	----Parlay
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29) OR @Bettypes = '0')
	 INSERT INTO #WinLossMember
	 SELECT		B.Username,
				B.CustID,
				COUNT(B.TransID) as BetCount,
		   		SUM(ABS(B.Stake)) AS BetAmount,
				SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END)  as CommBase,
				
				SUM(B.WinLost - B.Actual_Stake) AS WinLost,
				SUM(B.PlayerComm) AS PlayerComm,
				SUM(B.WinLost - B.Actual_Stake) + SUM(B.PlayerComm) AS MemberTotal,
				
				SUM(B.AWinLost) AS AWinLost,	
				SUM(B.AComm) - SUM (B.PlayerComm) AS AComm,
				SUM(B.AWinLost) + SUM(B.AComm) - SUM (B.PlayerComm) AS ATotal,

				SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END * (1-B.APositionTaking))  as UplineEffStake,
				- (SUM(B.WinLost - B.Actual_Stake+ B.PlayerComm)  + SUM(B.AWinLost) + SUM(B.AComm - B.PlayerComm)) AS UplineTotal

		FROM	(
				SELECT 	DISTINCT C.Username,
						C.CustID,
						COUNT(DISTINCT B.TransID) as BetCount,
		   				B.Stake, B.MOdds, B.StatusID,
						B.WinLost , B.Actual_Stake,	B.PlayerComm,	
						BA.AWinLost, BA.AComm, B.TransID, BA.APositionTaking
				FROM		Bettrans14 B WITH (NOLOCK)
				INNER JOIN	BetTrans14_Agent BA WITH (NOLOCK)
						ON	BA.TransID = B.TransID
						AND BA.AgentId = @AgentID
						AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
						AND BA.StatusID NOT IN (0,1)	
						AND BA.bettype IN (9,29)
						AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))	
				INNER JOIN	CustInfo C WITH (NOLOCK)
						ON	B.CustID = C.CustID AND  C.AgentId = @AgentID				
				WHERE	 B.Winlostdate BETWEEN @FromDate AND @ToDate 
						AND B.StatusID NOT IN (0,1)	
						AND B.bettype IN (9,29)
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

				GROUP BY	C.Username,C.CustID,		
		   					B.Stake, B.MOdds, B.StatusID,
							B.WinLost , B.Actual_Stake,	B.PlayerComm,	
							BA.AWinLost, BA.AComm, B.TransID, BA.APositionTaking
				) B
		GROUP BY B.Username,B.CustID

----- Outright14
	 IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype  IN ( 10) OR @Bettypes = '0')
	 INSERT INTO #WinLossMember
	 SELECT  C.Username,
				C.CustID,
				COUNT(B.TransID) as BetCount,
		   		SUM(ABS(B.Stake)) AS BetAmount,
				SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END)  as CommBase,
				
				SUM(B.WinLost - B.Actual_Stake) AS WinLost,
				SUM(B.PlayerComm) AS PlayerComm,
				SUM(B.WinLost - B.Actual_Stake) + SUM(B.PlayerComm) AS MemberTotal,
				
				SUM(BA.AWinLost) AS AWinLost,	
				SUM(BA.AComm) - SUM (B.PlayerComm) AS AComm,
				SUM(BA.AWinLost) + SUM(BA.AComm) - SUM (B.PlayerComm) AS ATotal,

				SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END * (1-BA.APositionTaking))  as UplineEffStake,
				- (SUM(B.WinLost - B.Actual_Stake+ B.PlayerComm)  + SUM(BA.AWinLost) + SUM(BA.AComm - B.PlayerComm)) AS UplineTotal
		FROM		Bettrans14 B WITH (NOLOCK)
		INNER JOIN	BetTrans14_Agent BA WITH (NOLOCK)
				ON	BA.TransID = B.TransID
				AND BA.AgentId = @AgentID
				AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND BA.StatusID NOT IN (0,1)	
				AND BA.bettype =10
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))
		INNER JOIN	CustInfo C WITH (NOLOCK)
				ON	B.CustID = C.CustID AND  C.AgentId = @AgentID	
		WHERE	B.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND B.StatusID NOT IN (0,1)	
				AND B.bettype =10
				AND (@Sporttypes = '0' 
						OR EXISTS (	SELECT	1 
									FROM Outright14 m  WITH (NOLOCK) 									
									INNER JOIN  League l WITH (NOLOCK)
											ON	l.leagueID = m.leagueId
											AND (l.sporttype IN (Select sporttype FROM #SportsList))							
									WHERE	m.orid = B.MatchID
									)				
						)

		GROUP BY C.Username, C.CustID
 	    
	 
END
--############################################# Outstanding Section ##############################################

CREATE TABLE #MemberOutstanding (Username NVARCHAR(50), CustID INT, OutstandingAmount MONEY, OutstandingShareAmount MONEY)


-----Member Outstanding
-- Sportsbook
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10) OR @Bettypes = '0')
	INSERT INTO #MemberOutstanding
	SELECT  C.Username, B.CustID, 
			ISNULL(SUM(ABS(BA.actual_stake)),0) OutstandingAmount,  
			ISNULL(SUM(ABS(BA.actual_stake) * BA.APositiontaking),0) OutstandingShareAmount
	FROM	bettrans B WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK)
		ON	BA.TransID = B.TransID AND BA.AgentId = @AgentID  
	INNER JOIN CustInfo C WITH (NOLOCK)
			ON B.CustID = C.CustID AND BA.AgentId = C.AgentId
	WHERE	BA.StatusId IN (0,1)	
			AND BA.matchID > 0
			AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

			AND B.StatusId IN (0,1)	
			AND B.matchID > 0
			AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))
			
			AND (@Sporttypes = '0' 
					OR EXISTS (SELECT 1 FROM match (NOLOCK) 
								WHERE matchid=b.matchid AND sporttype IN (SELECT sporttype FROM #SportsList)
								)
					)
	GROUP BY C.Username, B.CustID
	ORDER BY C.Username


--Parlay
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29) OR @Bettypes = '0')
	INSERT INTO #MemberOutstanding
	SELECT  B.Username, B.CustID, 
			ISNULL(SUM(ABS(B.actual_stake)),0) OutstandingAmount,  
			ISNULL(SUM(ABS(B.actual_stake) * B.APositiontaking ),0) OutstandingShareAmount
			
	FROM (
			SELECT  DISTINCT C.Username, B.CustID, 
					BA.bettype ,BA.actual_stake, BA.APositiontaking
			FROM	bettrans B WITH (NOLOCK)
			INNER JOIN BetTrans_Agent BA WITH (NOLOCK)
				ON	BA.TransID = B.TransID AND BA.AgentId = @AgentID 
			INNER JOIN CustInfo C WITH (NOLOCK)
					ON B.CustID = C.CustID AND BA.AgentId = C.AgentId
			WHERE	BA.StatusId IN (0,1)
					AND BA.matchID IN (9,29)
					AND BA.Bettype IN (9,29) 	
					AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

					AND B.StatusId IN (0,1)	
					AND B.matchID IN (9,29)
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
			
			) B
	GROUP BY B.Username, B.CustID
	ORDER BY B.Username

--- Outright
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype = 10 OR @Bettypes = '0')
	INSERT INTO #MemberOutstanding
	SELECT  C.Username, B.CustID, 
			ISNULL(SUM(ABS(BA.actual_stake) ),0) OutstandingAmount,  
			ISNULL(SUM(ABS(BA.actual_stake) * BA.APositiontaking ),0) OutstandingShareAmount
			
	FROM	bettrans B WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK)
		ON	BA.TransID = B.TransID AND BA.AgentId = @AgentID 
	INNER JOIN CustInfo C WITH (NOLOCK)
			ON B.CustID = C.CustID AND BA.AgentId = C.AgentId
	WHERE	BA.StatusId IN (0,1)
			AND BA.matchID  > 0
			AND BA.Bettype = 10 	

			AND B.StatusId IN (0,1)	
			AND B.matchID  > 0
			AND B.Bettype = 10 	
			
			AND (@Sporttypes = '0' 
				 OR EXISTS (SELECT	1 
							FROM	Outright M WITH (NOLOCK) 
							INNER JOIN League L WITH (NOLOCK) 
									ON L.leagueid = M.leagueid		
									AND (L.sporttype IN (Select sporttype FROM #SportsList))				
							WHERE	M.orid = B.MatchId
							)	
					)
	GROUP BY C.Username, B.CustID
	ORDER BY C.Username

--####################################### GET DATA #####################################-- 

DECLARE @Share smallint


--verison _CustDB
SELECT TOP 1 @Share = PositionTaking
FROM SVRCUST.CustDB.dbo.CustPositionTaking PT WITH (NOLOCK) 
WHERE  Custid= (select top 1 custid from CustInfo where AgentID = @AgentID) AND PT.AgentID = @AgentID AND PT.Bettype = 1 AND PT.SportType = 1 AND PT.IsLive = 0

-----Verion local
--SELECT TOP 1 @Share = PositionTaking
--FROM SVRCUST.CustDB.dbo.AgentCustPositionTaking PT WITH (NOLOCK) 
--WHERE PT.AgentCustId = @AgentID AND PT.AgentId = @AgentID AND PT.Bettype = 1 AND PT.SportType = 1 AND PT.IsLive = 0


SELECT	ISNULL(A.Username, B.Username) as Username, 
		ISNULL(A.CustId, B.CustId) as CustId,
		ISNULL(@Share,0) as Share,
		ISNULL(BetCount,0) as BetCount,
		ISNULL(BetAmount,0) as BetAmount,
		ISNULL(CommBase,0) as CommBase,

		ISNULL(WinLost,0) as WinLost,
		ISNULL(PlayerComm,0) as PlayerComm,
		ISNULL(MemberTotal,0) as MemberTotal,

		ISNULL(AWinLost,0) as AWinLost,
		ISNULL(AComm,0) as AComm,
		ISNULL(ATotal,0) as ATotal,

		ISNULL(UplineEffStake,0) as UplineEffStake,
		ISNULL(UplineTotal,0) as UplineTotal,

		ISNULL(OutstandingAmount,0) as OutstandingAmount,
		ISNULL(OutstandingShareAmount,0) as OutstandingShareAmount
FROM	(
		SELECT	Username, CustId,  
				SUM(BetCount) as BetCount,	
				SUM(BetAmount) as BetAmount,
				SUM(CommBase) as CommBase,

				SUM(WinLost) as  WinLost, 
				SUM(PlayerComm) as PlayerComm,
				SUM(MemberTotal) as MemberTotal,

				SUM(AWinLost) as  AWinLost, 
				SUM(AComm) as AComm,
				SUM(ATotal) as ATotal,

				SUM(UplineEffStake) as UplineEffStake,
				SUM(UplineTotal) as UplineTotal
		FROM	#WinLossMember
		GROUP BY Username, CustId
		) A
LEFT JOIN 
		( 	
		SELECT	M.Username, M.CustID,  
				SUM(OutstandingAmount) OutstandingAmount , 
				SUM(OutstandingShareAmount) OutstandingShareAmount 
		FROM	#MemberOutstanding M			
		GROUP BY M.Username, M.CustID 
		) B
	ON A.CustID = B.CustID

ORDER BY Share ASC, Username ASC



DROP TABLE #WinLossMember
DROP TABLE #MemberOutstanding
DROP TABLE #BettypeList
DROp TABLE #SportsList


