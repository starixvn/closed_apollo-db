USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetInfo]    Script Date: 3/29/2013 9:57:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Age_Agent_GetInfo]
	@AgentId	INT	
AS

/**
 * Created by	: Kos
 * Date			: 20130305
 * Task			: Get agent information
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

	SELECT 
		AgentHId,
		AgentLevel,
		Username,
		Currency,
		ParentId,
		AutoSuspend,
		Suspended,
		Credit,
		Closed,
		MatchLimit,
		VirtualMultiplier,
		Enabled,
		DoubleCommLosing		
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @AgentId
		
END	

