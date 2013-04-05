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

DECLARE @WinLossMember TABLE ( Username NVARCHAR(50), CustID INT, PositionTaking SMALLINT, TurnOver MONEY, ActualTO MONEY, WinLost MONEY, PlayerComm MONEY, MemTotal MONEY, AWinLost MONEY, AComm MONEY, ATotal MONEY)


IF @Todate >= @BalanceUpDay
BEGIN 
	
		INSERT INTO @WinLossMember
	    SELECT  C.Username,
				C.CustID,
				PT.PositionTaking, 
		   		SUM(ABS(B.Stake)) AS TurnOver,
				SUM(CASE WHEN ABS(B.MOdds)> 0.25 THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) = 0.25 THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  as ActualTO,

				SUM(B.WinLost) AS WinLost,
				SUM(B.PlayerComm) AS PlayerComm,
				SUM(B.WinLost) + SUM(B.PlayerComm) AS MemTotal,
				
				SUM(BA.AWinLost) AS AWinLost,	
				SUM(BA.AComm) - SUM (B.PlayerComm) AS AComm,
				SUM(BA.AWinLost) + SUM(BA.AComm) - SUM (B.PlayerComm) AS ATotal

		FROM		Bettrans B WITH (NOLOCK)
		INNER JOIN	BetTrans_Agent BA WITH (NOLOCK)
				ON	BA.TransID = B.TransID
		INNER JOIN	CustInfo C WITH (NOLOCK)
				ON	B.CustID = C.CustID AND  C.AgentId = @AgentID
		INNER JOIN	CustPositionTaking PT WITH (NOLOCK) 
				ON	PT.CustID = C.CustID AND PT.Bettype = 1 AND PT.SportType = 1
		WHERE		BA.AgentId = @AgentID
				AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND BA.StatusID NOT IN (0,1)	
				AND 
				(	BA.bettype < 31 
					OR BA.bettype between 121 and 999
					OR BA.bettype between 1301 and 1334 
					OR BA.bettype BETWEEN 81 AND 120 				
				) 
		GROUP BY C.Username, C.CustID, PT.PositionTaking

	    

		    
--	IF @BalanceUpDay < @FromDate --if this case occurs then there is no data from sum_winloss_old
--		SELECT @BalanceUpDay=@FromDate

--    INSERT INTO @WinLossAgent
--	    SELECT	AgentId, 
--				SUM(ABS(CustTurnover)) TurnOver,
--				SUM(GrossComm) as GrossComm,
--				SUM(AgentWinLost) as AWinLost,
--				SUM(AgentComm) as AComm,
--				SUM(AgentWinLost) + SUM(AgentComm) AS ATotal
--	    FROM	Sum_WinLoss_Agent b WITH(NOLOCK) 
--		WHERE	AgentId = @AgentId AND
--				Winlostdate BETWEEN @BalanceUpDay AND @ToDate 
--	    GROUP BY AgentId
END

--IF @FromDate < @BalanceUpDay 
--BEGIN
--	IF @todate >= DATEADD(dd, -1, @BalanceUpDay)
--		SELECT @ToDate = DATEADD(dd, -1, @BalanceUpDay)
		
--    INSERT INTO @WinLossAgent
--	    SELECT	AgentId, 
--				SUM(ABS(CustTurnover)) TurnOver,
--				SUM(GrossComm) as GrossComm,
--				SUM(AgentWinLost) as AWinLost,
--				SUM(AgentComm) as AComm,
--				SUM(AgentWinLost) + SUM(AgentComm) AS ATotal
--	    FROM	SVRARC.ArchiveDB.dbo.Sum_WinLoss_Agent_Old b WITH(NOLOCK) 
--	    WHERE
--			recommend = @CustID AND 
--			roleID = 1 AND
--		    Winlostdate BETWEEN @FromDate AND @ToDate
		    
--	    GROUP BY AgentId
	    
SELECT * FROM @WinLossMember

GO
GRANT EXECUTE ON [dbo].[Age_Rpt_WinLoss_Member] TO [aplWeb]
Go
--GRANT VIEW DEFINITION ON [dbo].[Age_Rpt_WinLoss_Member] TO [vnteam]