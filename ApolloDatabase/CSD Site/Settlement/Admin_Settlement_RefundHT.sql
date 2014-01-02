ALTER PROCEDURE [dbo].[Admin_Settlement_RefundHT]
	@matchid int,
	@adminid int,	
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
as

/*
Created By: Dan
Date: 2013-03-21
Task : Refund Half-time in case there are HT tickets bet on special matches that have 3 sets
DB: SVRTXN/TransDB
Original: 

Revisions:
		
Param's Explanation:
• @matchid: matchid of match to Refund HT

*/
SET NOCOUNT ON 

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
			@UserID = @adminID,
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = 110, 
			@Remark = 'ADD SUCCESS'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'ADD SUCCESS ErrMsg=' + left(error_message(), 400)
		EXEC LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @adminID,
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = 110, 
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
SELECT custid, SUM(winlost-actual_stake+playercomm)
FROM dbo.bettrans with (rowlock)
WHERE matchid = @matchid AND bettype IN (7,8,12,15,21,30,125)
GROUP BY custid

--Check if match already Refund FT => refund whole match

if exists(select 1 from SVRPRO.ProdDB.dbo.match_remark_ex with (nolock) where matchid = @matchid AND betstatus like '%Refund FT%')
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
				@ActionID = 110, 
				@Remark = 'DEL SUCCESS'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS ErrMsg=' + left(error_message(), 400)
			EXEC LogDB.dbo.WriteLog_Settlement_Checking 
				@UserID = @adminID,
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 110, 
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
				@ActionID = 110, 
				@Remark = 'DEL FAILED'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL FAILED ErrMsg=' + left(error_message(), 400)
			EXEC LogDB.dbo.WriteLog_Settlement_Checking 
				@UserID = @adminID,
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 110, 
				@Remark = @Remark
		END CATCH
	END
	
	EXEC dbo.Admin_Settlement_Refund_All 
			@matchid = @matchid, 
			@creator = @adminid,			
			@betstatus = NULL,			
			@IP = @IP,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT 
		
	RETURN
END

DECLARE @RowCount INT

EXEC SVRPRO.ProdDB.dbo.Admin_Match_Update @Command	= 'Admin_Settlement_RefundHT', 
										@Matchid	= @matchid,
										@RowCount	= @Rowcount OUTPUT,
										@creator	= @adminid 

IF @Rowcount > 0
BEGIN
	EXEC SVRPRO.ProdDB.dbo.Admin_Match_UpdateMatchRemark @matchid, 'F'

	EXEC dbo.Admin_Calculate_RefundHT 	@matchid = @matchid	
END

INSERT INTO #BalanceAfter
SELECT custid, SUM(winlost-actual_stake+playercomm)
FROM dbo.bettrans with (rowlock)
WHERE matchid = @matchid AND bettype IN (7,8,12,15,21,30,125)
GROUP BY custid


-------------------------------------------------------------
---                   compare BALANCE                     ---
---------------------------VVVV------------------------------
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

-------------------------------------------------------------
---                      WRITE LOG                        ---
---------------------------VVVV------------------------------
SELECT @stop = CURRENT_TIMESTAMP


IF @Rowcount > 0
BEGIN 
	Declare @LogData nvarchar(300)
	SELECT @LogData = 'Calculate (Refund HT) for matchid:' + CAST(@matchid as nvarchar(10))
	EXEC dbo.WriteLog_UserLog_T @UserID = @AdminID, @Doing = @LogData		
	
	--Write Log Settle
	DECLARE 
			@finalhomescore INT, @finalawayscore INT,
			@betstatus nvarchar(50), @goalrecord varchar(50)

	SELECT 
			@finalhomescore = finalhomescore, 
			@finalawayscore = finalawayscore,
			@goalrecord = goalrecord,
			@betstatus = betstatus
	 FROM	SVRPRO.ProdDB.dbo.match_remark_ex WITH(NOLOCK) WHERE matchid = @matchid

	SELECT	@Remark = 'Duration=' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms;'
	BEGIN TRY	
		EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Settle
			@UserID = @adminid,
			@Matchid = @matchid,
			@ActionID = 110,
			@finalhomescore = @finalhomescore,
			@finalawayscore = @finalawayscore,  
			@hthomescore = 0,
			@htawayscore = 0,
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
			@ActionID = 110,
			@finalhomescore = @finalhomescore,
			@finalawayscore = @finalawayscore,  
			@hthomescore = 0,
			@htawayscore = 0,
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
			@ActionID = 110, 
			@Remark = 'DEL SUCCESS'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'DEL SUCCESS ErrMsg=' + left(error_message(), 400)
		EXEC LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @adminID,
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = 110, 
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
			@ActionID = 110, 
			@Remark = 'DEL FAILED'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'DEL FAILED ErrMsg=' + left(error_message(), 400)
		EXEC LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @adminID,
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = 110, 
			@Remark = @Remark
	END CATCH
END

GO
GRANT EXECUTE ON [dbo].[Admin_Settlement_RefundHT] TO [aplweb]
