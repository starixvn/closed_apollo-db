
/****** Object:  StoredProcedure [dbo].[Task_BalanceUp_background]    Script Date: 05/20/2013 05:34:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Task_BalanceUp    Script Date: 5/23/2011 6:34:21 PM ******/
ALTER PROCEDURE [dbo].[Task_BalanceUp_background]
	@fdate as date = NULL,
	@step as tinyint = 1
AS

Declare @Doing nvarchar(300)

/*
Created: 20130530@Sophia
Task : Balance Up
DB: SVRTXN.TransDB
Original:

Revisions: 
	- 20131230@Sophia: Not insert Balance ticket (bettype 20000) for deleted AgentID (AgentID not have data in AgentInfo)
	
Param's Explanation: 

*/

IF @fdate IS NULL
BEGIN
	SELECT	TOP 1 @fdate = DATEADD(day, 7, winlostdate)
	FROM	bettrans with (nolock)
	WHERE	matchid = 0 and bettype = 20000
	ORDER BY transid
	
	IF @fdate IS NULL
	BEGIN 
	-- raiserror here to continue to next step of jobs
		RAISERROR ('Please specify a balance up date (first time balance-up', -- Message text.
					16, -- Severity.
					1 -- State.
					);
	END

	IF @fdate > CURRENT_TIMESTAMP
		SET @fdate = DATEADD(day, -7, @fdate)
END


PRINT '@fdate = ' + CONVERT(varchar(10), @fdate, 120)

SET @Doing = 'call Task_BalanceUp_background @fdate = ' + CONVERT(nvarchar(10), @fdate, 120) + ', @step = ' + CAST(@step as nvarchar(2))
EXEC dbo.WriteLog_UserLog_T @UserID = 70, @Doing = @Doing  




-- ================== STEP : 1 
IF @step = 1
BEGIN
-- ================== DATA VERIFY

	--- DATA VERIFY
	
	IF EXISTS (SELECT * FROM bettrans with (nolock) WHERE winlostdate < @fdate AND (Winlost IS NULL OR PlayerComm IS NULL))
	BEGIN 
	-- raiserror here to continue to next step of jobs
		RAISERROR ('Some records in BetTrans have Null Commission/WinLost of Member', -- Message text.
				   16, -- Severity.
				   1 -- State.
				   );
	END
	
	IF EXISTS (SELECT * FROM bettrans_Agent with (nolock) WHERE winlostdate < @fdate AND (AWinlost IS NULL OR AComm IS NULL))
	BEGIN 
	-- raiserror here to continue to next step of jobs
		RAISERROR ('Some records in bettrans_Agent have Null Commission/WinLost of Member', -- Message text.
				   16, -- Severity.
				   1 -- State.
				   );
	END
	
-- ================== END STEP : 1 
END
-- ================== DATA VERIFY

--- START --- START --- START ---
--- START --- START --- START ---
--- START --- START --- START ---


-- ================== STEP : 2
IF @step = 2
BEGIN
-- ================== Clear BalanceTable and Perform Backup

	UPDATE SVRCSD.RepDB.dbo.SystemSettings
	SET VValue = '1'
	WHERE VName = 'isArchivingBet' 

	---- for safety, shutdown trigger in BalanceTable_tmp	 
	EXEC Task_BalanceUp_TriggerControl @On = 0

	truncate table BalanceTable
	truncate table BalanceTable_tmp
	truncate table BalanceTable_Agent
	truncate table BalanceTable_Agent_Tmp

	---later
	EXEC dbo.Task_BalanceCheck @fdate, 11
	/*
	-- doing backup
	Declare @suffix varchar(10)
	SET @suffix = 'bbu' + RIGHT(CONVERT(varchar(10), @fdate,120),5)

	--EXEC dbo.Task_BackupFULL_TransDB @suffix
	--EXEC SVRPRO.ProdDB.dbo.Task_BackupFULL_ProdDB @suffix
	--EXEC SVRCUST.CustDB.dbo.Task_BackupFULL_CustDB @suffix
	-- doing backup : end
	*/
-- ================== END STEP : 2
END
-- ================== Clear BalanceTable and Perform Backup



-- ================== STEP : 3
IF @step = 3
BEGIN
-- ================== Calculate Balance

	-- =====================
	--   CALCULATE BALANCE
	-- =====================
 
		-- Member
		INSERT INTO BalanceTable(Custid, Amount, TicketCount, BalTicketCount)
		SELECT	custid,
				SUM (winlost - actual_stake + playercomm) amount,
				COUNT(*) TicketCount,
				SUM(CASE bettype WHEN 20000 THEN 1 ELSE 0 END) balTicketCount
		FROM  bettrans WITH (ROWLOCK, index =IX_WinlostDate_StatusId_Bettype)
		WHERE	Winlostdate < @Fdate 
				AND StatusId NOT IN (0,1)			 
		GROUP BY custid
	 
		-- Agent
		INSERT INTO BalanceTable_Agent (AgentId, Amount, TicketCount, BalTicketCount)		
		SELECT  AgentId, sum (Amount) Amount, 
			sum(TicketCount) TicketCount, 
			sum(balTicketCount) balTicketCount
		FROM
			(
			-- get winlost for direct child agent
			SELECT	BP.AgentId, 						
						SUM(BP.AWinlost + BP.AComm  - BA.AComm) as Amount,
						COUNT (*) TicketCount,
						0 AS balTicketCount
				FROM BetTrans_Agent BP  WITH (ROWLOCK, index =IX_WinlostDate_StatusId_Bettype) 		
				JOIN AgentInfo A WITH (NOLOCK) ON A.ParentID = BP.AgentId
				JOIN BetTrans_Agent BA WITH (ROWLOCK ) ON A.AgentId = BA.AgentId AND BP.TransId = BA.TransId										
				WHERE	BP.Winlostdate <  @Fdate		
						AND BP.STatusID NOT IN (0,1)	
						AND BP.BETTYPE<20000
						AND BA.Winlostdate <  @Fdate	
						AND BA.STatusID NOT IN (0,1)	 				
						AND BA.BETTYPE<20000							
				GROUP BY BP.AgentId 
			UNION ALL				
			-- get winlost for direct member
			SELECT	BP.AgentId, 
						SUM(BP.AWinlost + BP.AComm  - B.PlayerComm) as Amount,
						COUNT (*) TicketCount,
						0 balTicketCount
				FROM BetTrans_Agent BP  WITH (ROWLOCK, index =IX_WinlostDate_StatusId_Bettype) 
					INNER JOIN bettrans B WITH (ROWLOCK, index =IX_WinlostDate_StatusId_Bettype) ON B.TransId = BP.TransId	
					INNER  JOIN CustInfo c WITH (NOLOCK) ON c.AgentId = BP.AgentId	and c.CustId=b.CustId
				WHERE	BP.Winlostdate <  @Fdate		
						AND BP.STatusID NOT IN (0,1)					 							
						AND B.Winlostdate <  @Fdate 
						AND B.STatusID NOT IN (0,1)						
				GROUP BY BP.AgentId 		
			UNION ALL
			-- for balance record
			SELECT	BP.AgentId, 
						SUM(BP.AWinlost) as Amount,
						0 as TicketCount,
						COUNT (*) balTicketCount
				FROM BetTrans_Agent BP  WITH (ROWLOCK, index =IX_WinlostDate_StatusId_Bettype) 			
				WHERE	BP.Winlostdate <  @Fdate		
						AND BP.STatusID NOT IN (0,1)	
						AND BP.bettype >= 20000  --BALANCE 								
				GROUP BY BP.AgentId 	
			) T
		GROUP BY AgentId  
 
		----- Delete AgentID not have data in AgentInfo (Deleted AgentID)
		DELETE	B
		FROM	BalanceTable_Agent B
		LEFT JOIN AgentInfo  A 
			ON	A.AgentId = B.AgentId
		WHERE	A.AgentID IS NULL

	 
		UPDATE b
		SET	currency  = c.currency,
			UserName  = c.username,
			CurrencyName = e.currency,
			actualrate = e.ActualRate ------Later: IsNull(ed.ActualRate, e.ActualRate)
		FROM BalanceTable b
			INNER JOIN Custinfo c WITH (NOLOCK) ON b.custid = c.custid
			INNER JOIN Exchange e WITH (NOLOCK) ON c.currency = e.exchangeid
			----Later : LEFT OUTER JOIN bodb02.dbo.ExchangeDailyOanda ed ON c.currency = ed.ExchangeId AND ed.ExchangeDate = @fdate


		UPDATE b
		SET	currency  = A.currency,
			UserName  = A.username,
			CurrencyName = E.currency,
			actualrate = E.ActualRate ------Later: IsNull(ed.ActualRate, e.ActualRate)
		FROM BalanceTable_Agent B
			INNER JOIN AgentInfo A WITH (NOLOCK) ON A.AgentId = A.AgentId
			INNER JOIN Exchange E WITH (NOLOCK) ON A.currency = e.exchangeid
			----Later : LEFT OUTER JOIN bodb02.dbo.ExchangeDailyOanda ed ON A.currency = ed.ExchangeId AND ed.ExchangeDate = @fdate


		-- copy data, ready for insertion
		-- customer
		INSERT INTO BalanceTable_tmp(
			[WinlostDate]
			,[CustId]
			,[Amount]
			,[Currency]
			,[Username]
			,[CurrencyName]
			,[ActualRate]
			,[TicketCount]
			,[BalTicketCount])
		SELECT @fdate
			,[CustId]
			,[Amount]
			,[Currency]
			,[Username]
			,[CurrencyName]
			,[ActualRate]
			,[TicketCount]
			,[BalTicketCount]
		FROM BalanceTable

		--agent
		DECLARE @TransID BIGINT

		--create a dummy record in bettrans so that we can link to bettrans_agent Balance record
		INSERT INTO dbo.bettrans
			(transdate, winlostdate, custid, checktime,
			winlost, PlayerComm, actual_stake, 
			bettype, matchid, status, statusID, transdesc, refno, creator, ruben,
			currency, username, currencyname, actualrate, virtualrate)

		SELECT 	@fdate, @fdate, 0, CURRENT_TIMESTAMP,
			0 as Winlost,
			0 as PlayerComm,
			0 as actual_stake,
			20000, 0, 'BALANCE', 141, 'OPENING BALANCE', 260000000000, 8, 1,
			0, '', '', 0, 0
		
		SELECT @TransID = SCOPE_IDENTITY()


		INSERT INTO BalanceTable_Agent_tmp(
				[TransID],[WinlostDate]
				,[AgentId],[Amount]	,[Currency]	,[Username]	,[CurrencyName]	,[ActualRate]
				,[TicketCount],[BalTicketCount])
		SELECT @TransID, @fdate,
				[AgentId],[Amount],[Currency],[Username],[CurrencyName],[ActualRate]
				,[TicketCount],[BalTicketCount] 
		FROM BalanceTable_Agent
 
	-- =====================
	--   CLEAN OLD EVENTS
	-- =====================
		
		EXEC Task_BalanceUp_DeleteOldMatch @fdate

		EXEC SVRPRO.ProdDB.dbo.Task_BalanceUp_ProdDB @fdate

	EXEC Task_BalanceUp_TriggerControl @on = 1

-- ================== END STEP : 3
END
-- ================== Calculate Balance


-- ======================
--   INSERT NEW BALANCE
-- ======================
-- start remove transaction/insert balance

-- ================== STEP : 4
IF @step = 4
BEGIN
-- ================== BalanceUp Cust
	SET NOCOUNT ON
	 EXEC Task_BalanceUp_Cust @fdate
	SET NOCOUNT OFF
-- ================== END STEP : 4
END
-- ================== BalanceUp Cust

-- ================== STEP : 5
IF @step = 5
BEGIN
-- ================== BalanceUp Agent
	SET NOCOUNT ON

	EXEC dbo.Task_BalanceUp_Agent @fdate
	SET NOCOUNT OFF
-- ================== END STEP : 5
END
-- ================== BalanceUp Agent


-- ================== STEP : 6
IF @step = 6
BEGIN
-- ================== Finishing

	EXEC dbo.Task_BalanceUp_TriggerControl @on = 0

	-- end comment

	----later
	--EXEC dbo.balancecheck @fdate, 21
	EXEC dbo.Task_BalanceCheck @fdate, 12

	UPDATE SVRCSD.RepDB.dbo.SystemSettings
	SET VValue = '0'
	WHERE VName = 'isArchivingBet' 

	SET @Doing = 'Task_BalanceUp_background : Done'
	EXEC dbo.WriteLog_UserLog_T @UserID = 70, @Doing = @Doing  
-- ================== END STEP : 6
END
-- ================== Finishing

