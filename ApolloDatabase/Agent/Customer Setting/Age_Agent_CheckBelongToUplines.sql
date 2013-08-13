USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_CheckBelongToUplines]    Script Date: 8/13/2013 10:52:45 AM ******/
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
	DECLARE @UplineUsernames	NVARCHAR(1000)	= '401s,40222,613'
			,@SUPERLVEL			SMALLINT		= 0
	-- Hard code allow super can sso
	IF @Username = 'super'
		BEGIN
			SET @Allowed = 1

			RETURN
		END

	IF EXISTS (	SELECT ai.Username
				FROM 
					AgentInfo AS ai WITH (NOLOCK)
					INNER JOIN AgentInfo AS pai WITH (NOLOCK) 
						ON pai.AgentHId.IsDescendantOf(ai.AgentHId) = 1
						AND ai.AgentLevel	> @SUPERLVEL					
				WHERE pai.Username IN (SELECT val FROM dbo.[StrSplit](@UplineUsernames, ','))						 
						AND ai.Username = @Username
				UNION
				SELECT ai.Username
				FROM 
					AgentInfo AS ai WITH (NOLOCK)
					INNER JOIN AgentInfo AS cai WITH (NOLOCK)
						ON ai.AgentHId.IsDescendantOf(cai.AgentHId) = 1					
				WHERE cai.Username IN (SELECT val FROM dbo.[StrSplit](@UplineUsernames, ','))
					AND ai.Username = @Username)
		SET @Allowed = 1
	ELSE
		SET @Allowed = 0
END
