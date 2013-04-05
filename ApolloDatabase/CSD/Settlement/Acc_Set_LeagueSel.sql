CREATE PROCEDURE [dbo].[Acc_Set_LeagueSel]
	@FromDate datetime,
	@ToDate datetime,
	@sporttype tinyint = 0
AS
/**
 * Created by	: Kaden
 * Date			: 20130318
 * Task			: Select league to settle
 * DB			: APL.ProdDB
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
	SELECT DISTINCT league.leagueid, leaguename, match.sporttype
	FROM match WITH (NOLOCK)
		INNER JOIN league WITH (NOLOCK) ON match.leagueid = league.leagueid
	WHERE match.eventdate BETWEEN @FromDate AND @ToDate AND match.sporttype <> 162

	UNION 
	
	SELECT DISTINCT o.leagueid, l.leaguename, l.sporttype
	FROM outright o (NOLOCK)
		INNER JOIN league l (NOLOCK) ON o.leagueid = l.leagueid 
	WHERE o.eventdate BETWEEN @FromDate AND @ToDate
		AND l.sporttype BETWEEN  151 AND 153 
	ORDER BY sporttype, leaguename
END 
ELSE IF @sporttype IN (151,152,153) 
BEGIN 
	SELECT DISTINCT o.leagueid, l.leaguename, l.sporttype
	FROM outright o (NOLOCK)
		INNER JOIN league l (NOLOCK) ON o.leagueid = l.leagueid 
	WHERE o.eventdate BETWEEN @FromDate AND @ToDate
		AND l.sporttype =  @sporttype 
	ORDER BY sporttype, leaguename
END 
ELSE 
BEGIN 
	SELECT DISTINCT league.leagueid, leaguename, match.sporttype
	FROM match WITH (NOLOCK)
		INNER JOIN league WITH (NOLOCK) ON match.leagueid = league.leagueid
	WHERE match.eventdate BETWEEN @FromDate AND @ToDate
		AND match.sporttype = @sporttype
	ORDER BY leaguename
END 
GRANT EXECUTE ON [dbo].[Acc_Set_LeagueSel] TO [aplweb]	



