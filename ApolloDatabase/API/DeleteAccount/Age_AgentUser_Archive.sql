ALTER  PROCEDURE [dbo].[Age_AgentUser_Archive]
	@AgentUserId	INT,
	@ErrCode		INT				= 0		OUTPUT,
	@ErrMsg			NVARCHAR(1000)	= ''	OUTPUT 
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Archive agent data
 * DB			: SVRCUST.CustDB
 * Revisions	:
 *	• 
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON

	-- Check if agent user ID exists
	IF NOT EXISTS ( SELECT 1 FROM AgentUser WITH (NOLOCK) WHERE AgentUserId = @AgentUserId )
		BEGIN
			SELECT 
				@ErrCode = 5300, 
				@ErrMsg = 'Agent user ID not exist [AgentUserId = ' + COALESCE(CAST(@AgentUserId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	-- Check if agent user ID is shadow
	IF EXISTS ( SELECT 1 FROM AgentUser WITH (NOLOCK) WHERE AgentUserId = @AgentUserId AND IsMaster = 1)
		BEGIN
			SELECT 
				@ErrCode = 5310, 
				@ErrMsg = 'Agent user is master [AgentUserId = ' + COALESCE(CAST(@AgentUserId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	-- For write log
	DECLARE 
		@startRun	DATETIME,
		@endRun		DATETIME,
		@duration	INT,
		@logData	NVARCHAR(MAX),
		@xml		XML,
		@agentId	INT,
		@username	NVARCHAR(50)

	SET @startRun = GETDATE()

	SELECT 
		@agentId = AgentId,
		@username = Username
	FROM AgentUser WITH (NOLOCK)
	WHERE AgentUserId = @AgentUserId

	-- Archive AgentUser 
	INSERT INTO SVRCUSTARC.CustArchiveDB.dbo.AgentUser (
		AgentUserId,
		AgentId,
		Username,
		IsMaster,
		PageAccess,
		CreateDate,
		Creator,
		LoginCount,
		Status,
		ArchiveDate
	)
	SELECT 
		AgentUserId,
		AgentId,
		Username,
		IsMaster,
		PageAccess,
		CreateDate,
		Creator,
		LoginCount,
		Status,
		GETDATE()
	FROM AgentUser WITH (NOLOCK)
	WHERE AgentUserId = @AgentUserId

	-- Check error
	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 5311, 
				@ErrMsg = 'Failed to archive agent user [AgentUserId = ' + COALESCE(CAST(@AgentUserId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	-- Archive agent user permission (master and shadow)
	INSERT INTO SVRCUSTARC.CustArchiveDB.dbo.AgentUserFunction (
		AgentUserId,
		FunctionId,
		AgentId,
		Policy,
		ArchiveDate
	)
	SELECT 
		AgentUserId,
		FunctionId,
		AgentId,
		Policy,
		GETDATE()
	FROM AgentUserFunction WITH (NOLOCK)
	WHERE AgentUserId = @AgentUserId

	-- Check error
	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 5316, 
				@ErrMsg = 'Failed to archive agent user permission [AgentUserId = ' + COALESCE(CAST(@AgentUserId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	-- Delete data in CustDB
	DELETE FROM AgentUser WITH (ROWLOCK)
	WHERE AgentUserId = @AgentUserId

	DELETE FROM AgentUserFunction WITH (ROWLOCK)
	WHERE AgentUserId = @AgentUserId

	-- Check error
	IF @@ERROR > 0
		BEGIN
			-- Rollback
			DELETE FROM SVRCUSTARC.CustArchiveDB.dbo.AgentUser WITH (ROWLOCK)
			WHERE AgentUserId = @AgentUserId

			SELECT 
				@ErrCode = 5311, 
				@ErrMsg = 'Failed to archive agent user [AgentUserId = ' + COALESCE(CAST(@AgentUserId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	-- Write log for archive agent
	SET @xml = (
		SELECT	
			@AgentUserId AS '@au'
		FOR XML PATH('z'), ROOT('r')
	)

	SET @logData = REPLACE(CONVERT(NVARCHAR(MAX), @xml), '" />', '"/"')

	SET @endRun = GETDATE()
	SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun) 	

	IF @@ERROR = 0
		BEGIN TRY
			EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpAgent
				@UserId		= @AgentId,
				@SPName		= 'Age_AgentUser_Archive',
				@LogDate	= @startRun,
				@AgentId	= @AgentUserId,
				@Duration	= @Duration,
				@Data		= @logData,
				@OldData	= NULL
		END	TRY
		BEGIN CATCH
			EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpAgent
				@UserId		= @AgentId,
				@SPName		= 'Age_AgentUser_Archive',
				@LogDate	= @startRun,
				@AgentId	= @AgentUserId,
				@Duration	= @Duration,
				@Data		= @logData,
				@OldData	= NULL
		END CATCH	
END

