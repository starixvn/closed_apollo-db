ALTER PROCEDURE [dbo].[Acc_UserLog_Settle_MatchSelByID]
	@matchid INT
AS
/**
 * Created by	: Kaden
 * Date			: 20130403
 * Task			: View match info - settlement log
 * DB			: SVRAGE/LogDB
 * Revisions	:
 *	•
 * Parameters:
	@matchId: Match Id
*/

SET NOCOUNT ON
SELECT 
	l.logid,
	l.logdate,	
	o.username,
	la.ActionName,
    l.finalhomescore,
    l.finalawayscore,  
    l.hthomescore,
    l.htawayscore,
    l.GoalRecord,
    l.betstatus,
    l.Remark,
	l.IP
FROM Settlement l WITH(NOLOCK)	
	LEFT JOIN LogAction la WITH (NOLOCK) ON l.ActionID = la.ActionID
	LEFT JOIN SVRAGE.CustDB.dbo.AdminInfo o WITH(NOLOCK) ON o.AdminId = l.userid
WHERE l.matchid = @matchid
ORDER BY logdate ASC
GRANT EXECUTE ON [dbo].[Acc_UserLog_Settle_MatchSelByID] TO [aplweb]

