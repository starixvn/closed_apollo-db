ALTER PROCEDURE [dbo].[Admin_Calculate_Undo] 
	@matchid int
As
/*
Created By: Dan 
Created Date: 2013-03-14
Task : unsettle a match, called by main SP Acc_Settlement_Undo, uses Rep execution
DB: ApollloTrans/TransDB
Original: DBTRANS.bodb02.Admin_Calculate_Undo

Revisions:
		
Param's Explanation:
		• @matchid: matchid of match to be unsettled
*/
WHILE 1=1
BEGIN
    UPDATE TOP (10000) dbo.bettrans with (ROWLOCK, UPDLOCK)
    SET
	    ruben = 0, status = 'running', statusID = 0,
	    winlost = 0, TWinLost=0,
		playercomm = 0, TComm=0
    WHERE
	    matchid = @matchid AND 
	    --status NOT IN ('running','waiting','void','reject')
	    statusID NOT IN (0,1,102,101)
	    --and bettype not between 1301 and 1334 -- exclude sporting solution product
    
    IF @@ROWCOUNT < 10000 BREAK
END

WHILE 1=1
BEGIN
    UPDATE TOP (10000) dbo.BetTrans_Agent with (ROWLOCK, UPDLOCK)
    SET
	    status = 'running', statusID = 0,
	    awinlost = 0, acomm = 0
    WHERE
	    matchid = @matchid AND 
	    --status NOT IN ('running','waiting','void','reject')
	    statusID NOT IN (0,1,102,101)
	    --and bettype not between 1301 and 1334 -- exclude sporting solution product
    
    IF @@ROWCOUNT < 10000 BREAK
END
