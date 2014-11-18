USE [ProdDB]
GO
/****** Object:  StoredProcedure [dbo].[Task_DailySummary_ProdDB_Delete]    Script Date: 7/14/2014 2:21:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Task_DailySummary_ProdDB_Delete]
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
	
	delete from odds_ex
	where oddsid_ex in (select oddsid from odds where matchid in (select matchid from match where eventdate=@winlostdate))  

	delete from odds
	where matchid in (select matchid from match where eventdate=@winlostdate)

	--delete from BingoBall
	--where MatchID in (SELECT MatchID from Match where eventdate = @winlostdate)

	delete from match 
	where eventdate=@winlostdate

	delete from outright_ex
	where orid_ex in (select orid from outright where eventdate = @winlostdate AND oddsstatus = 'Completed')

	delete from outright
	where eventdate = @winlostdate AND oddsstatus = 'Completed'

	select orid 
	into #ManualSettleOutright
	from outright_ex oe with (nolock) join outright o with (nolock) on o.orid=oe.orid_ex
	Where DisabledAutoSettle=1 and oddsstatus_ex='Completed' and eventdate = @winlostdate
			AND o.oddsstatus <> 'Completed'

	delete from outright_ex
	where orid_ex in (select orid from #ManualSettleOutright)

	delete from outright
	where orid in (select orid from #ManualSettleOutright)


END
 