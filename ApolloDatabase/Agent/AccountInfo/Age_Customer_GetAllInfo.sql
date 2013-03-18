USE DB05
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetAllInfo]    Script Date: 3/18/2013 2:08:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- [Age_Customer_GetAllInfo] 3, 'testcs-3-4', false
-- [Age_Customer_GetAllInfo] 4, 6 ,'anders-tes-3-10', true

ALTER PROCEDURE [dbo].[Age_Customer_GetAllInfo]
	@CurrentAgentId INT = -1,
	@CustId INT = -1,
	@UserName VARCHAR(50) = null,
	@IsMember BIT = 0
AS

/**
 * Created by	: Quinn
 * Date			: 20130307
 * Task			: Retrieve value for left menu
 * DB			: APL.DB05
 * Revisions	:
 *	•
 * Parameters:
 *	@AgentId: agent ID
 *  @IsAgent: is agent or user
 */

SET NOCOUNT ON
DECLARE @ObjectId INT,
	@AgentLevel SMALLINT,
	-- @AgentHId HIERARCHYID,
	@ParentId INT,
	@ParentName VARCHAR(50),
	@HasAgentDownLine BIT = 0,
	@HasPlayerDownLine BIT = 0,
	@UGroup varchar(3),
	@Enable  BIT = 0

IF (@IsMember = 0)
BEGIN
	SELECT 
		@ObjectId = a.AgentId, 
		@UserName = a.Username,
		@AgentLevel = a.AgentLevel,
		@ParentId = b.AgentId,
		@ParentName = b.Username,
		@Enable = a.Enabled
	FROM 
	(	SELECT 
			AgentId,
			Username,
			AgentLevel,
			Enabled,
			ParentId  
		FROM AgentInfo WITH (NOLOCK) 
		WHERE 
		((@CustId = -1 AND Username = @UserName) OR (@CustId <> -1 AND AgentId = @CustId))
		AND AgentId <> @CurrentAgentId
		AND AgentHId.IsDescendantOf((SELECT AgentHId FROM AgentInfo WITH (NOLOCK) WHERE AgentId = @CurrentAgentId)) = 1
	) a
	INNER JOIN AgentInfo b WITH (NOLOCK) ON a.ParentId = b.AgentId
	
	IF (@ObjectId IS NULL) 
		RETURN

	IF(EXISTS (SELECT 1 FROM AgentInfo WITH (NOLOCK) WHERE ParentId = @ObjectId))
		SET @HasAgentDownLine = 1

	IF(EXISTS (SELECT 1 FROM CustInfo WITH (NOLOCK) WHERE AgentId = @ObjectId))
		SET @HasPlayerDownLine = 1

END
ELSE
BEGIN
	SELECT 
		@ObjectId = a.CustId,
		@UserName = a.Username,
		@ParentId = a.AgentId,
		@ParentName = b.Username,
		@UGroup = a.UGroup,
		@Enable = a.Enabled 
	FROM 
	(	SELECT 
			 CustId,
			 Username,
			 AgentId,
			 UGroup,
			 Enabled
		FROM CustInfo p WITH (NOLOCK) 
		WHERE 
			((@CustId = -1 AND Username = @UserName) OR (@CustId <> -1 AND CustId = @CustId))
			AND (SELECT AgentHId FROM AgentInfo WITH (NOLOCK) WHERE AgentId = p.AgentId).IsDescendantOf(
			(SELECT AgentHId FROM AgentInfo WITH (NOLOCK) WHERE AgentId = @CurrentAgentId)) = 1
	) a
	INNER JOIN AgentInfo b WITH (NOLOCK) ON a.AgentId = b.AgentId

	IF (@ObjectId IS NULL) 
		RETURN
END

SELECT 
		@IsMember AS IsMember,
		@ObjectId AS ObjectId, 
		@UserName AS UserName, 
		@AgentLevel AS AgentLevel,
		@ParentId as ParentId,
		@ParentName as ParentName,
		@HasAgentDownLine AS HasAgentDownLine, 
		@HasPlayerDownLine AS HasPlayerDownLine,
		@Enable as Enabled,
		@UGroup as UGroup

---- Retrive downline
