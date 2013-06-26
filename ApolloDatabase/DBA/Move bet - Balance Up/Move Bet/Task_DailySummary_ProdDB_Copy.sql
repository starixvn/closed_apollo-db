/****** Object:  StoredProcedure [dbo].[Task_DailySummary_DB02_Copy]    Script Date: 05/07/2013 02:37:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_DailySummary_ProdDB_Copy]
	@winlostdate datetime
AS
/*
Created: 20130515@Sophia
Task :	Call by TransDB : Task_DailySummary
		Copy match/odds/outright into [14] table
DB: SVRPRO.ProdDB
Original:  IBC.Task_DailySummary_DB02_Copy
Revisions:
	 

*/
	BEGIN
	SET NOCOUNT ON	
	
	insert into odds14
		(oddsid, matchid, bettype, switch, hdp1, hdp2, odds1a, odds2a, odds1b, odds2b, odds1c, odds2c, odds1e, odds2e, odds1f, odds2f, odds1d, odds2d, 
		odds1hka, odds2hka, odds1hkb, odds2hkb, odds1hkc, odds2hkc, odds1hke, odds2hke, odds1hkf, odds2hkf, odds1hkd, odds2hkd, oddsspreada, oddsspreadb, 
		oddsspreadd, oddsspreade, oddsspreadf, oddsspreadc, autobookie, gapodds1, gapodds2, maxstake1, maxstake2, minstake1, minstake2, diffbalance, 
		maxodds, minodds, oddsstatus, liveindicator, changetime, risk, stakerange, newoffersetup, livehomescore, liveawayscore, com1, comx, com2, 
		cs00, cs01, cs10, cs11, cs02, cs12, cs22, cs21, cs20, cs30, cs31, cs32, cs33, cs23, cs13, cs03, cs43, cs42, cs41, cs40, cs44, cs14, cs24, cs04, cs34, cs50, cs05, 
		comstatus, csstatus, commaxbet, csmaxbet, bal00, bal10, bal11, bal01, bal20, bal21, bal22, bal12, bal02, bal30, bal31, bal32, bal33, bal23, bal13, bal03, 
		bal40, bal41, bal42, bal43, bal44, bal34, bal24, bal14, bal04, bal50, bal05, maxbet, ht, autoreject, allowance, autosuspend, multiple, stakerange2, risk2, 
		allowance2, site2, site3, site4, sporttype, Resourceid, ResultKey, creator)
	select
		oddsid, matchid, bettype, switch, hdp1, hdp2, odds1a, odds2a, odds1b, odds2b, odds1c, odds2c, odds1e, odds2e, odds1f, odds2f, odds1d, odds2d, 
		odds1hka, odds2hka, odds1hkb, odds2hkb, odds1hkc, odds2hkc, odds1hke, odds2hke, odds1hkf, odds2hkf, odds1hkd, odds2hkd, oddsspreada, oddsspreadb, 
		oddsspreadd, oddsspreade, oddsspreadf, oddsspreadc, autobookie, gapodds1, gapodds2, maxstake1, maxstake2, minstake1, minstake2, diffbalance, 
		maxodds, minodds, oddsstatus, liveindicator, changetime, risk, stakerange, newoffersetup, livehomescore, liveawayscore, com1, comx, com2, 
		cs00, cs01, cs10, cs11, cs02, cs12, cs22, cs21, cs20, cs30, cs31, cs32, cs33, cs23, cs13, cs03, cs43, cs42, cs41, cs40, cs44, cs14, cs24, cs04, cs34, cs50, cs05, 
		comstatus, csstatus, commaxbet, csmaxbet, bal00, bal10, bal11, bal01, bal20, bal21, bal22, bal12, bal02, bal30, bal31, bal32, bal33, bal23, bal13, bal03, 
		bal40, bal41, bal42, bal43, bal44, bal34, bal24, bal14, bal04, bal50, bal05, maxbet, ht, autoreject, allowance, autosuspend, multiple, stakerange2, risk2, 
		allowance2, site2, site3, site4, sporttype, Resourceid, ResultKey, creator
	from odds
	where matchid in (select matchid from match where eventdate=@winlostdate)  

	insert into match14 
		(matchid, leagueid, homeid, awayid, eventdate, eventstatus, betstatus, livehomescore, liveawayscore, finalhomescore, finalawayscore, creator, 
		matchcode, kickofftime, closedtime, showtime, hthomescore, htawayscore, ruben, multiple, yenbet, exrisk, sporttype, homeid2, awayid2, 
		DisplayMode, LeaguePatternID, HomeDisplayPatternID, AwayDisplayPatternID, IsNeutral, GoalRecord, settletime)
	select
		matchid, leagueid, homeid, awayid, eventdate, eventstatus, betstatus, livehomescore, liveawayscore, finalhomescore, finalawayscore, creator, 
		matchcode, kickofftime, closedtime, showtime, hthomescore, htawayscore, ruben, multiple, yenbet, exrisk, sporttype, homeid2, awayid2, 
		DisplayMode, LeaguePatternID, HomeDisplayPatternID, AwayDisplayPatternID, IsNeutral, GoalRecord, settletime
	from match
	where eventdate=@winlostdate 


	insert into outright14
		(orid, leagueid, teamid, eventdate, kickofftime, oddsstatus, odds, maxbet, gapodds, matchcode, groupmatch, status, creator, bal, risk, DisplayMode, 
		 PlaceOdds, Placing, IsFavor, IsSCR, ProgramID, FOddsStatus, SCRTime, LeaguePatternID, TeamPatternID, ProgramDate, IsDeadheat, StdDelBetCheck )
	select
		orid, leagueid, teamid, eventdate, kickofftime, oddsstatus, odds, maxbet, gapodds, matchcode, groupmatch, status, creator, bal, risk, DisplayMode, 
		PlaceOdds, Placing, IsFavor, IsSCR, ProgramID, FOddsStatus, SCRTime, LeaguePatternID, TeamPatternID, ProgramDate, IsDeadheat, StdDelBetCheck 
	from outright
	where eventdate = @winlostdate AND oddsstatus = 'Completed'
	
END



