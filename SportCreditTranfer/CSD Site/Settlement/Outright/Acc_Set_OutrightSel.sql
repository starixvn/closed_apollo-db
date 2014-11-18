ALTER PROCEDURE [dbo].[Acc_Set_OutrightSel]
	@FromDate datetime,
	@ToDate datetime,
	@sporttype tinyint = 0,
	@LeagueID int = 0, -- 0 for ALL Leagues
	@isSettled bit = 0

AS 
/**
 * Created by	: Dan
 * Date			: 20130716
 * Task			: Outright results 
 * DB			: SVRTXN/TransDB
 * Revisions	:
 *	•
 * Parameters:
 *  @FromDate: From  date,
	@ToDate: To date ,
	@sporttype: Sport type,	
	@LeagueID: = 0: show info of all leagues     
	
 *  
 */
   
  
SET NOCOUNT ON  

CREATE TABLE #tmpList
	(
		orid INT,
		leagueid INT,
		[teamid] INT,
		matchcode VARCHAR(10),
		kickofftime DATETIME, 
		eventdate SMALLDATETIME, 
		oddsstatus  VARCHAR(10),
		sporttype TINYINT,
		FailedActionID TINYINT,
		DisabledAutoSettle BIT,
		odds SMALLMONEY
		)

INSERT INTO #tmpList
EXEC SVRPro.ProdDB.dbo.[Acc_Set_OutrightSelInfo] 	
	@FromDate = @FromDate,
	@ToDate = @ToDate ,
	@sporttype = @sporttype ,
	@LeagueID = @LeagueID , -- 0 for ALL Leagues	
	@isSettled = @isSettled 

SELECT *
FROM #tmpList 
ORDER BY  
	leagueid, 
	matchcode,
	CASE WHEN eventdate >= CONVERT(nvarchar(10),CURRENT_TIMESTAMP,120) THEN 1 ELSE 2 END,
	eventdate,	
	CASE oddsstatus WHEN 'running' THEN 1 WHEN 'suspend' THEN 2 ELSE 3 END,
	odds

SELECT * 
FROM [dbo].[outright_log] WITH(NOLOCK) 
WHERE [orid] IN (SELECT ORID FROM #tmpList)
	and ActionId=30
ORDER BY LogId ASC


GO
GRANT EXECUTE ON [dbo].[Acc_Set_OutrightSel] TO [aplweb]	