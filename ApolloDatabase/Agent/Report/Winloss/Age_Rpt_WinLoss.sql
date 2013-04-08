ALTER PROCEDURE [dbo].[Age_Rpt_WinLoss]
	@AgentID 	INT,
	@FromDate 	SMALLDATETIME,
	@ToDate 	SMALLDATETIME,	
	@BalanceUpDay SMALLDATETIME	
AS
    /*
    Created: Sophia
	Date: 20130401
    Task : Report Agent Winloss
    DB: SVRAGE.RepDB
    Original SP:[Age_Rpt_WinLoss_Ag]
    EX: EXEC Age_Rpt_WinLoss @AgentId =3, @FromDate = '2013-01-01',  @ToDate = '2013-04-10', @BalanceUpDay = '2013-03-01'

    Revisions:
       
    */
    
SET NOCOUNT ON


DECLARE @WinLossAgent TABLE ( Username NVARCHAR(50), AgentID INT, IsAgent BIT, PositionTaking SMALLINT, TurnOver MONEY, ActualTO MONEY, AWinLost MONEY, AComm MONEY, ATotal MONEY)
DECLARE @WinLossMember TABLE ( Username NVARCHAR(50), AgentID INT, IsAgent BIT,  PositionTaking SMALLINT, TurnOver MONEY, ActualTO MONEY, AWinLost MONEY, AComm MONEY, ATotal MONEY)

IF @Todate >= @BalanceUpDay
BEGIN  
	IF @AgentId = 0
	BEGIN 
		----Super view
		INSERT INTO @WinLossAgent
		SELECT  C.Username, C.AgentID, 1 as IsAgent,
				PT.MaxPositionTaking as PositionTaking,				
		   		SUM(ABS(B.Stake)) AS TurnOver,
				SUM(CASE WHEN ABS(B.MOdds)> 0.25 THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) = 0.25 THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS ActualTO,
				SUM(B.TWinlost) AS AWinlost,	
				ISNULL(SUM(B.TComm),0) AS AComm,
				ISNULL(SUM(B.TWinlost) + SUM (B.TComm),0) AS ATotal			
		FROM		AgentInfo C WITH (NOLOCK)
		INNER JOIN	BetTrans_Agent BA WITH (NOLOCK)
				ON	BA.AgentID = C.AgentID		
		INNER JOIN	Bettrans B WITH (NOLOCK) 
				ON	B.TransID = BA.TransID		
		INNER JOIN  AgentPositionTaking PT WITH (NOLOCK) 
				ON PT.AgentID = C.AgentId AND PT.Bettype = 1 AND PT.SportType = 1
		WHERE		C.ParentId = @AgentID
		GROUP BY	C.Username, C.AgentID, PT.MaxPositionTaking
	END
	ELSE 
	BEGIN
		---- Agent Winloss
		INSERT INTO @WinLossAgent
		SELECT  C.Username, C.AgentID, 1 as IsAgent,
				PT.MaxPositionTaking as PositionTaking,				
		   		SUM(ABS(B.Stake)) AS TurnOver,
				SUM(CASE WHEN ABS(B.MOdds)> 0.25 THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) = 0.25 THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS ActualTO,
				SUM(BP.AWinlost) AS AWinlost,	
				ISNULL(SUM(BP.AComm) - SUM(BA.AComm),0) AS AComm,
				ISNULL(SUM(BP.AWinlost) + SUM (BP.AComm) - SUM (BA.AComm),0) AS ATotal			
		FROM	AgentInfo C  WITH (NOLOCK)
		INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK)
				ON BA.AgentID = C.AgentID
		INNER JOIN Bettrans B WITH (NOLOCk)
				ON B.TransId = BA.TransId
		INNER JOIN BetTrans_Agent AS BP WITH (NOLOCK)
				ON BP.TransID = BA.TransID AND BP.AgentID = @AgentID
		INNER JOIN  AgentPositionTaking PT WITH (NOLOCK) 
				ON PT.AgentID = C.AgentId AND PT.Bettype = 1 AND PT.SportType = 1
		WHERE	C.ParentId = @AgentID 
				AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND BA.StatusID NOT IN (0,1)	
				AND 
				(	BA.bettype < 31 
					OR BA.bettype between 121 and 999
					OR BA.bettype between 1301 and 1334 
					OR BA.bettype BETWEEN 81 AND 120 				
				) 	
		GROUP BY C.Username, C.AgentID, PT.MaxPositionTaking
	 
	END

	

-----Member Outstanding
	INSERT INTO @WinLossMember  
	SELECT	'', C.AgentId, 0 as IsAgent,
			'' as PositionTaking,				
		   	SUM(ABS(B.Stake)) as TurnOver,
			SUM(CASE WHEN ABS(B.MOdds)> 0.25 THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) = 0.25 THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  as ActualTO,
			SUM(BA.AWinLost) as AWinlost,	
			(SUM(BA.AComm) - SUM (B.PlayerComm)) as AComm,
			(SUM(BA.AWinLost) + SUM(BA.AComm) - SUM (B.PlayerComm)) AS ATotal		
	FROM Bettrans B WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK) 
		ON BA.TransID = B.TransID 
	INNER JOIN CustInfo C WITH (NOLOCK)
		ON B.CustID = C.CustID AND C.AgentId = @AgentID
	WHERE	BA.AgentId = @AgentID 
			AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
			AND BA.StatusID NOT IN (0,1)	
			AND 
			(	BA.bettype < 31 
				OR BA.bettype between 121 and 999
				OR BA.bettype between 1301 and 1334 
				OR BA.bettype BETWEEN 81 AND 120 				
			)   
	GROUP BY C.AgentId


	    
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
	    



SELECT * FROM @WinLossAgent
UNION ALL
SELECT * FROM @WinLossMember 


 

GO
GRANT EXECUTE ON [dbo].[Age_Rpt_WinLoss] TO [aplWeb]
Go
--GRANT VIEW DEFINITION ON [dbo].[Age_Rpt_WinLoss_Ag] TO [vnteam]

