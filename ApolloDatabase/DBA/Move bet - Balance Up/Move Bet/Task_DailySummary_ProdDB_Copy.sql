USE [ProdDB]
GO
/****** Object:  StoredProcedure [dbo].[Task_DailySummary_ProdDB_Copy]    Script Date: 7/14/2014 2:20:44 AM ******/
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
	-20140220@Dan: add logic to copy running outright in IBC but settle manually in Suncity
	 

*/
	BEGIN
	SET NOCOUNT ON	
	
	insert into odds_ex14
		([oddsid_ex],[odds1a_adj],[odds2a_adj],[odds1b_adj],[odds2b_adj],[odds1c_adj],[odds2c_adj],[odds1e_adj],[odds2e_adj],[odds1f_adj]
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
	select
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
	from odds_ex
	where oddsid_ex in (select oddsid from odds where matchid in (select matchid from match where eventdate=@winlostdate))  

	insert into odds14
		(oddsid, matchid, bettype, switch, hdp1, hdp2, odds1a, odds2a, odds1b, odds2b, odds1c, odds2c, odds1e, odds2e, odds1f, odds2f, odds1d, odds2d, 
		odds1hka, odds2hka, odds1hkb, odds2hkb, odds1hkc, odds2hkc, odds1hke, odds2hke, odds1hkf, odds2hkf, odds1hkd, odds2hkd, oddsspreada, oddsspreadb, 
		oddsspreadd, oddsspreade, oddsspreadf, oddsspreadc, autobookie, gapodds1, gapodds2, maxstake1, maxstake2, minstake1, minstake2, diffbalance, 
		maxodds, minodds, oddsstatus, liveindicator, changetime, risk, stakerange, newoffersetup, livehomescore, liveawayscore, com1, comx, com2, 
		cs00, cs01, cs10, cs11, cs02, cs12, cs22, cs21, cs20, cs30, cs31, cs32, cs33, cs23, cs13, cs03, cs43, cs42, cs41, cs40, cs44, cs14, cs24, cs04, cs34, cs50, cs05, 
		comstatus, csstatus, commaxbet, csmaxbet, bal00, bal10, bal11, bal01, bal20, bal21, bal22, bal12, bal02, bal30, bal31, bal32, bal33, bal23, bal13, bal03, 
		bal40, bal41, bal42, bal43, bal44, bal34, bal24, bal14, bal04, bal50, bal05, maxbet, ht, autoreject, allowance, autosuspend, multiple, stakerange2, risk2, 
		allowance2, site2, site3, site4, sporttype, Resourceid, ResultKey, creator, tstamp)
	select
		oddsid, matchid, bettype, switch, hdp1, hdp2, odds1a, odds2a, odds1b, odds2b, odds1c, odds2c, odds1e, odds2e, odds1f, odds2f, odds1d, odds2d, 
		odds1hka, odds2hka, odds1hkb, odds2hkb, odds1hkc, odds2hkc, odds1hke, odds2hke, odds1hkf, odds2hkf, odds1hkd, odds2hkd, oddsspreada, oddsspreadb, 
		oddsspreadd, oddsspreade, oddsspreadf, oddsspreadc, autobookie, gapodds1, gapodds2, maxstake1, maxstake2, minstake1, minstake2, diffbalance, 
		maxodds, minodds, oddsstatus, liveindicator, changetime, risk, stakerange, newoffersetup, livehomescore, liveawayscore, com1, comx, com2, 
		cs00, cs01, cs10, cs11, cs02, cs12, cs22, cs21, cs20, cs30, cs31, cs32, cs33, cs23, cs13, cs03, cs43, cs42, cs41, cs40, cs44, cs14, cs24, cs04, cs34, cs50, cs05, 
		comstatus, csstatus, commaxbet, csmaxbet, bal00, bal10, bal11, bal01, bal20, bal21, bal22, bal12, bal02, bal30, bal31, bal32, bal33, bal23, bal13, bal03, 
		bal40, bal41, bal42, bal43, bal44, bal34, bal24, bal14, bal04, bal50, bal05, maxbet, ht, autoreject, allowance, autosuspend, multiple, stakerange2, risk2, 
		allowance2, site2, site3, site4, sporttype, Resourceid, ResultKey, creator, tstamp
	from odds
	where matchid in (select matchid from match where eventdate=@winlostdate)  

	insert into match14 
		(matchid, leagueid, homeid, awayid, eventdate, eventstatus, betstatus, livehomescore, liveawayscore, finalhomescore, finalawayscore, creator, 
		matchcode, kickofftime, closedtime, showtime, hthomescore, htawayscore, ruben, multiple, yenbet, exrisk, sporttype, homeid2, awayid2, 
		DisplayMode, LeaguePatternID, HomeDisplayPatternID, AwayDisplayPatternID, IsNeutral, GoalRecord, settletime, tstamp)
	select
		matchid, leagueid, homeid, awayid, eventdate, eventstatus, betstatus, livehomescore, liveawayscore, finalhomescore, finalawayscore, creator, 
		matchcode, kickofftime, closedtime, showtime, hthomescore, htawayscore, ruben, multiple, yenbet, exrisk, sporttype, homeid2, awayid2, 
		DisplayMode, LeaguePatternID, HomeDisplayPatternID, AwayDisplayPatternID, IsNeutral, GoalRecord, settletime, tstamp
	from match
	where eventdate=@winlostdate 

	insert into outright_ex14
		( [orid_ex],[oddsstatus_ex],[odds_adj],[maxbet_ex],[gapodds_ex] ,[status_ex],[bal_ex],[risk_ex],[DisplayMode_ex]      
		,[PlaceOdds_adj],[FOddsStatus_ex],[changetime_ex],[IsDeadheat_ex] ,[StdDelBetCheck_ex], DisabledAutoSettle)
	select
		 [orid_ex],[oddsstatus_ex],[odds_adj],[maxbet_ex],[gapodds_ex] ,[status_ex],[bal_ex],[risk_ex],[DisplayMode_ex]      
		,[PlaceOdds_adj],[FOddsStatus_ex],[changetime_ex],[IsDeadheat_ex] ,[StdDelBetCheck_ex], DisabledAutoSettle
	from outright_ex
	where orid_ex in (select orid from outright where eventdate = @winlostdate AND oddsstatus = 'Completed')

	insert into outright14
		(orid, leagueid, teamid, eventdate, kickofftime, oddsstatus, odds, maxbet, gapodds, matchcode, groupmatch, status, creator, bal, risk, DisplayMode, 
		 PlaceOdds, Placing, IsFavor, IsSCR, ProgramID, FOddsStatus, SCRTime, LeaguePatternID, TeamPatternID, ProgramDate, IsDeadheat, StdDelBetCheck )
	select
		orid, leagueid, teamid, eventdate, kickofftime, oddsstatus, odds, maxbet, gapodds, matchcode, groupmatch, status, creator, bal, risk, DisplayMode, 
		PlaceOdds, Placing, IsFavor, IsSCR, ProgramID, FOddsStatus, SCRTime, LeaguePatternID, TeamPatternID, ProgramDate, IsDeadheat, StdDelBetCheck
	from outright
	where eventdate = @winlostdate AND oddsstatus = 'Completed'

	-- move outright (running in IBC but settle in Suncity)
	insert into outright_ex14
		( [orid_ex],[oddsstatus_ex],[odds_adj],[maxbet_ex],[gapodds_ex] ,[status_ex],[bal_ex],[risk_ex],[DisplayMode_ex]      
		,[PlaceOdds_adj],[FOddsStatus_ex],[changetime_ex],[IsDeadheat_ex] ,[StdDelBetCheck_ex], DisabledAutoSettle)
	select
		 [orid_ex],[oddsstatus_ex],[odds_adj],[maxbet_ex],[gapodds_ex] ,[status_ex],[bal_ex],[risk_ex],[DisplayMode_ex]      
		,[PlaceOdds_adj],[FOddsStatus_ex],[changetime_ex],[IsDeadheat_ex] ,[StdDelBetCheck_ex], DisabledAutoSettle
	from outright_ex
	where orid_ex in (select orid 
					from outright_ex oe with (nolock) join outright o with (nolock) on o.orid=oe.orid_ex
					Where DisabledAutoSettle=1 and oddsstatus_ex='Completed' and eventdate = @winlostdate
						AND o.oddsstatus <> 'Completed'
					)	

	insert into outright14
		(orid, leagueid, teamid, eventdate, kickofftime, oddsstatus, odds, maxbet, gapodds, matchcode, groupmatch, status, creator, bal, risk, DisplayMode, 
		 PlaceOdds, Placing, IsFavor, IsSCR, ProgramID, FOddsStatus, SCRTime, LeaguePatternID, TeamPatternID, ProgramDate, IsDeadheat, StdDelBetCheck )
	select
		orid, leagueid, teamid, eventdate, kickofftime, oddsstatus, odds, maxbet, gapodds, matchcode, groupmatch, status, creator, bal, risk, DisplayMode, 
		PlaceOdds, Placing, IsFavor, IsSCR, ProgramID, FOddsStatus, SCRTime, LeaguePatternID, TeamPatternID, ProgramDate, IsDeadheat, StdDelBetCheck
	--from outright where eventdate = @winlostdate AND oddsstatus = 'Completed'
	from outright_ex oe with (nolock) join outright o with (nolock) on o.orid=oe.orid_ex
	Where DisabledAutoSettle=1 and oddsstatus_ex='Completed' and eventdate = @winlostdate
		AND o.oddsstatus <> 'Completed'
	
END



