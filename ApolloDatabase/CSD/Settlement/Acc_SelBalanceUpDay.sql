CREATE PROCEDURE  [dbo].[Acc_SelBalanceUpDay]		
		
AS	
/**
 * Created by	: Kaden
 * Date			: 20130318
 * Task			: Get move bet day, balanceup day
 * DB			: APL.RepDB
 * Revisions	:
 *	•
 * Parameters:
 */

SET NOCOUNT ON
BEGIN
	DECLARE @BalanceUpDay SMALLDATETIME , @MoveBetsDay SMALLDATETIME
	SELECT 
		TOP 1 @BalanceUpDay = winlostdate
	FROM Bettrans WITH(NOLOCK)
	WHERE bettype = 20000 AND matchid = 0	AND custid = 3
	
	SELECT    
		@MoveBetsDay = MAX(eventdate)  
	FROM match14 WITH(NOLOCK)  

	SELECT @BalanceUpDay AS BalanceUpDay, @MoveBetsDay AS MoveBetsDay
END
GRANT EXECUTE ON [dbo].[Acc_SelBalanceUpDay] TO [aplweb]	
