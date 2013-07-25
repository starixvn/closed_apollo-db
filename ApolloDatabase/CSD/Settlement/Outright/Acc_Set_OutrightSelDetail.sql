ALTER PROCEDURE [dbo].[Acc_Set_OutrightSelDetail]	
	@LeagueID int	
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

SELECT o.orid, o.leagueid , teamid,
		o.matchcode, o.kickofftime,  		
		o.eventdate,  
		ISNULL(orex.oddsstatus_ex, 'running') AS oddsstatus, 				
		status_ex AS [status], odds		
INTO #tmp
FROM SVRPRO.ProdDB.dbo.outright o WITH(NOLOCK) 
	LEFT JOIN SVRPRO.ProdDB.dbo.outright_ex orex WITH(NOLOCK) ON o.orid= orex.orid_ex	
WHERE o.leagueID = @LeagueID

SELECT * 
FROM #tmp	
ORDER BY  
	leagueid, 
	matchcode,
	CASE WHEN eventdate >= CONVERT(nvarchar(10),CURRENT_TIMESTAMP,120) THEN 1 ELSE 2 END,
	eventdate,	
	CASE oddsstatus WHEN 'running' THEN 1 WHEN 'suspend' THEN 2 ELSE 3 END,
	odds

SELECT * 
FROM [dbo].[outright_log] WITH(NOLOCK) 
WHERE [orid] IN (SELECT ORID FROM #tmp)
and ActionId=30
ORDER BY LogId ASC

GO
GRANT EXECUTE ON [dbo].[Acc_Set_OutrightSelDetail] TO [aplweb]	