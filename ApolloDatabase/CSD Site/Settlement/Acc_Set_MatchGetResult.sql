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
		mr.hthomescore,
		mr.htawayscore,
		m.homeid, m.awayid,  
		m.matchcode, m.kickofftime,  
		mr.finalhomescore,  
		mr.finalawayscore, 
		mr.betstatus,  
		CASE WHEN mr.betstatus like 'Refund FT%' THEN 'Refund FT'  
		WHEN mr.betstatus like 'Refund HT%' THEN 'Refund HT'  
		WHEN mr.betstatus like 'Refund%' THEN 'Refund'  
		ELSE mr.eventstatus
		END AS eventstatus,    			
		m.sporttype,  
		CAST(isnull(m.isNeutral,0) AS BIT) AS IsNeutral,  
		m.eventdate,  
		mr.goalrecord,
		m.showtime,
		--ISNULL(mr.isPending,0) AS isPending,
		ISNULL(mr.calculate,0) AS calculate	,
		ISNULL(mr.IsHTCal,0) AS IsHTCal
	FROM match m WITH (NOLOCK)  
		LEFT JOIN match_remark_ex mr WITH (NOLOCK) ON m.matchid = mr.matchid  
	WHERE m.eventdate = @date
		AND m.leagueID = CASE WHEN @LeagueID <> 0 THEN @LeagueID ELSE m.leagueID END  
		AND m.sporttype = CASE WHEN @sporttype = 0 THEN m.sporttype ELSE @sporttype END 	
		AND (@eventstatus='' OR mr.eventstatus in (@eventstatus,'internal')) 
		AND (@isRefund IS NULL OR 
				(@isRefund =1 AND mr.betstatus LIKE 'Refund%') OR
				(@isRefund =0 AND ISNULL(mr.betstatus,'') NOT LIKE 'Refund%') 
			)	  	
) X 

ORDER BY  
	sporttype, leagueid, 
	CASE eventstatus WHEN 'completed' THEN 1 WHEN 'Refund' THEN 1 ELSE 0 END,  
	eventdate, kickofftime, matchid, matchcode

GO
GRANT EXECUTE ON [dbo].[Acc_Set_MatchGetResult] TO [aplweb]	