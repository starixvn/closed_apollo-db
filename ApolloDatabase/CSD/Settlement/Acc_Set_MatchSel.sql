

ALTER PROCEDURE [dbo].[Acc_Set_MatchSel]
	@FromDate datetime,
	@ToDate datetime,
	@sporttype tinyint = 0,
	@LeagueID int = 0, -- 0 for ALL Leagues
	@matchcode nvarchar(50) = '',
	@statusid tinyint = 0,
	@filterBy tinyint = 0,
	@isReLoad bit = 0
AS 
/**
 * Created by	: Kaden
 * Date			: 20130315
 * Task			: Match results for calculating settlement 
 * DB			: APL.ProdDB
 * Revisions	:
 *	•
 * Parameters:
 *  @FromDate: From  date,
	@ToDate: To date ,
	@sporttype: Sport type,	
	@LeagueID: = 0: show info of all leagues     
	@matchcode: match code
	@statusid: 0: all, 1: running; 2: closed; 3: completed; 4: refund; 
	@filterBy: 0: none, 1: un-calculated game; 2: Un-calculated multiple only; 3: all
	@isReLoad: 1: reload partial matches of a league, 0: not reload
 *  
 */
   
  
SET NOCOUNT ON  

DECLARE @UncalOnly BIT,	
	@UncalMultiOnly BIT,
	@eventstatus NVARCHAR(50),
	@isRefund BIT

SELECT @matchcode = ISNULL(@matchcode,''), @LeagueID = ISNULL(@LeagueID,0),	@filterBy = ISNULL(@filterBy,0)
-- if entering matcode, ignore other params (excep FromDate, ToDate, sport type)
IF (@matchcode <> '')
BEGIN
	SELECT @eventstatus= '', @isRefund=null, 
		@LeagueID = CASE WHEN @isReLoad = 1 THEN @LeagueID ELSE 0 END, -- reload partial; search on LeagueID, not reload: get all leagues
		@UncalOnly = CASE WHEN @filterBy in (3,1) THEN 1 ELSE 0 END,				
		@UncalMultiOnly = CASE WHEN @filterBy in (3,2) THEN 1 ELSE 0 END			
END
ELSE
BEGIN
	SELECT @eventstatus = CASE @statusid WHEN 1 THEN 'running'
										WHEN 2 THEN 'closed'
										WHEN 3 THEN 'completed'
										ELSE ''
							END,
		@isRefund = CASE @statusid WHEN 4 THEN 1 
									WHEN 0 THEN NULL
									ELSE 0	END,						
		@UncalOnly = CASE WHEN @filterBy in (3,1) THEN 1 ELSE 0 END,				
		@UncalMultiOnly = CASE WHEN @filterBy in (3,2) THEN 1 ELSE 0 END			
	
	--ignore event status if selecting filterby
	IF (@UncalMultiOnly=1 OR @UncalOnly=1)
		SELECT @eventstatus= '', @isRefund=NULL
	
END
SELECT *
INTO #tmpMatch
FROM   
(
	SELECT m.matchid, m.leagueid ,
		hthomescore_ext AS hthomescore,
		htawayscore_ext AS htawayscore, 
		ISNULL(mr.calculate_ext,0) IsCalculated, ISNULL(mr.multiple_ext,0) IsMultiCaled,  
		ISNULL(mr.refund_ext,0) IsRefund, ISNULL(mr.calrefund_ext,0) IsCalRefund,  
		
		m.homeid, m.awayid,  
		m.matchcode, m.kickofftime,  
		m.finalhomescore_ext AS finalhomescore,  
		m.finalawayscore_ext AS finalawayscore,
		m.betstatus_ext AS betstatus,  
		CASE WHEN m.betstatus_ext LIKE 'Refund FT%' THEN 'Refund FT'  
		WHEN m.betstatus_ext LIKE 'Refund HT%' THEN 'Refund HT'  
		WHEN m.betstatus_ext LIKE 'Refund%' THEN 'Refund'  
		ELSE m.eventstatus_ext  
		END AS eventstatus,    
		m.sporttype,  
		ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,  
		m.eventdate,  
		m.GoalRecord_ext AS GoalRecord, 
		ISNULL(mr.IsHTCal_ext,0) AS IsHTCal,  		
		CAST(CASE WHEN hthomescore_ext IS NOT NULL AND htawayscore_ext IS NOT NULL AND finalhomescore_ext IS NOT NULL AND finalawayscore_ext IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS IsKeyscore
	
	FROM match m WITH (NOLOCK)  
		LEFT OUTER JOIN match_remark mr WITH (NOLOCK) ON m.matchid = mr.matchid  
	WHERE m.eventdate BETWEEN @FromDate AND @ToDate  
		AND m.leagueID = CASE WHEN @LeagueID <> 0 THEN @LeagueID ELSE m.leagueID END  
		AND m.sporttype = CASE WHEN @sporttype = 0 THEN m.sporttype ELSE @sporttype END  	  		
		AND (@matchcode = '' OR m.matchcode = @matchcode) 
		AND (m.matchcode NOT LIKE 'hedge%')
		AND (@eventstatus='' OR ISNULL(eventstatus_ext, 'running') = @eventstatus) 
		AND (@isRefund IS NULL OR
				(@isRefund =1 AND betstatus_ext like 'Refund%') or
				(@isRefund =0 AND ISNULL(betstatus_ext,'') not like 'Refund%') 
			)	  
		AND (@UncalOnly = 0 or (ISNULL(mr.calculate_ext,0) = 0 AND m.eventstatus_ext <> 'Completed'))  
		AND (@UncalMultiOnly = 0 or ISNULL(mr.multiple_ext,0) = 0)    
		AND CASE WHEN @UncalMultiOnly = 0 THEN 1   
			 WHEN @UncalMultiOnly = 1 THEN hthomescore_ext*htawayscore_ext*finalhomescore_ext*finalawayscore_ext  
		END IS NOT NULL  
) X 
ORDER BY  
	sporttype, leagueid, 
	CASE eventstatus WHEN 'completed' THEN 1 WHEN 'Refund' THEN 1 ELSE 0 END,  
	eventdate, kickofftime, matchid, matchcode

SELECT * FROM #tmpMatch WITH (NOLOCK)

SELECT ml.* FROM match_log ml WITH (NOLOCK) INNER JOIN #tmpMatch t WITH (NOLOCK)
ON (ml.Matchid = t.matchid)
ORDER BY LogId ASC

GRANT EXECUTE ON [dbo].[Acc_Set_MatchSel] TO [aplweb]