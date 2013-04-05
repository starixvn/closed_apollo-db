
CREATE PROCEDURE [dbo].[Acc_Set_MatchSelNumberGame]
	@FromDate		DATETIME,
	@ToDate			DATETIME = NULL,
	@LeagueID		INT,
	@matchcode		NVARCHAR(50) = '',
	@statusid		TINYINT = 0,
	@isReLoad		bit = 0
AS
/**
 * Created by	: Kaden
 * Date			: 20130318
 * Task			: Get Number Game result 
 * DB			: APL.RepDB
 * Revisions	:
 *	•
 * Parameters:
	@matchcode: match code
	@LeagueID: = 0: show info of all leagues     
	@statusid: 0: all, 1: running; 2: closed; 3: completed; 4: refund;   
	@isReLoad: 1: reload partial matches of a league, 0: not reload
 *  
 */
   
SET NOCOUNT ON  
DECLARE @eventstatus NVARCHAR(50),
		@isRefund BIT,
		@matchid INT

IF @ToDate IS NULL
BEGIN
	SELECT @ToDate = DATEADD(s,-1, DATEADD(d, 1, @FromDate))  
END  

SELECT @matchcode = ISNULL(@matchcode,''), @LeagueID = ISNULL(@LeagueID,0)
-- if entering matcode, ignore other params (excep FromDate, ToDate)
IF (@matchcode <> '')
BEGIN
	SELECT @eventstatus= '', @isRefund=0, 
			@LeagueID = CASE WHEN @isReLoad = 1 THEN @LeagueID ELSE 0 END -- reload partial; search on LeagueID, not reload: get all leagues
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
									ELSE 0	END			
END

SELECT   
	m.betstatus,   
	m.leagueid,  
	m.matchid,
	m.matchcode,  
	m.eventdate,   
	m.kickofftime,
	m.homeid,
	CASE WHEN m.betstatus LIKE 'Refund FT%' THEN 'Refund FT'   
		 WHEN m.betstatus LIKE 'Refund HT%' THEN 'Refund HT'  
		 WHEN m.betstatus LIKE 'Refund%' THEN 'Refund'   
		 ELSE m.eventstatus END AS eventstatus,
	CAST(CASE WHEN m.betstatus LIKE 'Refund' THEN 1   
		 ELSE 0 END AS BIT) AS IsRefund,
	b.seq,
	CAST(b.number AS VARCHAR(20)) AS number
FROM  
   (SELECT sporttype, betstatus, matchid, matchcode, leagueid, eventdate, eventstatus, kickofftime, homeid  
	FROM MATCH (NOLOCK)  
    WHERE	eventdate BETWEEN  @FromDate  AND  @ToDate 
			AND sporttype=161
			AND (@LeagueID = 0 OR leagueid = @LeagueID)
	UNION ALL  
	SELECT sporttype, betstatus, matchid, matchcode, leagueid, eventdate, eventstatus, kickofftime,homeid   
	FROM match14 (NOLOCK)  
	WHERE	eventdate BETWEEN  @FromDate  AND  @ToDate 
			AND sporttype=161
			AND (@LeagueID = 0 OR leagueid = @LeagueID)
   )AS m 
	LEFT OUTER JOIN (SELECT matchid, seq, number FROM bingoball(NOLOCK)
				UNION ALL
				SELECT matchid, seq, number FROM bingoball14(NOLOCK)
				) AS B ON B.matchid = m.matchid
	LEFT OUTER JOIN match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid  
WHERE (m.eventstatus NOT IN ('internal','running')  
			OR (m.eventstatus = 'running' AND mr.ishtcal=1)
		)		
		AND (@matchcode = '' OR (m.matchid = @matchid OR m.matchcode = @matchcode)) 
		AND (@eventstatus='' OR eventstatus IN (@eventstatus)) 
		AND (@isRefund is null OR 
				(@isRefund =1 AND betstatus LIKE 'Refund%') OR
				(@isRefund =0 AND ISNULL(betstatus,'') NOT LIKE 'Refund%') 
			)	  
ORDER BY m.leagueid, m.matchid, b.seq
GRANT EXECUTE ON [dbo].[Acc_Set_MatchSelNumberGame] TO [aplweb]	
  
  

