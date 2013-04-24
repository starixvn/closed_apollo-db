ALTER PROCEDURE [dbo].[Mem_API_GetCustBalance]  	
	@custid int,	
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,				
	@osbalance money = 0 OUTPUT,
	@balance money = 0 OUTPUT,
	@currency varchar(5) = 0 OUTPUT
AS
/*
Creator : Dan
Date : 2013-04-23
Task : get customer balance
DB: DBTXN/TransDB
History:

Param's Explanation:
• @custid:Player Id
• @osbalance:Player outstanding balance amount	
• @balance:Player IBC balance amount
• @ErrCode:
	= 0: Transaction recorded successfully.
	> 0: Specific Error.
• @ErrMsg: Error description.
*/

Select @currency = e.currency
from SVRCUST.CustDB.dbo.custinfo as ci with (NOLOCK) 
LEFT JOIN exchange as e with (NOLOCK) on ci.currency = e.exchangeid
where ci.custid = @custid

if @@ROWCOUNT=0
BEGIN
	Select @ErrMsg = 'Invalid Cust ID.', @ErrCode = 101
	return
END

DECLARE @Credit MONEY, @Debit MONEY
SELECT @Credit = SUM(Balance)
FROM BalanceCredit credit WITH (NOLOCK) 
WHERE custid=@custid
	
SELECT @Debit = SUM(Balance)
FROM BalanceDebit debit WITH (NOLOCK) 
WHERE custid=@custid	
	
SET @Balance = ISNULL(@Credit,0) -  ISNULL(@Debit,0)

SELECT @osbalance = ISNULL(SUM(winlost-actual_stake+playercomm),0) 
FROM bettrans WITH (NOLOCK) 
WHERE custid = @custid and Ruben=0

