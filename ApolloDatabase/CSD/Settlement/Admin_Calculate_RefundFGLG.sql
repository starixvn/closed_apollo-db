CREATE PROCEDURE [dbo].[Admin_Calculate_RefundFGLG]
	@matchid	int,
	@LGOnly		bit,
	@matchdate	datetime
AS
/*	Created by: Dan
	Date: 2013-03-08
	Task: Refund HT 
	DB: SVRTXN/TransDB

	Revisions: 
*/
SET NOCOUNT ON

WHILE 1=1
BEGIN
	UPDATE TOP (10000) dbo.bettrans with (ROWLOCK, UPDLOCK)
	SET
		status = 'Refund',
		statusID = 103,
		winlost=actual_stake,		
		playercomm=0,		
		ruben = 1 
	where
		matchid=@matchid
		--AND [status] not in ('Void', 'Reject')
		AND statusID not in (103,101,102)
		AND bettype = 14
		--AND ruben = 1 
		AND right(betteam, 1) = case when @LGOnly = 1 then '2' else right(betteam, 1) end
    
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
	FROM  BetTrans B WITH (NOLOCK) JOIN BetTrans_Agent ON 
		b.TransId=BetTrans_Agent.TransId and BetTrans_Agent.matchid=b.matchid AND BetTrans_Agent.bettype=b.bettype 
	where
		b.matchid=@matchid
		--AND [status] not in ('Void', 'Reject')
		AND b.statusID not in (103,101,102)
		AND b.bettype = 14
		--AND ruben = 1 
		AND right(b.betteam, 1) = case when @LGOnly = 1 then '2' else right(b.betteam, 1) end
    
    IF @@ROWCOUNT < 10000 BREAK
END

-------------Start: Refund FGLG for bettransm-------------

--WHILE 1=1
BEGIN
    --UPDATE TOP (10000) dbo.bettransm with (ROWLOCK, UPDLOCK)
	UPDATE dbo.bettransm with (ROWLOCK, UPDLOCK)
    SET 
		winlostdate=@matchdate,
		[status]='Refund',
		statusID = 103,
		statuswinlost=0,	
		ruben=1 
	WHERE 
		bettype = 14 
		AND matchid=@matchid
		AND statusID not in (103,101,102)
		AND right(betteam, 1) = case when @LGOnly = 1 then '2' else right(betteam, 1) end		
	
--	IF @@ROWCOUNT < 10000 BREAK

    UPDATE dbo.betParlayDetail with (ROWLOCK, UPDLOCK)
    SET 
		winlostdate=@matchdate,
		statusID = 103,
		statuswinlost=0
	WHERE 
		bettype = 14 
		AND matchid=@matchid
		AND statusID not in (103,101,102)
		AND right(betteam, 1) = case when @LGOnly = 1 then '2' else right(betteam, 1) end		

END
-------------End: Refund FGLG for bettransm-------------



GO
GRANT EXECUTE ON [dbo].[Admin_Calculate_RefundFGLG] TO [aplweb]
