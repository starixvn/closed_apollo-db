ALTER PROCEDURE [dbo].[Age_BetList_SelMatchResult]
	@MatchID int 	
AS

/*  
Created: Sophia 
Date : 20130401
Task : Get Result
DB:  SVRAGE.RepDB
Original:  
Revisions:  
     
*/

SET NOCOUNT ON
	
	BEGIN
		IF exists(SELECT 1 FROM match WITH(NOLOCK) WHERE matchid = @matchid)
		BEGIN	
			SELECT 
				m.sporttype, 
				ISNULL(e.betstatus, '') AS betstatus,
				ISNULL(e.hthomescore,0) AS hthomescore,
				ISNULL(e.htawayscore,0) AS htawayscore,
				ISNULL(e.finalhomescore,0) AS finalhomescore ,
				ISNULL(e.finalawayscore,0) AS finalawayscore,
				datediff(minute,kickofftime,CURRENT_TIMESTAMP) playtime,
				m.LeagueID,
				m.matchid, 
				m.homeID,
				m.awayID,
				m.matchcode,
				m.kickofftime,
				m.eventdate,				
				CASE WHEN ISNULL(e.betstatus,'') like 'Refund FT%' THEN 'Refund FT' 
							 WHEN ISNULL(e.betstatus,'') like 'Refund HT%' THEN 'Refund HT'
							 WHEN ISNULL(e.betstatus,'') like 'Refund%' THEN 'Refund' 
							ELSE ISNULL(e.eventstatus,'') END as eventstatus,
				isnull(e.refund,0) IsRefund, 
				isnull(e.calrefund,0) IsCalRefund,
				isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
				ISNULL(e.goalrecord, '') AS goalrecord,
				ISNULL(e.IsHTCal,0) as IsHTCal,
				ISNULL(e.calculate,0) as calculate	,
				ISNULL(mr.IsPending,0) as IsPending	,
				m.showtime
			FROM match m WITH(NOLOCK)
				LEFT OUTER JOIN match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid
				LEFT OUTER JOIN match_remark_ex e WITH(NOLOCK) ON m.matchid = e.matchid
			WHERE m.matchid = @matchid
			ORDER BY m.eventdate,m.matchcode
			RETURN
		END

		IF exists(SELECT 1 FROM match14 WITH(NOLOCK) WHERE matchid = @matchid)	
		BEGIN
			SELECT 
				m.sporttype, 
				ISNULL(e.betstatus, '') AS betstatus,
				ISNULL(e.hthomescore,0) AS hthomescore,
				ISNULL(e.htawayscore,0) AS htawayscore,
				ISNULL(e.finalhomescore,0) AS finalhomescore ,
				ISNULL(e.finalawayscore,0) AS finalawayscore,
				datediff(minute,kickofftime,CURRENT_TIMESTAMP) playtime,
				m.LeagueID,
				m.matchid, 
				m.homeID,
				m.awayID,
				m.matchcode,
				m.kickofftime,
				m.eventdate,
				CASE WHEN ISNULL(e.betstatus,'') like 'Refund FT%' THEN 'Refund FT' 
							 WHEN ISNULL(e.betstatus,'') like 'Refund HT%' THEN 'Refund HT'
							 WHEN ISNULL(e.betstatus,'') like 'Refund%' THEN 'Refund' 
							ELSE ISNULL(e.eventstatus,'') END as eventstatus,
				isnull(e.refund,0) IsRefund, 
				isnull(e.calrefund,0) IsCalRefund,
				isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
				ISNULL(e.goalrecord, '') AS goalrecord,
				ISNULL(e.IsHTCal,0) as IsHTCal,
				ISNULL(e.calculate,0) as calculate	,
				ISNULL(mr.IsPending,0) as IsPending	,
				m.showtime
			FROM match14 m WITH(NOLOCK)		
				LEFT OUTER JOIN match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid
				LEFT OUTER JOIN match_remark_ex e WITH(NOLOCK) ON m.matchid = e.matchid
			WHERE m.matchid = @matchid
			ORDER BY m.eventdate,m.matchcode
			RETURN
		END
		ELSE
		BEGIN
			SELECT 
				m.sporttype, 
				ISNULL(e.betstatus, '') AS betstatus,
				ISNULL(e.hthomescore,0) AS hthomescore,
				ISNULL(e.htawayscore,0) AS htawayscore,
				ISNULL(e.finalhomescore,0) AS finalhomescore ,
				ISNULL(e.finalawayscore,0) AS finalawayscore,
				datediff(minute,kickofftime,CURRENT_TIMESTAMP) playtime,
				m.LeagueID,
				m.matchid, 
				m.homeID,
				m.awayID,
				m.matchcode,
				m.kickofftime,
				m.eventdate,
				CASE WHEN ISNULL(e.betstatus,'') like 'Refund FT%' THEN 'Refund FT' 
							 WHEN ISNULL(e.betstatus,'') like 'Refund HT%' THEN 'Refund HT'
							 WHEN ISNULL(e.betstatus,'') like 'Refund%' THEN 'Refund' 
							ELSE ISNULL(e.eventstatus,'') END as eventstatus,
				isnull(e.refund,0) IsRefund, 
				isnull(e.calrefund,0) IsCalRefund,
				isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
				ISNULL(e.goalrecord, '') AS goalrecord,
				ISNULL(e.IsHTCal,0) as IsHTCal,
				ISNULL(e.calculate,0) as calculate	,
				ISNULL(mr.IsPending,0) as IsPending	,
				m.showtime
			FROM SVRARC.ArchiveDB.dbo.Match_BK m WITH (NOLOCK)		
				LEFT OUTER JOIN match_remark mr WITH (NOLOCK) ON m.matchid = mr.matchid
				LEFT OUTER JOIN match_remark_ex e WITH (NOLOCK) ON m.matchid = e.matchid
			WHERE m.matchid = @matchid
			ORDER BY m.eventdate,m.matchcode
		END						
	END
	

GO
GRANT EXECUTE ON [dbo].[Age_BetList_SelMatchResult] TO aplweb
GO
--GRANT VIEW DEFINITION ON [dbo].[Age_BetList_SelMatchResult] TO [vnteam]