ALTER PROCEDURE [dbo].[Admin_Settlement_Refund_All]
	@matchid int,
	@creator int, 		
	@betstatus nvarchar(50) = NULL,	
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

/*
Creator: Dan
Date: 2013-03-21 
Task : refund tickets 
Original: refund
DB: SVRTXN/TransDB

Revisions: 
	
Param's Explanation:
• @matchid: matchid need to refund
BetDaq account: 
			BQUS888:50057
			BQUSMLB:879241
			BQUSNBA:103873 
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
			@UserID = @creator, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = 109, 
			@Remark = 'ADD SUCCESS'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'ADD SUCCESS ErrMsg=' + left(error_message(), 400)
		EXEC LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @creator, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = 109, 
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
		AND bettype <> 14
GROUP BY custid

EXEC SVRPRO.ProdDB.dbo.Admin_Match_Update @Command = 'Admin_Settlement_Refund_All', @MatchID = @matchid, @creator = @creator , @betstatus = @betstatus
-- in IBC, web call this after refund. But we update it in apollo as refund FT/HT
EXEC SVRPRO.ProdDB.dbo.Admin_Match_UpdateMatchRemark @matchid, 'F'

EXEC dbo.Admin_Calculate_RefundAll @matchid = @matchid

INSERT INTO #BalanceAfter	
SELECT	custid, SUM(winlost-actual_stake+playercomm)
FROM	dbo.bettrans with (rowlock)
WHERE	matchid = @matchid 
		AND bettype <> 14
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

Declare @LogData nvarchar(200)
SELECT @LogData = 'Calculate (Refund All) for matchid:' + CAST(@matchid as nvarchar(10))

EXEC dbo.WriteLog_UserLog_T @creator, @LogData

--Write Log Settle
SELECT @Remark = 'Duration=' + CAST(DATEDIFF(millisecond, @start, @stop) as nvarchar(50)) + ' ms;'
BEGIN TRY					
	EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Settle
		@UserID = @creator,
		@Matchid = @matchid,
		@ActionID = 109,
		@finalhomescore = 0,
		@finalawayscore = 0,  
		@hthomescore = 0,
		@htawayscore = 0,
		@GoalRecord = '',
		@betstatus = 'Refund',
		@Remark = @Remark,
		@IP = @IP
END TRY
BEGIN CATCH
	SELECT @Remark = @Remark + ' ErrMsg=' + left(error_message(), 250)	
	EXEC LogDB.dbo.WriteLog_Settlement_Settle
		@UserID = @creator,
		@Matchid = @matchid,
		@ActionID = 109,
		@finalhomescore = 0,
		@finalawayscore = 0,  
		@hthomescore = 0,
		@htawayscore = 0,
		@GoalRecord = '',
		@betstatus = 'Refund',
		@Remark = @Remark,
		@IP = @IP
END CATCH


-----
DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
WHERE KeyID = 1 AND KeyValue = @matchid    
IF (@@Error = 0)
BEGIN
	BEGIN TRY
		EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking
			@UserID = @creator, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = 109, 
			@Remark = 'DEL SUCCESS'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'DEL SUCCESS ErrMsg=' + left(error_message(), 350)	
		EXEC LogDB.dbo.WriteLog_Settlement_Checking
			@UserID = @creator, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = 109, 
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
			@ActionID = 109, 
			@Remark = 'DEL FAILED'
	END TRY
	BEGIN CATCH		
		SELECT @Remark = 'DEL FAILED ErrMsg=' + left(error_message(), 350)	
		EXEC LogDB.dbo.WriteLog_Settlement_Checking
			@UserID = @creator, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = 109, 
			@Remark = @Remark
	END CATCH
END
GO
GRANT EXECUTE ON [dbo].[Admin_Settlement_Refund_All] TO [aplweb]
