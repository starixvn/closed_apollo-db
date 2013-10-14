 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_Archive_SelectSum_Winloss_Agent]
AS

/*
Created:  Sophia
Date: 20130528
Task: Get data to import to SVRARC.ArchiveDB.dbo.Sum_Winloss_Agent_Old
DB: SVRTXN.TRANSDB
Original: IBC.Task_Archive_SelectSum_Winloss

Revisions:    
	- 20130930@Sophia: Add new and rename some columns
 
*/
SET NOCOUNT ON

Declare @min_winlostdate smalldatetime,
		@max_winlostdate smalldatetime
SELECT
	@min_winlostdate = MIN(winlostdate),
	@max_winlostdate = MAX(winlostdate)
FROM dbo.Task_ArchiveDate

 
SELECT	WinLostDate,
		AgentId,
		AgentUsername,
		ParentID,
		BetAmount,
		BetCount,
		CommBase,
		Winlost,
		PlayerComm,
		AWinLost,
		AComm,
		GrossTotal,
		UplineWinlost,
		UplineComm,
		DownlineEffStake,
		UplineEffStake,
		SportType,
		BetType
FROM dbo.Sum_Winloss_Agent
WHERE winlostdate
BETWEEN @min_winlostdate AND @max_winlostdate
 

  