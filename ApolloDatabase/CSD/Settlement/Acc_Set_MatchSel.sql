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
 * DB			: SVRTXN/TransDB
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
CREATE TABLE #matchList
	(
		matchid INT,
		leagueid INT,
		hthomescore INT,
		htawayscore INT,
		IsCalculated BIT,
		IsMultiCaled BIT,
		IsRefund BIT,   
		IsCalRefund BIT,		
		homeid INT,
		awayid INT,
		matchcode NVARCHAR(50),
		kickofftime DATETIME, 
		finalhomescore INT,
		finalawayscore INT,   
		betstatus NVARCHAR(50),
		eventstatus NVARCHAR(50),                            		
		sporttype INT,
		IsNeutral BIT,
		eventdate  DATETIME,          
		goalrecord VARCHAR(50),                       		
		IsHTCal BIT,	
		IsKeyscore BIT,
		IsFGLG BIT
	)


INSERT INTO #matchList
EXEC SVRPro.ProdDB.dbo.[Acc_Set_MatchSelInfo] 	
	@FromDate ,
	@ToDate ,
	@sporttype ,
	@LeagueID , -- 0 for ALL Leagues
	@matchcode,
	@statusid ,
	@filterBy,
	@isReLoad

;WITH rs AS
	(
		SELECT matchid, COUNT(1) AS cnt
		FROM bettrans WITH(NOLOCK)
		WHERE matchid IN (SELECT matchid FROM #matchList)
			AND bettype = 14
		GROUP BY matchid 
	)
UPDATE m
SET IsFGLG = CASE WHEN rs.cnt = 0 OR rs.cnt IS NULL THEN 0 ELSE 1 END
FROM #matchList m
	LEFT JOIN rs ON m.matchid = rs.matchid

SELECT * 
FROM #matchList
ORDER BY  
	sporttype, leagueid, 
	CASE eventstatus WHEN 'completed' THEN 1 WHEN 'Refund' THEN 1 ELSE 0 END,  
	eventdate, kickofftime, matchid, matchcode

SELECT ml.* 
FROM match_log ml WITH (NOLOCK) INNER JOIN #matchList t WITH (NOLOCK)
	ON (ml.Matchid = t.matchid)
ORDER BY LogId ASC

DROP TABLE #matchList

GRANT EXECUTE ON [dbo].[Acc_Set_MatchSel] TO [aplweb]