ALTER PROCEDURE [dbo].[Acc_Set_MatchSelNumberGameDetail]
	@matchid int	
AS
/**
 * Created by	: Kaden
 * Date			: 20130318
 * Task			: Get detail info of a number game match
 * DB			: APL.RepDB
 * Revisions	:
 *	•
 * Parameters:
 * @@matchid: match id
 *  
 */
   
SET NOCOUNT ON  

SELECT   	
	m.matchid,
	m.matchcode,  	 
	m.kickofftime,	
	b.seq,
	CAST(b.number AS VARCHAR(20)) AS number
FROM  
   (SELECT matchid, matchcode, kickofftime
	FROM MATCH (NOLOCK)  
    WHERE	matchid=@matchid
	UNION ALL  
	SELECT matchid, matchcode, kickofftime
	FROM match14 (NOLOCK)  
	WHERE matchid=@matchid
   )AS m 
	LEFT OUTER JOIN (SELECT matchid, seq, number FROM bingoball(NOLOCK)
				UNION ALL
				SELECT matchid, seq, number FROM bingoball14(NOLOCK)
				) AS B ON B.matchid = m.matchid
ORDER BY b.seq
GRANT EXECUTE ON [dbo].[Acc_Set_MatchSelNumberGameDetail] TO [aplweb]	