ALTER PROCEDURE [dbo].[Admin_Settlement_Refund_FGLG]
	@matchid int,
	@adminid int,
	@action varchar(10) = 'CAL',
	@LGOnly bit,
	@IP varchar(15) = '',
	@IsLoopTempTable BIT = 0,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
as

/*
Creator: Dan
Date: 2013-03-08 
Task : Refund Half-time in case there are HT tickets bet on special matches that have 3 sets
DB: SVRTXN/TransDB
Original: Admin_Settlement_Refund_FGLG	

Revisions:
		- 20140515@Dan: Add 1H FGLG bettypes (127) 
Param's Explanation:
		+ @matchid: matchid of match to Refund HT
		+ @IsLoopTempTable: 1 : is nested
							0 : Normal

*/
SET NOCOUNT ON

DECLARE @Remark VARCHAR(500)
		, @ActionID	INT
		, @bettype int
SELECT	@ActionID = 112
		, @bettype = CASE when @action = 'CAL-HT' THEN 127
						  when @action = 'CAL-FT' then 14
						  ELSE 0
					 END 

IF @IsLoopTempTable = 0
BEGIN
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
		
	CREATE TABLE #BalanceBefore (custid int PRIMARY KEY, balance money)
	Declare @TotalAccount int, @TotalAccount_BalanceUpdate int
	BEGIN
		INSERT INTO #BalanceBefore
		SELECT custid, SUM(winlost-actual_stake+playercomm)
		FROM dbo.bettrans with (rowlock)		
		WHERE matchid = @matchid AND ((@bettype = 0 AND bettype IN (14,127)) OR (bettype = @bettype))
		GROUP BY custid

		SET @TotalAccount = @@ROWCOUNT
	END 

END 
------

DECLARE 
	@finalhomescore INT, @finalawayscore INT,
	@hthomescore INT, @htawayscore INT,
	@goalrecord varchar(50), @betstatus nvarchar(50),
	@matchdate datetime

SELECT	@matchdate = eventdate		
FROM SVRPRO.ProdDB.dbo.match WITH(NOLOCK)
WHERE matchid=@matchid
	
SELECT	@betstatus = betstatus
FROM SVRPRO.ProdDB.dbo.match_remark_ex WITH(NOLOCK)
WHERE matchid=@matchid

IF @LGOnly = 1 ---refund last goal
BEGIN		
	IF @action in ('CAL', 'CAL-FT')
		SET @betStatus = CASE WHEN CHARINDEX('FL:',@betstatus) > 0 THEN STUFF(@betStatus,LEN(@betStatus),1,'0')
						ELSE @betStatus END 
	IF @action in ('CAL', 'CAL-HT')
		SET @betStatus = CASE WHEN CHARINDEX('1FL:',@betstatus) > 0 THEN STUFF(@betstatus, CHARINDEX('1FL:',@betstatus)+ 6,1,'0')
						ELSE @betStatus END 
END
ELSE  --- refund all FGLG
BEGIN
	IF @betStatus = 'Refund' 
		SET @betStatus = 'Refund;'
	
	IF @action in ('CAL', 'CAL-HT')
	BEGIN
		SET @betStatus = CASE WHEN CHARINDEX('1FL:',@betstatus) > 0 THEN STUFF(@betstatus, CHARINDEX('1FL:',@betstatus),7,'1FL:0-0')
						ELSE ISNULL(@betstatus,'') + '1FL:0-0;' END
	END 
	

	IF @action in ('CAL', 'CAL-FT')
	begin
		SET @betStatus = CASE WHEN CHARINDEX(';FL:',@betstatus) > 0 THEN SUBSTRING(@betStatus,1,CHARINDEX(';FL:',@betStatus)) + 'FL:0-0'  
						ELSE ISNULL(@betstatus,'') +  'FL:0-0' END 
	end
END

EXEC SVRPRO.ProdDB.dbo.Admin_Match_Update @Command	= 'Admin_Settlement_Refund_FGLG', 
											@MatchID	= @matchid,										
											@BetStatus	= @betstatus											

EXEC dbo.Admin_Calculate_RefundFGLG @matchid = @matchid, @action = @action, @LGOnly=@LGOnly, @matchdate=@matchdate

IF @IsLoopTempTable = 0
BEGIN
	-------------------------------------------------------------
	---         CAPTURE value BALANCE after settlement        ---
	---------------------------VVVV------------------------------
	CREATE TABLE #BalanceAfter (custid int PRIMARY KEY, balance money)
	BEGIN
		INSERT INTO #BalanceAfter
		SELECT custid, SUM(winlost-actual_stake+playercomm)
		FROM dbo.bettrans with (rowlock)		
		WHERE matchid = @matchid AND ((@bettype = 0 AND bettype IN (14,127)) OR (bettype = @bettype))
		GROUP BY custid

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
END

Declare @LogData nvarchar(200)
SELECT @LogData = 'Calculate (Refund FT FGLG) for matchid:' + CAST(@matchid as nvarchar(10))	
	+ 'action: ' + @action
	+ 'LG Only:' + case when @LGOnly = 1 then ' (LG only)' else ' (All)' end
EXEC dbo.WriteLog_UserLog_T @AdminID, @LogData


--Write Log Settle

SELECT 
	@finalhomescore = finalhomescore,
	@finalawayscore = finalawayscore,
	@hthomescore = hthomescore, 
	@htawayscore = htawayscore,
	@goalrecord = goalrecord,
	@betstatus = betstatus
 FROM SVRPRO.ProdDB.dbo.match_remark_ex WITH(NOLOCK) WHERE matchid = @matchid

SELECT @Remark = 'Action=' +@action + ' RefundLGOnly=' + convert(char(1), @LGOnly)

BEGIN TRY
	EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Settle
		@UserID = @adminid,
		@Matchid = @matchid,
		@ActionID = @ActionID,
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
	SELECT @Remark = @Remark + ' ErrMsg=' + left(error_message(), 350)
	EXEC LogDB.dbo.WriteLog_Settlement_Settle
		@UserID = @adminid,
		@Matchid = @matchid,
		@ActionID = @ActionID,
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
END

GO
GRANT EXECUTE ON [dbo].[Admin_Settlement_Refund_FGLG] TO [aplweb]


