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
 * DB			: SVRTXN/TransDB
 * Revisions	:
 	-20140523@Dan: Get 1H FGLG ticket info 
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
		calculate bit,
		hthomescore int,
		htawayscore int,
		finalhomescore int, 
		finalawayscore int,
		betstatus nvarchar(50),
		GoalRecord varchar(50),
		eventstatus nvarchar(50),
		FailedActionID tinyint NULL,
		DisabledAutoSettle BIT
		)		
INSERT INTO @m  
SELECT  
		m.matchid, 
		ISNULL(mr.calculate,0) IsCalculated, 
		ISNULL(mr.multiple,0) IsMultiCaled,  
		ISNULL(mr.refund,0) IsRefund, 
		ISNULL(mr.calrefund,0) IsCalRefund,  
		mr.IsHTCal AS IsHTCal,
		mr.calculate AS calculate,
		mr.hthomescore, mr.htawayscore,
		mr.finalhomescore, mr.finalawayscore,
		mr.betstatus,	mr.GoalRecord, mr.eventstatus, mr.FailedActionID, mr.DisabledAutoSettle 
FROM  SVRPRO.ProdDB.dbo.match m with (nolock)  
	LEFT JOIN SVRPRO.ProdDB.dbo.match_remark_ex mr with (nolock) ON m.matchid = mr.matchid  		
WHERE
	m.eventdate BETWEEN @FromDate AND @ToDate  
	AND m.leagueID = case when @LeagueID <> 0 then @LeagueID else m.leagueID end  
	AND m.sporttype = case when @sporttype = 0 then sporttype else @sporttype end 
	AND (@matchcode = '' OR m.matchcode = @matchcode) 
	AND (m.matchcode NOT LIKE 'hedge%')
	AND ISNULL(mr.eventstatus,N'running') <> N'Completed'  
	AND (m.kickofftime < DATEADD(s, -6000, CURRENT_TIMESTAMP) 
			--OR ConfirmFT > 0
		)  
UNION 
SELECT  
		m.matchid, 
		ISNULL(mr.calculate,0) IsCalculated, 
		ISNULL(mr.multiple,0) IsMultiCaled,  
		ISNULL(mr.refund,0) IsRefund, 
		ISNULL(mr.calrefund,0) IsCalRefund,  
		mr.IsHTCal AS IsHTCal,
		mr.calculate AS calculate,
		mr.hthomescore, mr.htawayscore,
		mr.finalhomescore, mr.finalawayscore,
		mr.betstatus,	mr.GoalRecord, mr.eventstatus, mr.FailedActionID , mr.DisabledAutoSettle 
FROM  SVRPRO.ProdDB.dbo.match m with (nolock)  
	LEFT JOIN SVRPRO.ProdDB.dbo.match_remark_ex mr with (nolock) ON m.matchid = mr.matchid  
	LEFT JOIN SVRPRO.ProdDB.dbo.match_remark with (nolock) ON m.matchid = match_remark.matchid  
	
WHERE
	m.eventdate BETWEEN @FromDate AND @ToDate  
	AND m.leagueID = case when @LeagueID <> 0 then @LeagueID else m.leagueID end  
	AND m.sporttype = case when @sporttype = 0 then sporttype else @sporttype end 
	AND (@matchcode = '' OR m.matchcode = @matchcode) 
	AND (m.matchcode NOT LIKE 'hedge%')
	AND ISNULL(mr.eventstatus,N'running') <> N'Completed'  
	AND (ConfirmFT > 0)  

SELECT *
INTO #tmpMatch
FROM  
(	SELECT  
		m.matchid,  
		m.leagueid,  
		tm.hthomescore AS hthomescore,
		tm.htawayscore AS htawayscore, 
		IsCalculated, IsMultiCaled,  
		IsRefund, IsCalRefund,  
		m.homeid,  
		m.awayid,  
		m.matchcode,  
		m.kickofftime,  
		tm.finalhomescore AS finalhomescore,  
		tm.finalawayscore AS finalawayscore,  
		tm.betstatus AS betstatus,  
		case when tm.betstatus like 'Refund FT%' then 'Refund FT'  
		when tm.betstatus like 'Refund HT%' then 'Refund HT'  
		when tm.betstatus like 'Refund%' then 'Refund'  
		else tm.eventstatus  
		end as eventstatus,  		
		m.sporttype,  	
		ISNULL(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,  
		m.eventdate,  
		tm.GoalRecord AS goalrecord, 	
		C.betcount,  	
		ISNULL(tm.IsHTCal,0) as IsHTCal,  
		ISNULL(tm.calculate,0) as calculate,  
		CAST(CASE WHEN tm.hthomescore IS NOT NULL AND tm.htawayscore IS NOT NULL AND tm.finalhomescore IS NOT NULL AND tm.finalawayscore IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS IsKeyscore ,		
		CASE WHEN c.cntFGLG = 0 THEN 0 ELSE 1 END as isExistFGLG,
		CASE WHEN c.cntHTFGLG = 0 THEN 0 ELSE 1 END as isExistHTFGLG,
		tm.FailedActionID ,
		DisabledAutoSettle 
	FROM SVRPRO.ProdDB.dbo.match m with (nolock)  
		INNER JOIN @m tm ON m.matchid = tm.matchid  
		INNER JOIN (  
					SELECT b.matchid, count(b.matchid) AS BetCount 							
							,SUM(CASE WHEN bettype = 14 THEN 1 ELSE 0 END) AS cntFGLG
							,SUM(CASE WHEN bettype = 127 THEN 1 ELSE 0 END) AS cntHTFGLG
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

GO
GRANT EXECUTE ON [dbo].[Acc_Set_MatchSelCompleted] TO [aplweb]	

