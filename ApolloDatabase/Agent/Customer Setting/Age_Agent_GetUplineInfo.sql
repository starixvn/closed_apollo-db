USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetUplineInfo]    Script Date: 3/29/2013 9:59:02 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Age_Agent_GetUplineInfo]
	@CurrentAgentId		INT,
	@AgentId			INT	
AS

/**
 * Created by	: Edward
 * Date			: 20130304
 * Task			: Get upline information
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
	
	DECLARE @agentHId	HIERARCHYID
	DECLARE @AgentLevel	INT

	-- Get agent hierarchy ID
	SELECT @agentHId = AgentHId
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @AgentId

	-- Get current agent level
	SELECT @AgentLevel = AgentLevel
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @CurrentAgentId

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
	WHERE ai.AgentId IN (	SELECT AgentId 
							FROM AgentInfo 
							WHERE @AgentHId.IsDescendantOf(AgentHId) = 1 AND AgentLevel >= @AgentLevel )		  

END
