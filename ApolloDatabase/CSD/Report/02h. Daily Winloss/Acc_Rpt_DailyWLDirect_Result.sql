ALTER PROCEDURE [dbo].[Acc_Rpt_DailyWLDirect_Result]
	@MatchID int,
	@Bettype int 
	---@TraderName nvarchar(100) OUTPUT
AS
/*
Created: Sophia
Date: 20130816
Task: Get result in report 2h
DB: SVRCSD.RepDB
Original: 

Revisions:    
	
*/
SET NOCOUNT ON
IF EXISTS (SELECT 1 FROM match WITH(NOLOCK) WHERE matchid = @matchid)
BEGIN	
	SELECT 
		m.betstatus, 
		m.hthomescore,
		m.htawayscore,
		datediff(minute,kickofftime,CURRENT_TIMESTAMP) playtime,
		m.LeagueID,
		m.homeID,
		m.awayID,
		m.matchcode,
		m.kickofftime,
		m.eventdate,
		m.finalhomescore,
		m.finalawayscore,
		case	when m.betstatus like 'Refund FT%' then 'Refund FT' 
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
	FROM match m WITH(NOLOCK)
		LEFT OUTER JOIN match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid
	WHERE m.matchid = @matchid
	
	--SELECT @TraderName = c.username
	--FROM  Dot_Admin_Assignment_Operator o WITH (NOLOCK)
	--	INNER JOIN customer c with(nolock) on o.OperatorID = c.custid
	--WHERE matchid = @MatchID 
	--	AND @Bettype = CASE WHEN bettype IN (1,5) AND OperatorType = 1 THEN 1
	--						WHEN bettype = 1 AND OperatorType = 2 THEN 7
	--						WHEN bettype = 2 AND OperatorType = 1 THEN 3
	--						WHEN bettype = 2 AND OperatorType = 2 THEN 8
	--						WHEN bettype = 3 AND OperatorType = 1 THEN 5
	--						WHEN bettype = 3 AND OperatorType = 2 THEN 15
	--						WHEN bettype = 4 AND OperatorType = 1 THEN 2
	--						WHEN bettype = 4 AND OperatorType = 2 THEN 12
	--						END
END
ELSE 
IF EXISTS(SELECT 1 FROM match14 WITH(NOLOCK) WHERE matchid = @matchid)	
BEGIN	
	SELECT 
		m.betstatus, 
		m.hthomescore,
		m.htawayscore,
		datediff(minute,kickofftime,CURRENT_TIMESTAMP) playtime,
		m.LeagueID,
		m.homeID,
		m.awayID,
		m.matchcode,
		m.kickofftime,
		m.eventdate,
		m.finalhomescore,
		m.finalawayscore,
		case	when m.betstatus like 'Refund FT%' then 'Refund FT' 
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
	FROM match14 m WITH(NOLOCK)
		LEFT OUTER JOIN match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid
	WHERE m.matchid = @matchid
	
	--SELECT @TraderName = c.username
	--FROM  DBARC.bodb_archive.dbo.Dot_Admin_Assignment_Operator_bk o WITH (NOLOCK)
	--	INNER JOIN customer c with(nolock) on o.OperatorID = c.custid
	--WHERE matchid = @MatchID 
	--	AND @Bettype = CASE WHEN bettype IN (1,5) AND OperatorType = 1 THEN 1
	--						WHEN bettype = 1 AND OperatorType = 2 THEN 7
	--						WHEN bettype = 2 AND OperatorType = 1 THEN 3
	--						WHEN bettype = 2 AND OperatorType = 2 THEN 8
	--						WHEN bettype = 3 AND OperatorType = 1 THEN 5
	--						WHEN bettype = 3 AND OperatorType = 2 THEN 15
	--						WHEN bettype = 4 AND OperatorType = 1 THEN 2
	--						WHEN bettype = 4 AND OperatorType = 2 THEN 12
	--						END
END

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_DailyWLDirect_Result] TO [aplweb]
GO