USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_AgentUser_Insert]    Script Date: 4/17/2013 3:10:28 PM ******/
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
	@LogDate		DATETIME		= NULL,
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
 *	• 20130417@Edward : Add @LogDate and Write log
 * Parameters:
 *	•
 *	•
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

	-- Insert into AgentUser
	INSERT INTO AgentUser(
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
				@ErrCode = 1205, 
				@ErrMsg = 'Failed to insert agent user [AgentUserId = ' + COALESCE(CAST(@AgentUserId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END
	
	SET @xml = (
		SELECT	@Username		AS '@u'
				,@AgentId		AS '@ai'
				,@PageAccess	AS '@pa'
				,@Status		AS '@s'				
		 FOR XML PATH('z'), ROOT('r')
	)

	SET @logSPData = REPLACE(CONVERT(varchar(max), @xml), '" />', '"/"')

	SET @endRun		= GETDATE()  
	SET @duration	= DATEDIFF(millisecond, @startRun, @endRun) 

	IF @LogDate IS NULL
		SET @LogDate = GETDATE()	

	EXEC LogDB.dbo.Age_LogRunSp_Insert
		@UserId			= @Creator,
		@SPName			= 'Age_AgentUser_Insert',
		@LogDate		= @LogDate,
		@ObjectId		= @AgentUserId,
		@ObjectTypeId	= 1,			--Object type : Agent						
		@Duration		= @Duration,
		@Data			= @logSPData,
		@OldData		= @logSPDataOld		
END	
