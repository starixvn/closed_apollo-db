ALTER PROCEDURE [dbo].[Admin_Settlement_Refund_FGLG]
	@matchid int,
	@AdminId int,
	@action varchar(10) = 'REFUND', -- REFUND, REFUND-FT, REFUND-HT
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

SELECT @ActionID = 112
		,@bettype = CASE 
			WHEN @action = 'REFUND-HT' THEN 127
			WHEN @action = 'REFUND-FT' THEN 14
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
				@UserID = @AdminId,
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = @ActionID, 
				@Remark = 'ADD SUCCESS'
		END TRY
		BEGIN CATCH	
			SELECT @Remark = 'ADD SUCCESS ErrMsg=' + left(error_message(), 400)
			EXEC LogDB.dbo.WriteLog_Settlement_Checking 
				@UserID = @AdminId,
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
	@matchdate datetime,
	@betstatus1 nvarchar(50),
	@betstatus2 nvarchar(50)

SELECT	@matchdate = eventdate		
FROM SVRPRO.ProdDB.dbo.match WITH(NOLOCK)
WHERE matchid=@matchid
	
SELECT	@betstatus = betstatus
FROM SVRPRO.ProdDB.dbo.match_remark_ex WITH(NOLOCK)
WHERE matchid=@matchid

SELECT @betstatus1 = CASE when CHARINDEX('1FL:',@betstatus) > 0 THEN SUBSTRING(@betstatus, CHARINDEX('1FL:',@betstatus),8)
							ELSE ''
					END,
		@betstatus2 = CASE when CHARINDEX('1FL:',@betstatus) > 0 THEN REPLACE(@betstatus,@betstatus1,'')
							ELSE @betstatus	
					END							
			
IF @LGOnly = 1 --refund last goal
	BEGIN
		IF @action IN ('REFUND', 'REFUND-HT')
		BEGIN
			SELECT @betstatus1 = CASE WHEN @betstatus1 = '' THEN @betstatus1 -- Ex: 1FL:1-0;
									 ELSE STUFF(@betstatus1,7,1,'0')
								END
		END
		IF @action IN ('REFUND', 'REFUND-FT')
		BEGIN
			select @betstatus2 = CASE when CHARINDEX('FL:',@betstatus2) > 0 THEN STUFF(@betstatus2,CHARINDEX('FL:',@betstatus2)+5,1,'0')
									  ELSE @betstatus2
								 end -- Ex: Refund;FL:1-0;
		END
	END
	ELSE -- refund all FGLG
	BEGIN
		IF @action IN ('REFUND', 'REFUND-HT')
		BEGIN
			select @betstatus1 = '1FL:0-0;'
		END
		IF @action IN ('REFUND', 'REFUND-FT')
		BEGIN
			select @betstatus2 = CASE when CHARINDEX('FL:',@betstatus2) > 0 then STUFF(@betstatus2,CHARINDEX('FL:',@betstatus2),7,'FL:0-0;')
										ELSE @betstatus2 + 'FL:0-0;' -- Ex: Refund;FL:0-0;
								END 
		END
	END

	SELECT @betstatus = @betstatus2 + @betstatus1

EXEC SVRPRO.ProdDB.dbo.Admin_Match_Update   @Command	= 'Admin_Settlement_Refund_FGLG', 
											@MatchID	= @matchid,										
											@BetStatus	= @betstatus,
											@AdminId	= @AdminId 											

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
EXEC dbo.WriteLog_UserLog_T @AdminId, @LogData


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
		@UserID = @AdminId,
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
		@UserID = @AdminId,
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
				@UserID = @AdminId,
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = @ActionID, 
				@Remark = 'DEL SUCCESS'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS ErrMsg=' + left(error_message(), 400)
			EXEC LogDB.dbo.WriteLog_Settlement_Checking
				@UserID = @AdminId,
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
				@UserID = @AdminId,
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = @ActionID,
				@Remark = 'DEL FAILED'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL FAILED ErrMsg=' + left(error_message(), 400)
			EXEC LogDB.dbo.WriteLog_Settlement_Checking
				@UserID = @AdminId,
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = @ActionID,
				@Remark = @Remark
		END CATCH				
	END
END

GO
GRANT EXECUTE ON [dbo].[Admin_Settlement_Refund_FGLG] TO [aplweb]


