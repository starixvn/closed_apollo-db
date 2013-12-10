ALTER PROCEDURE [dbo].[Acc_Set_MatchSelInfo]
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
 * Created by	: Dan
 * Date			: 20130409
 * Task			: Match results 
 * DB			: SVRPRO/ProdDB
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

SELECT m.matchid, m.leagueid ,
		mr.hthomescore AS hthomescore,
		mr.htawayscore AS htawayscore, 
		ISNULL(mr.calculate,0) IsCalculated, ISNULL(mr.multiple,0) IsMultiCaled,  
		ISNULL(mr.refund,0) IsRefund, ISNULL(mr.calrefund,0) IsCalRefund,  
		m.homeid, m.awayid,
		m.matchcode, m.kickofftime,  
		mr.finalhomescore AS finalhomescore,  
		mr.finalawayscore AS finalawayscore,
		mr.betstatus AS betstatus, 
		CASE WHEN mr.betstatus LIKE 'Refund FT%' THEN 'Refund FT'  
			WHEN mr.betstatus LIKE 'Refund HT%' THEN 'Refund HT'  
			WHEN mr.betstatus LIKE 'Refund%' THEN 'Refund'  
			ELSE mr.eventstatus  
		END AS eventstatus,    
		m.sporttype,  
		ISNULL(m.isNeutral, CONVERT(BIT,0)) AS IsNeutral,  
		m.eventdate,  
		mr.GoalRecord AS GoalRecord, 
		ISNULL(mr.IsHTCal,0) AS IsHTCal,  		
		CAST(CASE WHEN mr.hthomescore IS NOT NULL AND mr.htawayscore IS NOT NULL AND mr.finalhomescore IS NOT NULL AND mr.finalawayscore IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS IsKeyscore
		,0 AS IsFGLG
		,FailedActionID
		,DisabledAutoSettle
FROM dbo.match m WITH(NOLOCK) 
	LEFT JOIN dbo.match_remark_ex mr WITH(NOLOCK) ON m.matchid = mr.matchid  	
WHERE m.eventdate BETWEEN @FromDate AND @ToDate  
	AND m.leagueID = CASE WHEN @LeagueID <> 0 THEN @LeagueID ELSE m.leagueID END  
	AND m.sporttype = CASE WHEN @sporttype = 0 THEN m.sporttype ELSE @sporttype END  	  		
	AND (@matchcode = '' OR m.matchcode = @matchcode) 
	AND (m.matchcode NOT LIKE 'hedge%')
	AND (@eventstatus='' OR ISNULL(mr.eventstatus, 'running') = @eventstatus) 
	AND (@isRefund IS NULL OR
			(@isRefund =1 AND mr.betstatus like 'Refund%') or
			(@isRefund =0 AND ISNULL(mr.betstatus,'') not like 'Refund%') 
		)	  
	AND (@UncalOnly = 0 or ISNULL(mr.calculate,0) = 0)  --AND mr.eventstatus <> 'Completed')			
	AND (@UncalMultiOnly = 0 or ISNULL(mr.multiple,0) = 0)    
	AND CASE WHEN @UncalMultiOnly = 0 THEN 1   
			WHEN @UncalMultiOnly = 1 THEN mr.hthomescore*mr.htawayscore*mr.finalhomescore*mr.finalawayscore  
	END IS NOT NULL 
GO
GRANT EXECUTE ON [dbo].[Acc_Set_MatchSelInfo] TO [aplweb]	