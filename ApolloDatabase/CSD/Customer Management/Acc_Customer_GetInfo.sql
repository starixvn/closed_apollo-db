USE [RepDB]
GO
IF EXISTS (SELECT TOP 1 1 FROM sys.objects WHERE type = 'P' AND name = 'Acc_Customer_GetInfo')
	DROP PROC dbo.Acc_Customer_GetInfo
GO
CREATE PROCEDURE [dbo].[Acc_Customer_GetInfo]
(
	@CustId INT
	, @Username NVARCHAR(50) = null
)
AS

/**
 * Created by	: Kos
 * Date			: 20130305
 * Task			: Get customer information
 * DB			: SVRAGE/RepDB
 * Revisions	:
 *	• @20130412	: Add statuses
 *  • 20131119@Patrick	: change method get UplineStatus & UplineBetStatus
 *  • 20131205@Patrick	: Add more field: SportCredit
 * Parameters:
 *	•
 * Test string:
		exec [dbo].[Acc_Customer_GetInfo] null, '621m1'
		exec [dbo].[Acc_Customer_GetInfo] 103, null
 */

BEGIN
	
	SET NOCOUNT ON	
	IF @CustId IS NOT NULL -- for case search by id
	BEGIN
		SELECT ci.CustId, ci.Username, ci.[Status], ci.BetStatus, ci.AgentId
			, (SELECT TOP(1) Currency FROM dbo.Exchange WHERE exchangeid = ci.Currency) AS Currency
			, dbo.f_GetAgentUplineStatusById(ci.AgentId)  AS 'UplineStatus'
			, dbo.f_GetAgentUplineBetStatusById(ci.AgentId) AS 'UplineBetStatus'
			, ISNULL(SUM(bt.Winlost - bt.Actual_Stake + bt.PlayerComm), 0) AS SportCredit
			, ai.Username AS AgentUsername, AgentLevel AS AgentLevel
		FROM dbo.CustInfo AS ci WITH (NOLOCK)
		INNER JOIN dbo.AgentInfo AS ai WITH (NOLOCK) ON ci.AgentId = ai.AgentId
		INNER JOIN dbo.BetTrans AS bt WITH(NOLOCK) ON ci.CustId = bt.CustId
		WHERE ci.CustId = @CustId
		GROUP BY ci.CustId, ci.Username, ci.[Status], ci.BetStatus, ci.AgentId, ci.Currency, ai.Username, AgentLevel
	END
	ELSE -- for case search by username
	BEGIN
		SELECT ci.CustId, ci.Username, ci.[Status], ci.BetStatus, ci.AgentId
			, (SELECT TOP(1) Currency FROM dbo.Exchange WHERE exchangeid = ci.Currency) AS Currency
			, dbo.f_GetAgentUplineStatusById(ci.AgentId)  AS 'UplineStatus'
			, dbo.f_GetAgentUplineBetStatusById(ci.AgentId) AS 'UplineBetStatus'
			, ISNULL(SUM(bt.Winlost - bt.Actual_Stake + bt.PlayerComm), 0) AS SportCredit
			, ai.Username AS AgentUsername, AgentLevel AS AgentLevel
		FROM dbo.CustInfo AS ci WITH (NOLOCK)
		INNER JOIN dbo.AgentInfo AS ai WITH (NOLOCK) ON ci.AgentId = ai.AgentId
		INNER JOIN dbo.BetTrans AS bt WITH(NOLOCK) ON ci.CustId = bt.CustId
		WHERE ci.Username = @Username
		GROUP BY ci.CustId, ci.Username, ci.[Status], ci.BetStatus, ci.AgentId, ci.Currency, ai.Username, AgentLevel
	END
END

GO
GRANT EXECUTE ON [dbo].[Acc_Customer_GetInfo] TO [aplweb]
GO

