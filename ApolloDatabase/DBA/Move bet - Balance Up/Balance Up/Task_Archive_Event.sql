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
	INSERT INTO SVRARC.ArchiveDB.dbo.odds_bk
	SELECT * FROM odds14 
	WHERE matchid in (select matchid from match14 where eventdate = @winlostdate)

	INSERT INTO SVRARC.ArchiveDB.dbo.match_remark_ex 
	SELECT	e.matchid, e.eventstatus, e.betstatus, e.finalhomescore, e.finalawayscore, 
			e.hthomescore, e.htawayscore, e.GoalRecord, e.ruben, e.changetime, e.settletime, 
			e.calculate, e.multiple, e.calrefund, e.refund, e.IsHTCal
	FROM	Match_remark_ex e
	WHERE	matchid in (select matchid from match14 where eventdate = @winlostdate)


	INSERT INTO SVRARC.ArchiveDB.dbo.match_bk
	SELECT	matchid,  leagueid,  homeid,  awayid,  eventdate,  eventstatus,  betstatus,  livehomescore,  liveawayscore, 
			finalhomescore,  finalawayscore,  creator,  matchcode,  kickofftime,  closedtime,  showtime, 
			hthomescore,  htawayscore,  ruben,  multiple,  yenbet,  exrisk,  sporttype,  tstamp, 
			homeid2,  awayid2,  DisplayMode,  LeaguePatternID,  HomeDisplayPatternID,  AwayDisplayPatternID,  IsNeutral,  GoalRecord
	FROM match14 
	WHERE eventdate = @winlostdate

	 
	INSERT INTO SVRARC.ArchiveDB.dbo.outright_bk (
			orid, leagueid, teamid, eventdate, kickofftime, oddsstatus, odds, maxbet, gapodds, 
			matchcode, groupmatch, status, creator, bal, risk, DisplayMode, PlaceOdds, Placing, 
			IsFavor, IsSCR, ProgramID, FOddsStatus, SCRTime, LeaguePatternID, TeamPatternID, 
			ProgramDate, IsDeadheat, StdDelBetCheck, WinOdds2, PlaceOdds)
	SELECT	orid, leagueid, teamid, eventdate, kickofftime, oddsstatus, odds, maxbet, gapodds, 
			matchcode, groupmatch, status, creator, bal, risk, DisplayMode, PlaceOdds, Placing, 
			IsFavor, IsSCR, ProgramID, FOddsStatus, SCRTime, LeaguePatternID, TeamPatternID, 
			ProgramDate, IsDeadheat, StdDelBetCheck, WinOdds2, PlaceOdds
	FROM outright14 
	WHERE eventdate = @winlostdate

	--INSERT INTO SVRARC.ArchiveDB.dbo.bingoBall_bk
	--	([Matchid],  [Seq],  [Number],  [UpdateTime])
	--SELECT
	--	[Matchid],  [Seq],  [Number],  [UpdateTime]
	--FROM BingoBall14
	--WHERE MatchID in (SELECT MatchID from Match14 where eventdate = @winlostdate)
		


----Delete table [14]	
	
	DELETE FROM odds14 WHERE matchid in (SELECT matchid FROM match14 WHERE eventdate = @winlostdate)	
	DELETE FROM match_remark_ex WHERE MatchId IN (SELECT MatchId FROM Match14 WHERE eventdate = @winlostdate)
	DELETE FROM match14 WHERE eventdate = @winlostdate
	DELETE FROM outright14 WHERE eventdate = @winlostdate
	--DELETE FROM BingoBall14 WHERE matchid in (select matchid from match14 where eventdate = @winlostdate)
	