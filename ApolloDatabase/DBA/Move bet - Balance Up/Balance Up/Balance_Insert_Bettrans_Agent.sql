/****** Object:  Trigger [dbo].[Balance_Insert_bettrans]    Script Date: 05/21/2013 00:08:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER TRIGGER [dbo].[Balance_Insert_Bettrans_Agent]
   ON  [dbo].[BalanceTable_Agent_Tmp]
   AFTER DELETE
AS 
/*
Created by:  Sophia
Date:  20130603
Task:  Trigger Insert balance into bettrans table
DB: SVRTXN.TransDB
Original:  IBC.step2_balance_insert
Revisions: 
	 

*/
SET NOCOUNT ON
BEGIN     
		-- Insert statements for trigger here
		INSERT INTO dbo.Bettrans_Agent 
			(TransID, transdate, winlostdate, AgentId, 
			AWinlost, AComm, actual_stake,
			bettype, matchid, status, statusID, transdesc, refno,
			currency, username, currencyname, actualrate, virtualrate)

		SELECT TransID, winlostdate, winlostdate, AgentId,
			amount as AWinlost,   ----- keep balance on this column only, not use actual_stake for negative balance
			0 as AComm,
			0 as actual_stake,
			20000, 0, 'BALANCE', 141, 'OPENING BALANCE', 260000000000, 
			currency, UserName, CurrencyName, actualrate, actualrate
		FROM deleted
		WHERE Amount <> 0
		
END