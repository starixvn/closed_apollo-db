
ALTER TRIGGER [dbo].[Balance_Insert_CreditTrans]
   ON  [dbo].[BalanceCreditTrans]
   AFTER DELETE
AS 
/*
Created by:  Sophia
Date:  20141118
Task:  Trigger Insert balance into CreditTrans table	    
DB: SVRTXN/TransDB
Original: Balance_Insert_Bettrans
Revisions: 
	 

*/
SET NOCOUNT ON
BEGIN     
		-- Insert Balance for trigger here
		INSERT INTO dbo.CreditTrans (AgentId, CustId, TransDate, BalanceBefore, 
									Amount, BetType, WinlostDate, TransDesc,
									Username, RefNo, Creator, IP)
		SELECT	AgentId, 0 AS CustId, GETDATE() AS TransDate, 0 AS BalanceBefore, 
				Amount, 20000 AS BetType, WinlostDate, 'OPENING BALANCE' AS TransDesc, 
				Username, 260000000000 AS RefNo, 70 AS Creator, NULL AS IP
		FROM	deleted
		WHERE	Amount <> 0 AND AgentID <> 0
		
END
GO