ALTER PROCEDURE [dbo].[Age_Rpt_MatchSelResultEntered]   
 @isShowAll bit = 1 -- 1: Show All; 0: is NOT show Test  
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

SELECT @isShowAll = CASE @isShowAll WHEN 1 THEN NULL ELSE 0 END  
  
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
	  SELECT	LeagueID, EventDate, MAX(EventStatus) AS EventStatus  
	  FROM		Match WITH (NOLOCK)  
	  WHERE		Match.EventDate between @FROMDate and @ToDate  
				and Match.eventstatus <> 'closed'  
	  GROUP BY 	leagueid, EventDate, matchid--, awayid  
	  
	 
		  
 ) as Match  
	INNER JOIN League WITH (NOLOCK) on Match.LeagueID = League.LeagueID and League.isTest = isnull(@isShowAll, League.isTest)   
GROUP BY  Sporttype, EventDate
ORDER BY  Sporttype, EventDate

GO
GRANT EXECUTE ON [dbo].[Age_Rpt_MatchSelResultEntered] TO [aplweb]
GO

--GRANT VIEW DEFINITION ON [dbo].[Age_Rpt_MatchSelResultEntered] TO [vnteam]
GO