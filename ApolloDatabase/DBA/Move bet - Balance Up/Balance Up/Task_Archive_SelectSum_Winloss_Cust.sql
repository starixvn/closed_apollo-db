 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_Archive_SelectSum_Winloss_Cust]
AS
/*
Created:  Sophia
Date: 20130528
Task: Get data to import to SVRARC.ArchiveDB.dbo.Sum_Winloss_Cust_Old
DB: SVRTXN.TRANSDB
Original: IBC.Task_Archive_SelectSum_Winloss

Revisions:    
 
*/

SET NOCOUNT ON

Declare @min_winlostdate smalldatetime,
		@max_winlostdate smalldatetime
SELECT
	@min_winlostdate = MIN(winlostdate),
	@max_winlostdate = MAX(winlostdate)
FROM dbo.Task_ArchiveDate


SELECT	WinLostDate,CustId,Username,AgentId,Turnover,Actual_Turnover,
		WinLost,PlayerComm,UplineWinLost,UplineComm,BetCount,SportType,BetType
FROM	dbo.Sum_Winloss_Cust
WHERE	winlostdate BETWEEN @min_winlostdate AND @max_winlostdate
 

  