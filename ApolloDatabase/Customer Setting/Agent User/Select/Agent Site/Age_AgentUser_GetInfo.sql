USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_AgentUser_GetInfo]    Script Date: 4/23/2013 12:40:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_AgentUser_GetInfo]
	@AgentUserId	INT
AS

/**
 * Created by	: Kos
 * Date			: 20130305
 * Task			: Get agent user information
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	• @20130412	: Add status
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON	

	SELECT
		au.AgentUserId,
		au.Username,
		au.IsMaster,
		au.PageAccess,
		au.Status,
		au.CreateDate,
		au.Creator,
		au.LoginCount,
		au.AgentId,
		ai.Username AS AgentUsername,
		ai.AgentLevel
	FROM 
		AgentUser AS au WITH (NOLOCK)
		INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON au.AgentId = ai.AgentId
	WHERE au.AgentUserId = @AgentUserId
		
END
