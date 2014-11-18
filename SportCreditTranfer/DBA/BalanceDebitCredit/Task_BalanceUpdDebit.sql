USE [TransDB]
GO
/****** Object:  StoredProcedure [dbo].[Task_BalanceUpdDebit]    Script Date: 5/28/2013 11:08:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_BalanceUpdDebit]
AS
/*
Created: Dan
DB: SVRTXN/TransDB
Task: update balance debit table from BalancePendingDebit
Revisions:   
	 
Param's Explanation:
	 
*/
SET NOCOUNT ON 
Declare @rn bigint, @rnx bigint
SELECT @rn = MIN(rn), @rnx = MAX(rn)
FROM dbo.BalancePendingDebit with (nolock)

IF @rn IS NULL
BEGIN
	WAITFOR DELAY '000:00:01.000'
	RETURN -- no data to be update.
END

-- update maximum only 25 rows once
SET @rn = CASE WHEN @rnx - @rn > 25 THEN @rn + 25 ELSE @rnx END

-- collect balance value.
CREATE TABLE #Balance (custid int PRIMARY KEY, balance money)
INSERT INTO #Balance
SELECT custid, SUM(balance)
FROM dbo.BalancePendingDebit --with (rowlock)
WHERE rn <= @rn
GROUP BY custid


-- perform update
Declare @Retry int, @Success bit
SET @Retry = 0

TryAgain:

BEGIN TRY
	SET @Retry = @Retry + 1
	SET @Success = 1
	BEGIN TRANSACTION
	
		UPDATE bal
		SET Balance = bal.Balance + B.balance
		FROM dbo.BalanceDebit bal WITH (rowlock, updlock)
			INNER JOIN #Balance B ON bal.custid = B.custid
		
	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	SET @Success = 0
	ROLLBACK TRANSACTION
END CATCH

-- retry 3 times, in case some problem happen.
IF @Success = 0 AND @Retry < 3 GOTO TryAgain

-- remove data which already updated.
IF @Success = 1
	DELETE FROM dbo.BalancePendingDebit
	WHERE rn <= @rn


