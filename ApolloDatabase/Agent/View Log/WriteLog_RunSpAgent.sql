USE [LogDB]
GO
/****** Object:  StoredProcedure [dbo].[WriteLog_RunSpAgent]    Script Date: 5/20/2013 5:24:44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[WriteLog_RunSpAgent]
	@UserId			INT,
	@SPName			NVARCHAR(50)	= NULL,
	@LogDate		DATETIME,
	@AgentId		INT				= NULL,
	@Duration		INT				= NULL,
	@Data			NVARCHAR(MAX)	= NULL,
	@OldData		NVARCHAR(MAX)	= NULL
AS

/**
 * Created by	: Kos
 * Date			: 20130427
 * Task			: Write log user run store procedure on agent
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
	
	INSERT INTO RunSpAgent (
		UserId,
		SPName,
		LogDate,
		AgentId,
		ActionId,
		Duration,
		Data,
		OldData )
	SELECT
		@UserId,
		@SPName,
		@LogDate,
		@AgentId,
		ActionId,
		@Duration,
		@Data,
		@OldData
	FROM LogAction WITH (NOLOCK)
	WHERE SPName = @SPName

END