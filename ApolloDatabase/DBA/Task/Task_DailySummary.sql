SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_DailySummary]
	@WinLostDate date,
	@TestMode tinyint = 0
AS

/*
Created by: Sophia
Date: 20130505
Task:	- Daily Summary
		- Update outright on ProdDB via linked server call: Task_DailySummary_DB02_Copy/Delete 
DB: SVRTXN.TransDB
Revisions:	
	- 20130923@Sophia: Exclude Parlay and outright in ActualTO
	- 20131004@Dan: update summary winlost report section

 */

SET NOCOUNT ON

Declare @Doing nvarchar(300)
SET @Doing = 'Call Task_DailySummary @WinLostDate = ' + CONVERT(nvarchar(10), @WinLostDate, 120) + ', @TestMode = ' + CAST(@TestMode as nvarchar(2))
EXEC dbo.WriteLog_UserLog_T @UserID = 25520, @Doing = @Doing  

-- update ticket (if any) which WinLostDate is not synced with eventdate 
UPDATE b
SET WinLostDate = o.eventdate
FROM dbo.bettrans b WITH (ROWLOCK,UPDLOCK)
INNER JOIN dbo.outright o  WITH (NOLOCK) ON b.matchid = o.orid
WHERE b.winlostdate <> o.eventdate

UPDATE b
SET WinLostDate = o.eventdate
FROM dbo.BetTrans_Agent b WITH (ROWLOCK,UPDLOCK)
INNER JOIN dbo.outright o  WITH (NOLOCK) ON b.matchid = o.orid
WHERE b.winlostdate <> o.eventdate
-----

UPDATE b
SET winlostdate = m.eventdate
FROM dbo.bettrans b WITH (ROWLOCK,UPDLOCK)
INNER JOIN dbo.match m  WITH (NOLOCK) ON b.matchid = m.matchid
WHERE b.winlostdate <> m.eventdate

UPDATE b
SET winlostdate = m.eventdate
FROM dbo.BetTrans_Agent b WITH (ROWLOCK,UPDLOCK)
INNER JOIN dbo.match m WITH (NOLOCK) ON b.matchid = m.matchid
WHERE b.winlostdate <> m.eventdate

 
-- ====================
-- DATA VERIFICATION
-- ====================


IF EXISTS (
	SELECT	TransId FROM bettrans WITH (NOLOCK)
	WHERE	statusID = 0
			AND custid <> 0
			AND bettype <=19000 AND bettype <> 10 AND winlostdate <= @winlostdate
			AND currency <> 20
)
BEGIN
	SELECT DISTINCT matchid, bettype, 'EXEC DBA_MatchName ' + CAST(matchid as nvarchar(20)) cmd FROM bettrans WITH (NOLOCK)
	WHERE	winlostdate <= @winlostdate 		
			AND statusID = 0 
			AND bettype <=19000 and bettype NOT IN (9, 10, 29)
			AND currency <> 20

	SELECT DISTINCT 'EXEC DBA_MatchName ' + CAST(bm.matchid as varchar(10)) matchid, m.eventdate, bm.matchid, ',' [Comma]
	FROM dbo.bettrans b WITH (NOLOCK)
		INNER JOIN dbo.bettransm bm WITH (NOLOCK) ON b.refno = bm.refno
		INNER JOIN dbo.match m WITH (NOLOCK) ON bm.matchid = m.matchid
	WHERE	b.winlostdate <= @winlostdate 
			AND b.statusID = 0 AND bm.statusID = 0 
			AND b.bettype in (9,29)
			AND b.matchID in (9,29)
			AND b.currency <> 20
	ORDER BY m.eventdate

	IF @@ROWCOUNT > 0
	BEGIN
		PRINT '--'
		PRINT '--SELECT CONVERT(VARCHAR(20),transID) + '','', * FROM bettrans WITH (NOLOCK) WHERE statusid = 0 AND matchid IN (9,29) AND bettype IN (9,29) AND winlostdate <= ''' + CONVERT(varchar(10), @winlostdate, 120) + ''''
		PRINT '--UPDATE dbo.bettrans SET winlostdate = ''' + CONVERT(varchar(10), DATEADD(day,1,@winlostdate), 120) + ''' WHERE transid IN ( xxxxx )'
		PRINT '--UPDATE dbo.bettrans_Agent SET winlostdate = ''' + CONVERT(varchar(10), DATEADD(day,1,@winlostdate), 120) + ''' WHERE transid IN ( xxxxx )'
		PRINT '--'
	END

	RAISERROR ('FAILED: Have running tickets', 16, 1)
	RETURN
END
-- ====================
---No need
--IF EXISTS (
--	SELECT transid FROM bettrans WITH (NOLOCK)
--	WHERE srecommend <= 100 AND (scomm <> acomm OR swinlost <> 0)
--	AND bettype <=19000 AND winlostdate = @winlostdate
--)
--BEGIN
--	RAISERROR ('FAILED: Incorrect Company SuperAgent setting', 16, 1)
--	RETURN
--END

-- ====================
IF EXISTS (
	SELECT transid FROM BetTrans WITH (NOLOCK)
	WHERE (PlayerComm IS NULL OR WinLost IS NULL)
		  AND bettype <=19000 AND winlostdate = @winlostdate
)
BEGIN
	RAISERROR ('FAILED: Null Commission/WinLost of Member', 16, 1)
	RETURN
END
-- ====================
IF EXISTS (
	SELECT transid FROM BetTrans_Agent WITH (NOLOCK)
	WHERE (AComm IS NULL OR AWinLost IS NULL)
		  AND bettype <=19000 AND winlostdate = @winlostdate
)
BEGIN
	RAISERROR ('FAILED: Null Commission/WinLost of Agent', 16, 1)
	RETURN
END
-- ====================
IF EXISTS (
	SELECT currency
	FROM bettrans WITH (NOLOCK)
	WHERE bettype <=19000 AND winlostdate = @winlostdate
	AND NOT (bettype = 10 and statusID = 0) -- exclude running outright
	GROUP BY currency
	HAVING COUNT(DISTINCT actualrate) > 1
)
BEGIN
	RAISERROR ('FAILED: Multiple Exchange Rate', 16, 1)
	RETURN
END
-- ====================
 
IF @TestMode = 1
BEGIN
	PRINT 'DATA OK'

	IF EXISTS (SELECT 1 FROM bettrans WITH (NOLOCK)
		WHERE bettype = 10 
			AND statusID = 0 
			AND winlostdate = @winlostdate)
		PRINT 'Some Outright need to moved : Run with parameter = 2'

	IF EXISTS (SELECT 1 FROM bettrans WITH (NOLOCK)
		WHERE currency = 20
			AND winlostdate = @winlostdate
			AND bettype <=19000
			AND statusID = 0)
		PRINT 'Some TEST Ticket need to Refund : Run with parameter = 2'

	SET @Doing = 'Task_DailySummary : End Test'
	EXEC dbo.WriteLog_UserLog_T @UserID = 25520, @Doing = @Doing  

	RETURN
END

-- =====================
-- OUTRIGHT WINLOST MOVE
-- =====================

SELECT	TOP 1 transid FROM bettrans WITH (NOLOCK)
WHERE	bettype = 10 
		AND statusID = 0 
		AND winlostdate = @winlostdate  

IF @@ROWCOUNT > 0
BEGIN
	Declare @outright TABLE (orid int)
	INSERT INTO @outright SELECT distinct matchid FROM bettrans WITH (NOLOCK)
	WHERE	bettype = 10 
			AND statusID = 0 
			AND winlostdate <= @winlostdate

	---- Outright will be replicated from IBC
	--UPDATE O
	--SET eventdate = DATEADD(day, 1, @winlostdate), changeTime = GETDATE()
	--FROM SVRPRO.ProdDB.dbo.outright O WITH (UPDLOCK, ROWLOCK)
	--WHERE orid IN (SELECT orid FROM @outright)

	UPDATE bettrans WITH (UPDLOCK, ROWLOCK) 
	SET winlostdate = DATEADD(day, 1, @winlostdate)
	WHERE bettype = 10 AND matchid IN (SELECT orid FROM @outright)

	UPDATE BetTrans_Agent WITH (UPDLOCK, ROWLOCK) 
	SET winlostdate = DATEADD(day, 1, @winlostdate)
	WHERE bettype = 10 AND matchid IN (SELECT orid FROM @outright)
END

-- =====================
-- AUTO VOID TEST TICKET
-- =====================
	IF EXISTS (
		SELECT 1 FROM dbo.bettrans WITH (NOLOCK)
		WHERE currency = 20 AND winlostdate = @winlostdate AND bettype <=19000
		AND statusID = 0
	)
	BEGIN
		DECLARE @custs TABLE (custid int)
		
		UPDATE dbo.bettrans with (ROWLOCK, UPDLOCK)  
		SET winlost=actual_stake, 
			playercomm = 0,
			Twinlost = 0,
			Tcomm = 0, 
			ruben=1, 
			statuswinlost=6, 
			status = 'Void',
			statusid = 102,
			transdesc = '[AutoVoid]' + transdesc
		OUTPUT deleted.custid INTO @custs
		where currency = 20 AND winlostdate = @winlostdate AND bettype <=19000
		AND statusID IN (0,1)

		UPDATE dbo.BetTrans_Agent with (ROWLOCK, UPDLOCK)  
		SET AWinLost=0, 
			AComm = 0,
			status = 'Void',
			statusid = 102,
			transdesc = '[AutoVoid]' + transdesc
		where currency = 20 AND winlostdate = @winlostdate AND bettype <=19000
		AND statusID IN (0,1)

		
		INSERT INTO dbo.Task_Cust_CheckBalanceVerify (custid)
		SELECT DISTINCT custid
		FROM @custs
		
		EXEC dbo.[Task_CheckBalance] @step = 33, @Action = 'JustFix'
	END


IF @TestMode <> 0 -- @TestMode = 2
BEGIN
	SET @Doing = 'Task_DailySummary : End Test (with Outright update)'
	EXEC dbo.WriteLog_UserLog_T @UserID = 25520, @Doing = @Doing  


	PRINT 'DATA OK && Outright Update : done'
	RETURN
END

-- =====================
-- Daily Summary Process
-- =====================

-- Summary WinLost Report : Later
/*
EXEC DB06.bodb02.dbo.Task_rptWinLost_UpdateTable @winlostdate
WAITFOR DELAY '000:00:30'
*/

---- No Need because Delete /Cancel ticket not have custID = 0 any more 
---- Clear deleted/cancel record (custid = 0)
----DELETE FROM bettrans WHERE winlostdate=@winlostdate AND custid = 0



DELETE FROM BetTrans_Sum WHERE winlostdate=@winlostdate
DELETE FROM BetTrans_Agent_Sum WHERE winlostdate=@winlostdate
DELETE FROM Task_BalanceRecord WHERE winlostdate=@winlostdate


-- Get Exchange Rate
DECLARE @Exchange TABLE (currency tinyint, actualrate float, CurrencyName nvarchar(50))
INSERT INTO @Exchange (currency, actualrate)
SELECT DISTINCT currency, actualrate
FROM dbo.bettrans WITH (NOLOCK)
WHERE winlostdate = @winlostdate AND bettype <=19000

UPDATE @Exchange
SET CurrencyName = e.currency
FROM @Exchange ex, dbo.exchange e WITH (NOLOCK)
WHERE ex.currency = e.exchangeid

-- Generate SUM record
INSERT INTO dbo.Bettrans_Sum (custid, currency, winlostdate, stake, actual_stake, winlost, playercomm, TWinLost, TComm)
SELECT	custid, currency, winlostdate,
		sum(stake) stake, sum(actual_stake) actual_stake,
		sum(winlost) winlost, sum(playercomm) playercomm,
		sum(TWinLost) TWinLost, sum(playercomm) TComm
FROM	bettrans WITH (PAGLOCK)
WHERE	winlostdate=@winlostdate and
		bettype <=19000 and 	
		statusID NOT IN (101,102) -- ('VOID', 'REJECT')
GROUP BY custid, currency, winlostdate 


INSERT INTO dbo.Bettrans_Agent_Sum (AgentId, CustID, Currency, Winlostdate, stake, actual_stake, AWinlost, AComm)
SELECT	ba.AgentId, b.CustID, ba.currency, ba.winlostdate, 
		sum(ba.stake) stake, sum(ba.actual_stake) actual_stake,
		sum(ba.Awinlost) Awinlost, sum(ba.AComm) AComm
FROM	Bettrans_Agent ba WITH (PAGLOCK)
INNER JOIN 	Bettrans b WITH (PAGLOCK) ON b.TransId = ba.TransId
WHERE	ba.winlostdate=@winlostdate and
		ba.bettype <=19000 and 	
		ba.statusID NOT IN (101,102) -- ('VOID', 'REJECT')
GROUP BY ba.AgentId, b.CustID, ba.currency, ba.winlostdate 


-- =====================
	
	---- Outright will be replicated from IBC
	--UPDATE O
	--SET eventdate = @winlostdate, changeTime = GETDATE()
	--FROM SVRPRO.ProdDB.dbo.Outright O WITH (UPDLOCK, ROWLOCK)
	--WHERE orid IN 
	--	(SELECT distinct matchid 
	--	FROM bettrans WITH (NOLOCK) 
	--	WHERE bettype = 10 AND winlostdate = @winlostdate AND statusID <> 0 
	--	)

-- Copy odds/match/outright -> odd14/match14/outright14 for whole day of @winlostdate
EXEC SVRPRO.ProdDB.dbo.Task_DailySummary_ProdDB_Copy @winlostdate

---later
EXEC Task_BalanceCheck @winlostdate, 1


UPDATE SVRCSD.RepDB.dbo.SystemSettings
SET VValue = '1'
WHERE VName = 'isMovingBet' 

-- =====================
SET @Doing = 'Task_DailySummary : MoveBet start'
EXEC dbo.WriteLog_UserLog_T @UserID = 25520, @Doing = @Doing  

SET NOCOUNT ON
SET DEADLOCK_PRIORITY HIGH
-- =====================

-- Copy bettransm -> bettransm14 for whole day of @winlostdate
EXEC dbo.ExecRep_08 @winlostdate = @winlostdate, @parlay = 1

-- Delete bettransm for whole day of @winlostdate
EXEC dbo.ExecRep_09 @winlostdate = @winlostdate, @parlay = 1

--set FALSE for the flag isMovingBet on SVRCSD.RepDB.dbo.SystemSettings to allow the Mix Parlay calculation again
UPDATE SVRCSD.RepDB.dbo.SystemSettings
SET VValue = '0'
WHERE VName = 'isMovingBet' 

----##### Bettrans ######----

DECLARE @ids varchar(max), @rowcnt int      

DECLARE @CustID_List TABLE (custid INT PRIMARY KEY, isfinished BIT)

INSERT INTO @CustID_List (custid, isfinished)
SELECT DISTINCT custid, 0
FROM bettrans WITH (NOLOCK)
WHERE winlostdate = @winlostdate AND bettype < 19999
 
  
WHILE (1=1)
BEGIN
	SELECT @ids = ''
	
	UPDATE TOP (200) @CustID_List
	SET @ids = @ids + case @ids when '' then '' else ',' end + cast(custid as varchar(12))
		,isfinished = 1
	FROM @CustID_List
	WHERE isfinished = 0
	
	SELECT @rowcnt = @@rowcount	

	BEGIN TRANSACTION
		EXEC dbo.ExecRep_08 @CustIDs = @ids, @IsAgent = 0, @winlostdate = @winlostdate, @parlay = 0   /* copy ticket from [active] to [14] for bettrans */
	COMMIT TRANSACTION

	BEGIN TRANSACTION
		EXEC dbo.ExecRep_09 @CustIDs = @ids, @IsAgent = 0, @winlostdate = @winlostdate, @parlay = 0 /* delete ticket from bettrans/bettransm */
	
			---Member
		INSERT INTO bettrans
			(ruben, status, statusID, matchid, bettype, refno, creator, transdate,
			custid, currency, 
			winlostdate, stake, winlost, 
			actual_stake, playercomm, 
			TPositiontaking,TWinlost, TComm,
			actualrate, virtualrate, Username, CurrencyName, DoubleCommLosing)
		SELECT
			1, 'SUM', 142, 0, 19999, refno, 8, winlostdate, 
			b.custid, b.currency,
			winlostdate, stake, winlost,
			actual_stake, playercomm, 
			0, TWinlost, TComm,
			e.actualrate, e.actualrate, c.username, e.CurrencyName, 0
		FROM Bettrans_Sum b WITH (NOLOCK)
			INNER JOIN @Exchange e ON b.currency = e.currency
			INNER JOIN custinfo c WITH (NOLOCK) ON b.custid = c.custid 
		WHERE	Winlostdate = @winlostdate
				AND b.CustID IN (select val FROM StrSplit_key(@ids,','))

	COMMIT TRANSACTION

    IF @rowcnt < 200 BREAK         
 
    WAITFOR DELAY '00:00:01'
END


----##### Bettrans_Agent ######----


DECLARE @AgentID_List TABLE (AgentId INT PRIMARY KEY, isfinished BIT)

INSERT INTO @AgentID_List (AgentId, isfinished)
SELECT DISTINCT AgentId, 0
FROM Bettrans_Agent (nolock) WHERE winlostdate = @winlostdate AND bettype < 19999
 
    

WHILE (1=1)
BEGIN
	SELECT @ids = ''
	
	UPDATE TOP (100) @AgentID_List
	SET @ids = @ids + case @ids when '' then '' else ',' end + cast(AgentId as varchar(12))
		,isfinished = 1
	FROM @AgentID_List
	WHERE isfinished = 0
	
	SELECT @rowcnt = @@rowcount	

	BEGIN TRANSACTION
		EXEC dbo.ExecRep_08 @CustIDs = @ids, @IsAgent = 1, @winlostdate = @winlostdate, @parlay = 0 /* copy ticket from [active] to [14] for bettrans */
	COMMIT TRANSACTION

	BEGIN TRANSACTION
		EXEC dbo.ExecRep_09 @CustIDs = @ids, @IsAgent = 1, @winlostdate = @winlostdate, @parlay = 0 /* delete ticket from bettrans/bettransm */

	---Agent	
		INSERT INTO BetTrans_Agent
			(transID, status, statusID, matchid, bettype, refno, transdate,
			AgentId, currency, 
			winlostdate, stake, actual_stake,
			AWinLost,  AComm,
			actualrate, virtualrate, Username, CurrencyName)
		SELECT
			b.transID, 'SUM', 142, 0, 19999, ba.refno, ba.winlostdate, 
			ba.AgentId, ba.currency,
			ba.winlostdate, ba.stake, ba.actual_stake,
			ba.AWinlost, ba.AComm, 
			e.actualrate, e.actualrate, A.username, e.CurrencyName
		FROM 
			Bettrans_Agent_Sum ba WITH (NOLOCK)		
			INNER JOIN Bettrans b WITH (NOLOCK) ON b.CustID = ba.CustId and b.Winlostdate = ba.winlostdate and b.Bettype = 19999 
			INNER JOIN @Exchange e ON ba.currency = e.currency
			INNER JOIN AgentInfo A WITH (NOLOCK) ON ba.AgentId = A.AgentId 
		WHERE 
			ba.winlostdate=@winlostdate
			AND ba.AgentId IN (select val FROM StrSplit_key(@ids,','))

	COMMIT TRANSACTION

    IF @rowcnt < 100 BREAK         
 
    WAITFOR DELAY '00:00:01'
END


-- =====================
SET DEADLOCK_PRIORITY NORMAL
SET NOCOUNT OFF

SET @Doing = 'Task_DailySummary : MoveBet done'
EXEC dbo.WriteLog_UserLog_T @UserID = 25520, @Doing = @Doing 

 
-- =====================
--Later
EXEC Task_BalanceCheck @winlostdate, 2
-- =====================

SET @Doing = 'Task_DailySummary : SumWinlost start insert'
EXEC dbo.WriteLog_UserLog_T @UserID = 25520, @Doing = @Doing  

EXEC Task_SummaryReport_GenData @winlostdate

SET NOCOUNT OFF

-- =====================
Delete Match_Log where matchID IN (Select matchID From Match WITH (NOLOCK) Where eventdate=@winlostdate)

Delete from outright_log
where orid in (select orid from outright where eventdate = @winlostdate AND oddsstatus = 'Completed')

-- =====================

EXEC [Task_AutoSettlement_CleanUp] @winlostdate

EXEC SVRPRO.ProdDB.dbo.Task_DailySummary_ProdDB_Delete @winlostdate



SET @Doing = 'Task_DailySummary : End (with Finish)'
EXEC dbo.WriteLog_UserLog_T @UserID = 25520, @Doing = @Doing  

PRINT CONVERT(varchar(10), @winlostdate, 120)
