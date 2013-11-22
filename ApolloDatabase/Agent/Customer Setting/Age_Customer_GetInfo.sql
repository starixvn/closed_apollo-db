USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetInfo]    Script Date: 11/22/2013 2:43:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[Age_Customer_GetInfo]
	@CustId		INT
AS

/**
 * Created by	: Kos
 * Date			: 20130305
 * Task			: Get customer information
 * DB			: SVRAGE/RepDB
 * Test string:
		exec [dbo].[Age_Customer_GetInfo] 567059
		exec [dbo].[Age_Customer_GetInfo_xtest] 567059
 * Revisions	:
 *	• @20130412	: Add statuses
 *  • 20131119@Patick	: change method get UplineStatus & UplineBetStatus
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON	

	SELECT 
		ci.CustId,
		ci.Username,
		ci.Currency,
		ci.Status,
		ci.BetStatus,
		dbo.f_GetAgentUplineStatusById(ci.AgentId)  AS 'UplineStatus',
		dbo.f_GetAgentUplineBetStatusById(ci.AgentId) AS 'UplineBetStatus',
		ci.MatchLimit,
		ci.VirtualMultiplier,
		ci.Danger,
		ci.CreateDate,
		ci.Creator,
		ci.LastLogged,
		ci.IPLogin,
		ci.UGroup,
		ci.DoubleCommLosing,
		ci.AgentId,
		ci.IsUGroupChanged,
		ai.Username AS AgentUsername,
		AgentLevel AS AgentLevel
	FROM CustInfo AS ci WITH (NOLOCK)
		INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON ci.AgentId = ai.AgentId
	WHERE CustId = @CustId
		
END
