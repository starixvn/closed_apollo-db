CREATE PROCEDURE [dbo].[Acc_Set_LeagueSelOutright]
	@FromDate datetime,
	@ToDate datetime,
	@sporttype tinyint = 0
AS
/**
 * Created by	: Dan
 * Date			: 20130717
 * Task			: Select league to settle
 * DB			: SVRPRO/ProdDB
 * Revisions	:
 *	•
 * Parameters:
 *  @FromDate: From  date,
	@ToDate: To date ,
	@sporttype: Sport type
 *  
 */

SET NOCOUNT ON
IF @sporttype = 0
BEGIN 
	SELECT DISTINCT o.leagueid, l.leaguename, l.sporttype
	FROM outright o (NOLOCK)
		INNER JOIN league l (NOLOCK) ON o.leagueid = l.leagueid 
	WHERE o.eventdate BETWEEN @FromDate AND @ToDate		
	ORDER BY sporttype, leaguename
END 
ELSE 
BEGIN 
	SELECT DISTINCT o.leagueid, l.leaguename, l.sporttype
	FROM outright o (NOLOCK)
		INNER JOIN league l (NOLOCK) ON o.leagueid = l.leagueid 
	WHERE o.eventdate BETWEEN @FromDate AND @ToDate		
		AND l.sporttype = @sporttype
	ORDER BY leaguename
END 
GRANT EXECUTE ON [dbo].[Acc_Set_LeagueSelOutright] TO [aplweb]	



