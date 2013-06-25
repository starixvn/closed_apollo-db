 
/****** Object:  StoredProcedure [dbo].[Task_BalanceUp_TriggerControl]    Script Date: 05/21/2013 00:07:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_BalanceUp_TriggerControl]
	@On	bit
AS

/*
Created: 20130531@Sophia
Task : Trigger Control
DB: SVRTXN.TransDB
Original: 

Revisions: 
	
Param's Explanation: 

*/
SET NOCOUNT ON 
	
	IF @On = 1 ENABLE  TRIGGER balance_insert_Bettrans ON BalanceTable_tmp
	IF @On = 0 DISABLE TRIGGER balance_insert_Bettrans ON BalanceTable_tmp

	IF @On = 1 ENABLE  TRIGGER balance_insert_Bettrans_Agent ON BalanceTable_Agent_tmp
	IF @On = 0 DISABLE TRIGGER balance_insert_Bettrans_Agent ON BalanceTable_Agent_tmp


WAITFOR DELAY '000:00:04.000'
