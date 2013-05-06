USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_AgentUser_Insert]    Script Date: 5/6/2013 11:31:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_AgentUser_Insert]
	@AgentUserId	INT,	
	@Username		NVARCHAR(50),
	@AgentId		INT,	
	@PageAccess		VARCHAR(50)		= '',
	@Status			TINYINT			= 1,
	@Creator		INT				= NULL,
	@ErrCode		INT				= 0			OUTPUT,
	@ErrMsg			NVARCHAR(1000)	= ''		OUTPUT 
AS

/**
 * Created by	: Edward
 * Date			: 20130304
 * Task			: Add new agent user
 * DB			: SVRCUST.CustDB
 * Revisions	:
 *	• 20130412@Kos	: Change parameter from Closed to Status
 *	• 20130417@Edward : Add @LogDate
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON	

	-- Check if agent user ID exists
	IF EXISTS ( SELECT 1 FROM AgentUser WITH (NOLOCK) WHERE AgentUserId = @AgentUserId )
		BEGIN
			SELECT 
				@ErrCode = 5301, 
				@ErrMsg = 'Agent user ID duplicated [AgentUserId = ' + COALESCE(CAST(@AgentUserId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	-- Check if username exists
	IF EXISTS ( SELECT 1 FROM AgentUser WITH (NOLOCK) WHERE Username = @Username )
		BEGIN
			SELECT 
				@ErrCode = 5303, 
				@ErrMsg = 'Username duplicated [Username = ' + COALESCE(@Username, SPACE(1)) + ']'
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

	-- Insert into AgentUser
	INSERT INTO AgentUser (
		AgentUserId,
		AgentId,
		Username,
		IsMaster,
		PageAccess,
		CreateDate,
		Creator,
		LoginCount,
		Status)
	VALUES(
		@AgentUserId,
		@AgentId,
		@Username,
		0,			-- sub agent
		@PageAccess,
		GETDATE(),		
		@Creator,
		0,			-- login count
		@Status)

	---- Not support for multiple language
	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 5304, 
				@ErrMsg = 'Failed to insert agent user [AgentUserId = ' + COALESCE(CAST(@AgentUserId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END
	
	SET @xml = (
		SELECT	
			@Username	AS '@u',
			@AgentId	AS '@ai',
			@PageAccess	AS '@pa',
			@Status		AS '@s'
		 FOR XML PATH('z'), ROOT('r')
	)

	SET @logSPData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	SET @endRun	= GETDATE()  
	SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun) 
		
	IF @@Error = 0
		BEGIN TRY
			EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpAgent
			@UserId			= @Creator,
			@SPName			= 'Age_AgentUser_Insert',
			@LogDate		= @startRun,
			@AgentId		= @AgentId,
			@Duration		= @Duration,
			@Data			= @logSPData,
			@OldData		= @logSPDataOld
		END	TRY
		BEGIN CATCH
			EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpAgent
			@UserId			= @Creator,
			@SPName			= 'Age_AgentUser_Insert',
			@LogDate		= @startRun,
			@AgentId		= @AgentId,
			@Duration		= @Duration,
			@Data			= @logSPData,
			@OldData		= @logSPDataOld
		END CATCH 
END	
