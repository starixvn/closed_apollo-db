
CREATE PROCEDURE  [dbo].[Acc_Set_GetConfirmedActionOutright]		
	@orid INT
AS	
/**
 * Created by	: Dan
 * Date			: 20130718
 * Task			: Get Confirmed Action value
 * DB			: SVRTRANS/TransDB
 * Revisions	:
 *	•
 * Parameters:
	@matchid: match Id
 */

SET NOCOUNT ON
BEGIN
	SELECT * 
	FROM [dbo].[outright_log] WITH(NOLOCK) 
	WHERE [orid] = @orid
			and ActionId=30
	ORDER BY LogId ASC

END

GO
GRANT EXECUTE ON [dbo].[Acc_Set_GetConfirmedActionOutright] TO [aplweb]	