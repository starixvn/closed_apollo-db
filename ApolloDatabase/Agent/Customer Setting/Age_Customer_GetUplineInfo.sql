USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetUplineInfo]    Script Date: 5/6/2013 11:30:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_GetUplineInfo]
	@CurrentAgentId		INT,
	@CustId				INT
AS

/**
 * Created by	: Edward
 * Date			: 20130304
 * Task			: Get upline information
 * DB			: SVRCUST.CustDB
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
	DECLARE @AgentLevel	SMALLINT
	DECLARE @parentId	INT

	---- Get parent id
	SELECT @parentId = AgentId
	FROM CustInfo WITH (NOLOCK)
	WHERE CustId = @CustId

	---- Get agent hierarchy ID
	SELECT @agentHId = AgentHId
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @parentId

	---- Get current agent level
	SELECT @AgentLevel = AgentLevel
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @CurrentAgentId

	---- Get parent information
	SELECT 
		ai.AgentId,
		ai.AgentLevel,
		ai.Username,
		ai.Currency,
		ai.AutoSuspend,
		ai.MatchLimit,
		ai.VirtualMultiplier,
		ai.DoubleCommLosing,
		ai.Status,
		ai.BetStatus,
		ai.UplineStatus,
		ai.UplineBetStatus,
		ai.ParentId,
		ap.Username				AS ParentUsername
	FROM 
		AgentInfo AS ai WITH (NOLOCK)
		INNER JOIN AgentInfo AS ap WITH (NOLOCK) ON ai.ParentId = ap.AgentId
	WHERE ai.AgentId IN (	SELECT AgentId 
							FROM AgentInfo WITH (NOLOCK)
							WHERE 
								@AgentHId.IsDescendantOf(AgentHId) = 1 
								AND AgentLevel >= @AgentLevel )

END

