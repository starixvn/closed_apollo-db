ALTER PROCEDURE [dbo].[Age_Result_MatchSelBySport]
	@FromDate DATETIME,
	@Sporttypes VARCHAR(MAX) = '0',
	@isShowAll bit = 0 -- 1: Show All; 0: is NOT show Test	

AS
/*
Created: Sophia
Date: 20130625
Task: Get result
DB: SVRAGE.RepDB
Original: Age_Result_MatchSelByLeague

Revision:
 
	
*/
SET NOCOUNT ON  
	
DECLARE @ToDate datetime
SELECT @ToDate = dateadd(s,-1, dateadd(d, 1, @FromDate))

SELECT
		m.sporttype, 
		m.betstatus , 
		m.leagueid,
		m.matchid,
		l.lcolor, 
		m.matchcode,
		m.eventdate, 
		m.kickofftime,
		m.homeID,
		m.awayID,
		m.hthomescore,
		m.htawayscore,
		m.finalhomescore ,
		m.finalawayscore,
		case when m.betstatus  like 'Refund FT%' then 'Refund FT' 
			 when m.betstatus  like 'Refund HT%' then 'Refund HT'
			 when m.betstatus  like 'Refund%' then 'Refund' 
		else m.eventstatus end as eventstatus,  
		m.showtime,
		m.homeid2 , 
		ISNULL(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
		m.goalrecord AS goalrecord,
		ISNULL(mr.IsHTCal,0) as IsHTCal,
		ISNULL(mr.calculate,0) as calculate	,
		ISNULL(mr.IsPending,0) as IsPending
	FROM league l WITH (NOLOCK) 
		INNER JOIN
			(	SELECT  sporttype, betstatus,matchid, matchcode, homeid, awayid, leagueid, eventdate, eventstatus, kickofftime, hthomescore, htawayscore, finalhomescore, finalawayscore, showtime, isneutral,goalrecord,homeid2
			 	FROM	match WITH (NOLOCK)
			 	WHERE	eventdate BETWEEN @FromDate AND @ToDate 
						AND sporttype <= 99 
						AND (@Sporttypes = '0' OR sporttype IN (SELECT val FROM StrSplit_Key(@Sporttypes, ','))) 						
						AND matchcode NOT LIKE '%hedge%'	
						AND matchcode NOT LIKE '%betdaq%'		 		
				--UNION ALL
				--SELECT	sporttype, betstatus,matchid, matchcode, homeid, awayid, leagueid, eventdate, eventstatus, kickofftime, hthomescore, htawayscore, finalhomescore, finalawayscore, showtime, isneutral,goalrecord,homeid2
				--FROM	match14 WITH (NOLOCK)	
				--WHERE	eventdate BETWEEN  @FromDate AND @ToDate 
				--		AND sporttype <= 99  
				--		AND (@Sporttypes = '0' OR sporttype IN (SELECT val FROM StrSplit_Key(@Sporttypes, ',')) ) 						
				--		AND matchcode NOT LIKE '%hedge%'	
				--		AND matchcode NOT LIKE '%betdaq%'		
			) AS m ON m.leagueid=l.leagueid	
		LEFT OUTER JOIN match_remark mr WITH (NOLOCK) ON m.matchid = mr.matchid
	WHERE
			(	
		       m.eventstatus NOT IN ('internal', 'closed', 'running')
		        OR (
		               mr.IsPending = 1
		               AND m.eventstatus IN ('running', 'closed')
		           )
		        OR (mr.IsHTCal = 1 AND m.eventstatus = 'running')
		    )
		
		AND (l.isTest = 0 OR @isShowAll = 1)
	ORDER BY m.eventdate, m.sporttype, m.leagueid

GO

GRANT EXECUTE ON [dbo].[Age_Result_MatchSelBySport] TO [aplWeb] 