ALTER PROCEDURE [dbo].[Admin_Calculate_RefundAll]
	@matchid			int	
AS
/*	Created by: Dan
	Date: 2013-03-21
	Task: Refund All
	DB: SVRTXN/TransDB
	Revisions:
		- 20140515@Dan: Add 1H FGLG bettypes (127)
*/
SET NOCOUNT ON 

BEGIN
	WHILE 1=1
	BEGIN
	   UPDATE TOP (10000) dbo.bettrans with (ROWLOCK, UPDLOCK)
	   set 
			[status]='Refund',
			statusID = 103,
			winlost=actual_stake,			
			playercomm=0,
			ruben=1,
			statuswinlost=0,
			TWinLost=0,TComm=0
		where
			matchid=@matchid
			--and [status] not in ('Void', 'Reject')
			AND statusID not in (103,101,102)
			AND bettype NOT IN (14, 127)
			and bettype not between 1301 and 1334 -- exclude sporting solution product
		IF @@ROWCOUNT < 10000 BREAK
	END

	WHILE 1=1
	BEGIN
		UPDATE TOP (10000) dbo.BetTrans_Agent with (ROWLOCK, UPDLOCK)
		SET
			status = 'Refund',
			statusID = 103,
			awinlost=0,
			acomm=0		
		where
			matchid=@matchid
			--AND [status] not in ('Void', 'Reject')
			AND statusID not in (103,101,102)
			AND bettype NOT IN (14, 127)	
			and bettype not between 1301 and 1334 -- exclude sporting solution product
    
		IF @@ROWCOUNT < 10000 BREAK
	END
END
GO
GRANT EXECUTE ON [dbo].[Admin_Calculate_RefundAll] TO [aplweb]
