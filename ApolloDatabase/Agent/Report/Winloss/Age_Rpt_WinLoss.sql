DROP PROC [Age_Rpt_WinLoss]
GO 
CREATE  PROCEDURE [dbo].[Age_Rpt_WinLoss]
	@AgentID 	INT,
	@FromDate 	DATE,
	@ToDate 	DATE,	
	@BalanceUpDay SMALLDATETIME	
AS
    /*
    Created: Sophia
	Date: 20130401
    Task : Report Agent Winloss
    DB: SVRAGE.RepDB
    Original SP:[Age_Rpt_WinLoss_Ag]
    EX: EXEC Age_Rpt_WinLoss @AgentId =99, @FromDate = '2013-01-01',  @ToDate = '2013-05-10', @BalanceUpDay = '2013-03-01'

    Revisions:
       
    */
    
SET NOCOUNT ON


CREATE TABLE #WinLossAgent ( Username NVARCHAR(50), AgentID INT, IsAgent BIT, PositionTaking SMALLINT, TurnOver MONEY, ActualTO MONEY, AWinLost MONEY, AComm MONEY, ATotal MONEY, GrossTotal MONEY, UplineTotal MONEY)
CREATE TABLE #WinLossMember ( Username NVARCHAR(50), AgentID INT, IsAgent BIT,  PositionTaking SMALLINT, TurnOver MONEY, ActualTO MONEY, AWinLost MONEY, AComm MONEY, ATotal MONEY, GrossTotal MONEY, UplineTotal MONEY)

IF @Todate >= @BalanceUpDay
BEGIN  
	IF @AgentId = 0
	BEGIN 
		----Super view
		INSERT INTO #WinLossAgent
		SELECT  C.Username, C.AgentID, 1 as IsAgent,
				PT.MaxUpperPositionTaking as PositionTaking,				
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
		INNER JOIN	Bettrans B WITH (NOLOCK) 
				ON	B.TransID = BA.TransID		
		INNER JOIN  AgentPositionTaking PT WITH (NOLOCK) 
				ON  PT.AgentID = C.AgentId AND PT.Bettype = 1 AND PT.SportType = 1 AND IsLive = 0
		WHERE		C.ParentId = @AgentID 
					AND B.Winlostdate BETWEEN @FromDate AND @ToDate
					AND B.StatusID NOT IN (0,1)
					AND B.Bettype <=19000 
					AND BA.Winlostdate BETWEEN @FromDate AND @ToDate
					AND BA.StatusID NOT IN (0,1)
					AND BA.Bettype <=19000
		GROUP BY	C.Username, C.AgentID, PT.MaxUpperPositionTaking


	END
	ELSE 
	BEGIN
		---- Agent Winloss
		SELECT  C.Username, C.AgentID, PT.MaxUpperPositionTaking as PositionTaking,			 
		   		SUM(ABS(B.Stake)) AS TurnOver,
				SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS ActualTO,
				SUM(BP.AWinlost) AS AWinlost,	
				SUM(BP.AComm) - SUM(BA.AComm) AS AComm,
				SUM(BP.AWinlost) + SUM (BP.AComm) - SUM (BA.AComm)  AS ATotal,
			    SUM(BA.AComm) ChildAComm  , 
				--SUM (BA.AWinlost)  as ChildWinlost,
				SUM(B.Winlost) as Winlost,
				SUM(B.Actual_Stake) as Actual_Stake
	    INTO	#T
		FROM	Bettrans B
		INNER JOIN Bettrans_Agent BP WITH (NOLOCK) 
				ON BP.TransID = B.TransID AND BP.AgentID = @AgentID ---Parent (k)
		INNER JOIN AgentInfo C WITH (NOLOCK) --- Child direct (k+1)
				ON C.ParentID = @AgentID  
		INNER JOIN AgentPositionTaking PT WITH (NOLOCK) 
				ON PT.AgentID = C.AgentId AND PT.Bettype = 1 AND PT.SportType = 1 AND IsLive = 0
		INNER JOIN Bettrans_Agent BA WITH (NOLOCK) 
				ON BA.TransID = B.TransID AND C.AgentID = BA.AgentID ---- Child direct (k+1)
		WHERE	 B.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND B.StatusID NOT IN (0,1)	
				AND B.Bettype <=19000
				--(	B.bettype < 31 
				--	OR B.bettype between 121 and 999
				--	OR B.bettype between 1301 and 1334 
				--	--OR B.bettype BETWEEN 81 AND 120 				
				--) 
				AND BP.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND BP.StatusID NOT IN (0,1)	
				AND BP.Bettype <=19000
				AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND BA.StatusID NOT IN (0,1)	
				AND BA.Bettype <=19000
		GROUP BY C.Username, C.AgentID ,  PT.MaxUpperPositionTaking


		INSERT INTO #WinLossAgent
		SELECT	T.Username, T.AgentID, 1 as IsAgent, T.PositionTaking as PositionTaking,	
				T.TurnOver, T.ActualTO, T.AWinlost, T.AComm, T.ATotal, 
				SUM(BA.AWINLOST) + (T.Winlost - T.Actual_Stake) + T.ChildAComm  AS GrossTotal,  
				-(SUM(BA.AWINLOST) + (T.Winlost - T.Actual_Stake) + T.ChildAComm  + T.ATotal) AS UplineTotal
		FROM AgentInfo P with (nolock)  
		INNER JOIN AgentInfo C WITH(NOLOCK) ON C.AgentHId.IsDescendantOf(P.AgentHId ) =1  AND C.AgentLevel >= P.AgentLevel  --- Children of k+1 (k+1 -> k+...)
		INNER JOIN Bettrans_Agent BA WITH (NOLOCK) ON BA.AgentID = C.AgentID
		INNER JOIN #T T ON T.AgentID = P.AgentID
		WHERE	BA.Winlostdate BETWEEN @FromDate AND @ToDate
				AND BA.StatusID NOT IN (0,1) 				 
				AND BA.Bettype <=19000 
		GROUP BY T.AgentID, T.Username,T.PositionTaking, T.TurnOver, T.ActualTO, T.AWinlost, T.AComm, T.ATotal, T.ChildAComm, T.Winlost , T.Actual_Stake
	 
	
		DROP TABLE #T

	END

	
-----Member winloss
	INSERT INTO #WinLossMember  
	SELECT	'' as Username, 0 as AgentId, 0 as IsAgent,
			0 as PositionTaking,				
		   	SUM(ABS(B.Stake)) as TurnOver,
			SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  as ActualTO,
			SUM(BA.AWinLost) as AWinlost,	
			SUM(BA.AComm) - SUM (B.PlayerComm) as AComm,
			SUM(BA.AWinLost) + SUM(BA.AComm) - SUM (B.PlayerComm) AS ATotal,
			SUM (B.Winlost - B.Actual_Stake + B.PlayerComm) GrossTotal,
			-(SUM (B.Winlost - B.Actual_Stake + B.PlayerComm) + SUM(BA.AWinLost) + SUM(BA.AComm) - SUM (B.PlayerComm)) UplineTotal
	FROM	Bettrans B WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK) 
		ON	BA.TransID = B.TransID 
	INNER JOIN CustInfo C WITH (NOLOCK)
		ON	B.CustID = C.CustID AND C.AgentId = @AgentID
	WHERE	BA.AgentId = @AgentID 
			AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
			AND BA.StatusID NOT IN (0,1)
			AND BA.Bettype <= 19000
			AND B.Winlostdate BETWEEN @FromDate AND @ToDate 
			AND B.StatusID NOT IN (0,1)
			AND B.Bettype <= 19000
	---GROUP BY C.AgentId

-------------------------------------------------------------------------------------------
	    
	IF @BalanceUpDay < @FromDate --if this case occurs then there is no data from sum_winloss_old
		SELECT @BalanceUpDay=@FromDate

        INSERT INTO #WinLossAgent
	    SELECT	AgentUsername as Username, A.AgentId, 1 as IsAgent,
				PT.MaxUpperPositionTaking as PositionTaking,				 
				SUM(Turnover) TurnOver,
				SUM(Actual_Turnover) ActualTO,		
				SUM(UplineWinlost) as AWinLost,
				SUM(UplineComm - AComm) as AComm,
				SUM(UplineWinlost) + SUM(UplineComm - AComm) AS ATotal,
				SUM(GrossTotal) AS GrossTotal,
				-(SUM(GrossTotal) + SUM(UplineWinlost) + SUM(UplineComm - AComm)) as UplineTotal
	    FROM	Sum_WinLoss_Agent A WITH(NOLOCK) 
		INNER JOIN AgentPositionTaking PT WITH (NOLOCK) 
				ON PT.AgentID = A.AgentId AND PT.Bettype = 1 AND PT.SportType = 1 AND PT.IsLive = 0
		WHERE	ParentID = @AgentId 
				AND WinLostDate BETWEEN @BalanceUpDay AND @ToDate 
	    GROUP BY AgentUsername, A.AgentId,PT.MaxUpperPositionTaking

		INSERT INTO #WinLossMember
	    SELECT	'' as Username, 0 as AgentID, 0 as IsAgent,
				0 as PositionTaking,				 
				SUM(Turnover) TurnOver,
				SUM(Actual_Turnover) ActualTO,		
				SUM(UplineWinlost) as AWinLost,
				SUM(UplineComm-PlayerComm) as AComm,
				SUM(UplineWinlost) + SUM(UplineComm-PlayerComm) AS ATotal,
				SUM(WinLost + PlayerComm) AS GrossTotal,
				-(SUM(WinLost) + SUM(UplineWinlost) + SUM(UplineComm)) as UplineTotal
	    FROM	Sum_WinLoss_Cust b WITH(NOLOCK) 
		WHERE	AgentId = @AgentId 
				AND WinLostDate BETWEEN @BalanceUpDay AND @ToDate 
	   --- GROUP BY Username, CustId

END

----------------------------------------------------------------------------------------------
IF @FromDate < @BalanceUpDay 
BEGIN
	IF @todate >= DATEADD(dd, -1, @BalanceUpDay)
		SELECT @ToDate = DATEADD(dd, -1, @BalanceUpDay)
		
		INSERT INTO #WinLossAgent
	    SELECT	AgentUsername as Username, A.AgentId, 1 as IsAgent,
				PT.MaxUpperPositionTaking as PositionTaking,				 
				SUM(Turnover) TurnOver,
				SUM(Actual_Turnover) ActualTO,		
				SUM(UplineWinlost) as AWinLost,
				SUM(UplineComm - AComm) as AComm,
				SUM(UplineWinlost) + SUM(UplineComm - AComm) AS ATotal,
				SUM(GrossTotal) AS GrossTotal,
				-(SUM(GrossTotal) + SUM(UplineWinlost) + SUM(UplineComm - AComm)) as UplineTotal				
	    FROM	SVRARC.ArchiveDB.dbo.Sum_WinLoss_Agent_Old A WITH(NOLOCK) 
		INNER JOIN AgentPositionTaking PT WITH (NOLOCK) 
				ON PT.AgentID = A.AgentId AND PT.Bettype = 1 AND PT.SportType = 1 AND PT.IsLive = 0
		WHERE	A.ParentID = @AgentId 
				AND WinLostDate BETWEEN @FromDate AND @ToDate 
	    GROUP BY AgentUsername, A.AgentId, PT.MaxUpperPositionTaking

		INSERT INTO #WinLossMember
	    SELECT	'' as Username, 0 as AgentID, 0 as IsAgent,
				0 as PositionTaking,				 
				SUM(Turnover) TurnOver,
				SUM(Actual_Turnover) ActualTO,		
				SUM(UplineWinlost) as AWinLost,
				SUM(UplineComm-PlayerComm) as AComm,
				SUM(UplineWinlost) + SUM(UplineComm-PlayerComm) AS ATotal,
				SUM(WinLost + PlayerComm) AS GrossTotal,
				-(SUM(WinLost) + SUM(UplineWinlost) + SUM(UplineComm)) as UplineTotal				
	    FROM	SVRARC.ArchiveDB.dbo.Sum_WinLoss_Cust_Old b WITH(NOLOCK) 
		WHERE	AgentId = @AgentId 
				AND WinLostDate BETWEEN @FromDate AND @ToDate 
	    ---GROUP BY Username, CustId
	    
END


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


SELECT	Username, AgentId, isAgent, PositionTaking,
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
		SUM(TurnOver) as TurnOver,
		SUM(ActualTO) as ActualTO,

		SUM(GrossTotal) as GrossTotal,

		SUM(AWinLost) as  AWinLost, 
		SUM(AComm) as AComm,
		SUM(ATotal) as ATotal,
		
		SUM(UplineTotal) as UplineTotal
FROM	#WinLossMember 
GROUP BY Username, AgentId, isAgent, PositionTaking
ORDER BY IsAgent DESC, Username ASC

DROP TABLE #WinLossAgent
DROP TABLE #WinLossMember


GO
GRANT EXECUTE ON [dbo].[Age_Rpt_WinLoss] TO [aplWeb]
Go 



 


