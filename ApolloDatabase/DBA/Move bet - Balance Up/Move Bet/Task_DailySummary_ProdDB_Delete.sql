 
/****** Object:  StoredProcedure [dbo].[Task_DailySummary_DB02_Delete]    Script Date: 05/07/2013 02:38:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Task_DailySummary_ProdDB_Delete]
	@winlostdate datetime
AS

/*
Created: 20130515@Sophia
Task :	call by TransDB : Task_DailySummary
		delete after move to [14] table
DB: SVRPRO.ProdDB
Original:  IBC.Task_DailySummary_DB02_Delete
Revisions:
	 

*/
BEGIN
SET NOCOUNT ON
	
	
	delete from odds
	where matchid in (select matchid from match where eventdate=@winlostdate)

	--delete from BingoBall
	--where MatchID in (SELECT MatchID from Match where eventdate = @winlostdate)

	delete from match 
	where eventdate=@winlostdate

	delete from outright
	where eventdate = @winlostdate AND oddsstatus = 'Completed'


END
 