CREATE PROCEDURE [dbo].[Age_Rpt_MatchSelResultEntered]   
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
  
DECLARE @FromDate DATETIME, @ToDate DATETIME  

SELECT @ToDate = CONVERT(DATETIME,CONVERT(NVARCHAR(20), GETDATE(), 101))  
SELECT @FromDate = DATEADD(dd,-1,@ToDate)  

DECLARE @Rpt AS TABLE (Sporttype SMALLINT, IsToday BIT, EventDate DATETIME, Entered INT, NonEntered INT)
INSERT INTO @Rpt (Sporttype,IsToday, EventDate, Entered, NonEntered )
SELECT 1, 0, NULL, 0, 0
UNION ALL
SELECT 2, 0, NULL, 0, 0
UNION ALL
SELECT 3, 0, NULL, 0, 0
UNION ALL
SELECT 4, 0, NULL, 0, 0
UNION ALL
SELECT 8, 0, NULL, 0, 0
UNION ALL
SELECT -10, 0, NULL, 0, 0
UNION ALL
SELECT -1, 0, NULL, 0, 0

  
UPDATE  r
SET		IsToday = m.IsToday,
		EventDate= m.EventDate,
		Entered= m.Entered,
		NonEntered = m.NonEntered		
FROM	@Rpt r
INNER JOIN (
					Select	DATEDIFF(dd,@FromDate,EventDate ) as IsToday,
							EventDate, 
							CASE WHEN m.Sporttype NOT IN (1, 2, 5, 6, 8,-10) THEN -1 ELSE m.Sporttype END Sporttype ,  
							SUM(CASE WHEN eventstatus in ('completed', 'refund') THEN 1 ELSE 0 END) AS Entered,  
							SUM(CASE WHEN eventstatus not in ('completed', 'refund') THEN 1 ELSE 0 END) AS NonEntered
					FROM   
					 (  
						  SELECT	LeagueID, EventDate, Sporttype,  MAX(EventStatus) AS EventStatus  
						  FROM		Match WITH (NOLOCK)  
						  WHERE		Match.EventDate between @FromDate and @ToDate  
									and Match.eventstatus NOT IN ( 'closed' ,'internal')
									and Match.sporttype <= 99
						  GROUP BY 	leagueid, EventDate,Sporttype, matchid 
	  
						  UNION ALL

						  SELECT	m.LeagueID, EventDate, -10 as Sporttype, MAX(OddsStatus) as EventStatus  
						  FROM		Outright m with (NOLOCK)   
						  INNER JOIN League with (NOLOCK)  
								ON  m.LeagueId = League.LeagueId and League.Sporttype  < =99
						  WHERE		m.EventDate between @FromDate and @ToDate  
									and m.OddsStatus <> 'closed'  
						  GROUP BY  m.LeagueID, m.EventDate 	 
		  
					 ) as m  
						INNER JOIN League WITH (NOLOCK) on m.LeagueID = League.LeagueID and League.isTest = 0 
					GROUP BY CASE WHEN m.Sporttype NOT IN (1, 2, 5, 6, 8,-10) THEN -1 ELSE m.Sporttype END, EventDate
			) m
ON r.Sporttype = m.sporttype

 
 SELECT * FROM @Rpt

GO
GRANT EXECUTE ON [dbo].[Age_Rpt_MatchSelResultEntered] TO [aplweb]
GO

GRANT VIEW DEFINITION ON [dbo].[Age_Rpt_MatchSelResultEntered] TO [vnteam]
GO
  