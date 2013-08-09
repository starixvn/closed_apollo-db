USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_CheckBelongToUplines]    Script Date: 8/9/2013 2:54:58 PM ******/
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
	DECLARE @UplineUsernames NVARCHAR(1000) = 'age-ed--0-206,a3,5000,402'

	-- Hard code allow super can sso
	IF @Username = 'super'
		BEGIN
			SET @Allowed = 1

			RETURN
		END

	IF EXISTS (	SELECT ai.Username
				FROM 
					AgentInfo AS ai WITH (NOLOCK)
					INNER JOIN AgentInfo AS cai WITH (NOLOCK) ON ai.AgentHId.IsDescendantOf(cai.AgentHId) = 1
				WHERE 
					ai.Username = @Username
					AND cai.Username IN (SELECT val FROM dbo.[StrSplit](@UplineUsernames, ',')) )
		SET @Allowed = 1
	ELSE
		SET @Allowed = 0
END
