USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetAllInfo]    Script Date: 11/6/2014 2:41:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_GetAllInfo]
	@ActorAgentId	INT,
	@AgentId		INT				= -1,
	@Username		NVARCHAR(50)	= '',
	@ExcludeActor	BIT				= 0
AS

/**
 * Created by	: Quinn
 * Date			: 20130307
 * Task			: Get downline agent information by ID or Username
 * DB			: SVRAGE/RepDB
 * Revisions	:
 *	• 20141106@Sophia: Get BetStatus, Status, SportCredit 
 * Parameters:
 *	@ActorAgentId	: agent ID of login user
 *	@AgentId		: agent ID
 *  @Username		: username of Agent
 *	@ExcludeActor	: not get Actor
 */
 
BEGIN

SET NOCOUNT ON

	DECLARE @agentHId HIERARCHYID
	DECLARE @UplineStatus TINYINT, @UplineBetStatus TINYINT, @ParentId INT, @SportCredit MONEY

	SELECT	@ParentId = ParentId, @AgentId = AgentId
	FROM	dbo.AgentInfo WITH (NOLOCK) 
	WHERE	(AgentId = @AgentId OR Username = @Username)

	----- Upline Status
	SELECT @UplineStatus = dbo.f_GetAgentUplineStatusById(@ParentId)	
	SELECT @UplineBetStatus = dbo.f_GetAgentUplineBetStatusById(@ParentId) 

	----- Get Balance
	SELECT @SportCredit = ISNULL(Balance,0) FROM dbo.CreditBalance_Agent WITH (NOLOCK) WHERE AgentId = @AgentId 
	
	---- Check downline		
	SELECT	@agentHId = AgentHId, @ParentId = ParentId
	FROM	dbo.AgentInfo WITH (NOLOCK) 
	WHERE	AgentId = @ActorAgentId

	---- Get data
	SELECT 
		a.AgentId, 
		a.Username,
		a.AgentLevel,
		a.ParentId,
		b.Username AS ParentName,
		CASE 
			WHEN (EXISTS (SELECT 1 FROM AgentInfo WITH (NOLOCK) WHERE ParentId = a.AgentId)) THEN CAST(1 AS BIT) 
			ELSE CAST(0 AS BIT) 
		END AS HasAgentDownline,
		CASE 
			WHEN (EXISTS (SELECT 1 FROM CustInfo WITH (NOLOCK) WHERE AgentId = a.AgentId)) THEN CAST(1 AS BIT) 
			ELSE CAST(0 AS BIT) 
		END AS HasMemberDownline,
		@UplineStatus AS UplineStatus,
		@UplineBetStatus AS UplineBetStatus,
		CASE 
			WHEN a.Status = 1 THEN au.Status 
			ELSE a.Status 
			END AS [Status],
		a.BetStatus,
		@SportCredit AS SportCredit
	FROM AgentInfo AS a WITH (NOLOCK) 
		INNER JOIN AgentInfo AS b WITH (NOLOCK) 
				ON a.ParentId = b.AgentId		
		INNER JOIN dbo.AgentUser AS au WITH (NOLOCK) 
				ON (a.AgentId = au.AgentId AND au.IsMaster = 1)	
	WHERE 
		(a.AgentId = @AgentId OR a.Username = @Username)
		AND (@ExcludeActor = 0 OR a.AgentId <> @ActorAgentId)
		AND a.AgentHId.IsDescendantOf(@agentHId) = 1

END
GO
GRANT EXECUTE ON [Age_Agent_GetAllInfo] TO [aplweb]
GO