ALTER PROCEDURE [dbo].[Task_EventMovement]	
AS

/*
	Created by: Sophia
	Date: 2013-05-31
	Task: update winlostdate of ticket = eventdate of event
	DB: SVRTXN.TransDB
	Original: 

	Revisions:
	 
        
*/

SET NOCOUNT ON


-- update ticket (if any) which WinLostDate is not synced with eventdate 
UPDATE b
SET WinLostDate = o.eventdate
FROM dbo.bettrans b WITH (ROWLOCK,UPDLOCK)
INNER JOIN dbo.outright o  WITH (NOLOCK) ON b.matchid = o.orid
WHERE b.winlostdate <> o.eventdate

UPDATE b
SET WinLostDate = o.eventdate
FROM dbo.BetTrans_Agent b WITH (ROWLOCK,UPDLOCK)
INNER JOIN dbo.outright o  WITH (NOLOCK) ON b.matchid = o.orid
WHERE b.winlostdate <> o.eventdate
-----

UPDATE b
SET winlostdate = m.eventdate
FROM dbo.bettrans b WITH (ROWLOCK,UPDLOCK)
INNER JOIN dbo.match m  WITH (NOLOCK) ON b.matchid = m.matchid
WHERE b.winlostdate <> m.eventdate

UPDATE b
SET winlostdate = m.eventdate
FROM dbo.BetTrans_Agent b WITH (ROWLOCK,UPDLOCK)
INNER JOIN dbo.match m WITH (NOLOCK) ON b.matchid = m.matchid
WHERE b.winlostdate <> m.eventdate

DECLARE @Doing varchar(4000)
SELECT @Doing = '[Task_EventMovement] - ' +  CONVERT(VARCHAR(50),GETDATE())

EXEC dbo.WriteLog_UserLog_T @UserID = 25520, @Doing = @Doing 
 


