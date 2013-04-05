
ALTER PROCEDURE [dbo].[Acc_Set_MatchSelCompleted]
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
 * Task			: List FT-completed matches for billing
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

SELECT @matchcode = ISNULL(@matchcode,''), @LeagueID = ISNULL(@LeagueID,0)
-- if entering matcode, ignore other params (excep FromDate, ToDate, sport type)
IF (@matchcode <> '')
BEGIN
	SELECT @LeagueID = CASE WHEN @isReLoad = 1 THEN @LeagueID ELSE 0 END -- reload partial; search on LeagueID, not reload: get all leagues
END
  
Declare @m TABLE (
		matchid int primary key, 
		IsCalculated bit, 
		IsMultiCaled bit,  
		IsRefund bit, 
		IsCalRefund bit,  
		IsHTCal bit,
		calculate bit)  
INSERT INTO @m  
SELECT  
		m.matchid, 
		ISNULL(mr.calculate_ext,0) IsCalculated, 
		ISNULL(mr.multiple_ext,0) IsMultiCaled,  
		ISNULL(mr.refund_ext,0) IsRefund, 
		ISNULL(mr.calrefund_ext,0) IsCalRefund,  
		mr.IsHTCal_ext AS IsHTCal,
		mr.calculate_ext AS calculate
FROM  match m with (nolock)  
	INNER JOIN match_remark mr with (nolock) ON m.matchid = mr.matchid  
	
WHERE
	m.eventdate BETWEEN @FromDate AND @ToDate  
	AND m.leagueID = case when @LeagueID <> 0 then @LeagueID else m.leagueID end  
	AND m.sporttype = case when @sporttype = 0 then sporttype else @sporttype end 
	AND (@matchcode = '' OR m.matchcode = @matchcode) 
	AND (m.matchcode NOT LIKE 'hedge%')
	AND m.eventstatus_ext <> N'Completed'  
	AND (m.kickofftime < DATEADD(s, -6000, CURRENT_TIMESTAMP) OR mr.ConfirmFT > 0)  

SELECT *
INTO #tmpMatch
FROM  
(	SELECT  
		m.matchid,  
		m.leagueid,  
		hthomescore_ext AS hthomescore,
		htawayscore_ext AS htawayscore, 
		IsCalculated, IsMultiCaled,  
		IsRefund, IsCalRefund,  
		m.homeid,  
		m.awayid,  
		m.matchcode,  
		m.kickofftime,  
		m.finalhomescore_ext AS finalhomescore,  
		m.finalawayscore_ext AS finalawayscore,  
		m.betstatus_ext AS betstatus,  
		case when m.betstatus_ext like 'Refund FT%' then 'Refund FT'  
		when m.betstatus_ext like 'Refund HT%' then 'Refund HT'  
		when m.betstatus_ext like 'Refund%' then 'Refund'  
		else m.eventstatus_ext  
		end as eventstatus,  		
		m.sporttype,  	
		ISNULL(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,  
		m.eventdate,  
		m.GoalRecord_ext AS goalrecord, 	
		C.betcount,  	
		ISNULL(tm.IsHTCal,0) as IsHTCal,  
		ISNULL(tm.calculate,0) as calculate,  
		CAST(CASE WHEN hthomescore_ext IS NOT NULL AND htawayscore_ext IS NOT NULL AND finalhomescore_ext IS NOT NULL AND finalawayscore_ext IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS IsKeyscore  
	FROM match m with (nolock)  
		INNER JOIN @m tm ON m.matchid = tm.matchid  
		INNER JOIN (  
					SELECT b.matchid, count(b.matchid) AS BetCount  
					FROM bettrans b with (nolock)  
					INNER JOIN @m stm ON b.matchid = stm.matchid  
					GROUP BY b.matchid  
					) as C ON m.matchid = c.matchid  
) X 
ORDER BY  sporttype, leagueid, 
	CASE eventstatus WHEN 'completed' THEN 1 WHEN 'Refund' THEN 1 ELSE 0 END,  
	eventdate, kickofftime, matchid, matchcode	 

SELECT * FROM #tmpMatch WITH (NOLOCK)

SELECT ml.* FROM match_log ml WITH (NOLOCK) 
INNER JOIN #tmpMatch t WITH (NOLOCK) ON (ml.Matchid = t.matchid)
ORDER BY LogId ASC

GRANT EXECUTE ON [dbo].[Acc_Set_MatchSelCompleted] TO [aplweb]	

