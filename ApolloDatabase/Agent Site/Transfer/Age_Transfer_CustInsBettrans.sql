ALTER PROCEDURE [dbo].[Age_Transfer_CustInsBettrans]  	
	@LoggedId	INT,
	@Custid		INT,	
	@Bettype	SMALLINT,
	@RefNo		BIGINT,
	@Amount		MONEY,	
	@IP			VARCHAR(40) ='',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(2000) = '' OUTPUT
AS
/*
Creator : Sophia
Date : 20141117
Task : Record transfer in/out tracsaction of Member into bettrans table (Called by Age_Transfer_AgentToCust)
DB: DBTXN/TransDB
Original: Mem_API_BettransInsTransaction
Revisions:
	
Param's Explanation:
• @amount: amount to transfer (>0)		
• @Bettype	= 22001: Deposit
			= 22002: Draw	
• @ErrCode:
	= 0: Transaction recorded successfully.
	> 0: SpecIFic Error.	
• @ErrMsg: Error description.
 
*/
SET NOCOUNT ON

DECLARE  @username NVARCHAR(50),
	@currencyid TINYINT,
	@currencyName VARCHAR(5),
	@transdate DATETIME,
	@transdesc NVARCHAR(300),	
	@actualrate FLOAT,
	@winlost MONEY,
	@actual_stake MONEY,
	@osbalance MONEY,
	@BeforeBalance MONEY,
	@TransID BIGINT
 
 	

IF ISNULL(@Bettype,0) not in (22001,22002)
BEGIN
	SELECT	@ErrMsg = 'Trans type is invalid.', 
			@ErrCode = 8010	
	RETURN		
END


IF EXISTS ( SELECT  transid 
			FROM	dbo.bettrans WITH (NOLOCK)
			WHERE   bettype in (22001,22002) AND RefNo = @RefNo)			
BEGIN
	SELECT	@ErrMsg = 'Duplicated RefNo.', 
			@ErrCode = 8011
	RETURN
END


SELECT  @osbalance = ISNULL(SUM(CASE WHEN bettype <= 19000 and ruben=0 THEN actual_stake ELSE 0 END),0) 
FROM	dbo.bettrans WITH (NOLOCK) 
WHERE	custid = @custid 

IF @amount <= 0  
BEGIN
	SELECT @ErrMsg = 'Invalid amount.', @ErrCode = 8003	
	RETURN		
END

SELECT	@username = username, @currencyid = ci.currency, @currencyName = e.currency, @actualrate = e.actualrate	
FROM	dbo.custinfo AS ci WITH (NOLOCK) 
LEFT JOIN dbo.exchange as e WITH (NOLOCK) on ci.currency = e.exchangeid
WHERE ci.custid = @custid

IF @@ROWCOUNT=0
BEGIN
	SELECT @ErrMsg = 'Invalid Customer ID.', @ErrCode = 5220
	RETURN
END

SELECT @transdesc =  CASE @bettype WHEN 22001 THEN 'Deposit to '
								  WHEN 22002 THEN 'Draw from '									
								  ELSE '' END + @Username				
SELECT 
	@winlost = CASE WHEN @bettype = 22001 THEN @amount ELSE 0 END,
	@actual_stake = CASE @bettype WHEN 22002 THEN @amount ELSE 0 END

----------------------------------
--Check enough balance for Withdraw

SELECT	@BeforeBalance = SUM(ISNULL(winlost,0) - ISNULL(actual_stake,0) + ISNULL(playercomm,0)) 
FROM	dbo.bettrans WITH (NOLOCK) 
WHERE	custid = @custid

SELECT @BeforeBalance = ISNULL(@BeforeBalance,0)


IF (@bettype= 22002)  --- Draw
BEGIN
	IF @Amount NOT BETWEEN 0 AND @BeforeBalance
	BEGIN
		SELECT @ErrMsg = 'Sport Credit of downline '+ @Username +' is not enough to draw.'
			, @ErrCode = 8002
		RETURN		
	END
END

------------------Insert trans into DB---------------------------------------------------------------

---- Checking the balance of customer before updating the amount on Credit or Debit table 

DECLARE @Cust_Balance MONEY,
		@Cust_Balance_ABS MONEY

SELECT	@Cust_Balance = @winlost - @actual_stake
SELECT	@Cust_Balance_ABS = abs(@Cust_Balance)		

--Update BalanceDebit 
IF @Cust_Balance < 0 
BEGIN
	EXEC Dot_BalanceUpdDebit @custid = @CustID, @Balance = @Cust_Balance_ABS
END 

DECLARE @LogData VARCHAR(1000)
SELECT @transdate = current_timestamp


BEGIN TRY
	INSERT INTO bettrans 
		(custid, username, refno, transdate, matchid, bettype, transdesc,winlost, actual_stake, winlostdate, 
		 creator,currency,actualrate, currencyName, ruben, status, statusID,ip, betid, balance, TWinLost)
	VALUES 
		(@CustID, @username, @RefNo , @transdate, 0, @bettype, @transdesc,@winlost, @actual_stake, CONVERT(NVARCHAR(10), current_timestamp, 120), 
		 @LoggedId, @Currencyid,@actualrate, @currencyName, 1, 'Completed', 131,@ip, 0, @beforebalance, @osbalance)

	SELECT @TransID = SCOPE_IDENTITY()

END TRY
BEGIN CATCH
	--Manually rollback
	DELETE FROM bettrans 
	WHERE custid = @custid 
		and refno = @RefNo 
		and matchid = 0
		and bettype = @bettype
	
	SELECT @ErrMsg = 'Insert transaction into bettrans failed (' + CAST (ERROR_MESSAGE() AS NVARCHAR(1000)) + ' )'
		 , @ErrCode = 8012	

	--Rollback BalanceDebit 
	IF @Cust_balance < 0 
	BEGIN 
		EXEC Dot_BalanceUpdCredit @custid = @CustID, @Balance = @Cust_Balance_ABS
	END 

	---- reset param
	--SET @balance = @beforebalance

	--keep track fail record WITH rejected status
	INSERT INTO bettrans 
	(custid, username, refno, transdate, matchid, bettype, transdesc,winlost, actual_stake, winlostdate, 
	 creator,currency,actualrate, currencyName, ruben, status, statusID,ip, betid, balance, TWinLost)
	VALUES 
		(@CustID, @username, @RefNo, @transdate, 0, @bettype, @transdesc, @amount, @amount, CONVERT(NVARCHAR(10), current_timestamp, 120), 
		 @LoggedId, @Currencyid,@actualrate, @currencyName, 1, 'Reject', 101,@ip, 0, @beforebalance, @osbalance)

	SELECT @TransID = SCOPE_IDENTITY()

	--write log
	SELECT @LogData = 
			'Insert trans = ' + CONVERT(VARCHAR(30), @TransID) + ', custid = ' + CONVERT(VARCHAR(20), @custid) + ', bettype = ' + CONVERT(VARCHAR(20), @bettype) + ', amount = ' + CONVERT(VARCHAR(20), @amount) + ', transdesc = '+  @transdesc +
			  '.Error: ' + CAST (ERROR_MESSAGE() AS NVARCHAR(200))
	EXEC dbo.WriteLog_UserLog_T @UserID = @custid, @Doing = @LogData

	RETURN
END CATCH

IF @Cust_Balance > 0  --Update BalanceCredit 
BEGIN
	EXEC Dot_BalanceUpdCredit @custid = @CustID, @Balance = @Cust_Balance
END 

----ADD DUMMY TRANSACTION (no need now)
---------------------------------------------------------------------------------------------------

SELECT @LogData = 
			'Insert trans = ' + CONVERT(VARCHAR(30), @TransID) + ', custid = ' + CONVERT(VARCHAR(20), @custid) + ', bettype = ' + CONVERT(VARCHAR(20), @bettype) + ', amount = ' + CONVERT(VARCHAR(20), @amount) + ', transdesc = '+  @transdesc

EXEC dbo.WriteLog_UserLog_T @UserID = @custid, @Doing = @LogData

GO
GRANT EXECUTE ON [dbo].[Age_Transfer_CustInsBettrans] TO [aplweb]