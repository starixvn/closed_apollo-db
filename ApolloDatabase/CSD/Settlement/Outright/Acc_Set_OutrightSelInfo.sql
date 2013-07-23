ALTER PROCEDURE [dbo].[Acc_Set_OutrightSelInfo]
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
 * DB			: SVRPRO/ProdDB
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

SELECT o.orid, o.leagueid ,[teamid],
		o.matchcode, o.kickofftime,  		
		o.eventdate,  
		ISNULL(orex.oddsstatus_ex, 'running') AS oddsstatus, 				
		l.sporttype, 				
		FailedActionID,
		DisabledAutoSettle
FROM dbo.outright o WITH(NOLOCK) 
	LEFT JOIN dbo.outright_ex orex WITH(NOLOCK) ON o.orid= orex.orid_ex
	JOIN League l WITH(NOLOCK) ON l.leagueid=o.leagueid
WHERE o.eventdate BETWEEN @FromDate AND @ToDate  
	AND o.leagueID = CASE WHEN @LeagueID <> 0 THEN @LeagueID ELSE o.leagueID END  
	AND l.sporttype = @sporttype 				  
	AND (@isSettled = 1 or (@isSettled= 0 and ISNULL(orex.oddsstatus_ex,'')<>'completed')) 	
--ORDER BY  
--	leagueid, 
--	matchcode,
--	CASE WHEN eventdate >= CONVERT(nvarchar(10),CURRENT_TIMESTAMP,120) THEN 1 ELSE 2 END,
--	eventdate,	
--	CASE oddsstatus WHEN 'running' THEN 1 WHEN 'suspend' THEN 2 ELSE 3 END,
--	odds
GO
GRANT EXECUTE ON [dbo].[Acc_Set_OutrightSelInfo] TO [aplweb]	