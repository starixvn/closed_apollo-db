/****** Object:  Trigger [dbo].[Balance_Insert_bettrans]    Script Date: 05/21/2013 00:08:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER TRIGGER [dbo].[Balance_Insert_bettrans]
   ON  [dbo].[BalanceTable_Tmp]
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
		INSERT INTO dbo.bettrans 
			(transdate, winlostdate, custid, checktime,
			winlost, actual_stake, PlayerComm, 
			bettype, matchid, status, statusID, transdesc, refno, creator, ruben,
			currency, username, currencyname, actualrate, virtualrate)

		SELECT 	winlostdate, winlostdate, custid, CURRENT_TIMESTAMP,
			(case when amount < 0 then 0 else amount end) as Winlost,  ---- The positive balance
			(case when amount < 0 then abs(amount) else 0 end) as actual_stake, ---- The negative balance
			0 as playerComm,
			20000, 0, 'BALANCE', 141, 'OPENING BALANCE', 260000000000, 148, 1,
			currency, UserName, CurrencyName, actualrate, actualrate
		FROM deleted
		WHERE Amount <> 0
		
END