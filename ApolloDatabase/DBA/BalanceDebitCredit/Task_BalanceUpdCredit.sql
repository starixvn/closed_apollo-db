USE [TransDB]
GO
/****** Object:  StoredProcedure [dbo].[Task_BalanceUpdCredit]    Script Date: 5/28/2013 11:08:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_BalanceUpdCredit]
AS
/*
Created: Dan
DB: SVRTXN/TransDB
Task: update balance debit table from BalancePendingCredit
Revisions:   
	 
Param's Explanation:
	 
*/

SET NOCOUNT ON

Declare @rn bigint, @rnx bigint
SELECT @rn = MIN(rn), @rnx = MAX(rn)
FROM dbo.BalancePendingCredit with (nolock)

IF @rn IS NULL
BEGIN
	WAITFOR DELAY '000:00:01.000'
	RETURN -- no data to be update.
END

-- update maximum only 100 rows once
SET @rn = CASE WHEN @rnx - @rn > 100 THEN @rn + 100 ELSE @rnx END

-- collect balance value.
CREATE TABLE #Balance (custid int PRIMARY KEY, balance money)
INSERT INTO #Balance
SELECT custid, SUM(balance)
FROM dbo.BalancePendingCredit --with (rowlock)
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
		FROM dbo.BalanceCredit bal WITH (rowlock, updlock)
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
	DELETE FROM dbo.BalancePendingCredit
	WHERE rn <= @rn


