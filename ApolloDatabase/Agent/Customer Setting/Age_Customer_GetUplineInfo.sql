USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetUplineInfo]    Script Date: 9/10/2013 1:38:50 PM ******/
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
 * Task			: Get up line information
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

	;WITH Tree(AgentId, AgentLevel, AgentHId)
	AS
	(
		SELECT  
			AgentId,
			AgentLevel,
			@agentHId AS AgentHId 
		FROM AgentInfo WITH (NOLOCK)
		WHERE AgentId = @parentId

		UNION ALL

		SELECT  
			h.AgentId,
			CAST(h.AgentLevel AS SMALLINT) AS AgentLevel, 
			h.AgentHId        
		FROM 
			AgentInfo AS h WITH (NOLOCK)
			INNER JOIN Tree AS t ON	t.[AgentHId].GetAncestor(1) = h.AgentHId
		WHERE h.AgentLevel >= @AgentLevel
	)   

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
	WHERE ai.AgentId IN ( SELECT AgentId	FROM Tree )

END

