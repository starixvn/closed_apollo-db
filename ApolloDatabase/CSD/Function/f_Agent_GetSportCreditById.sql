USE [RepDB]
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE TYPE = 'FN' AND name = 'f_Agent_GetSportCreditById')
	DROP FUNCTION [dbo].[f_Agent_GetSportCreditById]
GO
CREATE FUNCTION [dbo].[f_Agent_GetSportCreditById]
(
	 @AgentId INT
)
RETURNS MONEY
AS
/*
* Created by	: Patrick
* Date			: 20131119
* Task			: Get upline status by agent id
* DB			: SVRCSD/RepDB
* Parameters:
*	output		: 1 is active
				: 2: is stop
* Test string:
	select dbo.f_Agent_GetSportCreditById(107086)

* Revisions	:

*/
BEGIN
	DECLARE @SoprtCredit MONEY
	SELECT @SoprtCredit = ISNULL(SUM(a.Winlost - a.Actual_Stake + a.PlayerComm), 0)
	FROM dbo.Bettrans a WITH (NOLOCK)
	INNER JOIN dbo.CustInfo b WITH (NOLOCK) ON (a.CustId = b.CustId)
	WHERE b.AgentId = @AgentId
	RETURN @SoprtCredit
END
GO
