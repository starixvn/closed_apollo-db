USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetParentInfo]    Script Date: 5/6/2013 11:24:37 AM ******/
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

	SELECT
		pai.AgentId,
		pai.AgentLevel,
		pai.Username,
		pai.Currency,
		pai.Status,
		pai.BetStatus,
		pai.UplineStatus,
		pai.UplineBetStatus,
		pai.MatchLimit,
		pai.VirtualMultiplier,
		pai.DoubleCommLosing,
		pai.ParentId,
		gpai.Username AS ParentUsername
	FROM 
		AgentInfo AS ai WITH (NOLOCK)
		INNER JOIN AgentInfo AS pai WITH (NOLOCK) ON ai.ParentId = pai.AgentId
		INNER JOIN AgentInfo AS gpai WITH (NOLOCK) ON pai.ParentId = gpai.AgentId
	WHERE ai.AgentId = @AgentId
END
