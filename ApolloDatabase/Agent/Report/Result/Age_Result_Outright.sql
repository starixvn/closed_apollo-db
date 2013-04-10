
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
		league.sporttype, outright.leagueid, outright.eventdate, outright.teamid, 
		outright.status
	FROM         
		(SELECT leagueid, eventdate, teamid, status
		 FROM dbo.outright AS o1 with (nolock)
		 where oddsstatus = 'completed' and [status] IN ('WON','REFUND')
			and eventdate >= @FromDate and eventdate <= @ToDate
		 UNION ALL
		 SELECT leagueid, eventdate, teamid, status
		 FROM dbo.outright14 AS o14 with (nolock)
		 where oddsstatus = 'completed' and [status] IN ('WON','REFUND')
			and eventdate >= @FromDate and eventdate <= @ToDate
		) AS outright 
		 INNER JOIN dbo.league with (nolock) on outright.leagueid = league.leagueid
	WHERE (league.sporttype <=99 ) ---OR league.sporttype = 161)
		  and (league.isTest = 0 OR @isShowAll = 1)
	ORDER BY outright.leagueid,outright.eventdate, outright.teamid
	
	
GO
GRANT EXECUTE ON [dbo].[Age_Result_Outright] TO [aplweb]
GO
--GRANT VIEW DEFINITION ON [dbo].[Age_Result_Outright] TO vnteam