USE [TransDB]
GO
/****** Object:  StoredProcedure [dbo].[Admin_Settlement_RefundFT]    Script Date: 8/20/2014 9:18:22 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Admin_Settlement_RefundFT]
	@matchid int,
	@AdminId int,		
	@betstatus nvarchar(50) = NULL,
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
as

/*
Created By : Dan
Date: 2013-03-21
Task : Refund Full-time tickets
DB: SVRTXN/TransDB
Original: 
	
Revisions:	
	- 20140515@Dan: Add 2 new bettypes - 1H total goal, 1H FGLG  (126,127) 
	- 20140819@Sophia: Change @creator to @AdminId

Param's Explanation:
• @matchid: matchid of match to Refund HT

30 OCT 2008 : Joe 
Check if match MUST already settled 1st Half
*/
SET NOCOUNT ON 

DECLARE  @Remark	VARCHAR(500)
		,@ActionID	INT
SELECT	@ActionID = 111 

-- check and not allow attempt to settlement same game while it's still not finish
IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = 1 AND KeyValue = @matchid)
BEGIN
	SELECT  @ErrCode = 101,
			@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
	RETURN
END

INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (1, @matchid)
IF (@@Error = 0)
BEGIN
	BEGIN TRY
		EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @adminID,
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = @ActionID, 
			@Remark = 'ADD SUCCESS'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'ADD SUCCESS ErrMsg=' + left(error_message(), 400)
		EXEC LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @adminID,
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = @ActionID, 
			@Remark = @Remark
	END CATCH
END
ELSE 
BEGIN
	SELECT @ErrCode = 100, @ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
	RETURN
END
---

	DECLARE	@start DATETIME, @stop DATETIME

	SELECT	@start = CURRENT_TIMESTAMP


	CREATE TABLE #BalanceBefore (custid int PRIMARY KEY, balance money)

	CREATE TABLE #BalanceAfter (custid int PRIMARY KEY, balance money)

	CREATE TABLE #Balance (custid int PRIMARY KEY, balance money, Increased bit)
	CREATE INDEX IX_Balance_Increased ON #Balance (Increased)

	INSERT INTO #BalanceBefore
	SELECT	custid, SUM(winlost-actual_stake+playercomm)
	FROM	dbo.bettrans with (rowlock)
	WHERE	matchid = @matchid 
			AND bettype NOT IN (14, 127)
	GROUP BY custid

	Declare @status TABLE (FTBet bit, BetCount int, InRunning int)
	INSERT INTO @status
	SELECT
		CASE WHEN bettype IN (7,8,12,15,21,30,125,126) THEN 0 ELSE 1 END,
		SUM(CASE WHEN statusID IN (101,102) THEN 0 ELSE 1 END),
		SUM(CASE WHEN statusID = 0 THEN 1 ELSE 0 END)
		
	FROM dbo.bettrans with (nolock)
	WHERE matchid = @matchid
	GROUP BY CASE WHEN bettype IN (7,8,12,15,21,30,125,126) THEN 0 ELSE 1 END

	IF NOT EXISTS(SELECT * FROM @status WHERE FTBet = 0) INSERT INTO @status VALUES (0,0,0)
	IF NOT EXISTS(SELECT * FROM @status WHERE FTBet = 1) INSERT INTO @status VALUES (1,0,0)

	Declare @HTDone bit, @FTDone bit
	SELECT @HTDone = CASE InRunning WHEN 0 THEN 1 ELSE 0 END FROM @status WHERE FTBet = 0
	SELECT @FTDone = CASE InRunning WHEN 0 THEN 1 ELSE 0 END FROM @status WHERE FTBet = 1

---===============================================
--Check if match already Refund HT => refund whole match
if exists(select 1 from SVRPRO.ProdDB.dbo.match_remark_ex with (nolock) where matchid = @matchid AND betstatus like '%Refund HT%')
	AND @HTDone = 1
BEGIN
	-----
	DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
	WHERE KeyID = 1 AND KeyValue = @matchid
	IF (@@Error = 0)
	BEGIN
		BEGIN TRY
			EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
				@UserID = @adminID,
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = @ActionID, 
				@Remark = 'DEL SUCCESS'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS ErrMsg=' + left(error_message(), 400)
			EXEC LogDB.dbo.WriteLog_Settlement_Checking 
				@UserID = @adminID,
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = @ActionID, 
				@Remark = @Remark
		END CATCH
	END		
	ELSE
	BEGIN
		BEGIN TRY
			EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
				@UserID = @adminID,
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = @ActionID, 
				@Remark = 'DEL FAILED'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL FAILED ErrMsg=' + left(error_message(), 400)
			EXEC LogDB.dbo.WriteLog_Settlement_Checking 
				@UserID = @adminID,
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = @ActionID, 
				@Remark = @Remark
		END CATCH
	END		
	
	EXEC dbo.Admin_Settlement_Refund_All 
		@matchid=@matchid , 		
		@AdminId=@adminid,		
		@betstatus = @betstatus,		
		@IP=@IP,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
	return
END


DECLARE @RowCount INT

EXEC SVRPRO.ProdDB.dbo.Admin_Match_Update @Command	= 'Admin_Settlement_RefundFT', 
										@MatchID	= @matchid, 
										@HTDone		= @HTDone,
										@RowCount	= @RowCount OUTPUT,
										@AdminId	= @adminid 

IF @RowCount > 0
BEGIN
	EXEC SVRPRO.ProdDB.dbo.Admin_Match_UpdateMatchRemark @matchid, 'F'
	EXEC dbo.Admin_Calculate_RefundFT @matchid = @matchid
END

INSERT INTO #BalanceAfter	
SELECT	custid, SUM(winlost-actual_stake+playercomm)
FROM	dbo.bettrans with (rowlock)
WHERE	matchid = @matchid 
		AND bettype NOT IN (14, 127)
GROUP BY custid


INSERT INTO #Balance
SELECT b.custid, a.balance - b.balance, CASE WHEN a.balance > b.balance THEN 1 ELSE 0 END
FROM #BalanceBefore b
	INNER JOIN #BalanceAfter a ON b.custid = a.custid
WHERE b.balance <> a.balance

INSERT INTO dbo.BalancePendingDebit (custid, balance)
SELECT custid, ABS(balance)
FROM #Balance
WHERE Increased = 0

INSERT INTO dbo.BalancePendingCredit (custid, balance)
SELECT custid, balance
FROM #Balance
WHERE Increased = 1

DROP TABLE #Balance
DROP TABLE #BalanceBefore
DROP TABLE #BalanceAfter

SELECT	@stop = CURRENT_TIMESTAMP

IF @RowCount > 0
BEGIN
	Declare @LogData nvarchar(300)
	SELECT @LogData = 'Calculate (Refund FT) for matchid:' + CAST(@matchid as nvarchar(10))
	
	EXEC dbo.WriteLog_UserLog_T @AdminID, @LogData

	--Write Log Settle
	DECLARE 
		@hthomescore INT, @htawayscore INT,
		@goalrecord varchar(50)
		
	SELECT @Remark = 'Duration=' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms;'

	SELECT 
			@hthomescore = hthomescore, 
			@htawayscore = htawayscore,
			@goalrecord = goalrecord,
			@betstatus = betstatus
	 FROM	SVRPRO.ProdDB.dbo.match_remark_ex WITH(NOLOCK) WHERE matchid = @matchid

	BEGIN TRY
		EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Settle
			@UserID = @adminid,
			@Matchid = @matchid,
			@ActionID = @ActionID,
			@finalhomescore = 0,
			@finalawayscore = 0,  
			@hthomescore = @hthomescore,
			@htawayscore = @htawayscore,
			@GoalRecord = @goalrecord,
			@betstatus = @betstatus,
			@Remark = @Remark,
			@IP = @IP
	END TRY
	BEGIN CATCH
		SELECT @Remark = @Remark + ' ErrMsg=' + left(error_message(), 400)
		EXEC LogDB.dbo.WriteLog_Settlement_Settle
			@UserID = @adminid,
			@Matchid = @matchid,
			@ActionID = @ActionID,
			@finalhomescore = 0,
			@finalawayscore = 0,  
			@hthomescore = @hthomescore,
			@htawayscore = @htawayscore,
			@GoalRecord = @goalrecord,
			@betstatus = @betstatus,
			@Remark = @Remark,
			@IP = @IP
	END CATCH

END
   
-----
DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
WHERE KeyID = 1 AND KeyValue = @matchid
IF (@@Error = 0)
BEGIN
	BEGIN TRY
		EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @adminID,
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = @ActionID, 
			@Remark = 'DEL SUCCESS'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'DEL SUCCESS ErrMsg=' + left(error_message(), 400)
		EXEC LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @adminID,
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = @ActionID, 
			@Remark = @Remark
	END CATCH
END		
ELSE
BEGIN
	BEGIN TRY
		EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @adminID,
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = @ActionID, 
			@Remark = 'DEL FAILED'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'DEL FAILED ErrMsg=' + left(error_message(), 400)
		EXEC LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @adminID,
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = @ActionID, 
			@Remark = @Remark
	END CATCH
END

