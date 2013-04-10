CREATE PROCEDURE [dbo].[Acc_Set_MatchGetResult]
	@Date datetime,	
	@sporttype tinyint,
	@LeagueID int = 0, -- 0 for ALL Leagues	
	@statusid tinyint = 0
AS 
/**
 * Created by	: Kaden
 * Date			: 20130318
 * Task			: View Match results on Settlement 
 * DB			: SVRPRO/ProdDB
 * Revisions	:
 *	•
 * Parameters:
 *
	@sporttype: show info of particular sport
	@LeagueID: = 0: show info of all leagues    	
	@statusid: 0: all, 1: running; 2: closed; 3: completed; 4: refund; 
 *  
 */
    
  
SET NOCOUNT ON  
DECLARE @eventstatus NVARCHAR(50),
		@isRefund BIT
	
IF (@sporttype IN (151,152,153))
BEGIN
	SELECT *
	FROM   
	(	SELECT 
			o.groupmatch, --Race   
			o.leagueid ,   
			IsFavor,  --TF  
			o.IsSCR,  --SCR  
			o.teamid, 
			o.matchcode,   --Horse   
			o.kickofftime,  
			o.odds,  
			o.placeodds,   
			CASE WHEN o.placing = 0 THEN '5' ELSE ISNULL(CONVERT(VARCHAR(2),placing) ,5) END placing, --Placing  
			o.oddsstatus AS eventstatus,			
			l.sporttype,  
			CAST(0 AS BIT) IsNeutral,  
			o.eventdate  	  
		FROM	outright o WITH (NOLOCK)  
				INNER JOIN league l WITH (NOLOCK) ON  o.leagueid = l.leagueid   
		WHERE	o.eventdate = @Date
				AND l.sporttype = @sporttype 								
				AND o.leagueid = CASE WHEN @leagueid =0 THEN o.leagueid  ELSE @leagueid END
				AND (o.oddsstatus ='completed' OR o.Foddsstatus='completed') 		
	) X 

	ORDER BY  
		sporttype, leagueid, 
		CASE eventstatus WHEN 'completed' THEN 1 WHEN 'Refund' THEN 1 ELSE 0 END,  
		eventdate, kickofftime, groupmatch, placing, matchcode
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
								
	SELECT *
	FROM   
	(
		SELECT m.matchid, m.leagueid ,
			hthomescore_ext hthomescore,
			htawayscore_ext htawayscore,
			m.homeid, m.awayid,  
			m.matchcode, m.kickofftime,  
			m.finalhomescore_ext finalhomescore,  
			m.finalawayscore_ext finalawayscore, 
			m.betstatus_ext betstatus,  
			CASE WHEN m.betstatus_ext like 'Refund FT%' THEN 'Refund FT'  
			WHEN m.betstatus_ext like 'Refund HT%' THEN 'Refund HT'  
			WHEN m.betstatus_ext like 'Refund%' THEN 'Refund'  
			ELSE m.eventstatus_ext  
			END AS eventstatus,    			
			m.sporttype,  
			CAST(isnull(m.isNeutral,0) AS BIT) AS IsNeutral,  
			m.eventdate,  
			m.goalrecord_ext goalrecord,
			m.showtime,
			ISNULL(mr.isPending,0) AS isPending,
			ISNULL(mr.calculate_ext,0) AS calculate	,
			ISNULL(mr.IsHTCal_ext,0) AS IsHTCal
		FROM match m WITH (NOLOCK)  
			LEFT JOIN match_remark mr WITH (NOLOCK) ON m.matchid = mr.matchid  
		WHERE m.eventdate = @date
			AND m.leagueID = CASE WHEN @LeagueID <> 0 THEN @LeagueID ELSE m.leagueID END  
			AND m.sporttype = CASE WHEN @sporttype = 0 THEN m.sporttype ELSE @sporttype END 	
			AND (@eventstatus='' OR eventstatus_ext in (@eventstatus,'internal')) 
			AND (@isRefund IS NULL OR 
					(@isRefund =1 AND betstatus_ext LIKE 'Refund%') OR
					(@isRefund =0 AND ISNULL(betstatus_ext,'') NOT LIKE 'Refund%') 
				)	  	
	) X 

	ORDER BY  
		sporttype, leagueid, 
		CASE eventstatus WHEN 'completed' THEN 1 WHEN 'Refund' THEN 1 ELSE 0 END,  
		eventdate, kickofftime, matchid, matchcode
END	
GRANT EXECUTE ON [dbo].[Acc_Set_MatchGetResult] TO [aplweb]	