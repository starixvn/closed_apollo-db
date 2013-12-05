USE [RepDB]
GO
IF EXISTS (SELECT TOP 1 1 FROM sys.objects WHERE type = 'P' AND name = 'Age_Customer_GetInfo')
	DROP PROC dbo.Age_Customer_GetInfo
GO
CREATE PROCEDURE [dbo].[Age_Customer_GetInfo]
(
	@CustId		INT
)
AS

/**
 * Created by	: Kos
 * Date			: 20130305
 * Task			: Get customer information
 * DB			: SVRAGE/RepDB
 * Test string:
		exec [dbo].[Age_Customer_GetInfo] 567059

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
		dbo.f_Customer_GetSportCreditById(@CustId) AS SoprtCredit,
		ai.Username AS AgentUsername,
		AgentLevel AS AgentLevel
	FROM dbo.CustInfo AS ci WITH (NOLOCK)
	INNER JOIN dbo.AgentInfo AS ai WITH (NOLOCK) ON ci.AgentId = ai.AgentId
	WHERE CustId = @CustId
		
END

GO
GRANT EXECUTE ON [dbo].[Age_Agent_GetInfo] TO [aplweb]
GO

