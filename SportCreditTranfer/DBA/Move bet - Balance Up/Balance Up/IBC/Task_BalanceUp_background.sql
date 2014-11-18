USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Task_BalanceUp_background]    Script Date: 05/20/2013 05:34:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Task_BalanceUp    Script Date: 5/23/2011 6:34:21 PM ******/
ALTER PROCEDURE [dbo].[Task_BalanceUp_background]
	@fdate as datetime = NULL,
	@step as tinyint = 1
--	@continue as bit = 0
AS

Declare @Doing nvarchar(300)

/*
Created: 
Task : 

DB: DB02.bodb02
Original:

Revisions:
	- 20110523@Henry: change bettype to new range
	- 20130603@Sophia: Put the deleting-match code into [Acc_Apl_ExecRep_03]

	
Param's Explanation: 

*/

IF @fdate IS NULL
BEGIN
	SELECT @fdate = DATEADD(day, 7, winlostdate)
	FROM dbo.bettrans with (nolock)
	WHERE matchid = 0 and bettype = 20000
	ORDER BY transid
	
	IF @fdate > CURRENT_TIMESTAMP
		SET @fdate = DATEADD(day, -7, @fdate)
END

PRINT '@fdate = ' + CONVERT(varchar(10), @fdate, 120)

-- verify @fdate
Declare @testdate datetime
SET @testdate = CONVERT(varchar(10), @fdate, 120)
IF @testdate <> @fdate
BEGIN
--	SELECT 'ERROR: Input parameter is DATE value with TIME.' Result
--	RETURN
-- raiserror here to continue to next step of jobs
	RAISERROR ('ERROR: Input parameter is DATE value with TIME.', -- Message text.
               16, -- Severity.
               1 -- State.
               );
END

/*
SET @fdate = CONVERT(nvarchar(10), @fdate, 120)
IF (DATEPART(weekday, @fdate) <> 2) AND (@continue = 0)
BEGIN
	PRINT 'Input date is not Monday'
	PRINT 'If you really want to continue, call with @continue = 1'
	RETURN
END
*/

SET @Doing = 'call Task_BalanceUp_background @fdate = ' + CONVERT(nvarchar(10), @fdate, 120) + ', @step = ' + CAST(@step as nvarchar(2))
EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing  

-- ================== STEP : 1 
IF @step = 1
BEGIN
-- ================== DATA VERIFY

	--- DATA VERIFY
	IF EXISTS (SELECT * FROM Customer with (nolock) WHERE (recommend is null or mrecommend is null or srecommend is null) AND roleid <= 2)
	BEGIN
	--	SELECT 'Some Customer/Agent records have NULL AgentID' Result
	--	SELECT custid, username, roleid, recommend, mrecommend, srecommend, currency
	--		FROM customer with (nolock)
	--		WHERE roleid <= 2
	--		AND (recommend is NULL or mrecommend is NULL or srecommend is NULL)
	--	RETURN
	-- raiserror here to continue to next step of jobs
		RAISERROR ('Some Customer/Agent records have NULL AgentID', -- Message text.
				   16, -- Severity.
				   1 -- State.
				   );
	END

	IF EXISTS (SELECT * FROM customer with (nolock) WHERE (recommend is NULL or mrecommend is null or srecommend is null) AND roleid = 3)
	BEGIN
	--	SELECT 'Some Master records have NULL AgentID' Result
	--	SELECT custid, username, roleid, recommend, mrecommend, srecommend, currency
	--		FROM customer with (nolock)
	--		WHERE roleid = 3
	--		AND (recommend is NULL or mrecommend is NULL or srecommend is NULL)
	--	RETURN
	-- raiserror here to continue to next step of jobs
		RAISERROR ('Some Master records have NULL AgentID', -- Message text.
				   16, -- Severity.
				   1 -- State.
				   );
	END

	IF EXISTS (SELECT * FROM customer with (nolock) WHERE (recommend is NULL or mrecommend is null or srecommend is null) AND roleid = 4)
	BEGIN
	--	SELECT 'Some SuperAgent records have NULL AgentID' Result
	--	SELECT custid, username, roleid, recommend, mrecommend, srecommend, currency
	--		FROM customer with (nolock)
	--		WHERE roleid = 4
	--		AND (recommend is NULL or mrecommend is NULL or srecommend is NULL)
	--	RETURN
	-- raiserror here to continue to next step of jobs
		RAISERROR ('Some SuperAgent records have NULL AgentID', -- Message text.
				   16, -- Severity.
				   1 -- State.
				   );
	END

	IF EXISTS (SELECT * FROM bettrans with (nolock) WHERE winlostdate < @fdate AND (
			srecommend is null or mrecommend is null or recommend is null
		OR swinlost is null or mwinlost is null or awinlost is null or winlost is null
		OR scomm is null or acomm is null or comm is null or playercomm is null
		OR ((scomm <> acomm OR swinlost <> 0) AND srecommend <= 100)
		) )
	BEGIN
	--	SELECT 'Some records in BetTrans have NULL AgentID/NULL winlost/NULL commission/incorrect Company SuperAgent setting' Result
	--	RETURN
	-- raiserror here to continue to next step of jobs
		RAISERROR ('Some records in BetTrans have NULL AgentID/NULL winlost/NULL commission/incorrect Company SuperAgent setting', -- Message text.
				   16, -- Severity.
				   1 -- State.
				   );
	END
	

-- ================== END STEP : 1 
END
-- ================== DATA VERIFY

--IF @check = 1
--	RETURN


--- START --- START --- START ---
--- START --- START --- START ---
--- START --- START --- START ---


-- ================== STEP : 2
IF @step = 2
BEGIN
-- ================== Clear BalanceTable and Perform Backup

	UPDATE DB06.bodb02.dbo.SystemSettings
	SET VValue = '1'
	WHERE VName = 'isArchivingBet' 

	-- for safety, shutdown trigger in balanceTable_tmp
	EXEC dbo.Task_BalanceUp_TriggerControl @step = 1, @on = 0
	EXEC dbo.Task_BalanceUp_TriggerControl @step = 2, @on = 0

	truncate table dbo.balanceTable;
	truncate table dbo.balanceTable_tmp


	EXEC dbo.balancecheck @fdate, 11
	-- doing backup
	Declare @suffix varchar(10)
	SET @suffix = 'bbu' + RIGHT(CONVERT(varchar(10), @fdate,120),5)
	EXEC dbo.Task_BackupFULL @suffix
	EXEC DB02.bodb02.dbo.Task_BackupFULL @suffix
	-- doing backup : end

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
	--BEGIN TRANSACTION
		-- Member
		insert into dbo.balancetable(custid,  amount, TicketCount, balTicketCount)
		select 	bettrans.custid custid,
			sum(winlost-actual_stake + playercomm) amount,
			COUNT(*) TicketCount,
			sum(CASE bettype WHEN 20000 THEN 1 ELSE 0 END) balTicketCount
		from
			dbo.bettrans with (rowlock)
			--INNER JOIN dbo.custinfo c with (nolock) ON bettrans.custid = c.custid
		where
			ruben = 1 and
			winlostdate < @fdate and
			bettrans.custid <> bettrans.recommend and
			bettrans.custid <> bettrans.mrecommend and
			bettrans.custid <> bettrans.srecommend
		group by bettrans.custid;
	--COMMIT TRANSACTION

	--BEGIN TRANSACTION
		-- Agent
		insert into dbo.balancetable(custid, amount, TicketCount, balTicketCount)
		select	bettrans.recommend custid,
			sum(case
			when bettrans.custid=bettrans.recommend then winlost-actual_stake
			else awinlost+comm-playercomm
			end) amount,
			sum(CASE custid WHEN recommend THEN 1 ELSE 0 END) TicketCount,
			sum(CASE bettype WHEN 20000 THEN 1 ELSE 0 END) balTicketCount
		from
			dbo.bettrans with (rowlock)
			--INNER JOIN dbo.custinfo c with (nolock) ON bettrans.custid = c.custid
		where
			ruben=1 and 
			winlostdate < @fdate
		group by bettrans.recommend;

		-- Master
		insert into dbo.balancetable(custid, amount, TicketCount, balTicketCount)
		select	bettrans.mrecommend custid,
			sum(case
			when bettrans.custid=bettrans.mrecommend then winlost-actual_stake
			else mwinlost+acomm-comm
			end) amount,
			sum(CASE custid WHEN mrecommend THEN 1 ELSE 0 END) TicketCount,
			sum(CASE bettype WHEN 20000 THEN 1 ELSE 0 END) balTicketCount
		from
			dbo.bettrans with (rowlock)
			--INNER JOIN dbo.custinfo c with (nolock) ON bettrans.custid = c.custid
		where
			ruben=1 and 
			winlostdate < @fdate
		group by bettrans.mrecommend;

		-- Super
		insert into dbo.balancetable(custid, amount, TicketCount, balTicketCount)
		select	bettrans.srecommend custid, 
			sum(case
			when bettrans.custid=bettrans.srecommend then winlost-actual_stake
			else swinlost+scomm-acomm
			end) amount,
			sum(CASE custid WHEN srecommend THEN 1 ELSE 0 END) TicketCount,
			sum(CASE bettype WHEN 20000 THEN 1 ELSE 0 END) balTicketCount
		from
			dbo.bettrans with (rowlock)
			--INNER JOIN dbo.custinfo c with (nolock) ON bettrans.custid = c.custid
		where
			ruben=1 and 
			winlostdate < @fdate
		group by bettrans.srecommend;
	--COMMIT TRANSACTION

	--BEGIN TRANSACTION
		DELETE FROM dbo.balanceTable
		WHERE custid = 0

		update b
		set
			roleid = c.roleid,
			recommend = c.recommend,
			mrecommend= c.mrecommend,
			srecommend= c.srecommend,
			currency  = c.currency,
			UserName  = c.username,
			CurrencyName = e.currency,
			actualrate = IsNull(ed.ActualRate, e.ActualRate)
		from dbo.balancetable b
			INNER JOIN bodb02.dbo.custinfo c ON b.custid = c.custid
			INNER JOIN bodb02.dbo.exchange e ON c.currency = e.exchangeid
			LEFT OUTER JOIN bodb02.dbo.ExchangeDailyOanda ed ON c.currency = ed.ExchangeId AND ed.ExchangeDate = @fdate


		-- copy data, ready for insertion
		INSERT INTO dbo.balancetable_tmp
		SELECT @fdate, * FROM dbo.balancetable
	--COMMIT TRANSACTION

	-- =====================
	--   CLEAN OLD EVENTS
	-- =====================

		---- delete event/odds information

		--delete from DB02.bodb02.dbo.match
		--where matchid not in (select distinct matchid from bettrans where bettype <= 19000)
		--and kickofftime < @fdate

		-----> Put this code into [Acc_Apl_ExecRep_03]

		EXEC Acc_Apl_ExecRep_03 @fdate 

		EXEC DB02.bodb02.dbo.Task_BalanceUp_DB02 @fdate

	EXEC dbo.Task_BalanceUp_TriggerControl @step = 2, @on = 1

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
-- ================== BalanceUp Agent
	SET NOCOUNT ON
	EXEC dbo.Task_BalanceUp_SubAgent @fdate
	SET NOCOUNT OFF
-- ================== END STEP : 4
END
-- ================== BalanceUp Agent

-- ================== STEP : 5
IF @step = 5
BEGIN
-- ================== BalanceUp Super
	SET NOCOUNT ON
	EXEC dbo.Task_BalanceUp_SubSuper @fdate
	SET NOCOUNT OFF
-- ================== END STEP : 5
END
-- ================== BalanceUp Super


-- ================== STEP : 6
IF @step = 6
BEGIN
-- ================== Finishing

	EXEC dbo.Task_BalanceUp_TriggerControl @step = 2, @on = 0

	-- end comment

	EXEC dbo.balancecheck @fdate, 21

	UPDATE DB06.bodb02.dbo.SystemSettings
	SET VValue = '0'
	WHERE VName = 'isArchivingBet' 

	SET @Doing = 'Task_BalanceUp_background : Done'
	EXEC dbo.WriteLog_UserLog @UserID = 25520, @Doing = @Doing  
-- ================== END STEP : 6
END
-- ================== Finishing

