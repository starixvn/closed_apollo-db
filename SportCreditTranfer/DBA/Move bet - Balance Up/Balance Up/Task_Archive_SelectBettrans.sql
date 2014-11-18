--****** Object:  StoredProcedure [dbo].[Task_Archive_SelectBettrans]    Script Date: 05/23/2013 00:00:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_Archive_SelectBettrans]
AS

/*
Created: Sophia
Date:  20130530
Task : Archive data to SVRARC.ArchiveDB.dbo.bettrans_BK  
DB: SVRTXN.TransDB
Original: IBC.Task_Archive_SelectBettrans

Revisions:
 
	
Param's Explanation: 

*/	
SET NOCOUNT ON

Declare @winlostdate smalldatetime
SELECT TOP 1 @winlostdate = winlostdate 
FROM dbo.Task_ArchiveDate
ORDER BY winlostdate
 
  
SELECT	TransId,CustId,TransDate,OddsId,Hdp1,Hdp2,Odds,Stake,Status,WinLost,PlayerComm,
		PlayerDiscount,TWinLost,TComm,TPositionTaking,TDiscount,AgentIdList,AgentPositionTakingList,AgentDiscountList,
		LiveHomeScore,LiveAwayScore,LiveIndicator,BetTeam,Creator,RefNo,WinLostDate,BetFrom,BetCheck,
		CheckTime,OddsSpread,ActualRate,MatchId,Ruben,BetId,StatusWinLost,MOdds,BetType,Actual_Stake,Currency,
		IP,TransDesc,Username,CurrencyName,VirtualRate,StatusId,DoubleCommLosing,SecAcceptFlag,OddsType,balance
FROM dbo.bettrans14
WHERE winlostdate = @winlostdate 





