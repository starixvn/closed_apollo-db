USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetAgentDownlinePath]    Script Date: 5/20/2013 2:16:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Age_Agent_GetCustomerDownlinePath]
	@ParentId INT,
	@CustId INT
AS

/**
 * Created by	: Kos
 * Date			: 20130520
 * Task			: Retrieve list agent in relationship between parent agent and customer
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	•
 * Parameters:
 *	@ParentId	: agent ID from
 *	@CustId		: customer ID to
 */

SET NOCOUNT ON

DECLARE 
	@agentHId HIERARCHYID,
	@parentHId HIERARCHYID

SELECT @agentHId = ai.AgentHId 
FROM 
	CustInfo AS ci WITH (NOLOCK) 
	INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON ci.AgentId = ai.AgentId
WHERE ci.CustId = @CustId

SELECT @parentHId = AgentHId 
FROM AgentInfo WITH (NOLOCK) 
WHERE AgentId = @ParentId

SELECT * 
FROM
	(
		SELECT 
			AgentId, 
			Username,
			AgentLevel,
			ParentId
		FROM AgentInfo WITH (NOLOCK) 
		WHERE 
			AgentHId.IsDescendantOf(@parentHId) = 1
			AND @agentHId.IsDescendantOf(AgentHId) = 1

		UNION ALL 

		SELECT 
			CustId AS AgentId, 
			Username,
			999 AS AgentLevel,
			AgentId AS ParentId
		FROM CustInfo WITH (NOLOCK) 
		WHERE CustId = @CustId
	) AS a
ORDER BY a.AgentLevel
