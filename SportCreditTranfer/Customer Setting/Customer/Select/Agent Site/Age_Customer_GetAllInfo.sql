USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetAllInfo]    Script Date: 11/6/2014 2:41:47 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_GetAllInfo]
	@ActorAgentId	INT,
	@CustId			INT				= -1,
	@Username		NVARCHAR(50)	= ''
AS

/**
 * Created by	: Quinn
 * Date			: 20130307
 * Task			: Get downline customer information by ID or Username
 * DB			: SVRAGE/RepDB
 * Revisions	:
 *	• 20141106@Sophia: Get BetStatus, Status, CashBalance 
 * Parameters:
 *	@ActorAgentId	: AgentId of login user
 *	@CustId			: Customer ID
 *  @UserName		: Username of Agent
 */

BEGIN

	SET NOCOUNT ON

	DECLARE @agentHId HIERARCHYID, @AgentId INT
	DECLARE @UplineStatus TINYINT, @UplineBetStatus TINYINT, @CashBalance MONEY

	
	SELECT	@AgentId = AgentID, @CustId = CustId 
	FROM	dbo.CustInfo WITH (NOLOCK) 	
	WHERE	CustId = @CustId OR Username = @Username

	----- Upline Status
	SELECT	@UplineStatus = dbo.f_GetAgentUplineStatusById(@AgentId)
	SELECT	@UplineBetStatus = dbo.f_GetAgentUplineBetStatusById(@AgentId) 

	
	----- Get Balance
	SELECT  @CashBalance = SUM(ISNULL(b.Winlost, 0) - ISNULL(b.Actual_Stake, 0) + ISNULL(b.PlayerComm, 0)) 
	FROM	dbo.Bettrans b WITH (NOLOCK)
	WHERE	b.CustId = @CustId

	---- Check downline
	SELECT	@agentHId = AgentHId 
	FROM	dbo.AgentInfo WITH (NOLOCK) 
	WHERE	AgentId = @ActorAgentId

	-- Get data
	SELECT 
		a.CustId,
		a.Username,
		a.AgentId,
		b.Username AS ParentName,
		a.UGroup,
		a.Status, 
		a.BetStatus, 
		@UplineStatus AS UplineStatus, 
		@UplineBetStatus AS UplineBetStatus,
		@CashBalance AS CashBalance
	FROM 
		dbo.CustInfo AS a WITH (NOLOCK) 
		INNER JOIN dbo.AgentInfo AS b WITH (NOLOCK) ON a.AgentId = b.AgentId
	WHERE 
		(a.CustId = @CustId OR a.Username = @Username)
		AND b.AgentHId.IsDescendantOf(@agentHId) = 1

END
GO 
GRANT EXECUTE ON [dbo].[Age_Customer_GetAllInfo] TO [aplweb]
GO