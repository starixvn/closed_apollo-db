
ALTER PROCEDURE [dbo].[Age_Result_Outright]
	@FromDate DATETIME,
	@ToDate DATETIME,
	@isShowAll bit = 1 -- 1: Show All; 0: is NOT show Test	
AS 

/*
Created:  Sophia
Date: 20130401
Task: Get Result Outright  
DB: SVRAGE.REPDB
Original: Age_Result_Outright

Revisions:    
 
*/
SET NOCOUNT ON 
 

SELECT DISTINCT 
       league.sporttype,
       outright.leagueid,
       outright.eventdate,
       outright.teamid,
       outright.status
FROM   (
           SELECT leagueid,
                  eventdate,
                  teamid,
                  STATUS
           FROM   dbo.outright AS o1 WITH (NOLOCK)
           WHERE  oddsstatus = 'completed'
                  AND [status] IN ('WON', 'REFUND')
                  AND eventdate >= @FromDate
                  AND eventdate <= @ToDate
           UNION ALL
           SELECT leagueid,
                  eventdate,
                  teamid,
                  STATUS
           FROM   dbo.outright14 AS o14 WITH (NOLOCK)
           WHERE  oddsstatus = 'completed'
                  AND [status] IN ('WON', 'REFUND')
                  AND eventdate >= @FromDate
                  AND eventdate <= @ToDate
       ) AS outright
       INNER JOIN dbo.league WITH (NOLOCK)
            ON  outright.leagueid = league.leagueid
WHERE  (league.sporttype <= 99) ---OR league.sporttype = 161)
       AND (league.isTest = 0 OR @isShowAll = 1)
ORDER BY
       outright.leagueid,
       outright.eventdate,
       outright.teamid
	
	
GO
GRANT EXECUTE ON [dbo].[Age_Result_Outright] TO [aplweb]
GO
--GRANT VIEW DEFINITION ON [dbo].[Age_Result_Outright] TO vnteam