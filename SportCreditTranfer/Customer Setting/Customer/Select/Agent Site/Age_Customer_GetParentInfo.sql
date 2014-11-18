USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetParentInfo]    Script Date: 5/6/2013 11:16:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_GetParentInfo]
	@CustId		INT	
AS

/**
 * Created by	: Edward
 * Date			: 20130304
 * Task			: Get parent information
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	•	
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON

	SELECT 
		ai.AgentId,
		ai.AgentLevel,
		ai.Username,
		ai.Currency,
		ai.Status,
		ai.BetStatus,
		ai.UplineStatus,
		ai.UplineBetStatus,
		ai.MatchLimit,
		ai.VirtualMultiplier,
		ai.DoubleCommLosing,
		ai.ParentId,
		pai.Username AS ParentUsername
	FROM 
		CustInfo AS ci WITH (NOLOCK)
		INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON ci.AgentId = ai.AgentId
		INNER JOIN AgentInfo AS pai WITH (NOLOCK) ON ai.ParentId = pai.AgentId
	WHERE ci.CustId = @CustId
END

