USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Dot_Admin_SettleOutright_Trans]    Script Date: 07/12/2013 07:26:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Dot_Admin_SettleOutright_Trans    Script Date: 7/11/2013 12:28:33 AM ******/
/****** Object:  Stored Procedure dbo.Dot_Admin_SettleOutright_Trans    Script Date: 7/8/2013 2:52:09 PM ******/
ALTER PROCEDURE [dbo].[Dot_Admin_SettleOutright_Trans]
	@matchid int,
	@status nvarchar(10),
	@deadheat float = 1,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
BEGIN
/*
Created:
Task : sp for outright settlement

DB: DBTXN/BODB02
Original:

Revisions:
	- 20120202@Thien: receive @winlostdate param from outside SP, to resolve late replication in DBDW/2
	- 20120430@AllenWu: Apply new credit balance procedure
	- 20120808@Sophia: . Add table TempVariableNumber to check if this match is being calculated then not allow to settle until the on-going process is completed
					   . Add @ErrCode, @ErrMsg to raise error
	- 20130103@Elodie:  Write log for adding a match into TempVariableNumber table or deleting a match from TempVariableNumber table
	- 20130121@Elodie:  Write more log on DBTXN server in case of DBLOG server failure
	- 20130624@Martin: Hotfix(There is already an object named 'pk_C2' in the database.Could not create constraint. See previous errors)
	- 20130624@Jamie: Add BalanceNegative 
	
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

DECLARE  @Remark VARCHAR(500)
		,@ActionID	INT
SELECT	@ActionID = 128 

INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (2, @matchid)
IF (@@Error = 0)
BEGIN
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking
			@UserID = 5838421, --dbaAdmin
			@Matchid = @matchid,
			@KeyID = 2,
			@ActionID = 0,
			@Remark = 'ADD SUCCESS SPName = Dot_Admin_SettleOutright_Trans'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'ADD SUCCESS SPName = Dot_Admin_SettleOutright_Trans ErrMsg='+ left(error_message(), 400)
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking
			@UserID = 5838421, --dbaAdmin
			@Matchid = @matchid,
			@KeyID = 2,
			@ActionID = 0,
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
CREATE TABLE #BalanceBefore (custid int PRIMARY KEY, balance money)

    INSERT INTO #BalanceBefore
    SELECT custid,sum( winlost-actual_stake+playercomm)
    FROM dbo.bettrans with (rowlock)
    WHERE matchid = @matchid and bettype = 10 and statusID NOT IN (101, 102)
	Group by custid

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
				else 999 end
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

CREATE INDEX IX_Balance_Increased ON #Balance (Increased)

INSERT INTO dbo.BalancePendingDebit (custid, balance)
SELECT custid, ABS(balance)
FROM #Balance
WHERE Increased = 0

INSERT INTO dbo.BalancePendingCredit (custid, balance)
SELECT custid, balance
FROM #Balance
WHERE Increased = 1

----
-- Add Negative Balance into BalanceNegative table 
----
INSERT INTO [bodb02].[dbo].[BalanceNegative]
           ([ExecDate]
           ,[MatchID]
           ,[ActionID]
           ,[GroupID]
           ,[CustID]
           ,[Balance]
           ,[StatusID]
           ,[Remark])
SELECT	 GETDATE()
		,@MatchID
		,@ActionID
		,3			---- Outright Settlement 
		,CustID
		,Balance
		,0
		,NULL 
FROM	#Balance WITH (NOLOCK)
WHERE	Increased = 0
		        
---------------------------------------------------

DROP TABLE #Balance
DROP TABLE #BalanceBefore
DROP TABLE #BalanceAfter

---------------------------------------------------
--add log to outright_log to notify for Apollo
EXEC DBTXN.bodb02.dbo.[Acc_Set_ConfirmedActionOutright] 
	@matchid = @matchid,
	@actionid = 31,
	@status = @status,
	@deadheat = @deadheat

----------------------------------------------------

DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
WHERE KeyID = 2 AND KeyValue = @matchid
IF (@@Error = 0)
BEGIN
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking
			@UserID = 5838421, --dbaAdmin
			@Matchid = @matchid,
			@KeyID = 2,
			@ActionID = 0,
			@Remark = 'DEL SUCCESS SPName = Dot_Admin_SettleOutright_Trans'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'DEL SUCCESS SPName = Dot_Admin_SettleOutright_Trans ErrMsg='+ left(error_message(), 400)
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking
			@UserID = 5838421, --dbaAdmin
			@Matchid = @matchid,
			@KeyID = 2,
			@ActionID = 0,
			@Remark = @Remark
	END CATCH
END
ELSE
BEGIN
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking
			@UserID = 5838421, --dbaAdmin
			@Matchid = @matchid,
			@KeyID = 2,
			@ActionID = 0,
			@Remark = 'DEL FAILED SPName = Dot_Admin_SettleOutright_Trans'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'DEL FAILED SPName = Dot_Admin_SettleOutright_Trans ErrMsg='+ left(error_message(), 400)
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Settle_Checking
			@UserID = 5838421, --dbaAdmin
			@Matchid = @matchid,
			@KeyID = 2,
			@ActionID = 0,
			@Remark = @Remark
	END CATCH
END

END
GO
GRANT EXECUTE ON [dbo].[Dot_Admin_SettleOutright_Trans] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Dot_Admin_SettleOutright_Trans] TO [Dot_Admin] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Admin_SettleOutright_Trans] TO [vnteam] AS [dbo]