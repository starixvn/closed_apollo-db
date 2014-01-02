ALTER PROCEDURE [dbo].[Age_Agent_CheckUpdatePermission]
	@ActorAgentId		INT,
	@ObjectId			INT,
	@ObjectTypeId		INT,
	@HasPermission		BIT		OUTPUT
AS

/**
 * Created by	: Edward
 * Date			: 20130328
 * Task			: Check permission update of agent
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

	SET @HasPermission = 0

	DECLARE @agentHId	HIERARCHYID

	SELECT @agentHId = AgentHId 
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @ActorAgentId

	IF @ObjectTypeId = 1	-- Agent
		BEGIN
			
			IF EXISTS (	SELECT 1
						FROM AgentInfo WITH (NOLOCK)
						WHERE 
							AgentHId.IsDescendantOf(@agentHId) = 1
							AND AgentId <> @ActorAgentId
							AND AgentId = @ObjectId )
				SET @HasPermission = 1

			RETURN
		END

	IF @ObjectTypeId = 2	-- Customer
		BEGIN
			IF EXISTS (	SELECT 1
						FROM CustInfo WITH (NOLOCK)
						WHERE 
							CustId = @ObjectId
							AND AgentId IN (	SELECT AgentId
												FROM AgentInfo WITH (NOLOCK)
												WHERE AgentHId.IsDescendantOf(@agentHId) = 1 ) )
				SET @HasPermission = 1

			RETURN
		END
END

