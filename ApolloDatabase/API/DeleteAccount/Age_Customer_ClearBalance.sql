ALTER PROCEDURE [dbo].[Age_Customer_ClearBalance]
	@CustID INT ,
	@Username NVARCHAR(50),
	@Currency INT, 
	@CurrencyName VARCHAR(5),
	@ActualRate FLOAT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg VARCHAR(1000) = '' OUTPUT
AS
/**
 * Created by	: Sophia
 * Date			: 20131201
 * Task			: Balance to 0 for Customer
 * DB			: SVRTXN.TransDB
 * Revisions	:
 *	•  20131230@Sophia: Auto void test ticket
 * Parameters:
 *	•
 *	•
 *  
 */
DECLARE @refNo		BIGINT,
		@Now		Datetime,
		@Balance	MONEY 

		SELECT @Now = CURRENT_TIMESTAMP
		 

		-- =====================
		-- AUTO VOID TEST TICKET
		-- =====================
		---- currency 20
			DECLARE @TransIDs TABLE (TransID int)

			INSERT INTO @TransIDs (TransID)
			SELECT	TransID
			FROM	bettrans WITH (NOLOCK)
			WHERE	currency = 20 AND bettype <=19000 AND StatusID IN (0,1) AND CustID = @CustID

		---- line test Suntest
			INSERT INTO @TransIDs (TransID)
			SELECT	B.TransID		
			FROM	Bettrans B WITH (NOLOCK)
			INNER JOIN Bettrans_Agent BA WITH (NOLOCK)
					ON B.TransID = BA.TransID				
			WHERE	B.StatusID in (0,1)  
					AND B.bettype <=19000
					AND B.CustID = @CustId
					AND BA.StatusID in (0,1)  
					AND BA.bettype <=19000
					AND BA.AgentID = 53288 -----line test Suntest

			IF EXISTS (SELECT 1 FROM @TransIDs)
			BEGIN
				UPDATE dbo.bettrans with (ROWLOCK, UPDLOCK)  
				SET winlost=actual_stake, 
					playercomm = 0,
					Twinlost = 0,
					Tcomm = 0, 
					ruben=1, 
					statuswinlost=6, 
					status = 'Void',
					statusid = 102,
					transdesc = '[AutoVoid]' + transdesc				 
				WHERE TransID IN (SELECT TransID FROM @TransIDs)

				UPDATE dbo.BetTrans_Agent with (ROWLOCK, UPDLOCK)  
				SET AWinLost=0, 
					AComm = 0,
					status = 'Void',
					statusid = 102,
					transdesc = '[AutoVoid]' + transdesc
				WHERE TransID IN (SELECT TransID FROM @TransIDs)		 
				 
			END

		-- =====================
		-- END OF AUTO VOID TEST TICKET
		-- =====================

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
		
		DELETE BalancePendingCredit WHERE CustID = @CustID
			IF @@ERROR > 0
			BEGIN
				SELECT 
					@ErrCode = 5209, 
					@ErrMsg = 'Failed to clear balance of customer [CustId = ' + COALESCE(CAST(@CustId AS VARCHAR(10)), SPACE(1)) + ']'						 
				RETURN
			END	

		DELETE BalancePendingDebit WHERE CustID = @CustID
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
