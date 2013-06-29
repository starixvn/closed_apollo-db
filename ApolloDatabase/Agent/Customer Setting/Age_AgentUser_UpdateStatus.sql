USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_AgentUser_UpdateStatus]    Script Date: 5/6/2013 11:31:55 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_AgentUser_UpdateStatus]
	@AgentUserId	INT,	
	@Status			TINYINT,
	@Modifier		INT				= NULL,
	@ErrCode		INT				= 0			OUTPUT,
	@ErrMsg			NVARCHAR(1000)	= ''		OUTPUT	
AS

/**
 * Created by	: Kos
 * Date			: 20130415
 * Task			: Update agent user status
 * DB			: APL.CustDB
 * Revisions	:
 *	• 20130417@Edward : Write log
 * Parameters:
 *	• @Status	:	1 : Active
 *					2 : Stopped
 *					3 : Locked
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
	
	-- For write log
	DECLARE 
		@startRun		DATETIME,
		@endRun			DATETIME,
		@duration		INT,
		@logSPData		VARCHAR(5000),
		@logSPDataOld	VARCHAR(5000),
		@xml			XML

	SET @startRun = GETDATE()

	SET @xml = (
		SELECT Status AS '@s'	
		FROM AgentUser WITH (NOLOCK)
		WHERE AgentUserId = @AgentUserId
		FOR XML PATH('z'), ROOT('r')
	)

	SET @logSPDataOld = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	UPDATE AgentUser WITH (ROWLOCK, UPDLOCK)
	SET Status = @Status
	WHERE 
		AgentUserId = @AgentUserId
		AND Status <> @Status

	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 6300, 
				@ErrMsg = 'Failed to update agent user status [AgentUserId = ' + COALESCE(CAST(@AgentUserId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	
	
	
	SET @xml = (
		SELECT @Status AS '@s'
		FOR XML PATH('z'), ROOT('r')
	)

	SET @logSPData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	SET @endRun	= GETDATE()
	SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun) 
		
	IF @@Error = 0
		BEGIN TRY
			EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpAgent
			@UserId			= @Modifier,
			@SPName			= 'Age_AgentUser_UpdateStatus',
			@LogDate		= @startRun,
			@AgentId		= @AgentUserId,
			@Duration		= @Duration,
			@Data			= @logSPData,
			@OldData		= @logSPDataOld
		END	TRY
		BEGIN CATCH
			EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpAgent
			@UserId			= @Modifier,
			@SPName			= 'Age_AgentUser_UpdateStatus',
			@LogDate		= @startRun,
			@AgentId		= @AgentUserId,
			@Duration		= @Duration,
			@Data			= @logSPData,
			@OldData		= @logSPDataOld
		END CATCH
END
