--****** Object:  StoredProcedure [dbo].[Task_Archive_SelectBettrans_Agent]    Script Date: 05/23/2013 00:00:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_Archive_SelectBettrans_Agent]
AS

/*
Created: Sophia
Date:  20130530
Task : Archive data to SVRARC.ArchiveDB.dbo.Bettrans_Agent_BK  
DB: SVRTXN.TransDB
Original: IBC.Task_Archive_SelectBettrans 

Revisions:
 
	
Param's Explanation: 

*/	
SET NOCOUNT ON

Declare @winlostdate smalldatetime

SELECT TOP 1 @winlostdate = winlostdate 
FROM	dbo.Task_ArchiveDate
ORDER BY Winlostdate
 
SELECT	TransId,AgentId,TransDate,Stake,Actual_Stake,Status,AWinLost,AComm,APositionTaking,ADiscount,
		RefNo,WinLostDate,ActualRate,MatchId,BetType,Currency,IP,
		TransDesc,Username,CurrencyName,VirtualRate,StatusId,SecAcceptFlag
FROM dbo.Bettrans14_Agent
WHERE winlostdate = @winlostdate 
 





