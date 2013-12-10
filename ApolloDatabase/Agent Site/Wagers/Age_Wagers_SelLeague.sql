ALTER PROCEDURE [dbo].[Age_Wagers_SelLeague]
	@FromDate DATE,
	@Todate DATE = @FromDate,
	@Sporttypes VARCHAR(MAX) = '0',
	@IsOutright BIT = 0,
	@isShowAll BIT = 0
AS
/*
Created:  Sophia
Date: 20130628
Task: Get Leagueid for Wagers
DB: SVRAGE.REPDB
 
Revisions:    
	- 20130913@Sophia: Add @isShowAll	
	
Parameters
 
 
*/
SET NOCOUNT ON
IF @IsOutright = 0

	SELECT	DISTINCT m.LeagueId
	FROM	Match m WITH (NOLOCK) 
		INNER JOIN League l WITH (NOLOCK) ON m.leagueid = l.leagueid
	WHERE	m.eventdate = @FromDate  
			AND (l.Sporttype IN (SELECT val FROM StrSplit_Key(@Sporttypes, ',')) OR @Sporttypes = '0')
			AND (l.isTest = 0  OR @isShowAll = 1)

ELSE
	SELECT	DISTINCT m.LeagueId
	FROM	Outright m WITH (NOLOCK) 
		INNER JOIN League l WITH (NOLOCK) ON m.leagueid = l.leagueid
	WHERE	m.eventdate BETWEEN @FromDate AND @ToDate
			AND (l.Sporttype IN (SELECT val FROM StrSplit_Key(@Sporttypes, ',')) OR @Sporttypes = '0')
			AND (l.isTest = 0  OR @isShowAll = 1)

		 
GO
GRANT EXECUTE ON [Age_Wagers_SelLeague] TO [aplweb]

		 