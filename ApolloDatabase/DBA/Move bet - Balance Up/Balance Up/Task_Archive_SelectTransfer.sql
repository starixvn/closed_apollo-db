 
/****** Object:  StoredProcedure [dbo].[Task_Archive_SelectTransfer]    Script Date: 05/23/2013 00:01:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_Archive_SelectTransfer]
AS
/*
Created: Sophia
Date:  20130530
Task : Archive data to SVRARC.ArchiveDB.dbo.Transfer_BK  
DB: SVRTXN.TransDB
Original: IBC.Task_Archive_SelectTransfer

Revisions:
 
	
Param's Explanation: 

*/	  
	Declare @BU_Date datetime -- Next BalanceUp Date  


	SELECT @BU_Date = DATEADD(day, 1, MAX(winlostdate))
	FROM dbo.Task_ArchiveDate
	

	SELECT	b.custid, b.transdate, b.actual_stake as Debit, b.winlost as Credit, b.TransDesc, b.winlostdate, 
			c.AgentID, b.currency, b.refno, b.creator, b.TransID, b.bettype, b.Balance, b.TWinlost as TotalRunningStake
	FROM	bettrans b
	INNER JOIN CustInfo c ON c.CustID = b.CustID
	WHERE	b.ruben = 1 AND
			b.matchid = 0 AND b.bettype > 20000  
			AND b.winlostdate < @BU_Date  
			AND b.custid <> 0
			AND (b.winlost + b.actual_stake) <> 0


