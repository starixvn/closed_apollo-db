USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetInfo]    Script Date: 4/18/2013 1:37:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_GetInfo]
	@AgentId	INT	
AS

/**
 * Created by	: Kos
 * Date			: 20130305
 * Task			: Get agent information
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	• @20130412	: Add statuses
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON	

	SELECT
		ai.AgentId,
		ai.AgentLevel,
		ai.Username,
		ai.Currency,		
		ai.Status,
		ai.BetStatus,
		ai.UplineStatus,
		ai.UplineBetStatus,
		ai.Credit,
		ai.MatchLimit,
		ai.VirtualMultiplier,
		ai.DoubleCommLosing,
		ai.ParentId,
		pai.Username AS ParentUsername		
	FROM 
		AgentInfo AS ai WITH (NOLOCK)
		INNER JOIN AgentInfo AS pai WITH (NOLOCK) ON ai.ParentId = pai.AgentId		 
	WHERE ai.AgentId = @AgentId
		
END	

