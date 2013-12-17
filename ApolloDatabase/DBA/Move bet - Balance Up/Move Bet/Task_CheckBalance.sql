 
/****** Object:  StoredProcedure [dbo].[Task_CheckBalance]    Script Date: 05/07/2013 02:42:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_CheckBalance]
	@Step tinyint = 0,
	@Action varchar(20) = 'JustLog', -- 'JustFix', 'LogAndFix'
	@custid int = 0 
AS
/*
Created: Sophia 
Date: 2013-05-28
Task: Compare balance between bettrans table and BalanceCredit/BalanceDebit
DB: SVRTXN.TransDB

Revision: 

*/

SET NOCOUNT ON

Declare --@FromBalanceTable money, 
		@FromBettrans money, 
		@DiffBalance money
		
IF @custid > 0
BEGIN
	IF @Action = 'LogAndFix'
	BEGIN
		INSERT INTO dbo.Task_Cust_CheckBalanceVerify (custid) VALUES (@custid)
		
		EXEC dbo.Task_CheckBalance @Step = 3, @Action = 'LogAndFix'
		
		RETURN	
	END
	
	SELECT @FromBettrans = SUM(winlost-actual_stake+playercomm)
	FROM dbo.bettrans with (rowlock)
	WHERE custid = @custid
	
	SELECT @custid custid, c.username,
		@FromBettrans FromBettrans,
		cd.Balance - db.Balance FromBalanceTable,
		@FromBettrans - (cd.Balance - db.Balance) Diff
	FROM
		SVRCUST.CustDB.dbo.custinfo c with (nolock)
		INNER JOIN dbo.BalanceCredit cd with (nolock) ON c.custid = cd.custid
		INNER JOIN dbo.BalanceDebit  db with (nolock) ON c.custid = db.custid
	WHERE
		c.custid = @custid
	
	RETURN
END

IF @Step = 99
-- run through all step automatic
BEGIN
	EXEC dbo.Task_CheckBalance @Step = 1
	EXEC dbo.Task_CheckBalance @Step = 2
	EXEC dbo.Task_CheckBalance @Step = 33, @Action = @Action
	EXEC dbo.Task_CheckBalance @Step = 5	
END
ELSE IF @Step = 33
BEGIN
	WHILE EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalanceVerify)
	BEGIN
		EXEC dbo.Task_CheckBalance @Step = 3, @Action = @Action
	END
END
ELSE IF @Step = 1 -- Get List of Customer & Balance
BEGIN
	DELETE FROM dbo.Task_Cust_CheckBalance

	INSERT INTO dbo.Task_Cust_CheckBalance (custid, FromBettrans)
	SELECT b.custid, SUM(winlost-actual_stake+playercomm)
	FROM dbo.bettrans b with (nolock)
		--INNER JOIN SVRCUST.CustDB.dbo.custinfo c with (nolock) ON b.custid = c.custid  
	WHERE b.custid>0
	GROUP BY b.custid
END
ELSE IF @Step = 2 -- 1st round : check BalanceBettrans -vs- BalanceTable , Then save list to verify
BEGIN
	UPDATE cb
	SET FromBalanceTable = cd.Balance - db.Balance
	FROM
		dbo.Task_Cust_CheckBalance cb
		INNER JOIN dbo.BalanceCredit cd with (nolock) ON cb.custid = cd.custid
		INNER JOIN dbo.BalanceDebit  db with (nolock) ON cb.custid = db.custid
	
	DELETE FROM dbo.Task_Cust_CheckBalanceVerify

	INSERT INTO dbo.Task_Cust_CheckBalanceVerify (custid)
	SELECT custid
	FROM dbo.Task_Cust_CheckBalance with (nolock)
	WHERE FromBettrans <> FromBalanceTable
END
ELSE IF @Step = 3 -- 2nd round : verify each a/c one by one
BEGIN
	--
	-- Get @custid
	--
	SELECT TOP 1 @custid = custid
	FROM dbo.Task_Cust_CheckBalanceVerify with (nolock)

	DELETE FROM dbo.Task_Cust_CheckBalanceVerify WHERE custid = @custid

	--
	-- Get/Compare Balance
	--
	SELECT @FromBettrans = SUM(winlost-actual_stake+playercomm)
	FROM dbo.bettrans with (rowlock)
	WHERE custid = @custid
	
	SELECT --@FromBalanceTable = cd.Balance - db.Balance
		@DiffBalance = IsNull(@FromBettrans, 0) - (cd.Balance - db.Balance)
	FROM dbo.BalanceCredit cd with (nolock)
		INNER JOIN dbo.BalanceDebit db with (nolock) ON cd.custid = db.custid
	WHERE
		cd.custid = @custid
		AND db.custid = @custid
	
	--
	-- Take Action accordingly
	--
	IF @DiffBalance <> 0 --@FromBettrans <> @FromBalanceTable
	BEGIN
		IF NOT EXISTS (
			SELECT 1 FROM dbo.BalancePendingCredit WHERE custid = @custid
			UNION
			SELECT 1 FROM dbo.BalancePendingDebit  WHERE custid = @custid
		)
		BEGIN
			IF @Action IN ('JustLog', 'LogAndFix')
				INSERT INTO dbo.Task_Cust_BalanceProblem (custid, DiffBalance, Remark)
				SELECT
					@custid, @DiffBalance,
					CASE @Action
					WHEN 'LogAndFix' THEN 'Fixed by LogAndFix'
					ELSE '' END
			
			IF @Action IN ('JustFix', 'LogAndFix')
			BEGIN
				IF @DiffBalance > 0
					INSERT INTO dbo.BalancePendingCredit (custid, Balance) VALUES (@custid, @DiffBalance)
				ELSE
					INSERT INTO dbo.BalancePendingDebit  (custid, Balance) VALUES (@custid,-@DiffBalance)

				update task_cust_balanceproblem
				set remark = 'Reset ON ' + CONVERT(varchar(10), current_timestamp, 120)
				where remark = '' and custid = @custid

			END	
		END		
	END	
END
ELSE IF @Step = 4 -- check if need to continue
BEGIN
	IF EXISTS (SELECT 1 FROM dbo.Task_Cust_CheckBalanceVerify)
		-- raiserror here to continue to next step of jobs
		RAISERROR ('* no more data *', -- Message text.
				   16, -- Severity.
				   1 -- State.
				   );	
END
ELSE IF @Step = 5 -- Finishing
BEGIN
	UPDATE bp
	SET username = c.username
	FROM dbo.custinfo c with (nolock)
		INNER JOIN dbo.Task_Cust_BalanceProblem bp ON c.custid = bp.custid AND bp.username IS NULL

	UPDATE bp
	SET remark = c.Remark
	FROM dbo.Task_Cust_CheckBalance_Exception c
		INNER JOIN dbo.Task_Cust_BalanceProblem bp ON c.custid = bp.custid
	WHERE
		bp.remark = ''
	
 
END

