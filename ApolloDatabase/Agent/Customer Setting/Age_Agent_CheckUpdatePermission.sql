USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_CheckUpdatePermission]    Script Date: 3/29/2013 10:07:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_Agent_CheckUpdatePermission]
	@ActorAgentId		INT,			
	@ObjectId			INT,	
	@ObjectTypeId		INT,
	@HasPermission		BIT		OUTPUT
AS

/**
 * Created by	: Edward
 * Date			: 20130328
 * Task			: Check permission update of agents
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

	SET @HasPermission = 0

	DECLARE @agentHId	HIERARCHYID

	SELECT @agentHId = AgentHId 
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @ActorAgentId

	IF @ObjectTypeId = 1	-- Agent
		BEGIN
			
			IF EXISTS (
				SELECT *
				FROM AgentInfo AS ai WITH (NOLOCK)
				WHERE ai.AgentHId.IsDescendantOf(@agentHId) = 1
				AND ai.AgentId	<> @ActorAgentId
			)
				SET @HasPermission = 1		

			RETURN
		END

	IF @ObjectTypeId = 2	-- Cust
		BEGIN
			IF EXISTS (
				SELECT *
				FROM CustInfo AS ci WITH (NOLOCK)
				WHERE ci.AgentId IN (
					SELECT ai.AgentId
					FROM AgentInfo AS ai WITH (NOLOCK)
					WHERE ai.AgentHId.IsDescendantOf(@agentHId) = 1
				)
					AND ci.CustId	= @ObjectId
			)
				SET @HasPermission = 1

			RETURN
		END
END	
