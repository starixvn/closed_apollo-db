ALTER PROCEDURE  [dbo].[Age_SelBalanceUpDay]		
		
AS	
/*
Created: 20130319@Sophia
Task : Get move bet day, balanceup day
DB: SVRAGE.RepDB, SVRCSD.RepDB
Original:

Revisions:
   

Param's Explanation:
*/

SET NOCOUNT ON
BEGIN
	declare @BalanceUpDay smalldatetime, @MoveBetsDay smalldatetime

	SELECT TOP 1 @BalanceUpDay = winlostdate
	FROM Bettrans WITH(NOLOCK)
	WHERE bettype = 20000 and matchid = 0  
	
	SELECT @MoveBetsDay = MAX(eventdate)  
	FROM match14 WITH(NOLOCK)  
		
	IF @MoveBetsDay IS NULL SELECT @MoveBetsDay = '2013-05-01'
	IF @BalanceUpDay IS NULL SELECT @BalanceUpDay = '2013-05-01'

	SELECT @BalanceUpDay as BalanceUpDay, @MoveBetsDay as MoveBetsDay
END

GO
GRANT EXECUTE ON [dbo].[Age_SelBalanceUpDay] TO [aplWeb]
Go
---GRANT VIEW DEFINITION ON [dbo].[Age_SelBalanceUpDay] TO [vnteam]