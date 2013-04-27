
CREATE PROCEDURE [dbo].[Age_Result_SelAvaiDate]
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


select distinct eventdate
from match (nolock)
where match.eventstatus not in ('internal','closed','running')

UNION ALL

select distinct eventdate
from match14 match (nolock)
where match.eventstatus not in ('internal','closed','running')

order by eventdate desc

	
GO
GRANT EXECUTE ON [dbo].[Age_Result_SelAvaiDate] TO [aplweb]
GO
--GRANT VIEW DEFINITION ON [dbo].[Age_Result_SelAvaiDate] TO vnteam