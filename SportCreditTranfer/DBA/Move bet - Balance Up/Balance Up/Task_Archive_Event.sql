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
	- 20131205@Dan: add match_remark table
	- 20140111@Dan: add LiveDeleteChecker for match_remark_ex
Param's Explanation: 

*/
BEGIN
----Archive 
	INSERT INTO SVRARC.ArchiveDB.dbo.odds_ex_bk (
		[oddsid_ex],[odds1a_adj],[odds2a_adj],[odds1b_adj],[odds2b_adj],[odds1c_adj],[odds2c_adj],[odds1e_adj],[odds2e_adj],[odds1f_adj]
		,[odds2f_adj],[odds1d_adj] ,[odds2d_adj],[odds1hka_adj] ,[odds2hka_adj] ,[odds1hkb_adj] ,[odds2hkb_adj],[odds1hkc_adj],[odds2hkc_adj]
      ,[odds1hke_adj],[odds2hke_adj],[odds1hkf_adj],[odds2hkf_adj],[odds1hkd_adj],[odds2hkd_adj],[oddsspread_adj],[on_off],[gapodds1_adj]
	  ,[gapodds2_adj],[maxstake1_ex],[maxstake2_ex],[minstake1_ex],[minstake2_ex],[maxodds_adj],[minodds_adj],[oddsstatus_ex],[changetime_ex]
      ,[risk_ex],[stakerange_ex],[newoffersetup_ex],[com1_adj],[comx_adj],[com2_adj],[cs00_adj],[cs01_adj],[cs10_adj],[cs11_adj],[cs02_adj]
      ,[cs12_adj],[cs22_adj],[cs21_adj],[cs20_adj],[cs30_adj],[cs31_adj],[cs32_adj],[cs33_adj],[cs23_adj],[cs13_adj],[cs03_adj],[cs43_adj]
      ,[cs42_adj],[cs41_adj],[cs40_adj],[cs44_adj],[cs14_adj],[cs24_adj],[cs04_adj],[cs34_adj],[cs50_adj],[cs05_adj],[comstatus_ex],[csstatus_ex]
      ,[com1total_ex],[comxtotal_ex],[com2total_ex],[maxbet_ex],[ht_ex],[autosuspend_ex],[stakerange2_ex],[risk2_ex],[allowance2_ex]
      ,[site2_ex],[site3_ex],[site4_ex],[hometotal_ex],[awaytotal_ex],[SecAcceptFlag_ex],[SecAccept_ex],[diffbalance_ex],[bal00_ex],[bal01_ex],[bal02_ex]
      ,[bal03_ex],[bal04_ex],[bal05_ex],[bal10_ex],[bal11_ex],[bal12_ex],[bal13_ex],[bal14_ex],[bal20_ex],[bal21_ex],[bal22_ex],[bal23_ex],[bal24_ex]
      ,[bal30_ex],[bal31_ex],[bal32_ex],[bal33_ex],[bal34_ex],[bal40_ex],[bal41_ex],[bal42_ex],[bal43_ex],[bal44_ex],[bal50_ex]
	  ,oddsspreadb_adj,oddsspreadc_adj, oddsspreadd_adj)
	SELECT
		[oddsid_ex],[odds1a_adj],[odds2a_adj],[odds1b_adj],[odds2b_adj],[odds1c_adj],[odds2c_adj],[odds1e_adj],[odds2e_adj],[odds1f_adj]
		,[odds2f_adj],[odds1d_adj] ,[odds2d_adj],[odds1hka_adj] ,[odds2hka_adj] ,[odds1hkb_adj] ,[odds2hkb_adj],[odds1hkc_adj],[odds2hkc_adj]
      ,[odds1hke_adj],[odds2hke_adj],[odds1hkf_adj],[odds2hkf_adj],[odds1hkd_adj],[odds2hkd_adj],[oddsspread_adj],[on_off],[gapodds1_adj]
	  ,[gapodds2_adj],[maxstake1_ex],[maxstake2_ex],[minstake1_ex],[minstake2_ex],[maxodds_adj],[minodds_adj],[oddsstatus_ex],[changetime_ex]
      ,[risk_ex],[stakerange_ex],[newoffersetup_ex],[com1_adj],[comx_adj],[com2_adj],[cs00_adj],[cs01_adj],[cs10_adj],[cs11_adj],[cs02_adj]
      ,[cs12_adj],[cs22_adj],[cs21_adj],[cs20_adj],[cs30_adj],[cs31_adj],[cs32_adj],[cs33_adj],[cs23_adj],[cs13_adj],[cs03_adj],[cs43_adj]
      ,[cs42_adj],[cs41_adj],[cs40_adj],[cs44_adj],[cs14_adj],[cs24_adj],[cs04_adj],[cs34_adj],[cs50_adj],[cs05_adj],[comstatus_ex],[csstatus_ex]
      ,[com1total_ex],[comxtotal_ex],[com2total_ex],[maxbet_ex],[ht_ex],[autosuspend_ex],[stakerange2_ex],[risk2_ex],[allowance2_ex]
      ,[site2_ex],[site3_ex],[site4_ex],[hometotal_ex],[awaytotal_ex],[SecAcceptFlag_ex],[SecAccept_ex],[diffbalance_ex],[bal00_ex],[bal01_ex],[bal02_ex]
      ,[bal03_ex],[bal04_ex],[bal05_ex],[bal10_ex],[bal11_ex],[bal12_ex],[bal13_ex],[bal14_ex],[bal20_ex],[bal21_ex],[bal22_ex],[bal23_ex],[bal24_ex]
      ,[bal30_ex],[bal31_ex],[bal32_ex],[bal33_ex],[bal34_ex],[bal40_ex],[bal41_ex],[bal42_ex],[bal43_ex],[bal44_ex],[bal50_ex]
	  ,oddsspreadb_adj,oddsspreadc_adj, oddsspreadd_adj
	FROM odds_ex14
	WHERE oddsid_ex in (select oddsid from odds14 where matchid in (select matchid from match14 where eventdate=@winlostdate))  

	INSERT INTO SVRARC.ArchiveDB.dbo.odds_bk (
			oddsid, matchid, bettype, switch, hdp1, hdp2, odds1a, odds2a, odds1b, odds2b, odds1c, odds2c, odds1e, odds2e, odds1f, odds2f, odds1d, odds2d, 
			odds1hka, odds2hka, odds1hkb, odds2hkb, odds1hkc, odds2hkc, odds1hke, odds2hke, odds1hkf, odds2hkf, odds1hkd, odds2hkd, oddsspreada, oddsspreadb, 
			oddsspreadd, oddsspreade, oddsspreadf, oddsspreadc, autobookie, gapodds1, gapodds2, maxstake1, maxstake2, minstake1, minstake2, diffbalance, 
			maxodds, minodds, oddsstatus, liveindicator, changetime, risk, stakerange, newoffersetup, livehomescore, liveawayscore, com1, comx, com2, cs00, cs01, cs10, 
			cs11, cs02, cs12, cs22, cs21, cs20, cs30, cs31, cs32, cs33, cs23, cs13, cs03, cs43, cs42, cs41, cs40, cs44, cs14, cs24, cs04, cs34, cs50, cs05, comstatus, csstatus, 
			commaxbet, csmaxbet, bal00, bal10, bal11, bal01, bal20, bal21, bal22, bal12, bal02, bal30, bal31, bal32, bal33, bal23, bal13, bal03, bal40, bal41, bal42, bal43, 
			bal44, bal34, bal24, bal14, bal04, bal50, bal05, maxbet, ht, autoreject, allowance, autosuspend, multiple, stakerange2, risk2, allowance2, site2, site3, site4, 
			sporttype, Resourceid, ResultKey, creator, tstamp)
	SELECT	oddsid, matchid, bettype, switch, hdp1, hdp2, odds1a, odds2a, odds1b, odds2b, odds1c, odds2c, odds1e, odds2e, odds1f, odds2f, odds1d, odds2d, 
			odds1hka, odds2hka, odds1hkb, odds2hkb, odds1hkc, odds2hkc, odds1hke, odds2hke, odds1hkf, odds2hkf, odds1hkd, odds2hkd, oddsspreada, oddsspreadb, 
			oddsspreadd, oddsspreade, oddsspreadf, oddsspreadc, autobookie, gapodds1, gapodds2, maxstake1, maxstake2, minstake1, minstake2, diffbalance, 
			maxodds, minodds, oddsstatus, liveindicator, changetime, risk, stakerange, newoffersetup, livehomescore, liveawayscore, com1, comx, com2, cs00, cs01, cs10, 
			cs11, cs02, cs12, cs22, cs21, cs20, cs30, cs31, cs32, cs33, cs23, cs13, cs03, cs43, cs42, cs41, cs40, cs44, cs14, cs24, cs04, cs34, cs50, cs05, comstatus, csstatus, 
			commaxbet, csmaxbet, bal00, bal10, bal11, bal01, bal20, bal21, bal22, bal12, bal02, bal30, bal31, bal32, bal33, bal23, bal13, bal03, bal40, bal41, bal42, bal43, 
			bal44, bal34, bal24, bal14, bal04, bal50, bal05, maxbet, ht, autoreject, allowance, autosuspend, multiple, stakerange2, risk2, allowance2, site2, site3, site4, 
			sporttype, Resourceid, ResultKey, creator, tstamp
	FROM odds14 
	WHERE matchid in (select matchid from match14 where eventdate = @winlostdate)
	
	INSERT INTO SVRARC.ArchiveDB.dbo.match_remark (
		[matchid],[calculate],[multiple] ,[calrefund],[refund],[calStatus]
		,[IsTotalBetDenied_1],[IsTotalBetDenied_3],[IsTotalBetDenied_7],[IsTotalBetDenied_8]
		,[LiveTimer] ,[HomeRedCard], [AwayRedCard], [LivePeriod], [HedgeForecast],[IsTotalBetDenied_20]
		,[IsTotalBetDenied_21],[IsNeutral],[StreamingID],[IsInternal],[IsHTCal],[LiveDeleteChecker],[HomeColor]
		,[AwayColor],[ConfirmHT],[ConfirmFT],[PausePeriod],[TimerSuspend],[IsPending],[isUndecided],[StdDelBetCheck])
	SELECT			
			[matchid],[calculate],[multiple] ,[calrefund],[refund],[calStatus]
			,[IsTotalBetDenied_1],[IsTotalBetDenied_3],[IsTotalBetDenied_7],[IsTotalBetDenied_8]
			,[LiveTimer] ,[HomeRedCard], [AwayRedCard], [LivePeriod], [HedgeForecast],[IsTotalBetDenied_20]
			,[IsTotalBetDenied_21],[IsNeutral],[StreamingID],[IsInternal],[IsHTCal],[LiveDeleteChecker],[HomeColor]
			,[AwayColor],[ConfirmHT],[ConfirmFT],[PausePeriod],[TimerSuspend],[IsPending],[isUndecided],[StdDelBetCheck]
	FROM	Match_remark mr
	WHERE	matchid in (select matchid from match14 where eventdate = @winlostdate)


	INSERT INTO SVRARC.ArchiveDB.dbo.match_remark_ex (
			matchid, eventstatus, betstatus, finalhomescore, finalawayscore, hthomescore, htawayscore, GoalRecord, 
			ruben, changetime, settletime, calculate, multiple, calrefund, refund, IsHTCal, DisabledAutoSettle,LiveDeleteChecker)
	SELECT	e.matchid, e.eventstatus, e.betstatus, e.finalhomescore, e.finalawayscore, 
			e.hthomescore, e.htawayscore, e.GoalRecord, e.ruben, e.changetime, e.settletime, 
			e.calculate, e.multiple, e.calrefund, e.refund, e.IsHTCal, DisabledAutoSettle,LiveDeleteChecker
	FROM	Match_remark_ex e
	WHERE	matchid in (select matchid from match14 where eventdate = @winlostdate)


	INSERT INTO SVRARC.ArchiveDB.dbo.match_bk (
			matchid, leagueid, homeid, awayid, eventdate, eventstatus, betstatus, livehomescore, liveawayscore, finalhomescore, finalawayscore, 
			creator, matchcode, kickofftime, closedtime, showtime, hthomescore, htawayscore, ruben, multiple, yenbet, exrisk, sporttype, 
			homeid2, awayid2, DisplayMode, LeaguePatternID, HomeDisplayPatternID, AwayDisplayPatternID, IsNeutral, GoalRecord, tstamp)
	SELECT	matchid, leagueid, homeid, awayid, eventdate, eventstatus, betstatus, livehomescore, liveawayscore, finalhomescore, finalawayscore, 
			creator, matchcode, kickofftime, closedtime, showtime, hthomescore, htawayscore, ruben, multiple, yenbet, exrisk, sporttype, 
			homeid2, awayid2, DisplayMode, LeaguePatternID, HomeDisplayPatternID, AwayDisplayPatternID, IsNeutral, GoalRecord, tstamp
	FROM	match14 
	WHERE eventdate = @winlostdate

	INSERT INTO SVRARC.ArchiveDB.dbo.outright_ex_bk (	
		 [orid_ex],[oddsstatus_ex],[odds_adj],[maxbet_ex],[gapodds_ex] ,[status_ex],[bal_ex],[risk_ex],[DisplayMode_ex]      
		,[PlaceOdds_adj],[FOddsStatus_ex],[changetime_ex],[IsDeadheat_ex] ,[StdDelBetCheck_ex])
	SELECT
		 [orid_ex],[oddsstatus_ex],[odds_adj],[maxbet_ex],[gapodds_ex] ,[status_ex],[bal_ex],[risk_ex],[DisplayMode_ex]      
		,[PlaceOdds_adj],[FOddsStatus_ex],[changetime_ex],[IsDeadheat_ex] ,[StdDelBetCheck_ex]
	FROM outright_ex14
	WHERE orid_ex in (select orid from outright14 where eventdate = @winlostdate)
	 
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
	DELETE FROM odds_ex14 WHERE oddsid_ex in (select oddsid from odds14 where matchid in (select matchid from match14 where eventdate=@winlostdate))  
	DELETE FROM odds14 WHERE matchid in (SELECT matchid FROM match14 WHERE eventdate = @winlostdate)	
	DELETE FROM match_remark WHERE MatchId IN (SELECT MatchId FROM Match14 WHERE eventdate = @winlostdate)
	DELETE FROM match_remark_ex WHERE MatchId IN (SELECT MatchId FROM Match14 WHERE eventdate = @winlostdate)
	DELETE FROM match14 WHERE eventdate = @winlostdate
	DELETE FROM outright_ex14 WHERE orid_ex in (select orid from outright14 where eventdate = @winlostdate)
	DELETE FROM outright14 WHERE eventdate = @winlostdate 
END