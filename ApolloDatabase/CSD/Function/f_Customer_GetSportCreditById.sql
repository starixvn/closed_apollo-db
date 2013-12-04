USE [RepDB]
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE TYPE = 'FN' AND name = 'f_Customer_GetSportCreditById')
	DROP FUNCTION [dbo].[f_Customer_GetSportCreditById]
GO
CREATE FUNCTION [dbo].[f_Customer_GetSportCreditById]
(
	 @CustId INT
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
	select dbo.f_Customer_GetSportCreditById(107086)

* Revisions	:

*/
BEGIN
	DECLARE @SoprtCredit MONEY
	SELECT @SoprtCredit = ISNULL(SUM(a.Winlost - a.Actual_Stake + a.PlayerComm), 0)
	FROM dbo.Bettrans a WITH (NOLOCK)
	WHERE a.CustId = @CustId
	RETURN @SoprtCredit
END
GO
