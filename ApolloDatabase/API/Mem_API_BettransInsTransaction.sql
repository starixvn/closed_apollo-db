ALTER PROCEDURE [dbo].[Mem_API_BettransInsTransaction]  	
	@custid int,	
	@SGS_transid bigint, -- SGS transid
	@type tinyint,
	@amount money,	
	@ip	nvarchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(2000) = '' OUTPUT,		
	@transid bigint = 0 OUTPUT,		
	@beforebalance money = 0 OUTPUT,
	@balance money = 0 OUTPUT,	
	@osbalance money = 0 OUTPUT
AS
/*
Creator : Dan
Date : 2013-04-23
Task : record transfer in/out
DB: DBTXN/TransDB
History:
	
Param's Explanation:
• @custid: player
• @SGS_transid: Transaction Id at SGS
• @amount: amount to transfer (>0)		
• @type:
	1 – Fund In (SGS to IBC)
	2 – Fund Out (IBC to SGS)
	3 – Fund Out All (SB To SGS, except the amount in os_balance)
• @ErrCode:
	= 0: Transaction recorded successfully.
	> 0: Specific Error.
	
• @ErrMsg: Error description.
• @transid: IBC transaction id
• @beforebalance: The balance of the player before transfer
• @balance money: The balance of the player after transfer
• @osbalance:Player outstanding balance amount	
*/
SET NOCOUNT ON

declare @username nvarchar(50),
	@currencyid tinyint,
	@currencyName varchar(5),
	@transdate datetime,
	@transdesc nvarchar(300),	
	@actualrate float,
	@winlost money,
	@actual_stake money,	
	@agentID int,	
	@bettype smallint,
	@RefNo bigint, 
	@DDEP smallint,
	@DWIT smallint		

Select @ErrCode = 0,
		@ErrMsg = '',
		@RefNo = isnull(@RefNo,0),
		@amount = @amount,		
		@DDEP = 22001,
		@DWIT = 22002

if ISNULL(@type,0) not in (1,2,3)
BEGIN
	Select @ErrMsg = 'Type is invalid', @ErrCode = 101	
	return		
END

select @bettype = 
	case @type 
		when 1 then 22001 
		when 2 then 22002				
		when 3 then 22002 
	end


if EXISTS(SELECT transid 
	FROM bettrans WITH (NOLOCK)
	WHERE bettype in (22001,22002) AND betid=@SGS_transid
)
BEGIN
	SELECT @ErrMsg = 'Duplicated SGS trans id.', @ErrCode = 100
	RETURN
END

IF @type=3
	SELECT  @amount = ISNULL(SUM(winlost-actual_stake+playercomm),0),
		@osbalance = ISNULL(SUM(case when bettype <= 19000  and ruben=0 then actual_stake else 0 end),0) 
	FROM bettrans WITH (NOLOCK) 
	WHERE custid = @custid 
ELSE
	SELECT  @osbalance = ISNULL(SUM(case when bettype <= 19000  and ruben=0 then actual_stake else 0 end),0) 
	FROM bettrans WITH (NOLOCK) 
	WHERE custid = @custid 

if @amount <= 0 AND @type<>3
BEGIN
	Select @ErrMsg = 'Amount is invalid.', @ErrCode = 102	
	return		
END

Select @username = username, @currencyid = ci.currency, @currencyName = e.currency, @actualrate = e.actualrate	
from SVRCUST.CustDB.dbo.custinfo as ci with (NOLOCK) 
LEFT JOIN exchange as e with (NOLOCK) on ci.currency = e.exchangeid
where ci.custid = @custid

if @@ROWCOUNT=0
BEGIN
	Select @ErrMsg = 'Invalid Cust ID.', @ErrCode = 103
	return
END

select @transdesc = @username + ' - ' +
					case @bettype when @DDEP then 'Transfer In'
									when @DWIT then 'Transfer Out'									
									else '' end					
select 
	@winlost = case when @bettype = @DDEP then @amount else 0 end,
	@actual_stake = case @bettype when @DWIT then abs(@amount) else 0 end

/*
if @winlost < 0 --then swap the winlost and actual_stake
BEGIN	
	select @actual_stake = -@winlost,  @winlost = 0	
END
*/

----------------------------------
--Check enough balance for withdrawing
select @beforebalance = sum(winlost-actual_stake+playercomm) 
from bettrans with (NOLOCK) 
where custid = @custid

select @beforebalance = isnull(@beforebalance, 0)
select @balance = @beforebalance+@winlost-@actual_stake
if (@bettype=@DWIT) 
BEGIN
	if @balance<0
	BEGIN
		Select @ErrMsg = 'You do not have enough money to transfer out.'
			, @ErrCode = 104
		return		
	END
END

------------------Insert trans into DB---------------------------------------------------------------
if @RefNo = 0
BEGIN
	EXEC dbo.Acc_SelRefNo @RefNo = @RefNo OUTPUT
	select @RefNo = @RefNo + 100000000000
END

----------------------------------
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

declare @LogData varchar(300)

select @transdate = current_timestamp

BEGIN TRY
	INSERT INTO bettrans 
		(custid, username, refno, transdate, matchid, bettype, transdesc,winlost, actual_stake, winlostdate, 
		 creator,currency,actualrate, currencyName, ruben, status, statusID,ip, betid, balance, TWinLost)
	VALUES 
		(@CustID, @username, @RefNo, @transdate, 0, @bettype, @transdesc,@winlost, @actual_stake, convert(nvarchar(10), current_timestamp, 120), 
		 @CustID, @Currencyid,@actualrate, @currencyName, 1, 'Completed', 131,@ip, @SGS_transid,@beforebalance, @osbalance)

	SELECT @TransID = SCOPE_IDENTITY()

END TRY
BEGIN CATCH
	--Manually rollback
	DELETE FROM bettrans 
	where custid = @custid 
		and refno = @RefNo 
		and matchid = 0
		and bettype = @bettype
	
	SELECT @ErrMsg = 'Insert transaction failed (' + CAST (ERROR_MESSAGE() AS nvarchar(1000)) + ' )'
			, @ErrCode = 105	

	--Rollback BalanceDebit 
	IF @Cust_balance < 0 
	BEGIN 
		EXEC Dot_BalanceUpdCredit @custid = @CustID, @Balance = @Cust_Balance_ABS
	END 

	-- reset param
	set @balance = @beforebalance

	--keep track fail record with rejected status
	INSERT INTO bettrans 
	(custid, username, refno, transdate, matchid, bettype, transdesc,winlost, actual_stake, winlostdate, 
	 creator,currency,actualrate, currencyName, ruben, status, statusID,ip, betid, balance, TWinLost)
	VALUES 
		(@CustID, @username, @RefNo, @transdate, 0, @bettype, @transdesc, @amount, @amount, convert(nvarchar(10), current_timestamp, 120), 
		 @CustID, @Currencyid,@actualrate, @currencyName, 1, 'Reject', 101,@ip, @SGS_transid, @beforebalance, @osbalance)

	SELECT @TransID = SCOPE_IDENTITY()

	--write log
	Select @LogData = 
			'Insert trans = ' + convert(varchar(30), @TransID) + ', custid = ' + convert(varchar(20), @custid) + ', bettype = ' + convert(varchar(20), @bettype) + ', amount = ' + convert(varchar(20), @amount) + ', type = ' + convert(varchar(10), @type) +
			  '.Error: ' + CAST (ERROR_MESSAGE() AS nvarchar(200))
	EXEC dbo.WriteLog_UserLog_T @UserID = @custid, @Doing = @LogData

	RETURN
END CATCH

IF @Cust_Balance > 0  --Update BalanceCredit 
BEGIN
	EXEC Dot_BalanceUpdCredit @custid = @CustID, @Balance = @Cust_Balance
END 

----ADD DUMMY TRANSACTION (no need now)
---------------------------------------------------------------------------------------------------

Select @LogData = 
			'Insert trans = ' + convert(varchar(30), @TransID) + ', custid = ' + convert(varchar(20), @custid) + ', bettype = ' + convert(varchar(20), @bettype) + ', amount = ' + convert(varchar(20), @amount) + ', type = ' + convert(varchar(10), @type)

EXEC dbo.WriteLog_UserLog_T @UserID = @custid, @Doing = @LogData

GO
--GRANT EXECUTE ON [dbo].[Mem_API_BettransInsTransaction] TO [Dot_Member] AS [dbo]