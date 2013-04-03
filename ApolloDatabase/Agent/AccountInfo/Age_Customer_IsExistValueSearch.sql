USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_IsExistValueSearch]    Script Date: 4/3/2013 5:29:37 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- [Age_Customer_GetAllInfo] 3, -1,'dfdfdsf', false
-- [Age_Customer_GetAllInfo] 3, -1 ,'testcs-14-1', true

ALTER PROCEDURE [dbo].[Age_Customer_IsExistValueSearch]
	@CurrentAgentId INT = -1,
	@CustId INT = -1,
	@UserName VARCHAR(50) = null,
	@IsMember BIT = 0
AS

/**
 * Created by	: Quinn
 * Date			: 20130307
 * Task			: Check has value return
 * DB			: APL.DB05
 * Revisions	:
 *	•
 * Parameters:
 *	@AgentId: agent ID
 *  @IsMember: is agent or user
 */

SET NOCOUNT ON
IF (@IsMember = 0)
BEGIN
	SELECT 
		CASE WHEN (EXISTS (
			SELECT 
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
			)) 
		THEN CAST(1 AS BIT) 
		ELSE CAST(0 AS BIT) END AS Value
END
ELSE
BEGIN
	SELECT
		CASE WHEN (EXISTS (
				SELECT 
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
				)) 
			THEN CAST(1 AS BIT) 
			ELSE CAST(0 AS BIT) END AS Value
END


