ALTER PROCEDURE [dbo].[Mem_API_GetCustBalance]  	
	@custid int,	
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(2000) = '' OUTPUT,				
	@osbalance money = 0 OUTPUT,
	@balance money = 0 OUTPUT
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

if NOT EXISTS(
		Select 1
		from SVRCUST.CustDB.dbo.custinfo as ci with (NOLOCK) 
		where ci.custid = @custid)
BEGIN
	Select @ErrMsg = 'Invalid Cust ID.', @ErrCode = 101
	return
END

SELECT  
	@Balance = ISNULL(SUM(winlost-actual_stake+playercomm),0),
	@osbalance = ISNULL(SUM(case when bettype < 19000  and ruben=0 then actual_stake else 0 end),0) 
FROM bettrans WITH (NOLOCK) 
WHERE custid = @custid 

