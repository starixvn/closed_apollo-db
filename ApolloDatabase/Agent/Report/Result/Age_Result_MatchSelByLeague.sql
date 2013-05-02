ALTER PROCEDURE [dbo].[Age_Result_MatchSelByLeague]
	@FromDate DATETIME,
	@LeagueID INT,
	@Language NVARCHAR(2) = 'E',
	@sporttype smallint = 0,
	@isShowAll bit = 1 -- 1: Show All; 0: is NOT show Test	

AS
/*
Created: Sophia
Date: 20130401
Task: 
DB: SVRAGE.RepDB
Original: Age_Result_MatchSelByLeague
Revision:
	
*/
SET NOCOUNT ON 
	
declare @ToDate datetime
Select @ToDate = dateadd(s,-1, dateadd(d, 1, @FromDate))


if @LeagueID <> 0
BEGIN
	select 
		l.sporttype, 
		betstatus, 
		m.leagueid,
		m.matchid,
		l.lcolor, 
		m.matchcode,
		m.eventdate, 
		m.kickofftime,
		m.homeID,
		m.awayID,
		m.hthomescore,
		m.htawayscore, 
		m.finalhomescore,
		m.finalawayscore,
		case when m.betstatus like 'Refund FT%' then 'Refund FT' 
			 when m.betstatus like 'Refund HT%' then 'Refund HT'
			 when m.betstatus like 'Refund%' then 'Refund' 
		else m.eventstatus end as eventstatus,  
		m.showtime,
		m.homeid2 , 
		isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
		m.goalrecord,
		ISNULL(mr.IsHTCal,0) as IsHTCal,
		ISNULL(mr.calculate,0) as calculate	,
		ISNULL(mr.IsPending,0) as IsPending
	from
		league l (nolock) 
		inner join
			( select sporttype, betstatus,matchid, matchcode, homeid, awayid, leagueid, eventdate, eventstatus, kickofftime, hthomescore, htawayscore, finalhomescore, finalawayscore, showtime, isneutral,goalrecord,homeid2
			from match (nolock)
			UNION ALL
			select sporttype, betstatus,matchid, matchcode, homeid, awayid, leagueid, eventdate, eventstatus, kickofftime, hthomescore, htawayscore, finalhomescore, finalawayscore, showtime, isneutral,goalrecord,homeid2
			from match14 (nolock)
			) as m on m.leagueid=l.leagueid	
		LEFT OUTER JOIN match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid
	where
		l.leagueid = @leagueid
		and m.eventdate >= @FromDate
		and m.eventdate <= @ToDate			
		and (m.eventstatus not in ('internal','closed','running')
				OR ( mr.IsPending=1 AND m.eventstatus IN ('running','closed') )
				OR ( mr.IsHTCal = 1 AND m.eventstatus ='running')
			)
		and (m.sporttype <= 99 OR m.sporttype = 161)
		and m.sporttype = case when @sporttype = 0 then m.sporttype else @sporttype end
		and m.matchcode not like '%hedge%'	
		and m.matchcode not like '%betdaq%'
		---and (isnull(@site,'')='789y' OR  (m.matchcode not like '%(LR)%' and isnull(@site,'')<>'789y'))
		and (l.isTest = 0 OR @isShowAll = 1)
	order by m.eventdate, m.sporttype, m.leagueid
END
else
BEGIN
	select 
		l.sporttype, 
		betstatus, 
		m.leagueid,
		m.matchid,
		l.lcolor, 
		m.matchcode,
		m.eventdate, 
		m.kickofftime,
		m.homeID,
		m.awayID,
		m.hthomescore,
		m.htawayscore, 
		m.finalhomescore,
		m.finalawayscore,
		case when m.betstatus like 'Refund FT%' then 'Refund FT' 
			 when m.betstatus like 'Refund HT%' then 'Refund HT'
			 when m.betstatus like 'Refund%' then 'Refund' 
		else m.eventstatus end as eventstatus,  
		m.showtime,
		isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
		m.goalrecord,
		m.homeid2, 
		ISNULL(mr.IsHTCal,0) as IsHTCal,
		ISNULL(mr.calculate,0) as calculate	,
		ISNULL(mr.IsPending,0) as IsPending	
	from league l (nolock) inner join
		( select sporttype, betstatus,matchid, matchcode, homeid, awayid, leagueid, eventdate, eventstatus, kickofftime, hthomescore, htawayscore, finalhomescore, finalawayscore, showtime, isneutral,goalrecord,homeid2
		from match (nolock)
		UNION ALL
		select sporttype, betstatus,matchid, matchcode, homeid, awayid, leagueid, eventdate, eventstatus, kickofftime, hthomescore, htawayscore, finalhomescore, finalawayscore, showtime, isneutral,goalrecord,homeid2
		from match14 (nolock)
		) as m on m.leagueid=l.leagueid	
		LEFT OUTER JOIN match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid
	where
		m.eventdate >= @FromDate
		and m.eventdate <= @ToDate
		and (m.eventstatus not in ('internal','closed','running')
				OR ( mr.IsPending=1 AND m.eventstatus IN ('running','closed') )
				OR ( mr.IsHTCal = 1 AND m.eventstatus ='running')
			)
		and (m.sporttype <= 99 )----OR m.sporttype = 161)
		and m.sporttype = case when @sporttype = 0 then m.sporttype else @sporttype end
		and m.matchcode not like '%hedge%'
		and m.matchcode not like '%betdaq%'
		----and (isnull(@site,'')='789y' OR  (m.matchcode not like '%(LR)%' and isnull(@site,'')<>'789y'))
		and (l.isTest = 0 OR @isShowAll = 1)
	order by m.eventdate, m.sporttype, m.leagueID
END
GO

GRANT EXECUTE ON [dbo].[Age_Result_MatchSelByLeague] TO [aplWeb]
GO
--GRANT VIEW DEFINITION ON [dbo].[Age_Result_MatchSelByLeague] TO [vnteam]
