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
				m.betstatus, 
				hthomescore,
				htawayscore,
				datediff(minute,kickofftime,CURRENT_TIMESTAMP) playtime,
				m.LeagueID,
				m.matchid, 
				m.homeID,
				m.awayID,
				m.matchcode,
				m.kickofftime,
				m.eventdate,
				m.finalhomescore,
				m.finalawayscore,
				case when m.betstatus like 'Refund FT%' then 'Refund FT' 
							 when m.betstatus like 'Refund HT%' then 'Refund HT'
							 when m.betstatus like 'Refund%' then 'Refund' 
							else m.eventstatus end as eventstatus,
				isnull(mr.refund,0) IsRefund, 
				isnull(mr.calrefund,0) IsCalRefund,
				isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
				m.goalrecord,
				ISNULL(mr.IsHTCal,0) as IsHTCal,
				ISNULL(mr.calculate,0) as calculate	,
				ISNULL(mr.IsPending,0) as IsPending	,
				m.showtime
			FROM match m WITH(NOLOCK)
				LEFT OUTER JOIN match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid
			WHERE m.matchid = @matchid
			ORDER BY m.eventdate,m.matchcode
			RETURN
		END

		IF exists(SELECT 1 FROM match14 WITH(NOLOCK) WHERE matchid = @matchid)	
		BEGIN
			SELECT 
				m.sporttype, 
				m.betstatus, 
				hthomescore,
				htawayscore,
				datediff(minute,kickofftime,CURRENT_TIMESTAMP) playtime,
				m.LeagueID,
				m.matchid, 
				m.homeID,
				m.awayID,
				m.matchcode,
				m.kickofftime,
				m.eventdate,
				m.finalhomescore,
				m.finalawayscore,
				case when m.betstatus like 'Refund FT%' then 'Refund FT' 
							 when m.betstatus like 'Refund HT%' then 'Refund HT'
							 when m.betstatus like 'Refund%' then 'Refund' 
							else m.eventstatus end as eventstatus,
				isnull(mr.refund,0) IsRefund, 
				isnull(mr.calrefund,0) IsCalRefund,
				isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
				m.goalrecord,
				ISNULL(mr.IsHTCal,0) as IsHTCal,
				ISNULL(mr.calculate,0) as calculate,
				ISNULL(mr.IsPending,0) as IsPending	,
				m.showtime
			FROM match14 m WITH(NOLOCK)		
				LEFT OUTER JOIN match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid
			WHERE m.matchid = @matchid
			ORDER BY m.eventdate,m.matchcode
			RETURN
		END
		ELSE
		BEGIN
			SELECT 
				m.sporttype, 
				m.betstatus, 
				hthomescore,
				htawayscore,
				datediff(minute,kickofftime,CURRENT_TIMESTAMP) playtime,
				m.LeagueID,
				m.matchid, 
				m.homeID,
				m.awayID,
				m.matchcode,
				m.eventdate,
				m.kickofftime,
				m.finalhomescore,
				m.finalawayscore,
				case when m.betstatus like 'Refund FT%' then 'Refund FT' 
							 when m.betstatus like 'Refund HT%' then 'Refund HT'
							 when m.betstatus like 'Refund%' then 'Refund' 
							else m.eventstatus end as eventstatus,
				isnull(mr.refund,0) IsRefund,  
				isnull(mr.calrefund,0) IsCalRefund,
				isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
				m.goalrecord,
				ISNULL(mr.IsHTCal,0) as IsHTCal,
				ISNULL(mr.calculate,0) as calculate,
				ISNULL(mr.IsPending,0) as IsPending,
				m.showtime 
			FROM SVRARC.archiveDB.dbo.Match_BK m WITH(NOLOCK)		
				LEFT OUTER JOIN match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid
			WHERE m.matchid = @matchid
			ORDER BY m.eventdate,m.matchcode
		END						
	END
	

GO
GRANT EXECUTE ON [dbo].[Age_BetList_SelMatchResult] TO aplweb
GO
--GRANT VIEW DEFINITION ON [dbo].[Age_BetList_SelMatchResult] TO [vnteam]