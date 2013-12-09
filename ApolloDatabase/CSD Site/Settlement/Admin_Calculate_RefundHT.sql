ALTER PROCEDURE [dbo].[Admin_Calculate_RefundHT]
	@matchid int	
AS
/*	Created by: Dan
	Date: 2013-03-21
	Task: Refund HT 
	DB: SVRTXN/TransDB
	Revisions:
			
	Param's Explanation:
				
*/
SET NOCOUNT ON

	WHILE 1=1
	BEGIN
		UPDATE TOP (10000) dbo.bettrans with (ROWLOCK, UPDLOCK)
		SET
			[status] = 'Refund',
			statusID = 103,
			ruben = 1,
			winlost=actual_stake,			
			playercomm=0,
			TWinLost=0,TComm=0			
		WHERE
			matchid=@matchid
			--AND [status] not in (N'Void', N'Reject')
			AND statusID not in (103,101,102)
			AND bettype IN (7, 8, 15, 12,21,30, 125) 
			
		IF @@ROWCOUNT < 10000 BREAK
	END

	WHILE 1=1
	BEGIN
		UPDATE TOP (10000) dbo.BetTrans_Agent with (ROWLOCK, UPDLOCK)
		SET
			[status] = 'Refund',
			statusID = 103,						
			awinlost=0,						
			acomm=0			
		WHERE
			matchid=@matchid
			--AND [status] not in (N'Void', N'Reject')
			AND statusID not in (103,101,102)
			AND bettype IN (7, 8, 15, 12,21,30, 125) 
		
		IF @@ROWCOUNT < 10000 BREAK	
	END

GO
GRANT EXECUTE ON [dbo].[Admin_Calculate_RefundHT] TO [aplweb]
