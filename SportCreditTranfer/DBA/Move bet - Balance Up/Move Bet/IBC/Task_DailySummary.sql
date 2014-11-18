USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_DailySummary]    Script Date: 06/26/2013 01:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_DailySummary]
	@winlostdate datetime,
	@TestMode tinyint = 0
AS

-- Run on TransDB
-- update outright on DB02 via linksed server
-- called DB02 : Task_DailySummary_DB02_Copy/Delete via linked server

/*
Created by:[]
Date:
Task: daily summary
DB: DBTRANS.BODB02
Revisions:
    - 20100825@Lukas: Update last time modify (changetime column) for Outright table
	- 20100914@Jamie: Modify Bingo and Number Game
	- 20101007@Henry: Change column transid from INT to BIGINT
	- 20101229@Viet: Add moving for data from BingoBall table
	- 20110523@Jamie: Re-arrange bet type : 1 - 19000 : used for bet tickets
	- 20110803@Henry: expand bettype Number Game from 81 to 120
    - 20110910@Viet: Check running tickets of MP combination
    - 20110822@Sophia: Count Negative stake as positive turnover
    - 20111005@Tom: 1. Edit bet type of P2P: 72->1000
					2. Remove parameter @ABSDate '2011-09-01'      
	- 20120206@Sophia: Add Sporttype for Live Casino    
	- 20120807@Sophia: Add Virtual Sports (sporttype = 180 for representing)
	- 20120927@Sophia: Add column comstatus when insert into bettrans tabble
	- 20130313@Viet: add netTurnover
	- 20130520@Victor: add VSOutright
	- 20130715@Dan: delete match_log, outright_log
 */

SET NOCOUNT ON

Declare @Doing nvarchar(300)
SET @Doing = 'call Task_DailySummary @winlostdate = ' + CONVERT(nvarchar(10), @winlostdate, 120) + ', @TestMode = ' + CAST(@TestMode as nvarchar(2))
EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing  

-- update ticket (if any) which winlostdate is not synced with eventdate 
UPDATE b
SET winlostdate = o.eventdate
FROM dbo.bettrans b
	INNER JOIN dbo.outright o ON b.matchid = o.orid
WHERE b.winlostdate <> o.eventdate

UPDATE b
SET winlostdate = m.eventdate
FROM dbo.bettrans b
	INNER JOIN dbo.match m ON b.matchid = m.matchid
WHERE b.winlostdate <> m.eventdate

UPDATE b
SET winlostdate = o.eventdate
FROM dbo.bettrans b
	INNER JOIN dbo.VSOutright o ON b.matchid = o.EventID
WHERE b.winlostdate <> o.eventdate

DECLARE @transid bigint
-- ====================
-- DATA VERIFICATION
-- ====================
IF EXISTS (
	SELECT transid FROM bettrans with (nolock)
	WHERE	--[status] = 'running' 
			statusID = 0
			AND custid <> 0
			AND bettype <=19000 AND bettype <> 10 AND winlostdate <= @winlostdate
			AND currency <> 20
)
BEGIN
	SELECT DISTINCT matchid, bettype, 'EXEC DBA_MatchName ' + CAST(matchid as nvarchar(20)) cmd FROM bettrans (nolock)
	WHERE	winlostdate <= @winlostdate 
			--AND [status] = 'running'
			AND statusID = 0 
			AND bettype <=19000 and bettype NOT IN (9, 10, 29)
			AND currency <> 20

	SELECT DISTINCT 'EXEC DBA_matchname ' + CAST(bm.matchid as varchar(10)) matchid, m.eventdate, bm.matchid, ',' [Comma]
	FROM dbo.bettrans b (nolock)
		INNER JOIN dbo.bettransm bm (nolock) ON b.refno = bm.refno
		INNER JOIN dbo.match m (nolock) ON bm.matchid = m.matchid
	WHERE	b.winlostdate <= @winlostdate 
			--AND b.[status] = 'running' AND bm.[status] = 'running'
			AND b.statusID = 0 AND bm.statusID = 0 
			AND b.bettype in (9,29)
			--AND b.matchid = 0
			AND b.matchID in (9,29)
			AND b.currency <> 20
	ORDER BY m.eventdate

	IF @@ROWCOUNT > 0
	BEGIN
		PRINT '--'
		PRINT '--SELECT * FROM bettrans (nolock) WHERE status = ''running'' AND matchid IN (9,29) AND bettype IN (9,29) AND winlostdate <= ''' + CONVERT(varchar(10), @winlostdate, 120) + ''''
		PRINT '--UPDATE dbo.bettrans SET winlostdate = ''' + CONVERT(varchar(10), DATEADD(day,1,@winlostdate), 120) + ''' WHERE transid IN ( xxxxx )'
		PRINT '--'
	END

	RAISERROR ('FAILED: Have running tickets', 16, 1)
	RETURN
END
-- ====================
IF EXISTS (
	SELECT transid FROM bettrans with (nolock)
	WHERE srecommend <= 100 AND (scomm <> acomm OR swinlost <> 0)
	AND bettype <=19000 AND winlostdate = @winlostdate
)
BEGIN
	RAISERROR ('FAILED: Incorrect Company SuperAgent setting', 16, 1)
	RETURN
END
-- ====================
IF EXISTS (
	SELECT transid FROM bettrans with (nolock)
	WHERE (scomm IS NULL OR acomm IS NULL OR comm IS NULL OR playercomm IS NULL
	OR swinlost IS NULL OR mwinlost IS NULL OR awinlost IS NULL OR winlost IS NULL)
	AND bettype <=19000 AND winlostdate = @winlostdate
)
BEGIN
	RAISERROR ('FAILED: Null Commission/WinLost', 16, 1)
	RETURN
END
-- ====================
IF EXISTS (
	SELECT currency
	FROM bettrans (nolock)
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

	IF EXISTS (SELECT 1 FROM bettrans with (nolock)
		WHERE bettype = 10 
			--AND [status] = 'running'
			AND statusID = 0 
			AND winlostdate = @winlostdate)
		PRINT 'Some Outright need to moved : Run with parameter = 2'

	IF EXISTS (SELECT 1 FROM bettrans with (nolock)
		WHERE currency = 20
			AND winlostdate = @winlostdate
			AND bettype <=19000
			AND statusID = 0)
		PRINT 'Some TEST Ticket need to Refund : Run with parameter = 2'

	SET @Doing = 'Task_DailySummary : End Test'
	EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing  

	RETURN
END
 
-- =====================
-- OUTRIGHT WINLOST MOVE
-- =====================

SELECT	TOP 1 @transid = transid FROM bettrans with (nolock)
WHERE	bettype = 10 
		--AND [status] = 'running'
		AND statusID = 0 
		AND winlostdate = @winlostdate

IF @@ROWCOUNT > 0
BEGIN
	Declare @outright TABLE (orid int)
	INSERT INTO @outright SELECT distinct matchid FROM bettrans with (nolock)
	WHERE	bettype = 10 
			--AND [status] = 'running' 
			AND statusID = 0 
			AND winlostdate <= @winlostdate

	UPDATE O
	SET eventdate = DATEADD(day, 1, @winlostdate), changeTime = GETDATE()
	FROM DB02.bodb02.dbo.outright O WITH (UPDLOCK, ROWLOCK)
	WHERE orid IN (SELECT orid FROM @outright)

	UPDATE bettrans WITH (UPDLOCK, ROWLOCK) SET winlostdate = DATEADD(day, 1, @winlostdate)
	WHERE bettype = 10 AND matchid IN (SELECT orid FROM @outright)
END

-- =====================
-- AUTO VOID TEST TICKET
-- =====================
	IF EXISTS (
		SELECT 1 FROM dbo.bettrans with (nolock)
		where currency = 20 AND winlostdate = @winlostdate AND bettype <=19000
		AND statusID = 0
	)
	BEGIN
		Declare @custs TABLE (custid int)
		
		update dbo.bettrans with (ROWLOCK, UPDLOCK)  
		SET winlost=actual_stake,ruben=1,statuswinlost=6, status = 'Void', statusid = 102,
		awinlost = 0, mwinlost = 0, swinlost = 0, playercomm = 0, comm  = 0, acomm = 0, scomm = 0,
		transdesc = '[AutoVoid]' + transdesc
		OUTPUT deleted.custid INTO @custs
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
	EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing  


	PRINT 'DATA OK && Outright Update : done'
	RETURN
END

-- =====================
-- Daily Summary Process
-- =====================
-- Re-Summary WinLost Report : Added on 2007-03-16 (Joe)
EXEC DB06.bodb02.dbo.Task_rptWinLost_UpdateTable @winlostdate
WAITFOR DELAY '000:00:30'
-- Clear deleted/cancel record (custid = 0)
DELETE FROM bettrans WHERE winlostdate=@winlostdate AND custid = 0

DELETE FROM bettranssum WHERE winlostdate=@winlostdate

-- Get Exchange Rate
DECLARE @Exchange TABLE (currency tinyint, actualrate float, CurrencyName nvarchar(50))
INSERT INTO @Exchange (currency, actualrate)
SELECT DISTINCT currency, actualrate
FROM dbo.bettrans with (nolock)
WHERE winlostdate = @winlostdate AND bettype <=19000

UPDATE @Exchange
SET CurrencyName = e.currency
FROM @Exchange ex, dbo.exchange e with (nolock)
WHERE ex.currency = e.exchangeid

-- Generate SUM record
INSERT INTO dbo.bettranssum
	(custid, currency, recommend, mrecommend, srecommend,
	winlostdate, stake, actual_stake,
	winlost, awinlost, mwinlost, swinlost,
	playercomm, comm, acomm, scomm)
SELECT
	custid, currency, recommend, mrecommend, srecommend,
	winlostdate, sum(stake) stake, sum(actual_stake) actual_stake,
	sum(winlost) winlost, sum(awinlost) awinlost, sum(mwinlost) mwinlost, sum(swinlost) swinlost,
	sum(playercomm) playercomm, sum(comm) comm, sum(acomm) acomm, sum(scomm) scomm
FROM
	bettrans with (paglock)
WHERE
	winlostdate=@winlostdate and
	bettype <=19000 and 
	--[status] NOT IN ('VOID', 'REJECT')
	statusID NOT IN (101,102)
GROUP BY
	custid, currency, recommend, mrecommend, srecommend, winlostdate


-- move match/odds/outright into [14] table
	UPDATE O
	SET eventdate = @winlostdate, changeTime = GETDATE()
	FROM DB02.bodb02.dbo.Outright O WITH (UPDLOCK, ROWLOCK)
	WHERE orid IN 
		(SELECT distinct matchid 
		FROM bettrans with (nolock) 
		WHERE bettype = 10 AND winlostdate = @winlostdate AND statusID <> 0 --AND status <> 'running'
		)

EXEC DB02.bodb02.dbo.Task_DailySummary_DB02_Copy @winlostdate
EXEC dbo.Task_BalanceCheck @winlostdate, 1

-- viet ----
UPDATE DB06.bodb02.dbo.SystemSettings
SET VValue = '1'
WHERE VName = 'isMovingBet' 

-- =====================
SET @Doing = 'Task_DailySummary : MoveBet start'
EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing  

SET NOCOUNT ON
SET DEADLOCK_PRIORITY HIGH
-- =====================
-- Copy bettransm/bettransg -> bettransm14/bettransg14 for whole day of @winlostdate
EXEC dbo.ExecRep_08 @recommend =  0, @winlostdate = @winlostdate, @parlay = 1

-- Delete bettransm for whole day of @winlostdate
EXEC dbo.ExecRep_09 @recommend =  0, @winlostdate = @winlostdate, @parlay = 1

-- Delete bettransG for whole day of @winlostdate
EXEC dbo.ExecRep_09 @recommend =  0, @winlostdate = @winlostdate, @parlay = 2

DECLARE @recommend_List TABLE (recommend int PRIMARY KEY)
INSERT INTO @recommend_List
SELECT DISTINCT recommend FROM bettrans (nolock) WHERE winlostdate = @winlostdate AND bettype < 19999

DECLARE @recommend int
DECLARE CS_recommend
	CURSOR FOR
	SELECT recommend FROM @recommend_List

OPEN CS_recommend
FETCH NEXT FROM CS_recommend INTO @recommend

WHILE @@FETCH_STATUS = 0
BEGIN
	BEGIN TRANSACTION
		EXEC dbo.ExecRep_08 @recommend, @winlostdate /* copy ticket from [active] to [14] for bettrans */
	COMMIT TRANSACTION

	BEGIN TRANSACTION
		EXEC dbo.ExecRep_09 @recommend, @winlostdate /* delete ticket from bettrans/bettransm */

	insert into bettrans
		(ruben, [status], statusID, matchid, bettype, refno, creator, transdate,
		custid, currency, recommend, mrecommend, srecommend,
		winlostdate, stake, winlost, awinlost, mwinlost, swinlost,
		actual_stake, playercomm, comm, acomm, scomm, 
		apositiontaking, mpositiontaking, spositiontaking, tpositiontaking,
		actualrate, virtualrate, Username, CurrencyName, comstatus)
	select
		1, 'SUM', 142, 0, 19999, refno, 8, winlostdate, --99
		b.custid, b.currency, b.recommend, b.mrecommend, b.srecommend,
		winlostdate, stake, winlost, awinlost, mwinlost, swinlost,
		actual_stake, playercomm, comm, acomm, scomm,
		0, 0, 0, 0,
		e.actualrate, e.actualrate, c.username, e.CurrencyName, '0'
	from 
		bettranssum b with (nolock)
		INNER JOIN @Exchange e ON b.currency = e.currency
		INNER JOIN dbo.custinfo c with (nolock) ON b.custid = c.custid AND c.roleid = 1
	where
		winlostdate=@winlostdate
		AND b.recommend = @recommend
	COMMIT TRANSACTION

	FETCH NEXT FROM CS_recommend INTO @recommend
END

CLOSE CS_recommend
DEALLOCATE CS_recommend


-- =====================
SET DEADLOCK_PRIORITY NORMAL
SET NOCOUNT OFF

SET @Doing = 'Task_DailySummary : MoveBet done'
EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing 

-- viet ----
UPDATE DB06.bodb02.dbo.SystemSettings
SET VValue = '0'
WHERE VName = 'isMovingBet' 
 
-- =====================
EXEC Task_BalanceCheck @winlostdate, 3
-- =====================

-- =====================
-- 20100914@Jamie: Modify for Bingo and Number Game 
INSERT INTO dbo.sum_winloss_tmp
	(winlostdate, roleid, custid, recommend, mrecommend, srecommend, username,
	turnover, winlost, awinlost, mwinlost, swinlost,
	playercomm, comm, acomm, scomm, betcount, grosscomm,
	sporttype, bettype, netTurnover)
	SELECT @winlostdate, 1,
		customer.custid, customer.recommend, customer.mrecommend, customer.srecommend, customer.username,
		/*--sum(CASE WHEN bettype in (33, 43) AND liveawayscore = 0 THEN stake/2 ELSE stake END) turnover,
		SUM(CASE WHEN winlostdate >= @ABSDate 
				THEN case when liveawayscore = 0 and bettype in(33,43) then ABS(stake)/2 else ABS(stake) end
				ELSE case when liveawayscore = 0 and bettype in(33,43) then stake/2 else stake end 
				END
				) as TurnOver,*/
		sum(case when liveawayscore = 0 and bettype in(33,43) then ABS(stake)/2 else ABS(stake) end) TurnOver,
		sum(winlost-actual_stake)  winlost,
		sum(awinlost) awinlost,
		sum(mwinlost) mwinlost,
		sum(IsNull(swinlost,0)) swinlost,
		sum(playercomm) playercomm,
		sum(comm) comm,
		sum(acomm) acomm,
		sum(IsNull(scomm,0)) scomm,
		COUNT(transid) BetCount,
		--sum(scomm / (1-tpositiontaking)) grosscomm,
		-- 01-Dec-2009, apply gross commission by level
		-- 07 Jun 2012, apply case for P2P gross comission
		SUM(CASE bettype WHEN 1000 THEN oddsspread ELSE ISNULL( comm/(1-apositiontaking) ,0) END) grosscomm, 
		CASE
			WHEN bettype IN (31,32,33,41,42,43) THEN 151 -- Horse Racing
			WHEN bettype BETWEEN 81 AND 120 THEN 161 -- Number Game 
			WHEN bettype BETWEEN 1101 AND 1199 THEN 162 -- Live Casino
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (71,72) THEN 251
			WHEN bettype = 73 THEN 252 --Bingo 
			WHEN bettype = 1000 THEN 253
			ELSE 0 END sporttype,
		CASE WHEN bettype IN (71,72,73,1000) THEN bettype ELSE 0 END bettype, 
		0 -- netTurnover
	FROM
		dbo.customer with (nolock),
		dbo.bettrans14 bettrans with (nolock)
	WHERE
		bettrans.custid=customer.custid and 
		bettrans.winlostdate = @winlostdate and
		--bettrans.status not in ('running','waiting','VOID','REJECT','REFUND') and
		bettrans.statusID NOT IN (0,1,102,101,103) and 
		bettrans.bettype <=19000
	GROUP BY
		customer.custid, customer.recommend, customer.mrecommend, customer.srecommend,
		customer.username,
		CASE
			WHEN bettype IN (31,32,33,41,42,43) THEN 151 -- Horse Racing
			WHEN bettype BETWEEN 81 AND 120 THEN 161 -- Number Game 
			WHEN bettype BETWEEN 1101 AND 1199 THEN 162 -- Live Casino
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (71,72) THEN 251
			WHEN bettype = 73 THEN 252 --Bingo 
			WHEN bettype = 1000 THEN 253
			ELSE 0 END,
		CASE WHEN bettype IN (71,72,73,1000) THEN bettype ELSE 0 END


INSERT INTO dbo.sum_winloss_tmp
	(winlostdate, roleid, custid, recommend, mrecommend, srecommend, username,
	turnover, winlost, awinlost, mwinlost, swinlost,
	playercomm, comm, acomm, scomm, betcount, grosscomm,
	sporttype, bettype, netTurnover)
	SELECT @winlostdate, 2,
		ag.custid, customer.recommend, customer.mrecommend, customer.srecommend, ag.username,
		/*--sum(CASE WHEN bettype in (33, 43) AND liveawayscore = 0 THEN stake/2 ELSE stake END) turnover,
		SUM(CASE WHEN winlostdate >= @ABSDate 
				THEN case when liveawayscore = 0 and bettype in(33,43) then ABS(stake)/2 else ABS(stake) end
				ELSE case when liveawayscore = 0 and bettype in(33,43) then stake/2 else stake end 
				END
				) as TurnOver,*/
		sum(case when liveawayscore = 0 and bettype in(33,43) then ABS(stake)/2 else ABS(stake) end) TurnOver,
		sum(winlost-actual_stake)  winlost,
		sum(awinlost) awinlost,
		sum(mwinlost) mwinlost,
		sum(IsNull(swinlost,0)) swinlost,
		sum(playercomm) playercomm,
		sum(comm) comm,
		sum(acomm) acomm,
		sum(IsNull(scomm,0)) scomm,
		COUNT(transid) BetCount,
		--sum(scomm / (1-tpositiontaking)) grosscomm,
		SUM(CASE bettype WHEN 1000 THEN oddsspread ELSE ISNULL( acomm/(1-apositiontaking - mpositiontaking) ,0) END) grosscomm, 
		CASE
			WHEN bettype IN (31,32,33,41,42,43) THEN 151 -- Horse Racing
			WHEN bettype BETWEEN 81 AND 120 THEN 161 -- Number Game 
			WHEN bettype BETWEEN 1101 AND 1199 THEN 162 -- Live Casino
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (71,72) THEN 251
			WHEN bettype = 73 THEN 252 --Bingo 
			WHEN bettype = 1000 THEN 253
			ELSE 0 END sporttype,
		CASE WHEN bettype IN (71,72,73,1000) THEN bettype ELSE 0 END bettype,
		sum(case when liveawayscore = 0 and bettype in(33,43) then ABS(stake*apositiontaking)/2 else ABS(stake*apositiontaking) end) --netTurnover
	FROM
		dbo.customer with (nolock),
		dbo.customer ag with (nolock),
		dbo.bettrans14 bettrans with (nolock)
	WHERE
		bettrans.custid=customer.custid and 
		bettrans.winlostdate = @winlostdate and
		--bettrans.status not in ('running','waiting','VOID','REJECT','REFUND')  and
		bettrans.statusID NOT IN (0,1,101,102,103) and 
		ag.custid=customer.recommend and customer.roleid=1 and ag.roleid=2 and
		bettrans.bettype <=19000
	GROUP BY
		ag.custid, customer.recommend, customer.mrecommend, customer.srecommend,
		ag.username,
		CASE
			WHEN bettype IN (31,32,33,41,42,43) THEN 151 -- Horse Racing
			WHEN bettype BETWEEN 81 AND 120 THEN 161 -- Number Game 
			WHEN bettype BETWEEN 1101 AND 1199 THEN 162 -- Live Casino
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (71,72) THEN 251
			WHEN bettype = 73 THEN 252 --Bingo 
			WHEN bettype = 1000 THEN 253
			ELSE 0 END,
		CASE WHEN bettype IN (71,72,73,1000) THEN bettype ELSE 0 END


INSERT INTO dbo.sum_winloss_tmp
	(winlostdate, roleid, custid, recommend, mrecommend, srecommend, username,
	turnover, winlost, awinlost, mwinlost, swinlost,
	playercomm, comm, acomm, scomm, betcount, grosscomm,
	sporttype, bettype, netTurnover)
	SELECT @winlostdate, 3,
		ma.custid, 0 recommend, customer.mrecommend, customer.srecommend, ma.username,
		/*--sum(CASE WHEN bettype in (33, 43) AND liveawayscore = 0 THEN stake/2 ELSE stake END) turnover,
		SUM(CASE WHEN winlostdate >= @ABSDate 
				THEN case when liveawayscore = 0 and bettype in(33,43) then ABS(stake)/2 else ABS(stake) end
				ELSE case when liveawayscore = 0 and bettype in(33,43) then stake/2 else stake end 
				END
				) as TurnOver,*/
		sum(case when liveawayscore = 0 and bettype in(33,43) then ABS(stake)/2 else ABS(stake) end) TurnOver,
		sum(winlost-actual_stake)  winlost,
		sum(awinlost) awinlost,
		sum(mwinlost) mwinlost,
		sum(IsNull(swinlost,0)) swinlost,
		sum(playercomm) playercomm,
		sum(comm) comm,
		sum(acomm) acomm,
		sum(IsNull(scomm,0)) scomm,
		COUNT(transid) BetCount,
		SUM(CASE bettype WHEN 1000 THEN oddsspread ELSE 
			CASE tpositiontaking WHEN 1 THEN 0 ELSE scomm / (1-tpositiontaking) END
			END) grosscomm,
		CASE
			WHEN bettype IN (31,32,33,41,42,43) THEN 151 -- Horse Racing
			WHEN bettype BETWEEN 81 AND 120 THEN 161 -- Number Game 
			WHEN bettype BETWEEN 1101 AND 1199 THEN 162 -- Live Casino
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (71,72) THEN 251
			WHEN bettype = 73 THEN 252 --Bingo 
			WHEN bettype = 1000 THEN 253
			ELSE 0 END sporttype,
		CASE WHEN bettype IN (71,72,73,1000) THEN bettype ELSE 0 END bettype,
		sum(case when liveawayscore = 0 and bettype in(33,43) then ABS(stake*mpositiontaking)/2 else ABS(stake*mpositiontaking) end) --netTurnover
	FROM
		dbo.customer with (nolock),
		dbo.customer ma with (nolock),
		dbo.bettrans14 bettrans with (nolock)
	WHERE
		bettrans.custid=customer.custid and 
		bettrans.winlostdate = @winlostdate and
		--bettrans.status not in ('running','waiting','VOID','REJECT','REFUND')  and
		bettrans.statusID NOT IN (0,1,101,102,103) and
		ma.custid=customer.mrecommend and customer.roleid=1 and ma.roleid=3 and
		bettrans.bettype <=19000
	GROUP BY
		ma.custid, customer.mrecommend, customer.srecommend, 
		ma.username,
		CASE
			WHEN bettype IN (31,32,33,41,42,43) THEN 151 -- Horse Racing
			WHEN bettype BETWEEN 81 AND 120 THEN 161 -- Number Game 
			WHEN bettype BETWEEN 1101 AND 1199 THEN 162 -- Live Casino
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (71,72) THEN 251
			WHEN bettype = 73 THEN 252 --Bingo 
			WHEN bettype = 1000 THEN 253
			ELSE 0 END,
		CASE WHEN bettype IN (71,72,73,1000) THEN bettype ELSE 0 END

--20100601: Arrange sum_winloss data for Super Level.
INSERT INTO dbo.sum_winloss_tmp
	(winlostdate, roleid, custid, recommend, mrecommend, srecommend, username,
	turnover, winlost, awinlost, mwinlost, swinlost,
	playercomm, comm, acomm, scomm, betcount, grosscomm,
	sporttype, bettype, netTurnover)
	SELECT @winlostdate, 4,
		sa.custid, 0 recommend, 0 mrecommend, customer.srecommend, sa.username,
		/*--sum(CASE WHEN bettype in (33, 43) AND liveawayscore = 0 THEN stake/2 ELSE stake END) turnover,
		SUM(CASE WHEN winlostdate >= @ABSDate 
				THEN case when liveawayscore = 0 and bettype in(33,43) then ABS(stake)/2 else ABS(stake) end
				ELSE case when liveawayscore = 0 and bettype in(33,43) then stake/2 else stake end 
				END
				) as TurnOver,*/
		sum(case when liveawayscore = 0 and bettype in(33,43) then ABS(stake)/2 else ABS(stake) end )  TurnOver,
		sum(winlost-actual_stake)  winlost,
		sum(awinlost) awinlost,
		sum(mwinlost) mwinlost,
		sum(IsNull(swinlost,0)) swinlost,
		sum(playercomm) playercomm,
		sum(comm) comm,
		sum(acomm) acomm,
		sum(IsNull(scomm,0)) scomm,
		COUNT(transid) BetCount,
		SUM(CASE bettype WHEN 1000 THEN oddsspread ELSE 
			CASE tpositiontaking WHEN 1 THEN 0 ELSE scomm / (1-tpositiontaking) END
			END) grosscomm,
		CASE
			WHEN bettype IN (31,32,33,41,42,43) THEN 151 -- Horse Racing
			WHEN bettype BETWEEN 81 AND 120 THEN 161 -- Number Game 
			WHEN bettype BETWEEN 1101 AND 1199 THEN 162 -- Live Casino
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (71,72) THEN 251
			WHEN bettype = 73 THEN 252 --Bingo 
			WHEN bettype = 1000 THEN 253
			ELSE 0 END sporttype,
		CASE WHEN bettype IN (71,72,73,1000) THEN bettype ELSE 0 END bettype,
		sum(case when liveawayscore = 0 and bettype in(33,43) then ABS(stake*spositiontaking)/2 else ABS(stake*spositiontaking) end) --netTurnover
	FROM
		dbo.customer with (nolock),
		dbo.customer sa with (nolock),
		dbo.bettrans14 bettrans with (nolock)
	WHERE
		bettrans.custid=customer.custid and 
		bettrans.winlostdate = @winlostdate and
		--bettrans.status not in ('running','waiting','VOID','REJECT','REFUND')  and
		bettrans.statusID NOT IN (0,1,101,102,103) and
		sa.custid=customer.srecommend and customer.roleid=1 and sa.roleid=4 and
		bettrans.bettype <=19000
	GROUP BY
		sa.custid, customer.srecommend, 
		sa.username,
		CASE
			WHEN bettype IN (31,32,33,41,42,43) THEN 151 -- Horse Racing
			WHEN bettype BETWEEN 81 AND 120 THEN 161 -- Number Game 
			WHEN bettype BETWEEN 1101 AND 1199 THEN 162 -- Live Casino
			WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport
			WHEN bettype BETWEEN 51 AND 69 THEN 201
			WHEN bettype IN (71,72) THEN 251
			WHEN bettype = 73 THEN 252 --Bingo 
			WHEN bettype = 1000 THEN 253
			ELSE 0 END,
		CASE WHEN bettype IN (71,72,73,1000) THEN bettype ELSE 0 END


-- =====================
SET @Doing = 'Task_DailySummary : SumWinlost start insert'
EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing  

Declare @loop varchar(1)

SET NOCOUNT ON
SET @loop = 'y'
WHILE @loop = 'y'
BEGIN
		BEGIN TRANSACTION
	DELETE TOP(280) FROM dbo.sum_winloss
	WHERE winlostdate = @winlostdate

	IF @@ROWCOUNT = 0 SET @loop = 'n'
		COMMIT TRANSACTION


	WAITFOR DELAY '000:00:01.4'
END

SET @loop = 'y'
WHILE @loop = 'y'
BEGIN
		BEGIN TRANSACTION
	DELETE TOP(600) FROM dbo.sum_winloss_tmp
	WHERE winlostdate = @winlostdate
	
	IF @@ROWCOUNT = 0 SET @loop = 'n'
		COMMIT TRANSACTION

	WAITFOR DELAY '000:00:01.4'
END

SET NOCOUNT OFF

-- =====================
Delete Match_Log where matchID IN (Select matchID From Match WITH (NOLOCK) Where eventdate=@winlostdate)

Delete from outright_log
where orid in (select orid from outright where eventdate = @winlostdate AND oddsstatus = 'Completed')

-- =====================
EXEC DB02.bodb02.dbo.Task_DailySummary_DB02_Delete @winlostdate

SET @Doing = 'Task_DailySummary : End (with Finish)'
EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing  

PRINT CONVERT(varchar(10), @winlostdate, 120)
