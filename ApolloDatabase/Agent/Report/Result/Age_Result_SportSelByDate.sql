
ALTER PROCEDURE [dbo].[Age_Result_SportSelByDate]
	@EventDate DATETIME
AS
/*
Created: Sophia
Date: 20130401
Task: 
DB: SVRAGE.RepDB
Original: Age_Result_SportSelByDate
Revision:
	
*/

SET NOCOUNT ON

DECLARE @toDate		DATETIME,
		@matchcode	VARCHAR(10)  

SELECT @toDate = DATEADD(s,-1, DATEADD(d, 1, @EventDate))

SELECT DISTINCT sports.sporttype, sportname 
FROM sports WITH (NOLOCK) 
INNER JOIN (	SELECT matchid, eventdate, eventstatus, sporttype
										FROM match (nolock)
										UNION ALL
										SELECT matchid, eventdate, eventstatus, sporttype
										FROM match14 (nolock)
									  ) match ON match.sporttype = sports.sporttype
LEFT JOIN match_remark mr ON match.matchid = mr.matchid									  
WHERE 
	match.eventdate >= @EventDate
	AND match.eventdate <= @toDate
	AND ( match.eventstatus NOT IN ('internal','closed','running')
			OR ( mr.IsPending=1 AND match.eventstatus IN ('running','closed') )
			OR ( mr.IsHTCal = 1 AND match.eventstatus ='running')
		 )
	AND (sports.sporttype <= 99 ) ---- OR sports.sporttype = 161)  
	
GO
GRANT EXECUTE ON [dbo].Age_Result_SportSelByDate TO aplweb
GO
 

 