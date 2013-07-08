ALTER PROCEDURE [dbo].[ExecRep_APL_01]
	@Winlostdate Datetime
AS
/*
Created by:Sophia
Date: 20130831
Task: Called by Task_DailySummary_DB02_Delete
	  Delete Event by WinlostDate		
DB: DB02.BODB02 / SVRPRO.ProdDB
Revisions:
    
 */ 
SET NOCOUNT ON 
IF @@SERVERNAME = 'DBCLS1\SDBPROD' --- ProdDB of Apollo
	RETURN 

 
delete from odds
where matchid in (select matchid from match where eventdate=@winlostdate)

delete from BingoBall
where MatchID in (SELECT MatchID from Match where eventdate = @winlostdate)

delete from Dot_Admin_Assignment_Operator 
where MatchID in (SELECT MatchID from Match where eventdate = @winlostdate)

IF DATEPART(weekday, @winlostdate) = 2
BEGIN
	delete from Dot_Admin_Assignment_Operator 
	where MatchID not in (SELECT MatchID from Match nolock)
END

delete from SS_GameState
where matchid in (select matchid from match where eventdate=@winlostdate)
	
delete from match 
where eventdate=@winlostdate

delete from outright
where eventdate = @winlostdate AND oddsstatus = 'Completed'
	
delete from VSOutright
where eventdate = @winlostdate AND EventStatus = 'Completed'

 

