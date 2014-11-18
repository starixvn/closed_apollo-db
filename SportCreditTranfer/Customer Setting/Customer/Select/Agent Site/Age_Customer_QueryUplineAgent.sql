USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_QueryUplineAgent]    Script Date: 8/8/2013 1:37:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_QueryUplineAgent]
	@AgentLevel		SMALLINT
	,@CustId		INT
AS

/**
 * Created by	: Edward.Nguyen
 * Date			: 20130208
 * Task			: Get agent info by level
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

	DECLARE 
		@AgentId	INT				= NULL
		,@Username	NVARCHAR(50)	= NULL

	SELECT TOP(1) 
		@AgentId = cai.AgentId
		,@Username = cai.Username
	FROM 
		CustInfo AS ci WITH (NOLOCK)
		INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON ci.AgentId = ai.AgentId
		INNER JOIN AgentInfo AS cai WITH (NOLOCK) ON ai.AgentHId.IsDescendantOf(cai.AgentHId) = 1
	WHERE ci.CustId = @CustId AND cai.AgentLevel = @AgentLevel
		
	IF @AgentId IS NULL OR @Username IS NULL
		SELECT NULL
	ELSE
		SELECT 
			@AgentId AS AgentId, 
			@Username AS Username
	
END
