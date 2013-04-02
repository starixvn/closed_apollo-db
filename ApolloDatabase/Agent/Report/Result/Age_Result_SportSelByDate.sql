
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
FROM sports WITH (nolock) INNER JOIN (	SELECT matchid, eventdate, eventstatus, sporttype
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
	AND (sports.sporttype <= 99 OR sports.sporttype = 161)  
	
--UNION ALL

--SELECT s.sporttype, s.sportname
--FROM (
--		SELECT ROW_NUMBER() OVER (PARTITION BY sporttype ORDER BY l.leagueid) AS RowNumber, l.sporttype, l.leagueid
--		FROM league l with (nolock) 
--			INNER JOIN
--				(	SELECT leagueid, oddsstatus, eventdate FROM outright WITH (nolock)
--					WHERE eventdate >= @EventDate and eventdate <= @toDate
--					UNION ALL
--					SELECT leagueid, oddsstatus, eventdate FROM outright14 WITH (nolock) 
--					WHERE eventdate >= @EventDate and eventdate <= @toDate
--				 ) o ON o.leagueid = l.leagueid 
--		WHERE l.sporttype BETWEEN 151 AND 153 AND o.oddsstatus='completed'
--	 ) t INNER JOIN sports s WITH(NOLOCK) ON t.sporttype = s.sporttype
--WHERE t.RowNumber < 2

--UNION ALL

--SELECT s.sporttype, s.sportname
--FROM (
--		SELECT ROW_NUMBER() OVER (PARTITION BY sporttype ORDER BY l.leagueid) AS RowNumber, l.sporttype, l.leagueid
--		FROM league l with (nolock) 
--			INNER JOIN
--				(	SELECT leagueid, r.eventstatus, eventdate FROM VSOutright o WITH (nolock) INNER JOIN VSRaceInfo r WITH (NOLOCK) ON o.EventID = r.EventID
--					WHERE eventdate >= @EventDate and eventdate <= @toDate
--					UNION ALL
--					SELECT leagueid, r.eventstatus, eventdate FROM VSOutright14 o WITH (nolock) INNER JOIN VSRaceInfo r WITH (NOLOCK) ON o.EventID = r.EventID
--					WHERE eventdate >= @EventDate and eventdate <= @toDate
--				 ) o ON o.leagueid = l.leagueid 
--		WHERE l.sporttype = 181 AND o.eventstatus='completed'
--	 ) t INNER JOIN sports s WITH(NOLOCK) ON t.sporttype = s.sporttype
--WHERE t.RowNumber < 2

--order by sports.sporttype, sports.sportname

GO
GRANT EXECUTE ON [dbo].Age_Result_SportSelByDate TO aplweb
GO
 

 