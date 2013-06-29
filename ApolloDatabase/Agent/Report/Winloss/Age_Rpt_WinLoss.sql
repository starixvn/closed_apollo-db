ALTER PROCEDURE [dbo].[Age_Rpt_WinLoss_Member_Xtest]
	@AgentID 	INT,
	@FromDate 	DATE,
	@ToDate 	DATE,	
	@BalanceUpDay DATE,
	@Sporttypes VARCHAR(MAX) = '0',
	@Bettypes VARCHAR(MAX) = '0' 		
WITH RECOMPILE
AS
    /*
    Created: Sophia
	Date: 20130401
    Task : Members detail of Report Agent Winloss
    DB: SVRAGE.RepDB
    Original: Age_Rpt_WinLoss_Ag
    Revisions:
		- 20130627@Sophia: Modify for Singbet: filter by Sporttype and Bettype
	EX: EXEC Age_Rpt_WinLoss_Member @AgentId =3, @FromDate = '2013-01-01',  @ToDate = '2013-04-10', @BalanceUpDay = '2013-03-01'

       
    */
    
SET NOCOUNT ON

CREATE TABLE #WinLossMember ( Username NVARCHAR(50), CustID INT, PositionTaking SMALLINT, BetCount BIGINT, TurnOver MONEY, ActualTO MONEY, WinLost MONEY, PlayerComm MONEY, MemTotal MONEY, AWinLost MONEY, AComm MONEY, ATotal MONEY, UplineTotal MONEY)


DECLARE @SportsList TABLE (Sporttype TINYINT)
INSERT INTO @SportsList (Sporttype)
SELECT val FROM strSplit_key (@Sporttypes, ',')

DECLARE @BettypeList TABLE (Bettype SMALLINT)
INSERT INTO @BettypeList (Bettype)
SELECT val FROM strSplit_key (@Bettypes, ',')

IF @Todate >= @BalanceUpDay
BEGIN 
	
		INSERT INTO #WinLossMember
	    SELECT  C.Username,
				C.CustID,
				PT.PositionTaking, 
				COUNT(B.TransID) as BetCount,
		   		SUM(ABS(B.Stake)) AS TurnOver,
				SUM(CASE WHEN ABS(B.MOdds)<> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) = 0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  as ActualTO,

				SUM(B.WinLost - B.Actual_Stake) AS WinLost,
				SUM(B.PlayerComm) AS PlayerComm,
				SUM(B.WinLost - B.Actual_Stake) + SUM(B.PlayerComm) AS MemTotal,
				
				SUM(BA.AWinLost) AS AWinLost,	
				SUM(BA.AComm) - SUM (B.PlayerComm) AS AComm,
				SUM(BA.AWinLost) + SUM(BA.AComm) - SUM (B.PlayerComm) AS ATotal,

				- (SUM(B.WinLost - B.Actual_Stake)  + SUM(BA.AWinLost) + SUM(BA.AComm)) AS UplineTotal
		FROM		Bettrans B WITH (NOLOCK)
		INNER JOIN	BetTrans_Agent BA WITH (NOLOCK)
				ON	BA.TransID = B.TransID
		INNER JOIN	CustInfo C WITH (NOLOCK)
				ON	B.CustID = C.CustID AND  C.AgentId = @AgentID
		INNER JOIN  Match m  WITH (NOLOCK) 
				ON  m.MatchID = B.MatchID
		INNER JOIN	CustPositionTaking PT WITH (NOLOCK) 
				ON	PT.CustID = C.CustID AND PT.AgentID = @AgentID AND PT.Bettype = 1 AND PT.SportType = 1 AND PT.IsLive = 0
		WHERE		BA.AgentId = @AgentID
				AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND BA.StatusID NOT IN (0,1)	
				AND BA.bettype <= 19000
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM @BettypeList))			
				AND B.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND B.StatusID NOT IN (0,1)	
				AND B.bettype <= 19000
				AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM @BettypeList))
				AND (@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM @SportsList))
		GROUP BY C.Username, C.CustID, PT.PositionTaking

		    
	IF @BalanceUpDay < @FromDate --if this case occurs then there is no data from Sum_WinLoss_Cust_Old
		SELECT @BalanceUpDay=@FromDate

  		INSERT INTO #WinLossMember
	    SELECT	A.Username, A.CustId,
				PT.PositionTaking,
				SUM(BetCount) as BetCount,						 
				SUM(Turnover) TurnOver,
				SUM(Actual_Turnover) ActualTO,	
				SUM(WinLost) WinLost,
				SUM(PlayerComm) as PlayerComm,
				SUM(WinLost) + SUM(PlayerComm) as MemTotal,

				SUM(UplineWinlost) as AWinLost,
				SUM(UplineComm - PlayerComm) as AComm,
				SUM(UplineWinlost) + SUM(UplineComm-PlayerComm) AS ATotal,

				- (SUM(WinLost)  + SUM(UplineWinlost) + SUM(UplineComm)) as UplineTotal
	    FROM	Sum_WinLoss_Cust A WITH(NOLOCK) 
		INNER JOIN	CustPositionTaking PT WITH (NOLOCK) 
				ON	PT.CustID = A.CustID AND PT.AgentID = @AgentID AND PT.Bettype = 1 AND PT.SportType = 1 AND PT.IsLive = 0
		WHERE	A.AgentId = @AgentId 
				AND WinLostDate BETWEEN @BalanceUpDay AND @ToDate 
				AND (@Bettypes = '0' OR A.Bettype IN (Select bettype FROM @BettypeList))
				AND (@Sporttypes = '0' OR A.sporttype IN (Select sporttype FROM @SportsList))
		GROUP BY A.Username, A.CustId, PT.PositionTaking
END

IF @FromDate < @BalanceUpDay 
BEGIN
	IF @todate >= DATEADD(dd, -1, @BalanceUpDay)
		SELECT @ToDate = DATEADD(dd, -1, @BalanceUpDay)
		
		INSERT INTO #WinLossMember
	    SELECT	A.Username, A.CustId,
				PT.PositionTaking,	
				SUM(BetCount) as BetCount,				 
				SUM(Turnover) TurnOver,
				SUM(Actual_Turnover) ActualTO,	
				SUM(WinLost) WinLost,
				SUM(PlayerComm) as PlayerComm,
				SUM(WinLost) + SUM(PlayerComm) as MemTotal,	

				SUM(UplineWinlost) as AWinLost,
				SUM(UplineComm-PlayerComm) as AComm,
				SUM(UplineWinlost) + SUM(UplineComm-PlayerComm) AS ATotal,
				- (SUM(WinLost) + SUM(UplineWinlost) + SUM(UplineComm)) as UplineTotal
	    FROM	SVRARC.ArchiveDB.dbo.Sum_WinLoss_Cust_Old A WITH(NOLOCK) 
		INNER JOIN	CustPositionTaking PT WITH (NOLOCK) 
				ON	PT.CustID = A.CustID AND PT.AgentID = @AgentID AND PT.Bettype = 1 AND PT.SportType = 1 AND PT.IsLive = 0
		WHERE	A.AgentId = @AgentId 
				AND WinLostDate BETWEEN @FromDate AND @ToDate
				AND (@Bettypes = '0' OR A.Bettype IN (Select bettype FROM @BettypeList))
				AND (@Sporttypes = '0' OR A.sporttype IN (Select sporttype FROM @SportsList)) 
	    GROUP BY A.Username, A.CustId, PT.PositionTaking
END 
 
SELECT	Username, CustId,  PositionTaking,
		SUM(BetCount) as BetCount,	
		SUM(TurnOver) as TurnOver,
		SUM(ActualTO) as ActualTO,

		SUM(WinLost) as  WinLost, 
		SUM(PlayerComm) as PlayerComm,
		SUM(MemTotal) as MemTotal,

		SUM(AWinLost) as  AWinLost, 
		SUM(AComm) as AComm,
		SUM(ATotal) as ATotal,

		SUM(UplineTotal) as UplineTotal
FROM	#WinLossMember 
GROUP BY Username, CustId, PositionTaking
ORDER BY Username
 
DROP TABLE #WinLossMember


GO
GRANT EXECUTE ON [dbo].[Age_Rpt_WinLoss_Member_Xtest] TO [aplWeb]
GO

