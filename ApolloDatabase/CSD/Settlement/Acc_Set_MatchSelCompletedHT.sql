ALTER PROCEDURE [dbo].[Acc_Set_MatchSelCompletedHT]	
	@FromDate datetime,
	@ToDate datetime,
	@sporttype tinyint = 0,
	@LeagueID int = 0, -- 0 for ALL Leagues
	@matchcode nvarchar(50) = '',
	@isReLoad bit = 0
AS
/**
 * Created by	: Kaden
 * Date			: 20130315
 * Task			: List HT-completed matches for billing
 * DB			: APL.TransDB
 * Revisions	:
 *	•
 * Parameters:
 *  @FromDate: From  date,
	@ToDate: To date ,
	@sporttype: Sport type,	
	@LeagueID: = 0: show info of all leagues     
	@matchcode: match code
	@isReLoad: 1: reload partial matches of a league, 0: not reload
 *  
 */

SET NOCOUNT ON  
IF @sporttype NOT IN(1,2,3,32)  
	RETURN

DECLARE @HTOverStartMins int,
		@HTOverEndMins int
		
SELECT @matchcode = ISNULL(@matchcode,''), @LeagueID = ISNULL(@LeagueID,0)
-- if entering matcode, ignore other params (excep FromDate, ToDate, sport type)
IF (@matchcode <> '')
BEGIN
	SELECT @LeagueID = CASE WHEN @isReLoad = 1 THEN @LeagueID ELSE 0 END -- reload partial; search on LeagueID, not reload: get all leagues
END

SELECT @HTOverStartMins = CASE WHEN @sporttype = 1 THEN 45 ELSE 30 END ,
		@HTOverEndMins = CASE WHEN @sporttype = 1 THEN 100 ELSE 60 END

SELECT * 
INTO #tmpMatch
FROM
(
	SELECT 
			m.matchid, m.leagueid ,
			hthomescore,
			htawayscore, 
			isnull(m.calculate,0) IsCalculated, isnull(m.multiple,0) IsMultiCaled,  
			isnull(m.refund,0) IsRefund, isnull(m.calrefund,0) IsCalRefund,  		
			m.homeid, m.awayid,  
			m.matchcode, m.kickofftime,  
			m.finalhomescore,  
			m.finalawayscore,
			m.betstatus,  
			CASE WHEN m.betstatus like 'Refund FT%' THEN 'Refund FT'  
			WHEN m.betstatus like 'Refund HT%' THEN 'Refund HT'  
			WHEN m.betstatus like 'Refund%' THEN 'Refund'  
			ELSE m.eventstatus
			END AS eventstatus,    
			m.sporttype,  
			isnull(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,  
			m.eventdate,  			 
			ISNULL(m.IsHTCal,0) AS IsHTCal,   		
			CAST(CASE WHEN hthomescore IS NOT NULL AND htawayscore IS NOT NULL AND finalhomescore IS NOT NULL AND finalawayscore IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS IsKeyscore ,
			c.betcount,
			m.goalrecord,
			CASE WHEN c.cntFGLG = 0 THEN 0 ELSE 1 END AS isExistFGLG
	FROM		
		(
		SELECT match.matchid, match.leagueid ,
			hthomescore_ext AS hthomescore,
			htawayscore_ext AS htawayscore, 
			mr.calculate_ext AS calculate,
			mr.multiple_ext AS multiple,  
			mr.refund_ext AS refund, 
			mr.calrefund_ext AS calrefund,  		
			match.homeid, match.awayid,  
			match.matchcode, match.kickofftime,  
			match.finalhomescore_ext AS finalhomescore,  
			match.finalawayscore_ext AS finalawayscore, 
			match.betstatus_ext AS betstatus,  
			match.eventstatus_ext AS eventstatus,  		
			match.sporttype,  
			match.isNeutral,  
			match.eventdate,  			
			mr.IsHTCal_ext AS IsHTCal,
			match.goalrecord_ext as goalrecord
		FROM SVRPRO.ProdDB.dbo.match WITH (NOLOCK)   
		INNER JOIN SVRPRO.ProdDB.dbo.match_remark mr WITH (NOLOCK) on match.matchid = mr.matchid                    
		WHERE match.eventdate BETWEEN @FromDate AND @ToDate  
			AND match.leagueID = CASE WHEN @LeagueID <> 0 THEN @LeagueID ELSE match.leagueID END  
			AND match.sporttype = @sporttype 		
			AND (@matchcode = '' OR  match.matchcode = @matchcode) 
			AND (match.matchcode NOT LIKE 'hedge%')  -- exclude hedge matches
			AND (match.eventstatus_ext IN ('Closed','running') OR ISNULL(eventstatus_ext, 'running') = 'running')
			AND ((datediff(minute,match.kickofftime,CURRENT_TIMESTAMP) > @HTOverStartMins
				AND datediff(minute,match.kickofftime,CURRENT_TIMESTAMP) < @HTOverEndMins
				)  
				--OR  mr.confirmHT <> 0
				) 		
			AND mr.IsHTCal_ext=0  
		) AS m
		INNER JOIN  
		(SELECT   bettrans.matchid,  
			 COUNT(bettrans.matchid)  betcount,
			 SUM(CASE WHEN bettype = 14 THEN 1 ELSE 0 END) AS cntFGLG  
		  FROM     bettrans WITH (NOLOCK) 
			 JOIN match WITH (NOLOCK)  ON match.matchid = bettrans.matchid  
		  WHERE  match.eventdate BETWEEN @FromDate AND @ToDate  			
				 AND BETTYPE <= 19000  			 			 
				 AND (match.eventstatus_ext IN ('Closed','running') OR ISNULL(eventstatus_ext, 'running') = 'running')
				 AND match.sporttype = @sporttype  
		  GROUP BY bettrans.matchid  
			) c on m.matchid = c.matchid  
) AS X
ORDER BY  
	sporttype, leagueid, 
	CASE eventstatus WHEN 'completed' THEN 1 WHEN 'Refund' THEN 1 ELSE 0 END,  
	eventdate, kickofftime, matchid, matchcode	 

SELECT * FROM #tmpMatch WITH (NOLOCK)

SELECT ml.* FROM match_log ml WITH (NOLOCK) INNER JOIN #tmpMatch t WITH (NOLOCK)
ON (ml.Matchid = t.matchid)
ORDER BY LogId ASC

GRANT EXECUTE ON [dbo].[Acc_Set_MatchSelCompletedHT] TO [aplweb]	
	