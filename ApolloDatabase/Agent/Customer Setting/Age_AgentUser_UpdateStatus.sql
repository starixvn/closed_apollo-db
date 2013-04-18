USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_AgentUser_UpdateStatus]    Script Date: 4/17/2013 3:10:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_AgentUser_UpdateStatus]
	@AgentUserId	INT,	
	@Status			TINYINT,
	@Modifier		INT				= NULL,
	@LogDate		DATETIME		= NULL,
	@ErrCode		INT				= 0			OUTPUT,
	@ErrMsg			NVARCHAR(1000)	= ''		OUTPUT	
AS

/**
 * Created by	: Kos
 * Date			: 20130415
 * Task			: Update agent user status
 * DB			: APL.CustDB
 * Revisions	:
 *	• 20130417@Edward : Add @LogDate and Write log
 * Parameters:
 *	• @Status	:	1 : Active
 *					2 : Stopped
 *					3 : Locked
 *  
 */

BEGIN
	
	SET NOCOUNT ON

	-- For write log
    DECLARE @startRun			DATETIME  
			,@endRun			DATETIME  
			,@duration			INT
			,@logSPData			VARCHAR(5000)
			,@logSPDataOld		VARCHAR(5000)			
			,@xml				XML			

	SET @startRun = GETDATE()

	SET @xml = (
		SELECT	Status		AS '@s'	
		FROM AgentUser WITH (NOLOCK)
		WHERE AgentUserId = @AgentUserId			
		FOR XML PATH('z'), ROOT('r')
	)

	SET @logSPDataOld = REPLACE(CONVERT(varchar(max), @xml), '" />', '"/"')

	UPDATE AgentUser
	SET Status = @Status
	WHERE 
		AgentUserId = @AgentUserId
		AND Status <> @Status

	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 1207, 
				@ErrMsg = 'Failed to update agent user status [AgentUserId = ' + COALESCE(CAST(@AgentUserId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	
	
	
	SET @xml = (
		SELECT	@Status		AS '@s'				
		 FOR XML PATH('z'), ROOT('r')
	)

	SET @logSPData = REPLACE(CONVERT(varchar(max), @xml), '" />', '"/"')

	SET @endRun		= GETDATE()  
	SET @duration	= DATEDIFF(millisecond, @startRun, @endRun) 

	IF @LogDate IS NULL
		SET @LogDate = GETDATE()	

	EXEC LogDB.dbo.Age_LogRunSp_Insert
		@UserId			= @Modifier,
		@SPName			= 'Age_AgentUser_UpdateStatus',
		@LogDate		= @LogDate,
		@ObjectId		= @AgentUserId,
		@ObjectTypeId	= 1,			--Object type : Agent						
		@Duration		= @Duration,
		@Data			= @logSPData,
		@OldData		= @logSPDataOld		
END
