USE [LogDB]
GO
/****** Object:  StoredProcedure [dbo].[WriteLog_AgentLog_Login]    Script Date: 6/29/2013 11:36:02 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[WriteLog_AgentLog_Login]
 @AgentId INT,   
 @AgentUserId INT,    
 @ServerID INT = 0,   
 @LoginIP VARCHAR(40)='',  
 @ActionID INT = 0,  
 @Doing VARCHAR(300),
 @DomainName NVARCHAR(253) = NULL,
 @BrowserName NVARCHAR(255) = NULL,
 @Platform NVARCHAR(255) = NULL,
 @CountryCode VARCHAR(64) = NULL 
 
AS  
/**
 * Created by	: Terry
 * Date			: 20130514
 * Task			: Write log Agent login
 * DB			: SVRLOG.LogDB
 * Revisions	:
 *	• 
 * Parameters:
 *	•
 *	•
 *  
 */
  
  
SET NOCOUNT ON  
DECLARE @StartRun	DATETIME,
		@EndRun		DATETIME,
		@Duration	INT

BEGIN TRY

SET @StartRun = GETDATE()
INSERT INTO dbo.LoginAgent( AgentId,   
				AgentUserId,            
				ServerID,   
				IP, 		
				LogDate,   
				ActionID,   
				Doing,
				DomainName,  
				BrowserName,
				Platform,
				CountryCode,
				Duration		
         )   
      VALUES(	@AgentId,   
				@AgentUserId,            
				@ServerID,  
				@LoginIP,   		
				CURRENT_TIMESTAMP,   
				@ActionID,   
				@Doing,
				@DomainName, 
				@BrowserName,
				@Platform,
				@CountryCode,
				@Duration 	
			)  

END	TRY
BEGIN CATCH
	SET @EndRun	= GETDATE()
	SET @Duration	= DATEDIFF(MILLISECOND, @StartRun, @EndRun)
	EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpAgent
			@UserId			= @AgentUserId,
			@SPName			= 'WriteLog_AgentLog_Login',
			@LogDate		= @StartRun,
			@AgentId		= @AgentId,
			@Duration		= @Duration,
			@Data			= @Doing,
			@OldData		= ''
END CATCH
