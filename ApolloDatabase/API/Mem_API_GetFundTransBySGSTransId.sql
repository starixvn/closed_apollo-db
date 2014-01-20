ALTER PROCEDURE [dbo].[Mem_API_GetFundTransBySGSTransId]
	@SGS_trans_id bigint,	
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(2000) = '' OUTPUT,	
	@trans_id bigint OUTPUT,						
	@trans_date datetime OUTPUT,
	@amount money = 0 OUTPUT,		
	@beforebalance money = 0 OUTPUT,
	@balance money = 0 OUTPUT	,
	@osbalance money = 0 OUTPUT,
	@status tinyint = 1 OUTPUT
AS
/*
Creator : Dan
Date : 2013-08-27
Task : get fund in/put records by SGS transID
DB: DBTXN/TransDB
History:

Param's Explanation:
• @transid: IBC transaction id
• @SGS_transid: Transaction Id at SGS
• @amount: amount to transfer 
	>0: transfer in
	=0: rejected (fail); 
	<0: transfer out
• @ErrCode:
	= 0: Transaction recorded successfully.
	> 0: Specific Error.
• @ErrMsg: Error description.
• @beforebalance: The amount of the player before transfer
• @balance money: The amount of the player after transfer
• @osbalance:Player outstanding balance amount	
• @status: 1 – Success ; 2 – Failed
*/

SELECT @trans_id = transid 
FROM bettrans WITH (NOLOCK)
WHERE bettype in (22001,22002) AND betid=@SGS_trans_id

if @@ROWCOUNT=0
BEGIN
	SELECT @ErrMsg = 'Invalid SGS trans id.', @ErrCode = 100
	RETURN
END

EXEC [dbo].[Mem_API_GetFundTrans]
	@trans_id = @trans_id,	
	@ErrCode  = @ErrCode OUTPUT,
	@ErrMsg = @ErrMsg OUTPUT,
	@SGS_trans_id = @SGS_trans_id OUTPUT,					
	@trans_date = @trans_date OUTPUT,
	@amount = @amount OUTPUT,		
	@beforebalance = @beforebalance OUTPUT,
	@balance = @balance OUTPUT	,
	@osbalance = @osbalance OUTPUT,
	@status = @status OUTPUT


GO
GRANT EXECUTE ON [dbo].[Mem_API_GetFundTransBySGSTransId] TO [apollo_srv]

