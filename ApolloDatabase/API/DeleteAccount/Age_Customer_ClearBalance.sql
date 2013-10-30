ALTER PROCEDURE [dbo].[Age_Customer_ClearBalance]
	@CustID INT ,
	@Username NVARCHAR(50),
	@Currency INT, 
	@CurrencyName VARCHAR(5),
	@ActualRate FLOAT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg VARCHAR(1000) = '' OUTPUT
AS

DECLARE @refNo		BIGINT,
		@Now		Datetime,
		@Balance	MONEY 

		SELECT @Now = CURRENT_TIMESTAMP

		----- Clear balance tables first, so that member can not place bet
		DELETE BalanceCredit WHERE CustID = @CustID
			IF @@ERROR > 0
			BEGIN
				SELECT 
					@ErrCode = 5209, 
					@ErrMsg = 'Failed to clear balance of customer [CustId = ' + COALESCE(CAST(@CustId AS VARCHAR(10)), SPACE(1)) + ']'						 
				RETURN
			END	

		DELETE BalanceDebit WHERE CustID = @CustID
			IF @@ERROR > 0
			BEGIN
				SELECT 
					@ErrCode = 5210, 
					@ErrMsg = 'Failed to clear table balance of customer [CustId = ' + COALESCE(CAST(@CustId AS VARCHAR(10)), SPACE(1)) + ']'						 
				RETURN
			END	

		----
		
		SELECT	@Balance = ISNULL(SUM (Winlost - Actual_stake + PlayerComm),0)
		FROM	Bettrans WITH (NOLOCK)
		WHERE	CustID = @CustID
		 
		IF @Balance <> 0
		BEGIN
			EXEC Acc_SelRefNo @RefNo = @RefNo OUTPUT
			SELECT @RefNo = @RefNo + 100000000000
		END
		
		IF @Balance > 0 
		BEGIN 
			INSERT INTO Bettrans 
				(Matchid, Creator, Custid, Username, Refno, Transdate, Bettype, Transdesc, Winlost, Actual_stake, PlayerComm, 
				Status,StatusID, Ruben, Winlostdate, Currency, Actualrate, VirtualRate, CurrencyName, TComm, TWinlost, IP)
			VALUES (0, 8, @CustId, @Username, @refno, @Now, 22003, 'Delete account with positive balance - Customer::'+@Username, 0, @Balance, 0,
				'Completed',131, 1, convert(nvarchar(10), @Now,120), @Currency, @Actualrate, @Actualrate, @CurrencyName, 0, 0,'')
			
			-- Check error
			IF @@ERROR > 0
			BEGIN
				SELECT 
					@ErrCode = 5211, 
					@ErrMsg = 'Failed to clear balance of customer [CustId = ' + COALESCE(CAST(@CustId AS VARCHAR(10)), SPACE(1)) + ']'						 
				RETURN
			END	
		END
		ELSE
		IF @Balance < 0 
		BEGIN 
			SELECT @Balance = ABS(@Balance)

			INSERT INTO Bettrans 
				(Matchid, Creator, Custid, Username, Refno, Transdate, Bettype, Transdesc, Winlost, Actual_stake, PlayerComm, 
				Status,StatusID, Ruben, Winlostdate, Currency, Actualrate, VirtualRate, CurrencyName, TComm, TWinlost, IP)
			VALUES (0, 8, @CustId, @Username, @refno, @Now, 22003,  'Delete account with negative balance - Customer::'+@Username, @Balance, 0, 0,
				'Completed',131, 1, convert(nvarchar(10), @Now,120), @Currency, @Actualrate, @Actualrate, @CurrencyName, 0, 0,'')
		
			-- Check error
			IF @@ERROR > 0
			BEGIN
				SELECT 
					@ErrCode = 5211, 
					@ErrMsg = 'Failed to clear balance of customer [CustId = ' + COALESCE(CAST(@CustId AS VARCHAR(10)), SPACE(1)) + ']'		
				RETURN
			END			
		END 

GO
