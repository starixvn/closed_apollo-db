ALTER PROCEDURE [dbo].[Age_Wagers_SelLeague]
	@FromDate DATETIME,
	@Sporttypes VARCHAR(MAX) = '0'
AS
/*
Created:  Sophia
Date: 20130628
Task: Get Leagueid for Wagers
DB: SVRAGE.REPDB
 
Revisions:    

Parameters
	@isShowAll : 1: Show All
				 0: is NOT show Test	
 
*/
SET NOCOUNT ON

DECLARE @ToDate datetime
SELECT @ToDate = dateadd(s,-1, dateadd(d, 1, @FromDate))

SELECT	m.LeagueId
FROM	Match m WITH (NOLOCK) 
	INNER JOIN League l WITH (NOLOCK) ON m.leagueid = l.leagueid
WHERE	m.eventdate BETWEEN @FromDate AND @ToDate
		AND (m.Sporttype IN (SELECT val FROM [dbo].[StrSplit](@Sporttypes, ',') ) 
			OR @Sporttypes = '0')
		AND l.isTest = 0

		 
GO
GRANT EXECUTE ON [Age_Wagers_SelLeague] TO [aplweb]

		 