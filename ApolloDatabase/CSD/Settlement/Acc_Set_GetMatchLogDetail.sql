
CREATE PROCEDURE  [dbo].[Acc_Set_GetMatchLogDetail]		
@logid INT
AS	
/**
 * Created by	: Kaden
 * Date			: 20130326
 * Task			: Get detail action log by logId
 * DB			: APL.ProdDB
 * Revisions	:
 *	•
 * Parameters:
	@logId: log Id
 */

SET NOCOUNT ON
BEGIN
	SELECT * FROM match_log WITH (NOLOCK) WHERE LogId = @logid
END
GRANT EXECUTE ON [dbo].[Acc_Set_GetMatchLogDetail] TO [aplweb]	