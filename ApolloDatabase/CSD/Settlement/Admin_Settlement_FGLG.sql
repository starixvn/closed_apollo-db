ALTER PROCEDURE [dbo].[Admin_Settlement_FGLG]
	@creator int,
	@matchid int,	
	@betstatus nvarchar(50),
	@IncludeLG bit = 1,
	@IP varchar(15) = '',
	@goalrecord varchar(50) = '',
	@IsLoopTempTable BIT = 0,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
	
AS
/*	Creator: Dan
	Date: 2013-03-08 
	Task: SP for settle FGLG
	DB: SVRTXN/TransDB
	
	History:		
		
	Param's Explanation:
		+ @betstatus: FGLG status
		+ @IsLoopTempTable: 1 : is nested
							0 : Normal
		
*/
SET NOCOUNT ON

IF @IsLoopTempTable = 0
BEGIN
	-- check and not allow attempt to settlement same game while it's still not finish
	IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = 1 AND KeyValue = @matchid)
	BEGIN
		SELECT  @ErrCode = 101,
				@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
		RETURN
	END
	
	DECLARE @Remark VARCHAR(500)
	INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (1, @matchid)
	IF (@@Error = 0)
	BEGIN
		BEGIN TRY
			EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
				@UserID = @creator, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 108, 
				@Remark = 'ADD SUCCESS'
		END TRY
		BEGIN CATCH	
			SELECT @Remark = 'ADD SUCCESS ErrMsg=' + left(error_message(), 400)
			EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
				@UserID = @creator, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 108, 
				@Remark = @Remark	
		END CATCH
	END
	ELSE 
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
		RETURN
	END
END

---
EXEC SVRPRO.ProdDB.dbo.Admin_Match_Update @Command	= 'Admin_Settlement_FGLG', 
										@MatchID	= @matchid, 
										@BetStatus	= @betstatus,
										@GoalRecord	= @goalrecord,
										@creator	= @creator
	-------------------------
	--First Goal, Last Goal 
	Declare @FGLG1 varchar(10), @FGLG2 varchar(10), @FLString varchar(10)
	
	select @FGLG1 = '', @FGLG2 = ''
	
	if charindex('FL:', @betstatus) > 0
	BEGIN
		select 	@FLString = substring(@betstatus, charindex('FL:', @betstatus) + 3, 3)

		select @FGLG1 = case @FLString
							when '0-0' then '0:0'
							else left(@FLString,1) + ':1'
							end,			
				@FGLG2 = case @FLString
							when '0-0' then ''
							else right(@FLString,1) + ':2'
							end
	END
	-------------------------

-------------------------------------------------------------
---        CAPTURE value BALANCE before settlement        ---
---------------------------VVVV------------------------------
CREATE TABLE #BalanceBefore (custid int PRIMARY KEY, balance money)
Declare @TotalAccount int, @TotalAccount_BalanceUpdate int
BEGIN
--===
	INSERT INTO #BalanceBefore
	SELECT custid, SUM(winlost-actual_stake+playercomm)
	FROM dbo.bettrans with (rowlock)
	WHERE matchid = @matchid AND bettype = 14
	GROUP BY custid

	SET @TotalAccount = @@ROWCOUNT
--===
END

-- bettype 14 : First Goal Last Goal - re-use the SP of Correct Score, so we have to call it twice		
	DECLARE @betcount INT
	
	SELECT @betcount = COUNT(1)
	FROM dbo.bettrans WITH(NOLOCK)
	WHERE matchid = @matchid AND bettype = 14
	
	IF @betcount = 0
	BEGIN
		IF EXISTS (SELECT 1 FROM dbo.bettransm WITH(NOLOCK) WHERE matchid = @matchid AND bettype = 14)
			SET @betcount = 1
	END
	
	if @FGLG2 <> ''
	BEGIN	
		EXEC dbo.Admin_Calculate_4 @matchid, 14, @FGLG1, 0, @FGLG2, @betcount
	END
	ELSE 
	BEGIN
		EXEC dbo.Admin_Calculate_4 @matchid, 14, @FGLG1, 0, NULL, @betcount
	END

	--refund all LG tickets if not include LG
	IF @IncludeLG = 0
	BEGIN
		EXEC dbo.Admin_Settlement_Refund_FGLG--refund LG
			@matchid = @matchid,
			@adminid = @creator,
			@LGOnly = 1,
			@IP = @IP,
			@IsLoopTempTable = 1 ---Not check concurrency by TempVariableNumber table	
	END

-------------------------------------------------------------
---         CAPTURE value BALANCE after settlement        ---
---------------------------VVVV------------------------------
CREATE TABLE #BalanceAfter (custid int PRIMARY KEY, balance money)
BEGIN
--===
	INSERT INTO #BalanceAfter
	SELECT custid, SUM(winlost-actual_stake+playercomm)
	FROM dbo.bettrans with (rowlock)
	WHERE matchid = @matchid AND bettype = 14
	GROUP BY custid
--===
END

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

--Write Log Settle
DECLARE 
		@finalhomescore INT, @finalawayscore INT,
		@hthomescore INT, @htawayscore INT
SELECT 
		@finalhomescore = finalhomescore_ext,
		@finalawayscore = finalawayscore_ext,
		@hthomescore = hthomescore_ext, 
		@htawayscore = htawayscore_ext
 FROM	SVRPRO.ProdDB.dbo.match WITH(NOLOCK) WHERE matchid = @matchid
 
DECLARE	@LogData VARCHAR(200)
SELECT @LogData = 'Calculate FGLG for matchid:' + CAST(@matchid as nvarchar(10)) 
	+ ' score:' + CAST(ISNULL(@finalhomescore,0) as nvarchar(10)) + '-' + CAST(ISNULL(@finalawayscore,0) as nvarchar(10)) + ' HT:' + CAST(@hthomescore as nvarchar(10)) + '-' + CAST(@htawayscore as nvarchar(10)) 
	+ ' GoalRecord:' + ISNULL(@goalrecord, '') + ') Remark(BetStatus=' + @betstatus + ', IncludeLG=' + convert(char(1),@IncludeLG) + ')'
EXEC dbo.WriteLog_UserLog_T @creator, @LogData

SELECT @Remark = 'IncludeLG=' + convert(char(1),@IncludeLG)

BEGIN TRY
	EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Settle
		@UserID = @creator,
		@Matchid = @matchid,
		@ActionID = 108,
		@finalhomescore = @finalhomescore,
		@finalawayscore = @finalawayscore,  
		@hthomescore = @hthomescore,
		@htawayscore = @htawayscore,
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
		@ActionID = 108,
		@finalhomescore = @finalhomescore,
		@finalawayscore = @finalawayscore,  
		@hthomescore = @hthomescore,
		@htawayscore = @htawayscore,
		@GoalRecord = @goalrecord,
		@betstatus = @betstatus,
		@Remark = @Remark,
		@IP = @IP
END CATCH		
-----
IF @IsLoopTempTable = 0
BEGIN
	DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
	WHERE KeyID = 1 AND KeyValue = @matchid
	IF (@@Error = 0)
	BEGIN
		BEGIN TRY
			EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
				@UserID = @creator, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 108, 
				@Remark = 'DEL SUCCESS'
		END TRY
		BEGIN CATCH		
			SELECT @Remark = 'DEL SUCCESS ErrMsg=' + left(error_message(), 400)		
			EXEC LogDB.dbo.WriteLog_Settlement_Checking 
				@UserID = @creator, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 108, 
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
				@ActionID = 108, 
				@Remark = 'DEL FAILED'
		END TRY
		BEGIN CATCH		
			SELECT @Remark = 'DEL FAILED ErrMsg=' + left(error_message(), 400)		
			EXEC LogDB.dbo.WriteLog_Settlement_Checking
				@UserID = @creator, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 108, 
				@Remark = @Remark
		END CATCH
	END
END

GO
GRANT EXECUTE ON [dbo].[Admin_Settlement_FGLG] TO [aplweb]
