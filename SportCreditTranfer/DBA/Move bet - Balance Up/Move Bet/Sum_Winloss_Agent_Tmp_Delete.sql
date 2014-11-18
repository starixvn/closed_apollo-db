
ALTER TRIGGER [dbo].[Sum_Winloss_Agent_Tmp_Delete] 
   ON  [dbo].[Sum_Winloss_Agent_Tmp]
   AFTER DELETE
AS 

/*
Created: 20130515@Sophia
Task :	trigger delete on Sum_Winloss_Agent_Tmp
DB: SVRTXN.TransDB
Original:   Sum_Winloss_Tmp_Delete
Revisions:
	  - 20130930@Sophia: Add new and rename some columns

*/
BEGIN
SET NOCOUNT ON;

    -- Insert statements for trigger here
	INSERT INTO dbo.Sum_Winloss_Agent
				(	WinLostDate,
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
					BetType)
	SELECT			WinLostDate,
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
	FROM			Deleted

END

GO


