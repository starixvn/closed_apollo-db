CREATE PROCEDURE [dbo].[Task_BalanceCheck]
	@winlostdate date ,
	@InitStepNo tinyint = 1
AS

DECLARE @memberSUM money,  @memberAmount money,
		@agentSUM money,  @agentAmount money

SELECT	@memberSUM = SUM (winlost - actual_stake + playercomm),
		@memberAmount = SUM((winlost - actual_stake + playercomm) *e.actualrate)
FROM  bettrans WITH (NOLOCK)
	inner join exchange e with (nolock) ON bettrans.currency=e.exchangeid
WHERE ruben=1 AND winlostdate <= @winlostdate

SELECT @agentSUM=sum (agentSUM) , 
	@agentAmount=sum (agentAmount) 
FROM
	(
	-- get winlost for direct child agent
	SELECT	SUM(BP.AWinlost + BP.AComm  - BA.AComm) as agentSUM,
			SUM((BP.AWinlost + BP.AComm  - BA.AComm) *e.actualrate)  agentAmount
	FROM BetTrans_Agent BP  WITH (ROWLOCK, index =IX_WinlostDate_StatusId_Bettype) 		
	JOIN AgentInfo A WITH (NOLOCK) ON A.ParentID = BP.AgentId
	JOIN BetTrans_Agent BA WITH (ROWLOCK ) ON A.AgentId = BA.AgentId AND BP.TransId = BA.TransId										
	INNER JOIN exchange e with (nolock) ON BP.currency=e.exchangeid
	WHERE	BP.Winlostdate <= @winlostdate		
			AND BP.STatusID NOT IN (0,1)	
			AND BP.BETTYPE<20000
			AND BA.Winlostdate <= @winlostdate	
			AND BA.STatusID NOT IN (0,1)	 				
			AND BA.BETTYPE<20000							
	GROUP BY BP.AgentId 
	UNION ALL				
	-- get winlost for direct member
	SELECT	SUM(BP.AWinlost + BP.AComm  - B.PlayerComm) as Amount,
			SUM((BP.AWinlost + BP.AComm  - B.PlayerComm)*e.actualrate)  agentAmount
	FROM BetTrans_Agent BP  WITH (ROWLOCK, index =IX_WinlostDate_StatusId_Bettype) 
		INNER JOIN bettrans B WITH (ROWLOCK, index =IX_WinlostDate_StatusId_Bettype) ON B.TransId = BP.TransId	
		INNER  JOIN CustInfo c WITH (NOLOCK) ON c.AgentId = BP.AgentId	and c.CustId=b.CustId
		INNER JOIN exchange e with (nolock) ON BP.currency=e.exchangeid
	WHERE	BP.Winlostdate <= @winlostdate	
			AND BP.STatusID NOT IN (0,1)					 							
			AND B.Winlostdate <= @winlostdate
			AND B.STatusID NOT IN (0,1)						
	GROUP BY BP.AgentId 		
	UNION ALL
	-- for balance record
	SELECT	SUM(BP.AWinlost) as Amount,
			SUM(BP.AWinlost*e.actualrate)  agentAmount
		FROM BetTrans_Agent BP  WITH (ROWLOCK, index =IX_WinlostDate_StatusId_Bettype) 			
			INNER JOIN exchange e with (nolock) ON BP.currency=e.exchangeid
		WHERE	BP.Winlostdate <= @winlostdate	
				AND BP.STatusID NOT IN (0,1)	
				AND BP.bettype >= 20000  --BALANCE 								
		GROUP BY BP.AgentId 	
	) T

--select @memberSUM, @memberAmount , @agentSUM, @agentAmount

INSERT INTO dbo.Task_BalanceRecord (step, winlostdate, SPCode, TotalAmt, TotalSum)
SELECT @InitStepNo, @winlostdate, 0,
	(isnull(@memberAmount,0) + isnull(@agentAmount,0)) totalamt,
	(isnull(@memberSUM ,0)+ isnull(@agentSUM,0)) TotalSUM

