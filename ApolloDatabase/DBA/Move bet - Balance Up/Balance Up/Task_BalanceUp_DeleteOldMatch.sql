ALTER PROCEDURE [dbo].[Task_BalanceUp_DeleteOldMatch]
	@fdate Date
AS
/*
Created by:  Sophia
Date:  20130603
Task:  Call from SP Task_BalanceUp_background, delete old match 
DB: SVRTXN.TransDB
Original:  
Revisions: 
	 

*/

SET NOCOUNT ON 

DELETE FROM SVRPRO.ProdDB.dbo.match
WHERE	matchid not in (SELECT DISTINCT matchid FROM bettrans WITH (NOLOCK) WHERE bettype <= 19000)
		and kickofftime < @fdate