ALTER PROCEDURE [dbo].[Mem_API_GetFundTrans]
	@trans_id bigint,	
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(2000) = '' OUTPUT,
	@SGS_trans_id bigint OUTPUT,					
	@trans_date datetime OUTPUT,
	@amount money = 0 OUTPUT,		
	@beforebalance money = 0 OUTPUT,
	@balance money = 0 OUTPUT	,
	@osbalance money = 0 OUTPUT,
	@status tinyint = 1 OUTPUT
AS
/*
Creator : Dan
Date : 2013-04-24
Task : get fund in/put records
DB: DBTXN/TransDB
History:

Param's Explanation:
• @transid: IBC transaction id
• @amount: amount to transfer 
	>0: transfer in
	=0: rejected (fail); 
	<0: transfer out
• @ErrCode:
	= 0: Transaction recorded successfully.
	> 0: Specific Error.
• @ErrMsg: Error description.
• @SGS_transid: Transaction Id at SGS
• @beforebalance: The amount of the player before transfer
• @balance money: The amount of the player after transfer
• @osbalance:Player outstanding balance amount	
• @status: 1 – Success ; 2 – Failed
*/
declare @custid int, @location tinyint, @bettype smallint, @currencyid tinyint

Select @trans_date = transdate ,
	@SGS_trans_id= betid,	
	@amount =  CASE WHEN STATUSID= 101 THEN Actual_Stake ELSE WinLost - Actual_Stake END,
	@custid = custid,
	@bettype= bettype,
	@beforebalance = balance,
	@balance = balance + (WinLost - Actual_Stake),
	@osbalance = TWinLost,
	@status=case when statusid=101 then 2 else 1 end
from BetTrans as b with (NOLOCK) 
where transid = @trans_id

if @@ROWCOUNT=0
BEGIN			
	-- try to find transfer_bk in archive DB
	Select @trans_date = transdate ,
		@SGS_trans_id= RefTransId,	
		@amount =  CASE WHEN statusid= 101 THEN Debit ELSE Credit - Debit END,
		@custid = custid,		
		@beforebalance = balance,
		@balance = balance + (Credit - Debit),
		@osbalance = TotalRunningStake,
		@status=case when statusid=101 then 2 else 1 end
	from SVRARC.ArchiveDB.dbo.transfer_bk as b with (NOLOCK) 
	where transid = @trans_id

	if @@ROWCOUNT=0
	BEGIN
		Select @ErrMsg = 'Invalid trans id.', @ErrCode = 101
		return
	END			
END
ELSE
BEGIN
	IF @bettype NOT IN (22001,22002) 
	BEGIN
		Select @ErrMsg = 'Invalid trans id.', @ErrCode = 103
		return
	END	
END

GO
GRANT EXECUTE ON [dbo].[Mem_API_GetFundTrans] TO [apollo_srv]



