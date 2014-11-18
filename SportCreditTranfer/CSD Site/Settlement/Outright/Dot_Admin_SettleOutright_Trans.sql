ALTER PROCEDURE [dbo].[Dot_Admin_SettleOutright_Trans]
	@AdminId int = 0,
	@matchid int,
	@status nvarchar(10),
	@deadheat float = 1,
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
BEGIN
/*
Created:
Task : sp for outright settlement
DB: SVRTXN/TRANSDB
Original:

Revisions:
	- 20131125@Dan: add undo action
	- 20140819@Sophia: Change @creator to @AdminId


Param's Explanation:
	- @deadheat = fraction of deadheat to divide (1,2,3  etc)
*/
SET NOCOUNT ON
-- check and not allow attempt to settlement same game while it's still not finish
IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = 2 AND KeyValue = @matchid)
BEGIN
	SELECT  @ErrCode = 101,
			@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
	RETURN
END

DECLARE @Remark VARCHAR(500), @ActionID int 
SET @ActionID=128

Declare @start datetime, @stop datetime 
SELECT @start = CURRENT_TIMESTAMP

INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (2, @matchid)
IF (@@Error = 0)
BEGIN
	BEGIN TRY
		EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @AdminId,
			@Matchid = @matchid,
			@KeyID = 2,
			@ActionID = @ActionID,
			@Remark = 'ADD SUCCESS SPName = Dot_Admin_SettleOutright_Trans'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'ADD SUCCESS SPName = Dot_Admin_SettleOutright_Trans ErrMsg='+ left(error_message(), 400)
		EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @AdminId,
			@Matchid = @matchid,
			@KeyID = 2,
			@ActionID = @ActionID,
			@Remark = @Remark
	END CATCH
END
ELSE
BEGIN
	SELECT @ErrCode = 102, @ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
	RETURN
END
---------

declare @winlostdate smalldatetime

select @winlostdate = convert(char(10),getdate(),111)

-------------------------------------------------------------
---        CAPTURE value BALANCE before settlement        ---
---------------------------VVVV------------------------------
Declare @TotalAccount int, @TotalAccount_BalanceUpdate int

CREATE TABLE #BalanceBefore (custid int PRIMARY KEY, balance money)

    INSERT INTO #BalanceBefore
    SELECT custid,sum( winlost-actual_stake+playercomm)
    FROM dbo.bettrans with (rowlock)
    WHERE matchid = @matchid and bettype = 10 and statusID NOT IN (101, 102)
	Group by custid

	SET @TotalAccount = @@ROWCOUNT

EXEC Admin_Calculate_10 @matchid, @status, @deadheat, @winlostdate

-------------------------------------------------------------
---         CAPTURE value BALANCE after settlement        ---
---------------------------VVVV------------------------------
CREATE TABLE #BalanceAfter (custid int PRIMARY KEY , balance money)

        INSERT INTO #BalanceAfter
        SELECT custid,sum( winlost-actual_stake+playercomm)
        FROM dbo.bettrans with (rowlock)
        WHERE matchid = @matchid and bettype = 10
			and statusID = case @status when 'won' then 112
				when 'lose' then 113
				when 'Refund' then 103
				when 'UNDO' then statusID
				else 999 end
			and statusID NOT IN (101, 102)
		Group by custid

-------------------------------------------------------------
---                   compare BALANCE                     ---
---------------------------VVVV------------------------------
CREATE TABLE #Balance (custid int not null , balance money, Increased bit not null , PRIMARY KEY CLUSTERED(custid, Increased))

INSERT INTO #Balance
SELECT b.custid, a.balance - b.balance, CASE WHEN a.balance > b.balance THEN 1 ELSE 0 END
FROM #BalanceBefore b
        INNER JOIN #BalanceAfter a ON b.custid = a.custid
WHERE b.balance <> a.balance

SET @TotalAccount_BalanceUpdate = @@ROWCOUNT

CREATE INDEX IX_Balance_Increased ON #Balance (Increased)

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

--Write Log Settle
SELECT @Remark = 'Duration:' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms;' 	
	+ ' Bal:' + CAST(IsNull(@TotalAccount_BalanceUpdate,0) as varchar(20)) + '/' + CAST(IsNull(@TotalAccount,0) as varchar(20))	
	
BEGIN TRY
	EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_SettleOutright
		@UserID = @AdminId,
		@OrId = @matchid,
		@LeagueId = 0,
		@ActionID = @ActionID,
		@status = @status,
		@deadheat = @deadheat, 
		@Remark = @Remark,
		@IP = @IP		
END TRY  
BEGIN CATCH	
	SELECT @Remark = @Remark + ' ErrMsg=' + left(error_message(), 250)	
	EXEC LogDB.dbo.WriteLog_Settlement_SettleOutright
		@UserID = @AdminId,
		@OrId = @matchid,
		@LeagueId = 0,
		@ActionID = @ActionID,
		@status = @status,
		@deadheat = @deadheat, 
		@Remark = @Remark,
		@IP = @IP	
END CATCH
----
DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
WHERE KeyID = 2 AND KeyValue = @matchid
IF (@@Error = 0)
BEGIN
	BEGIN TRY
		EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @AdminId, 
			@Matchid = @matchid,
			@KeyID = 2,
			@ActionID = @ActionID,
			@Remark = 'DEL SUCCESS SPName = Dot_Admin_SettleOutright_Trans'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'DEL SUCCESS SPName = Dot_Admin_SettleOutright_Trans ErrMsg='+ left(error_message(), 400)
		EXEC LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @AdminId, 
			@Matchid = @matchid,
			@KeyID = 2,
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
			@KeyID = 2,
			@ActionID = @ActionID,
			@Remark = 'DEL FAILED SPName = Dot_Admin_SettleOutright_Trans'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'DEL FAILED SPName = Dot_Admin_SettleOutright_Trans ErrMsg='+ left(error_message(), 400)
		EXEC LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @AdminId, 
			@Matchid = @matchid,
			@KeyID = 2,
			@ActionID = @ActionID,
			@Remark = @Remark
	END CATCH
END

END
GO
GRANT EXECUTE ON [dbo].[Dot_Admin_SettleOutright_Trans] TO [aplweb] AS [dbo]
GO
--GRANT EXECUTE ON [dbo].[Dot_Admin_SettleOutright_Trans] TO [Dot_Admin] AS [dbo]
