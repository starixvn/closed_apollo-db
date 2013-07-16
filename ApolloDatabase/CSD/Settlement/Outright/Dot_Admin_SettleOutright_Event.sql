ALTER PROCEDURE [dbo].[Dot_Admin_SettleOutright_Event]
	@creator int = 0,
	@matchid int,
	@status nvarchar(10),
	@isDeadheat bit=0,
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
Created: Dan
Task : sp for outright settlement

DB: SVRPRO/ProdDB
Original: DBPRO.BODB02.Dot_Admin_SettleOutright_Event 

Revisions:						
Param's Explanation:
	- @deadheat = fraction of deadheat to divide (1,2,3  etc)
*/
SET NOCOUNT ON

---- check and not allow attempt to settlement same game while it's still not finish
IF EXISTS (SELECT 1 FROM SVRTXN.TransDB.dbo.TempVariableNumber WHERE KeyID = 2 AND KeyValue = @matchid)
BEGIN
	SELECT  @ErrCode = 101,
			@ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
	RETURN
END

declare @ActionID int 
set @ActionID=127

DECLARE @LogData NVARCHAR(300)
INSERT INTO SVRTXN.TransDB.dbo.TempVariableNumber (KeyID, KeyValue) VALUES (2, @matchid)
IF (@@Error = 0)
	BEGIN TRY
		EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @creator, 
			@Matchid = @matchid, 
			@KeyID = 2,
			@ActionID = @ActionID, 
			@Remark = 'ADD SUCCESS SPName = Dot_Admin_SettleOutright_Event'
	END TRY
	BEGIN CATCH		
		SELECT @LogData = 'ADD SUCCESS SPName = Dot_Admin_SettleOutright_Event MatchID=' + @matchid + ' KeyID=2 ErrMsg='+ left(error_message(), 70)		
		EXEC LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @creator, 
			@Matchid = @matchid, 
			@KeyID = 2,
			@ActionID = @ActionID, 
			@Remark = @LogData
	END CATCH
ELSE 
BEGIN
	SELECT @ErrCode = 102, @ErrMsg = 'This match is being calculated, please wait a few seconds until the on-going process is completed and try again.'
	RETURN
END
---------
IF NOT EXISTS(SELECT 1 FROM outright_ex with (nolock) where orid_ex = @matchid)
	INSERT outright_ex(orid_ex)
	SELECT @matchid

if (@status='won')
begin
	update outright_ex with (updlock,rowlock) 
	set oddsstatus_ex = 'Completed', 
		--eventdate = convert(char(10),getdate(),111), 
		status_ex = 'WON',
		changetime_ex = getdate(),
		IsDeadheat_ex = @isDeadheat
	where orid_ex = @matchid
end 
else if (@status='lose')
begin
	Update outright_ex with (updlock,rowlock)
	set oddsstatus_ex = 'Completed', 
		--eventdate = convert(char(10),getdate(),111), 
		status_ex = 'LOSE',
		changetime_ex = getdate(),
		IsDeadheat_ex = @isDeadheat
	where orid_ex = @matchid
end
ELSE IF @status = 'Refund'
BEGIN
	UPDATE dbo.outright_ex with (updlock,rowlock)
	SET oddsstatus_ex = 'Completed', 
		--eventdate = convert(char(10),getdate(),111), 
		status_ex = 'Refund',
		changetime_ex = getdate(),
		IsDeadheat_ex = @isDeadheat
	WHERE orid_ex = @matchid
END
ELSE
BEGIN
	UPDATE dbo.outright_ex with (updlock,rowlock)
	SET changetime_ex = getdate(),
		IsDeadheat_ex = @isDeadheat
	WHERE orid_ex = @matchid
END

----
-------------------------------------------------------------
---                      WRITE LOG                        ---
---------------------------VVVV------------------------------

BEGIN TRY
	EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_SettleOutright
		@UserID = @creator,
		@OrId = @matchid,
		@LeagueId = 0,
		@ActionID = @ActionID,
		@status = @status,
		@deadheat = @isDeadheat, 
		@Remark = null,
		@IP = @IP	
END TRY  
BEGIN CATCH	
	SELECT @LogData = ' ErrMsg=' + left(error_message(), 250)	
	EXEC LogDB.dbo.WriteLog_Settlement_SettleOutright
		@UserID = @creator,
		@OrId = @matchid,
		@LeagueId = 0,
		@ActionID = @ActionID,
		@status = @status,
		@deadheat = @isDeadheat, 
		@Remark = @LogData,
		@IP = @IP	
END CATCH

---
DELETE FROM SVRTXN.TransDB.dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
WHERE KeyID = 2 AND KeyValue = @matchid
IF (@@Error = 0)
BEGIN
	BEGIN TRY
		EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @creator, 
			@Matchid = @matchid, 
			@KeyID = 2,
			@ActionID = @ActionID, 
			@Remark = 'DEL SUCCESS SPName = Dot_Admin_SettleOutright_Event'
	END TRY
	BEGIN CATCH		
		SELECT @LogData = 'DEL SUCCESS SPName = Dot_Admin_SettleOutright_Event MatchID=' + @matchid + ' KeyID=2 ErrMsg='+ left(error_message(), 70)		
		EXEC LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @creator, 
			@Matchid = @matchid, 
			@KeyID = 2,
			@ActionID = @ActionID, 
			@Remark = @LogData
	END CATCH
END	
ELSE
BEGIN
	BEGIN TRY
		EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @creator, 
			@Matchid = @matchid, 
			@KeyID = 2,
			@ActionID = @ActionID, 
			@Remark = 'DEL FAILED SPName = Dot_Admin_SettleOutright_Event' 
	END TRY
	BEGIN CATCH		
		SELECT @LogData = 'DEL FAILED SPName = Dot_Admin_SettleOutright_Event MatchID=' + @matchid + ' KeyID=2 ErrMsg='+ left(error_message(), 70)		
		EXEC LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @creator, 
			@Matchid = @matchid, 
			@KeyID = 2,
			@ActionID = @ActionID, 
			@Remark = @LogData

	END CATCH
END

GO
GRANT EXECUTE ON [dbo].[Dot_Admin_SettleOutright_Event] TO aplweb
