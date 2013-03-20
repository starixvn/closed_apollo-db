ALTER PROCEDURE [dbo].[Admin_Settlement_1]
	@creator int,
	@matchid int,
	@fth smallint = NULL,
	@fta smallint = NULL,
	@hth smallint,
	@hta smallint,
	@goalrecord varchar(50)= NULL,
	@betstatus nvarchar(50),
	@action varchar(10) = 'CAL',
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@DelayTime int = 0 OUTPUT
AS

/*	Creator: Dan
	Date: 2013-03-08
	Task: main SP for settlement
	DB: SVRTXN/TransDB
	Original SP: Admin_Settlement_1
	History:
		
		
	Param's Explanation:
		+ @betstatus: Used for score table, FGLG status, refund status
		
*/

SET NOCOUNT ON

Declare @SkipBalanceUpdate bit
SET @SkipBalanceUpdate = 0
---

Declare @start datetime, @stop datetime, @goalrecord_old varchar(50)
Declare @LogData nvarchar(200)
Declare @eventstatus nvarchar(50)
SELECT @start = CURRENT_TIMESTAMP

-------------------------------------------------------------
---Put/check delay on settlement of big matches on weekend---
---------------------------VVVV------------------------------
Declare @TicketCount int, @NewDelayValue int, @matchcode nvarchar(50), @sporttype tinyint
DECLARE @NextAllowSettleTime datetime		

SELECT @TicketCount = 0, @NewDelayValue = 0

select @TicketCount = count(1)
from bettrans with (nolock)
where bettype <=19000 and matchid = @matchid 

SELECT @matchcode = matchcode
	,@sporttype = sporttype
	,@goalrecord_old = ISNULL(goalrecord,'')
FROM match WITH(NOLOCK)
WHERE matchid = @matchid

/*
--check whether it's at weekend peak-hour, from 7PM - 2AM (GMT+8)
if datename(weekday, getdate()) in ('Saturday','Sunday') and datepart(hour, getdate()) between 7 and 14  AND @matchcode NOT LIKE '%hedge%'
BEGIN
	select @NextAllowSettleTime = VValue from SystemSettings with (nolock) where VName = 'NextAllowSettleTime' 

	select @DelayTime = CASE WHEN DATEDIFF(ss, getdate(), @NextAllowSettleTime) < 0 THEN 0
							ELSE DATEDIFF(ss, getdate(), @NextAllowSettleTime) END

	if @DelayTime > 0
	BEGIN
		SELECT  @ErrCode = 101,
				@ErrMsg = 'We prevent the frequent calculations during peak hour at weekend, please hold on and try again in ' + cast(@DelayTime as varchar(3)) + ' seconds. Thanks!'
				
		RETURN
	END


	SELECT @NewDelayValue = CASE WHEN @TicketCount > 100000 THEN 120
								WHEN @TicketCount > 60000 THEN 60
						ELSE 0 END	
	IF @NewDelayValue > 0
	BEGIN
	    -- the calculation is executing for big match, so we block this action for 60 seconds, to prevent simultaneous calculations
		UPDATE systemSettings WITH (ROWLOCK, UPDLOCK)
			SET VValue = convert (varchar(100), DATEADD(ss, 120, getdate()), 109)
		WHERE VName = 'NextAllowSettleTime'
	END
END
*/
---------------------------^^^^------------------------------
---Put/check delay on settlement of big matches on weekend---
-------------------------------------------------------------
DECLARE @Remark varchar(500), @ActionID int
SELECT @ActionID = CASE @Action 
		WHEN 'CAL' THEN 100 
		WHEN 'CAL-FT' THEN 101 
		WHEN 'CAL-HT' THEN 102 
		WHEN 'UNDO' THEN 103
	END

-- check and not allow attempt to settlement same game while it's still not finish
IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = 1 AND KeyValue = @matchid)
BEGIN
	SELECT  @ErrCode = 102,
			@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
	RETURN
END

INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (1, @matchid)

IF (@@Error = 0)
BEGIN
	BEGIN TRY
		EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @creator, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = @ActionID, 
			@Remark = 'ADD SUCCESS'
	END TRY
	BEGIN CATCH	
		SELECT @Remark = 'ADD SUCCESS ErrMsg=' + left(error_message(), 400)
		EXEC LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @creator, 
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


-------------------------------------------------------------
---        CAPTURE value BALANCE before settlement        ---
---------------------------VVVV------------------------------
CREATE TABLE #BalanceBefore (custid int PRIMARY KEY, balance money)
Declare @TotalAccount int, @TotalAccount_BalanceUpdate int
IF @SkipBalanceUpdate = 0
BEGIN
--===
IF @Action IN ('CAL','CAL-FT')
BEGIN
	INSERT INTO #BalanceBefore
	SELECT custid, SUM(winlost-actual_stake+playercomm)
	FROM dbo.bettrans with (rowlock)
	WHERE matchid = @matchid AND bettype <> 14
	GROUP BY custid

	SET @TotalAccount = @@ROWCOUNT
END
ELSE IF @Action = 'CAL-HT'
BEGIN
	INSERT INTO #BalanceBefore
	SELECT custid, SUM(winlost-actual_stake+playercomm)
	FROM dbo.bettrans with (rowlock)
	WHERE matchid = @matchid AND bettype IN (7,8,12,15,21,30,125)
	GROUP BY custid

	SET @TotalAccount = @@ROWCOUNT
END
ELSE IF @Action = 'UNDO'
BEGIN
	INSERT INTO #BalanceBefore
	SELECT custid, SUM(winlost-actual_stake+playercomm)
	FROM dbo.bettrans with (rowlock)
	WHERE matchid = @matchid
	GROUP BY custid
END
--===
END --IF @SkipBalanceUpdate = 0
--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

-- 20090412 : Joe : case for unsettle the game.
IF @action = 'UNDO'
BEGIN
				
	EXEC dbo.Admin_Calculate_Undo @matchid
	--EXEC dbo.Admin_Settlement_Parlay @matchid, @creator, 'UNDO', @IP = @IP
	EXEC SVRPRO.ProdDB.dbo.Admin_Match_UpdateMatchRemark @matchid, 'U'
	
	EXEC SVRPRO.ProdDB.dbo.Admin_Match_Update @Command = 'Admin_Settlement_1-UNDO', @MatchID = @matchid, @creator = @creator 		
END
ELSE
BEGIN
	/* 06 OCT 2008 : Joe
	As of Today.  Match Remark can't tell game just settled for HT yet
	need below code to determine for mark match as calculated (all bets settled)
	*/
	Declare @status TABLE (FTBet bit, BetCount int, InRunning int)
	INSERT INTO @status
	SELECT
		CASE WHEN bettype IN (7,8,12,15,21,30,125) THEN 0 ELSE 1 END,
		SUM(CASE WHEN [statusID] IN (101,102) THEN 0 ELSE 1 END), --SUM(CASE WHEN [status] IN (N'VOID',N'REJECT') THEN 0 ELSE 1 END),
		SUM(CASE WHEN [statusID] = 0 THEN 1 ELSE 0 END) ----SUM(CASE WHEN [status] = N'running' THEN 1 ELSE 0 END)
	FROM dbo.bettrans with (nolock)
	WHERE matchid = @matchid
	GROUP BY CASE WHEN bettype IN (7,8,12,15,21,30,125) THEN 0 ELSE 1 END

	IF NOT EXISTS(SELECT * FROM @status WHERE FTBet = 0) INSERT INTO @status VALUES (0,0,0)
	IF NOT EXISTS(SELECT * FROM @status WHERE FTBet = 1) INSERT INTO @status VALUES (1,0,0)

	Declare @HTDone bit, @FTDone bit
	SELECT @HTDone = CASE InRunning WHEN 0 THEN 1 ELSE 0 END FROM @status WHERE FTBet = 0
	SELECT @FTDone = CASE InRunning WHEN 0 THEN 1 ELSE 0 END FROM @status WHERE FTBet = 1	

	/* Mode
	CAL : (default) Settle ALL BetTypes
	CAL-FT : Full Time Only
	CAL-HT : Half Time Only
	SCORE : Only Save Score
	UNDO : Unsettle the match
	*/	

	SELECT	@eventstatus = CASE	WHEN @action = 'CAL' THEN N'completed'
							    WHEN @action = 'CAL-HT' AND matchcode LIKE '%hedge%' THEN eventstatus -- Jamie@20120330: Not change eventstatus='completed' for Hedge Match although 
								WHEN @action = 'CAL-HT' AND @FTDone = 1 THEN N'completed'
								WHEN @action = 'CAL-FT' AND @HTDone = 1 THEN N'completed'
								ELSE eventstatus 
							END,
			@FTDone = CASE WHEN @action = 'CAL-HT' AND matchcode LIKE '%hedge%' THEN 0 ELSE @FTDone END 
	FROM	SVRPRO.ProdDB.dbo.Match WITH(NOLOCK) --DBPRO.BODB02.dbo.Match WITH(NOLOCK)
	WHERE	matchid = @matchid


	EXEC ProdDB.dbo.Admin_Match_Update @Command	= 'Admin_Settlement_1-CAL', 
											@MatchID	= @matchid,
											@FTHome		= @fth,
											@FTAway		= @fta,
											@HTHome		= @hth,
											@HTAway		= @hta,
											@BetStatus	= @betstatus,
											@GoalRecord	= @goalrecord,
											@Action		= @action,
											@FTDone		= @FTDone,
											@HTDone		= @HTDone,
											@creator	= @creator

	IF LEFT(@action, 3) = 'CAL' 
	BEGIN		
		EXEC dbo.Admin_Settlement_3 @creator, @matchid, @action
	END

/* later
	--Check and calc FGLG
	IF @action IN('CAL', 'CAL-FT') 	
	BEGIN
		IF EXISTS (select 1 from bettrans with (nolock) where bettype = 14 and matchid = @matchid)
			OR EXISTS (select 1 from bettransm with (nolock) where bettype = 14 and matchid = @matchid)	
			
				EXEC dbo.Admin_Settlement_FGLG
					@creator = @creator,
					@matchid = @matchid,	
					@betstatus = @betstatus,
					@IncludeLG = 1,
					@goalrecord = @goalrecord,
					@IP = @IP,
					@IsLoopTempTable = 1 ---Not check concurrency by TempVariableNumber table		
	

	END
*/
	IF @eventstatus = 'completed'
		EXEC SVRPRO.ProdDB.dbo.[Admin_Match_UpdateMatchRemark] @matchid, 'C'
	ELSE IF @action = 'CAL-HT'
		EXEC SVRPRO.ProdDB.dbo.[Admin_Match_UpdateMatchRemark] @matchid, 'H'
				
END -- IF @action = 'UNDO'



-------------------------------------------------------------
---         CAPTURE value BALANCE after settlement        ---
---------------------------VVVV------------------------------
CREATE TABLE #BalanceAfter (custid int PRIMARY KEY, balance money)
IF @SkipBalanceUpdate = 0
BEGIN
--===

IF @Action IN ('CAL','CAL-FT')
BEGIN
	INSERT INTO #BalanceAfter
	SELECT custid, SUM(winlost-actual_stake+playercomm)
	FROM dbo.bettrans with (rowlock)
	WHERE matchid = @matchid AND bettype <> 14
	GROUP BY custid
END
ELSE IF @Action = 'CAL-HT'
BEGIN
	INSERT INTO #BalanceAfter
	SELECT custid, SUM(winlost-actual_stake+playercomm)
	FROM dbo.bettrans with (rowlock)
	WHERE matchid = @matchid AND bettype IN (7,8,12,15,21,30,125)
	GROUP BY custid
END
ELSE IF @Action = 'UNDO'
BEGIN
	INSERT INTO #BalanceAfter
	SELECT custid, SUM(winlost-actual_stake+playercomm)
	FROM dbo.bettrans with (rowlock)
	WHERE matchid = @matchid
	GROUP BY custid
END
--===
END --IF @SkipBalanceUpdate = 0

-------------------------------------------------------------
---                   compare BALANCE                     ---
---------------------------VVVV------------------------------
CREATE TABLE #Balance (custid int PRIMARY KEY, balance money, Increased bit)
CREATE INDEX IX_Balance_Increased ON #Balance (Increased)

INSERT INTO #Balance
SELECT b.custid, a.balance - b.balance, CASE WHEN a.balance > b.balance THEN 1 ELSE 0 END
FROM #BalanceBefore b
	INNER JOIN #BalanceAfter a ON b.custid = a.custid
WHERE b.balance <> a.balance

SET @TotalAccount_BalanceUpdate = @@ROWCOUNT


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


-------------------------------------------------------------
---                      WRITE LOG                        ---
---------------------------VVVV------------------------------
SELECT @stop = CURRENT_TIMESTAMP

SELECT @LogData = 'Calculate (' + @action + ') for matchid:' + CAST(@matchid as nvarchar(10)) 
	+ ' score:' + CAST(ISNULL(@fth,0) as nvarchar(10)) + '-' + CAST(ISNULL(@fta,0) as nvarchar(10)) + ' HT:' + CAST(@hth as nvarchar(10)) + '-' + CAST(@hta as nvarchar(10)) 
	+ ' GoalRecord:' + ISNULL(@goalrecord, '') + '(Old:' + @goalrecord_old + ') Remark(' + @betstatus + ') (' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms)'
EXEC dbo.WriteLog_UserLog_T  @creator, @LogData

--Write Log Settle
SELECT @Remark = CASE WHEN LEN(@goalrecord_old) = 0 THEN '' ELSE  'Old GoalRecord:' + @goalrecord_old  + '<br/> ' END 
	+ 'Duration:' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms;' 
	+ ' TC:' + CAST(ISNULL(@ticketCount,0) as varchar(20)) 
	+ ' Bal:' + CAST(IsNull(@TotalAccount_BalanceUpdate,0) as varchar(20)) + '/' + CAST(IsNull(@TotalAccount,0) as varchar(20))
	
BEGIN TRY
	EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Settle
		@UserID = @creator,
		@Matchid = @matchid,
		@ActionID = @ActionID,
		@finalhomescore = @fth,
		@finalawayscore = @fta,  
		@hthomescore = @hth,
		@htawayscore = @hta,
		@GoalRecord = @goalrecord,
		@betstatus = @betstatus,
		@Remark = @Remark,
		@IP = @IP
END TRY  
BEGIN CATCH	
	SELECT @Remark = @Remark + ' ErrMsg=' + left(error_message(), 250)	
	EXEC LogDB.dbo.WriteLog_Settlement_Settle
		@UserID = @creator,
		@Matchid = @matchid,
		@ActionID = @ActionID,
		@finalhomescore = @fth,
		@finalawayscore = @fta,  
		@hthomescore = @hth,
		@htawayscore = @hta,
		@GoalRecord = @goalrecord,
		@betstatus = @betstatus,
		@Remark = @Remark,
		@IP = @IP
END CATCH

--
DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
WHERE KeyID = 1 AND KeyValue = @matchid

IF (@@Error = 0)
BEGIN
	BEGIN TRY
		EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @creator, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = @ActionID, 
			@Remark = 'DEL SUCCESS'
	END TRY
	BEGIN CATCH		
		SELECT @Remark = 'DEL SUCCESS  ErrMsg=' + left(error_message(), 400)				
		EXEC LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @creator, 
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
			@UserID = @creator, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = @ActionID, 
			@Remark = 'DEL FAILED'
	END TRY
	BEGIN CATCH		
		SELECT @Remark = 'DEL FAILED  ErrMsg=' + left(error_message(), 400)				
		EXEC LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @creator, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = @ActionID, 
			@Remark = @Remark		
	END CATCH
END

-------------------------------------------------------------
---Put/check delay on settlement of big matches on weekend---
---------------------------VVVV------------------------------

--check whether it's needed to set the Blocking time
if @NewDelayValue > 0
BEGIN	
    UPDATE systemSettings WITH (ROWLOCK, UPDLOCK)
	    SET VValue = convert (varchar(100), DATEADD(ss, @NewDelayValue, getdate()), 109)
    WHERE VName = 'NextAllowSettleTime'
END
-------------------------------------------------------------
---Put/check delay on settlement of big matches on weekend---
-------------------------------------------------------------

GO
GRANT EXECUTE ON [dbo].[Admin_Settlement_1] TO [aplweb]
--GO
--GRANT VIEW DEFINITION ON [dbo].[Admin_Settlement_1] TO [vnteam]