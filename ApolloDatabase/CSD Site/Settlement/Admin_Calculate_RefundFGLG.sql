ALTER PROCEDURE [dbo].[Admin_Calculate_RefundFGLG]
	@matchid	int,
	@action varchar(10) = 'CAL',
	@LGOnly		bit,
	@matchdate	datetime
AS
/*	Created by: Dan
	Date: 2013-03-08
	Task: Refund HT 
	DB: SVRTXN/TransDB

	Revisions: 
		- 20140515@Dan: Add 1H FGLG bettypes (127) 
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @bettype int

	SELECT @bettype = CASE WHEN @action = 'CAL-HT' then 127
							when @action = 'CAL-FT' then 14
							ELSE 0

						end
	WHILE 1=1
	BEGIN
		UPDATE TOP (10000) dbo.bettrans with (ROWLOCK, UPDLOCK)
		SET
			status = 'Refund',
			statusID = 103,
			winlost=actual_stake,		
			playercomm=0,		
			ruben = 1,
			TWinLost=0,TComm=0 
		where
			matchid=@matchid
			--AND [status] not in ('Void', 'Reject')
			AND statusID not in (103,101,102)			
			AND ((@bettype = 0 AND bettype IN (14,127)) 
					OR (bettype = @bettype))
			--AND ruben = 1 
			AND right(betteam, 1) = case when @LGOnly = 1 then '2' else right(betteam, 1) end
    
		IF @@ROWCOUNT < 10000 BREAK
	END

	WHILE 1=1
	BEGIN
		UPDATE TOP (10000) ba with (ROWLOCK, UPDLOCK)
		SET
			status = 'Refund',
			statusID = 103,
			awinlost=0,
			acomm=0
		FROM  BetTrans B WITH (NOLOCK) JOIN BetTrans_Agent  ba ON 
			b.TransId=ba.TransId and ba.matchid=b.matchid AND ba.bettype=b.bettype 
		where
			ba.matchid=@matchid
			--AND [status] not in ('Void', 'Reject')
			AND ba.statusID not in (103,101,102)			
			AND ((@bettype = 0 AND ba.bettype IN (14,127)) 
					OR (ba.bettype = @bettype))
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
			((@bettype = 0 and bettype in (14, 127)) OR (bettype = @bettype))
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
			((@bettype = 0 and bettype in (14, 127)) OR (bettype = @bettype))
			AND matchid=@matchid
			AND statusID not in (103,101,102)
			AND right(betteam, 1) = case when @LGOnly = 1 then '2' else right(betteam, 1) end		

	END

-------------End: Refund FGLG for bettransm-------------
END


GO
GRANT EXECUTE ON [dbo].[Admin_Calculate_RefundFGLG] TO [aplweb]
