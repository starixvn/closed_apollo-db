
ALTER PROCEDURE [dbo].[Age_Result_SelAvaiDate]
AS

/*
Created:  Sophia
Date: 20130401
Task:  
DB: SVRAGE.REPDB
Original: Age_Result_SelAvaiDate

Revisions:    
 
*/

SET NOCOUNT ON


SELECT DISTINCT m.eventdate
FROM   match m WITH (NOLOCK)
LEFT OUTER JOIN match_remark_ex e WITH (NOLOCK) ON m.matchid = e.matchid
WHERE  e.eventstatus NOT IN ('internal', 'closed', 'running')

UNION ALL

SELECT DISTINCT m.eventdate
FROM   match14 m WITH (NOLOCK)
LEFT OUTER JOIN match_remark_ex e WITH (NOLOCK) ON m.matchid = e.matchid
WHERE  e.eventstatus NOT IN ('internal', 'closed', 'running')
ORDER BY m.eventdate DESC

	
GO
GRANT EXECUTE ON [dbo].[Age_Result_SelAvaiDate] TO [aplweb]
GO
--GRANT VIEW DEFINITION ON [dbo].[Age_Result_SelAvaiDate] TO vnteam