USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Acc_Customer_GetInfo]    Script Date: 1/6/2014 3:03:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Acc_Customer_GetInfo]
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
 *  • 20131119@Patrick	: Change method get UplineStatus & UplineBetStatus
 *  • 20131205@Patrick	: Add more field: SportCredit
 *	• 20140106@Patrick	: Return more field AgentStatus
 * Parameters:
 *	•
 * Test string:
		exec [dbo].[Acc_Customer_GetInfo] null, '621m1'
		exec [dbo].[Acc_Customer_GetInfo] 103, null
 */

BEGIN
	
	SET NOCOUNT ON	

	DECLARE @SoprtCredit MONEY = 0
	IF @CustId IS NULL
	BEGIN
		SELECT @CustId = CustId FROM dbo.CustInfo WITH (NOLOCK) WHERE Username = @Username
	END
	
	--Get sport credit
	SELECT @SoprtCredit = ISNULL(SUM(a.Winlost - a.Actual_Stake + a.PlayerComm), 0)
	FROM dbo.Bettrans a WITH (NOLOCK)
	WHERE a.CustId = @CustId

	SELECT ci.CustId, ci.Username, ci.[Status], ci.BetStatus, ci.AgentId
		, (SELECT TOP(1) Currency FROM dbo.Exchange WHERE exchangeid = ci.Currency) AS Currency
		, dbo.f_GetAgentUplineStatusById(ci.AgentId)  AS 'UplineStatus'
		, dbo.f_GetAgentUplineBetStatusById(ci.AgentId) AS 'UplineBetStatus'
		, @SoprtCredit AS SportCredit
		, ai.Username AS AgentUsername, AgentLevel AS AgentLevel
		, IIF(ai.[Status] = 1, (SELECT TOP 1 [Status] FROM dbo.AgentUser WITH (NOLOCK) WHERE AgentId = ai.AgentId AND IsMaster = 1), ai.[Status]) AS [AgentStatus]
	FROM dbo.CustInfo AS ci WITH (NOLOCK)
	INNER JOIN dbo.AgentInfo AS ai WITH (NOLOCK) ON ci.AgentId = ai.AgentId
	WHERE ci.CustId = @CustId
	
END

