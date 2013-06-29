USE [LogDB]
GO
/****** Object:  StoredProcedure [dbo].[ReadLog_Login]    Script Date: 6/29/2013 11:35:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[ReadLog_Login]
	@AgentId		INT,
	@AgentUserId	INT
	
	
AS
/*  
 * Created: 05162013@Terry
 * Task : Read log login
 * DB: LogDB
 *  
 * Revisions:		
 * Param's Explanation: 
*/
BEGIN
	SELECT TOP 10		
	LogId,	
	Ip,
	LogDate,
	ActionId,
	Doing,
	DomainName,
	BrowserName,
	[Platform]

	FROM LoginAgent WITH(NOLOCK)
	WHERE AgentId = @AgentId AND AgentUserId = @AgentUserId
	ORDER BY LogDate DESC
END
