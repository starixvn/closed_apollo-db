
CREATE PROCEDURE  [dbo].[Acc_Set_GetConfirmedAction]		
@matchid INT
AS	
/**
 * Created by	: Kaden
 * Date			: 20130326
 * Task			: Get Confirmed Action value
 * DB			: SVRTRANS/TransDB
 * Revisions	:
 *	•
 * Parameters:
	@matchid: match Id
 */

SET NOCOUNT ON
BEGIN
	SELECT * FROM match_log WITH (NOLOCK) WHERE matchid = @matchid ORDER BY LogId ASC
END
GRANT EXECUTE ON [dbo].[Acc_Set_GetConfirmedAction] TO [aplweb]	