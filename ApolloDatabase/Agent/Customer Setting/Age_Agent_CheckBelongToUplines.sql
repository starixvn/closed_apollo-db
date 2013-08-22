USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_CheckBelongToUplines]    Script Date: 8/15/2013 1:46:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_CheckBelongToUplines]
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
	DECLARE @UplineUsernames NVARCHAR(1000) = '401s,40222,613'

	IF EXISTS (	SELECT 1
				FROM 
					AgentInfo AS ai WITH (NOLOCK)
					INNER JOIN AgentUser AS au WITH (NOLOCK) ON ai.AgentId = au.AgentId						
					INNER JOIN AgentInfo AS pai WITH (NOLOCK) ON pai.AgentHId.IsDescendantOf(ai.AgentHId) = 1					
				WHERE 
					(ai.Username = @Username OR au.Username = @Username)
					AND pai.Username IN (SELECT val FROM dbo.[StrSplit](@UplineUsernames, ','))
					
				UNION

				SELECT 1
				FROM 
					AgentInfo AS ai WITH (NOLOCK)					
					INNER JOIN AgentUser AS au WITH (NOLOCK) ON ai.AgentId = au.AgentId						
					INNER JOIN AgentInfo AS cai WITH (NOLOCK) ON ai.AgentHId.IsDescendantOf(cai.AgentHId) = 1
				WHERE 
					(ai.Username = @Username OR au.Username = @Username)
					AND cai.Username IN (SELECT val FROM dbo.[StrSplit](@UplineUsernames, ','))					)
		SET @Allowed = 1
	ELSE
		SET @Allowed = 0
END
