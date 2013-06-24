 
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER TRIGGER [dbo].[Sum_Winloss_Cust_Tmp_Delete] 
   ON  [dbo].[Sum_Winloss_Cust_Tmp]
   AFTER DELETE
AS 

/*
Created: 20130515@Sophia
Task :	trigger delete on Sum_Winloss_Cust_Tmp
DB: SVRTXN.TransDB
Original:   Sum_Winloss_Tmp_Delete
Revisions:
	 

*/

BEGIN
SET NOCOUNT ON;

    -- Insert statements for trigger here
	INSERT INTO dbo.Sum_Winloss_Cust 
				(WinLostDate,CustId,Username,AgentId,Turnover,
				 Actual_Turnover,WinLost,PlayerComm,UplineWinLost,
				 UplineComm,BetCount,SportType,BetType)
	SELECT		 WinLostDate,CustId,Username,AgentId,Turnover,
				 Actual_Turnover,WinLost,PlayerComm,UplineWinLost,
				 UplineComm,BetCount,SportType,BetType
	FROM		deleted

END

GO


