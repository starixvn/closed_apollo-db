ALTER PROCEDURE [dbo].[ExecRep_APL_03]
	@fdate Datetime
AS
/*
Created by:Sophia
Date: 20130601
Task: Called by Task_BalanceUp_DB02 
DB: DB02.BODB02 / SVRPRO.ProdDB
Revisions:
    
 */ 
SET NOCOUNT ON 


IF @@SERVERNAME LIKE 'DBCLS1\SDBPROD' --- ProdDB of Apollo
	RETURN
	
SET @fdate = CONVERT(varchar(10), @fdate, 120)
	
delete from odds where matchid not in (select matchid from match)
delete from liveScore where matchid not in (select matchid from match (nolock) union all select matchid from match14 (nolock))


