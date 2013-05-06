ALTER PROCEDURE [dbo].[Age_Rpt_MatchSelResultEntered]   
AS  
/*  
Created: Sophia 
Date : 20130319
Task : Report Match Resul Entered
DB:  SVRAGE.RepDB
Original: Age_Rpt_MatchSelResultEntered  
Revisions:  
     
*/  
SET NOCOUNT ON
  
DECLARE @FROMDate DATETIME, @ToDate DATETIME  

SELECT @ToDate = CONVERT(DATETIME,CONVERT(NVARCHAR(20), GETDATE(), 101))  
SELECT @FROMDate = DATEADD(dd,-1,@ToDate)  
  
Select	DATEDIFF(dd,@FROMDate,EventDate ) as IsToday,
		EventDate, 
		Sporttype,  
		SUM(CASE WHEN eventstatus in ('completed', 'refund') THEN 1 ELSE 0 END) AS Entered,  
		SUM(CASE WHEN eventstatus not in ('completed', 'refund') THEN 1 ELSE 0 END) AS NonEntered
FROM   
 (  
	  SELECT	LeagueID, EventDate, MAX(e.EventStatus) AS EventStatus  
	  FROM		Match WITH (NOLOCK)  
		LEFT OUTER JOIN Match_remark_ex e WITH (NOLOCK) ON Match.MatchID = e.matchID
	  WHERE		Match.EventDate between @FROMDate and @ToDate  
				and e.eventstatus NOT IN ( 'closed' ,'internal')
				and Match.sporttype <= 99
	  GROUP BY 	leagueid, EventDate, match.matchid 	 
		  
 ) as Match  
	INNER JOIN League WITH (NOLOCK) on Match.LeagueID = League.LeagueID and League.isTest = 0 
GROUP BY  Sporttype, EventDate
ORDER BY  Sporttype, EventDate

GO
GRANT EXECUTE ON [dbo].[Age_Rpt_MatchSelResultEntered] TO [aplweb]
GO

GRANT VIEW DEFINITION ON [dbo].[Age_Rpt_MatchSelResultEntered] TO [vnteam]
GO