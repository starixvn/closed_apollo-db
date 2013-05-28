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
	FROM Bettrans_Agent WITH(NOLOCK)
	WHERE bettype = 20000 and matchid = 0 and AgentID = 0
	
	SELECT @MoveBetsDay = MAX(eventdate)  
	FROM match14 WITH(NOLOCK)  
	

	SELECT @BalanceUpDay as BalanceUpDay, @MoveBetsDay as MoveBetsDay
END

GO
GRANT EXECUTE ON [dbo].[Age_SelBalanceUpDay] TO [aplWeb]
Go
---GRANT VIEW DEFINITION ON [dbo].[Age_SelBalanceUpDay] TO [vnteam]