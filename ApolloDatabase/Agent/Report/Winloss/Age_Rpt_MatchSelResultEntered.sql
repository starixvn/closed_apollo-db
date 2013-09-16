USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Rpt_MatchSelResultEntered]    Script Date: 7/10/2013 9:40:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_Rpt_MatchSelResultEntered]   
	@isShowAll BIT = 0
AS  
/*  
Created: Sophia 
Date : 20130319
Task : Report Match Resul Entered
DB:  SVRAGE.RepDB
Original: Age_Rpt_MatchSelResultEntered  
Revisions:  
	- 20130626@Sophia: Modify for Singbet
	- 20130913@Sophia: Add @isShowAll
     
*/  
SET NOCOUNT ON
  
DECLARE @FromDate DATETIME, @ToDate DATETIME  

SELECT @ToDate = CONVERT(DATETIME,CONVERT(NVARCHAR(20), GETDATE(), 101))  
SELECT @FromDate = DATEADD(dd,-1,@ToDate)  

DECLARE @Rpt AS TABLE (Sporttype SMALLINT, IsToday BIT, EventDate DATETIME, Entered INT, NonEntered INT)
INSERT INTO @Rpt (Sporttype,IsToday, EventDate, Entered, NonEntered )
SELECT 1, 0, @FromDate, 0, 0
UNION ALL
SELECT 1, 1, @ToDate, 0, 0
UNION ALL
SELECT 2, 0, @FromDate, 0, 0
UNION ALL
SELECT 2, 1, @ToDate, 0, 0
UNION ALL
SELECT 5, 0, @FromDate, 0, 0
UNION ALL
SELECT 5, 1, @ToDate, 0, 0
UNION ALL
SELECT 6, 0, @FromDate, 0, 0
UNION ALL
SELECT 6, 1, @ToDate, 0, 0
UNION ALL
SELECT 8, 0, @FromDate, 0, 0
UNION ALL
SELECT 8, 1, @ToDate, 0, 0
UNION ALL
SELECT -10, 0, @FromDate, 0, 0   ---- Outright
UNION ALL
SELECT -10, 1, @ToDate, 0, 0   ---- Outright
UNION ALL
SELECT -1, 0, @FromDate, 0, 0	---- Others
UNION ALL
SELECT -1, 1, @ToDate, 0, 0	---- Others
 

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
								and Match.eventstatus NOT IN ( 'internal')
								and Match.sporttype <= 99
						GROUP BY 	leagueid, EventDate,Sporttype, matchid 
	  
						UNION ALL

						SELECT	m.LeagueID, EventDate, -10 as Sporttype, MAX(OddsStatus) as EventStatus  
						FROM		Outright m with (NOLOCK)   
						INNER JOIN League with (NOLOCK)  
							ON  m.LeagueId = League.LeagueId and League.Sporttype  < =99
						WHERE		m.EventDate between @FromDate and @ToDate  
								---and m.OddsStatus <> 'closed'  
						GROUP BY  m.LeagueID, m.EventDate 	 
		  
					) as m  
					INNER JOIN League WITH (NOLOCK) on m.LeagueID = League.LeagueID and (League.isTest = 0 OR @isShowAll = 1)
				GROUP BY CASE WHEN m.Sporttype NOT IN (1, 2, 5, 6, 8,-10) THEN -1 ELSE m.Sporttype END, EventDate
			) m
ON r.Sporttype = m.sporttype and m.IsToday = r.IsToday

 
 SELECT * FROM @Rpt
  
