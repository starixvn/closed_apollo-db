USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetParentInfo]    Script Date: 5/3/2013 4:24:52 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Age_Agent_GetParentInfo]
	@AgentId	INT	
AS

/**
 * Created by	: Edward
 * Date			: 20130304
 * Task			: Get parent information
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	• @20130418	: Add statuses
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON
	
	-- Get parent id
	DECLARE @parentId INT

	SELECT @parentId = ParentId
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @AgentId

	-- Get parent information
	SELECT
		ai.AgentId,
		ai.AgentLevel,
		ai.Username,
		ai.Currency,
		ai.Status,
		ai.BetStatus,
		ai.UplineStatus,
		ai.UplineBetStatus,
		ai.MatchLimit,
		ai.VirtualMultiplier,
		ai.DoubleCommLosing,
		ai.ParentId,
		pai.Username AS ParentUsername
	FROM 
		AgentInfo AS ai WITH (NOLOCK)
		INNER JOIN AgentInfo AS pai WITH (NOLOCK) ON ai.ParentId = pai.AgentId
	WHERE ai.AgentId = @parentId
END
