USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetParentInfo]    Script Date: 3/29/2013 9:58:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Age_Agent_GetParentInfo]
	@AgentId		INT	
AS

/**
 * Created by	: Edward
 * Date			: 20130304
 * Task			: Get parent information
 * DB			: APL.CustDB
 * Revisions	:
 *	•	
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON
	
	-- Get parent id
	DECLARE @parentId	INT

	SELECT @parentId = ai.ParentId
	FROM AgentInfo AS ai WITH (NOLOCK)	
	WHERE ai.AgentId = @AgentId

	-- Get parent information
	SELECT 
		ai.AgentId,
		ai.AgentLevel,
		ai.Username,
		ai.Currency,		
		ai.AutoSuspend,
		ai.Suspended,
		ai.Credit,
		ai.Closed,
		ai.MatchLimit,
		ai.VirtualMultiplier,
		ai.Enabled,
		ai.DoubleCommLosing,
		ai.ParentId,
		ap.Username				AS ParentUsername
	FROM 
		AgentInfo AS ai WITH (NOLOCK)
		INNER JOIN AgentInfo AS ap WITH (NOLOCK) ON ai.ParentId = ap.AgentId
	WHERE ai.AgentId = @parentId
END

