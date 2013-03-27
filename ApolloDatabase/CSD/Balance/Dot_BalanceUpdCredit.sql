CREATE PROCEDURE [dbo].[Dot_BalanceUpdCredit]
	@CustId [int],
	@balance [money],
	@stoptest [bit] = 0
WITH EXECUTE AS CALLER
AS

/*
Created: Sophia
DB: SVRTXN.TransDB
Task: update balance credit table
Revisions:   
	 
Param's Explanation:
	 
*/

Declare @Retry int, @Success bit
SET @Retry = 0

TryAgain:

BEGIN TRY
	SET @Retry = @Retry + 1
	SET @Success = 1
	BEGIN TRANSACTION
	
		UPDATE dbo.BalanceCredit WITH (rowlock, updlock)
		SET Balance = Balance + @balance
		WHERE CustId = @CustId
		
		IF @@ROWCOUNT = 0 INSERT INTO dbo.BalanceCredit (CustId, balance) VALUES (@CustId, @balance)
		
	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	SET @Success = 0
	ROLLBACK TRANSACTION
END CATCH

IF @Success = 0 AND @Retry < 3 GOTO TryAgain


	 
GO
GRANT EXECUTE ON [dbo].[Dot_BalanceUpdCredit] TO [aplweb] AS [dbo]
GO
--GRANT VIEW DEFINITION ON [dbo].[Dot_BalanceUpdCredit] TO [vnteam] AS [dbo]