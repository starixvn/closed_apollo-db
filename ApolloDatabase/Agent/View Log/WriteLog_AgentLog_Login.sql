USE [LogDB]
GO
/****** Object:  StoredProcedure [dbo].[WriteLog_AgentLog_Login]    Script Date: 6/29/2013 11:36:02 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[WriteLog_AgentLog_Login]
	@AgentId		INT,
	@AgentUserId	INT,
	@ServerID		INT				= 0,
	@LoginIP		VARCHAR(40)		='',
	@ActionID		INT				= 0,
	@Doing			VARCHAR(300),
	@DomainName		NVARCHAR(253)	= NULL,
	@BrowserName	NVARCHAR(255)	= NULL,
	@Platform		NVARCHAR(255)	= NULL,
	@CountryCode	VARCHAR(64)		= NULL
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
BEGIN

	SET NOCOUNT ON

	INSERT INTO dbo.LoginAgent ( 
		AgentId,
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
	VALUES (
		@AgentId,
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

END