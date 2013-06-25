
/****** Object:  StoredProcedure [dbo].[Task_Archive_SelectBettransm]    Script Date: 05/23/2013 00:00:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_Archive_SelectBettransm]
AS

/*
Created: Sophia
Date:  20130530
Task : Archive data to SVRARC.ArchiveDB.dbo.bettransm
DB: SVRTXN.TransDB
Original: IBC.Task_Archive_SelectBettransm

Revisions:
 
	
Param's Explanation: 

*/	

SET NOCOUNT ON

Declare @max_winlostdate smalldatetime

SELECT	@max_winlostdate = MAX(winlostdate)
FROM dbo.Task_ArchiveDate
  
SELECT 
	BetCheck,BetFrom,BetTeam,ComStatus, Status,
	TransId,CustId,TransDate,OddsId,Hdp1,Hdp2,Odds,Stake,WinLost,
	LiveHomeScore,LiveAwayScore,LiveIndicator,Creator,RefNo,
	WinLostDate,CheckTime,OddsSpread,PlayerDiscount,PlayerComm,
	ActualRate,MatchId,MatchDate,FinalOdds,IsFinish,StatusWinLost,Ruben,Bettype,StatusId,RecommDate
FROM dbo.bettransm14
WHERE winlostdate <= @max_winlostdate





