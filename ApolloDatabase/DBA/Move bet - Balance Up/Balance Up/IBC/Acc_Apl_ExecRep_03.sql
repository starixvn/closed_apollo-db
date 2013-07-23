ALTER PROCEDURE [dbo].[Acc_Apl_ExecRep_03]
	@fdate Datetime
AS
/*
Created by:Sophia
Date: 20130601
Task:	Called by Task_BalanceUp_background
		Delete match (put this code from Task_BalanceUp_background to a new Sp)
DB: DBTXN.BODB02 / SVRTXN.TRANSDB
Revisions:
    
 */

SET NOCOUNT ON

IF @@SERVERNAME IN ('SDBTRANS1','SDBTRANS2') --- TransDB of Apollo
	RETURN

----Put into string because linked-server DB02 does not exists
DECLARE @S VARCHAR(4000)	
SET @S = '
DELETE FROM DB02.bodb02.dbo.match
WHERE	matchid not in (select distinct matchid from bettrans where bettype <= 19000)
		and kickofftime < '''+ CONVERT(VARCHAR(10),@fdate,120)+''''

-- PRINT @S
EXEC (@S)

GO
 