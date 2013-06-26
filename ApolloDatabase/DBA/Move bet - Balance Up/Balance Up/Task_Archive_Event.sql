/****** Object:  StoredProcedure [dbo].[Task_Archive_Event]    Script Date: 05/20/2013 22:55:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Task_Archive_Event    Script Date: 12/29/2010 6:54:02 PM ******/
ALTER PROCEDURE [dbo].[Task_Archive_Event]
	@winlostdate date
AS
/*
Created: 20130603@Sophia
Task : Archive and delete event 
DB: SVRPRO.ProdDB
Original:

Revisions: 
	
Param's Explanation: 

*/

----Archive 
	INSERT INTO SVRARC.ArchiveDB.dbo.odds_bk (
			oddsid, matchid, bettype, switch, hdp1, hdp2, odds1a, odds2a, odds1b, odds2b, odds1c, odds2c, odds1e, odds2e, odds1f, odds2f, odds1d, odds2d, 
			odds1hka, odds2hka, odds1hkb, odds2hkb, odds1hkc, odds2hkc, odds1hke, odds2hke, odds1hkf, odds2hkf, odds1hkd, odds2hkd, oddsspreada, oddsspreadb, 
			oddsspreadd, oddsspreade, oddsspreadf, oddsspreadc, autobookie, gapodds1, gapodds2, maxstake1, maxstake2, minstake1, minstake2, diffbalance, 
			maxodds, minodds, oddsstatus, liveindicator, changetime, risk, stakerange, newoffersetup, livehomescore, liveawayscore, com1, comx, com2, cs00, cs01, cs10, 
			cs11, cs02, cs12, cs22, cs21, cs20, cs30, cs31, cs32, cs33, cs23, cs13, cs03, cs43, cs42, cs41, cs40, cs44, cs14, cs24, cs04, cs34, cs50, cs05, comstatus, csstatus, 
			commaxbet, csmaxbet, bal00, bal10, bal11, bal01, bal20, bal21, bal22, bal12, bal02, bal30, bal31, bal32, bal33, bal23, bal13, bal03, bal40, bal41, bal42, bal43, 
			bal44, bal34, bal24, bal14, bal04, bal50, bal05, maxbet, ht, autoreject, allowance, autosuspend, multiple, stakerange2, risk2, allowance2, site2, site3, site4, 
			sporttype, Resourceid, ResultKey, creator)
	SELECT	oddsid, matchid, bettype, switch, hdp1, hdp2, odds1a, odds2a, odds1b, odds2b, odds1c, odds2c, odds1e, odds2e, odds1f, odds2f, odds1d, odds2d, 
			odds1hka, odds2hka, odds1hkb, odds2hkb, odds1hkc, odds2hkc, odds1hke, odds2hke, odds1hkf, odds2hkf, odds1hkd, odds2hkd, oddsspreada, oddsspreadb, 
			oddsspreadd, oddsspreade, oddsspreadf, oddsspreadc, autobookie, gapodds1, gapodds2, maxstake1, maxstake2, minstake1, minstake2, diffbalance, 
			maxodds, minodds, oddsstatus, liveindicator, changetime, risk, stakerange, newoffersetup, livehomescore, liveawayscore, com1, comx, com2, cs00, cs01, cs10, 
			cs11, cs02, cs12, cs22, cs21, cs20, cs30, cs31, cs32, cs33, cs23, cs13, cs03, cs43, cs42, cs41, cs40, cs44, cs14, cs24, cs04, cs34, cs50, cs05, comstatus, csstatus, 
			commaxbet, csmaxbet, bal00, bal10, bal11, bal01, bal20, bal21, bal22, bal12, bal02, bal30, bal31, bal32, bal33, bal23, bal13, bal03, bal40, bal41, bal42, bal43, 
			bal44, bal34, bal24, bal14, bal04, bal50, bal05, maxbet, ht, autoreject, allowance, autosuspend, multiple, stakerange2, risk2, allowance2, site2, site3, site4, 
			sporttype, Resourceid, ResultKey, creator
	FROM odds14 
	WHERE matchid in (select matchid from match14 where eventdate = @winlostdate)

	INSERT INTO SVRARC.ArchiveDB.dbo.match_remark_ex (
			matchid, eventstatus, betstatus, finalhomescore, finalawayscore, hthomescore, htawayscore, GoalRecord, 
			ruben, changetime, settletime, calculate, multiple, calrefund, refund, IsHTCal)
	SELECT	e.matchid, e.eventstatus, e.betstatus, e.finalhomescore, e.finalawayscore, 
			e.hthomescore, e.htawayscore, e.GoalRecord, e.ruben, e.changetime, e.settletime, 
			e.calculate, e.multiple, e.calrefund, e.refund, e.IsHTCal
	FROM	Match_remark_ex e
	WHERE	matchid in (select matchid from match14 where eventdate = @winlostdate)


	INSERT INTO SVRARC.ArchiveDB.dbo.match_bk (
			matchid, leagueid, homeid, awayid, eventdate, eventstatus, betstatus, livehomescore, liveawayscore, finalhomescore, finalawayscore, 
			creator, matchcode, kickofftime, closedtime, showtime, hthomescore, htawayscore, ruben, multiple, yenbet, exrisk, sporttype, 
			homeid2, awayid2, DisplayMode, LeaguePatternID, HomeDisplayPatternID, AwayDisplayPatternID, IsNeutral, GoalRecord)
	SELECT	matchid, leagueid, homeid, awayid, eventdate, eventstatus, betstatus, livehomescore, liveawayscore, finalhomescore, finalawayscore, 
			creator, matchcode, kickofftime, closedtime, showtime, hthomescore, htawayscore, ruben, multiple, yenbet, exrisk, sporttype, 
			homeid2, awayid2, DisplayMode, LeaguePatternID, HomeDisplayPatternID, AwayDisplayPatternID, IsNeutral, GoalRecord
	FROM	match14 
	WHERE eventdate = @winlostdate

	 
	INSERT INTO SVRARC.ArchiveDB.dbo.outright_bk (
			orid, leagueid, teamid, eventdate, kickofftime, oddsstatus, odds, maxbet, gapodds, matchcode, groupmatch, status, 
			creator, bal, risk, DisplayMode, PlaceOdds, Placing, IsFavor, IsSCR, ProgramID, FOddsStatus, 
			SCRTime, LeaguePatternID, TeamPatternID, ProgramDate, IsDeadheat, StdDelBetCheck)
	SELECT	orid, leagueid, teamid, eventdate, kickofftime, oddsstatus, odds, maxbet, gapodds, matchcode, groupmatch, status, 
			creator, bal, risk, DisplayMode, PlaceOdds, Placing, IsFavor, IsSCR, ProgramID, FOddsStatus, 
			SCRTime, LeaguePatternID, TeamPatternID, ProgramDate, IsDeadheat, StdDelBetCheck
	FROM	outright14 
	WHERE eventdate = @winlostdate

----Delete table [14]	
	
	DELETE FROM odds14 WHERE matchid in (SELECT matchid FROM match14 WHERE eventdate = @winlostdate)	
	DELETE FROM match_remark_ex WHERE MatchId IN (SELECT MatchId FROM Match14 WHERE eventdate = @winlostdate)
	DELETE FROM match14 WHERE eventdate = @winlostdate
	DELETE FROM outright14 WHERE eventdate = @winlostdate 