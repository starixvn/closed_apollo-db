USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_CheckBelongToUplinesForAgent]    Script Date: 9/16/2013 10:44:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Age_Agent_CheckBelongToUplinesForAgent]
	@Username	NVARCHAR(50),
	@Allowed	BIT				= 0		OUTPUT	
AS

/**
 * Created by	: Edward.Nguyen
 * Date			: 20130208
 * Task			: Check agent is belong to up line username
 * DB			: SVRAGE.RepDB
 * Revisions	: 
 *  
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	SET NOCOUNT ON
	-- Hard code allow user can sso from sungame to agentsite
	DECLARE @UplineUsernames NVARCHAR(1000) = '401,40222,613'

	DECLARE @TableAgent TABLE (
		Username	NVARCHAR(50),
		AgentId		INT, 
		AgentHId	HIERARCHYID)

	INSERT INTO @TableAgent (
		Username,
		AgentId,
		AgentHId)
	SELECT 
		Username,
		AgentId,
		AgentHId
	FROM 
		dbo.[StrSplit](@UplineUsernames, ',') AS t
		INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON ai.Username = t.val

	IF @@ROWCOUNT = 0
		BEGIN 
			SET @Allowed = 0
			RETURN
		END

	IF EXISTS (	SELECT 1
				FROM 
					AgentInfo AS ai WITH (NOLOCK)
					INNER JOIN @TableAgent AS ta 
						ON ta.AgentHId.IsDescendantOf(ai.AgentHId) = 1
						OR	ai.AgentHId.IsDescendantOf(ta.AgentHId) = 1
				WHERE ai.Username = @Username
					
				UNION

				SELECT 1
				FROM 
					AgentInfo AS ai WITH (NOLOCK)					
					INNER JOIN AgentUser AS au WITH (NOLOCK) ON ai.AgentId = au.AgentId						
					INNER JOIN @TableAgent AS ta 
						ON ta.AgentHId.IsDescendantOf(ai.AgentHId) = 1
						OR	ai.AgentHId.IsDescendantOf(ta.AgentHId) = 1
				WHERE au.Username = @Username )
		SET @Allowed = 1
	ELSE
		SET @Allowed = 0
END

