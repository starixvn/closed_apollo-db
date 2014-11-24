 
/****** Object:  StoredProcedure [dbo].[Task_Archive_ParlayResult]    Script Date: 05/22/2013 23:59:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_Archive_CreditTransSel]
AS
/*
Created: Sophia
Date:  20141118
Task : Archive data to SVRARC.ArchiveDB.dbo.CreditTrans_BK  
DB: SVRTXN/TransDB 

Revisions:
 
	
Param's Explanation: 

*/	
SET NOCOUNT ON
	DECLARE @WinlostDate SMALLDATETIME
	
	SELECT @WinlostDate = MAX(WinlostDate)
	FROM dbo.Task_ArchiveDate

		
	SELECT TransId, AgentId, CustId, TransDate, BalanceBefore, Amount, BetType, WinlostDate, TransDesc, Username, RefNo, Creator, IP
	FROM   dbo.CreditTrans
	WHERE  WinlostDate <= @WinlostDate

GO
