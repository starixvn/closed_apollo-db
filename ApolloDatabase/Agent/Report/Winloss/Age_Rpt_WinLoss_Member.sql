ALTER PROCEDURE [dbo].[Age_Rpt_WinLoss_Member]
	@AgentID 	INT,
	@FromDate 	SMALLDATETIME,
	@ToDate 	SMALLDATETIME,	
	@BalanceUpDay SMALLDATETIME	
AS
    /*
    Created: 
    Task : 
    DB: SVRAGE.RepDB
    Original SP:[Age_Rpt_WinLoss_Ag]
    Revisions:
	EX: EXEC Age_Rpt_WinLoss_Member @AgentId =3, @FromDate = '2013-01-01',  @ToDate = '2013-04-10', @BalanceUpDay = '2013-03-01'

       
    */
    
SET NOCOUNT ON

CREATE TABLE #WinLossMember ( Username NVARCHAR(50), CustID INT, PositionTaking SMALLINT, TurnOver MONEY, ActualTO MONEY, WinLost MONEY, PlayerComm MONEY, MemTotal MONEY, AWinLost MONEY, AComm MONEY, ATotal MONEY, UplineTotal MONEY)

IF @Todate >= @BalanceUpDay
BEGIN 
	
		INSERT INTO #WinLossMember
	    SELECT  C.Username,
				C.CustID,
				PT.PositionTaking, 
		   		SUM(ABS(B.Stake)) AS TurnOver,
				SUM(CASE WHEN ABS(B.MOdds)> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) = 0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  as ActualTO,

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
		INNER JOIN	CustPositionTaking PT WITH (NOLOCK) 
				ON	PT.CustID = C.CustID AND PT.AgentID = @AgentID AND PT.Bettype = 1 AND PT.SportType = 1 AND PT.IsLive = 0
		WHERE		BA.AgentId = @AgentID
				AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND BA.StatusID NOT IN (0,1)	
				AND 
				(	BA.bettype < 31 
					OR BA.bettype between 121 and 999
					OR BA.bettype between 1301 and 1334 
					--OR BA.bettype BETWEEN 81 AND 120 				
				) 
		GROUP BY C.Username, C.CustID, PT.PositionTaking

		    
	IF @BalanceUpDay < @FromDate --if this case occurs then there is no data from Sum_WinLoss_Cust_Old
		SELECT @BalanceUpDay=@FromDate

  		INSERT INTO #WinLossMember
	    SELECT	A.Username, A.CustId,
				PT.PositionTaking,						 
				SUM(Turnover) TurnOver,
				SUM(Actual_Turnover) ActualTO,	
				SUM(WinLost) WinLost,
				SUM(PlayerComm) as PlayerComm,
				SUM(WinLost) + SUM(PlayerComm) as MemTotal,

				SUM(UplineWinlost) as AWinLost,
				SUM(UplineComm) as AComm,
				SUM(UplineWinlost) + SUM(UplineComm) AS ATotal,

				- (SUM(WinLost) + SUM(UplineWinlost) + SUM(UplineComm)) as UplineTotal
	    FROM	Sum_WinLoss_Cust A WITH(NOLOCK) 
		INNER JOIN	CustPositionTaking PT WITH (NOLOCK) 
				ON	PT.CustID = A.CustID AND PT.AgentID = @AgentID AND PT.Bettype = 1 AND PT.SportType = 1 AND PT.IsLive = 0
		WHERE	A.AgentId = @AgentId 
				AND WinLostDate BETWEEN @BalanceUpDay AND @ToDate 
		GROUP BY A.Username, A.CustId, PT.PositionTaking
END

IF @FromDate < @BalanceUpDay 
BEGIN
	IF @todate >= DATEADD(dd, -1, @BalanceUpDay)
		SELECT @ToDate = DATEADD(dd, -1, @BalanceUpDay)
		
		INSERT INTO #WinLossMember
	    SELECT	A.Username, A.CustId,
				PT.PositionTaking,				 
				SUM(Turnover) TurnOver,
				SUM(Actual_Turnover) ActualTO,	
				SUM(WinLost) WinLost,
				SUM(PlayerComm) as PlayerComm,
				SUM(WinLost) + SUM(PlayerComm) as MemTotal,	
				SUM(UplineWinlost) as AWinLost,
				SUM(UplineComm) as AComm,
				SUM(UplineWinlost) + SUM(UplineComm) AS ATotal,
				- (SUM(WinLost) + SUM(UplineWinlost) + SUM(UplineComm)) as UplineTotal
	    FROM	SVRARC.ArchiveDB.dbo.Sum_WinLoss_Cust_Old A WITH(NOLOCK) 
		INNER JOIN	CustPositionTaking PT WITH (NOLOCK) 
				ON	PT.CustID = A.CustID AND PT.AgentID = @AgentID AND PT.Bettype = 1 AND PT.SportType = 1 AND PT.IsLive = 0
		WHERE	A.AgentId = @AgentId 
				AND WinLostDate BETWEEN @BalanceUpDay AND @ToDate 
	    GROUP BY A.Username, A.CustId, PT.PositionTaking
END 
 
SELECT	Username, CustId,  PositionTaking,
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
GRANT EXECUTE ON [dbo].[Age_Rpt_WinLoss_Member] TO [aplWeb]
Go
--GRANT VIEW DEFINITION ON [dbo].[Age_Rpt_WinLoss_Member] TO [vnteam]