ALTER PROCEDURE [dbo].[Age_BetList_SelMatchResultParlay]
	@refno	BIGINT
AS
/*
Created: 20130502@Sophia
Task : Select MixParlay result
DB: SVRAGE.RepDB
Original:  
Revisions:
   
*/
BEGIN
	SET NOCOUNT ON
	DECLARE	@tmpParlay TABLE(
		sporttype	TINYINT,
		leagueid	INT,
		matchid		INT,
		homeID		INT,
		awayID		INT,
		hthomescore	INT,
		htawayscore	INT,
		finalhomescore INT,
		finalawayscore INT,
		kickofftime DATETIME,
		eventdate	DATETIME,
		isNeutral	BIT,
		betstatus	VARCHAR(50),
		eventstatus	VARCHAR(15),
		IsRefund	BIT,
		IsCalRefund	BIT,
		goalrecord	VARCHAR(50),
		matchcode	VARCHAR(50),
		isHTCal		BIT,
		calculate	BIT,
		IsPending	BIT
	)
	IF EXISTS (SELECT 1 FROM bettransm WITH (NOLOCK) WHERE  refno = @refno)
	BEGIN
		INSERT INTO @tmpParlay (
			sporttype, 	
			LeagueID,
			matchid, 	
			homeID,
			awayID,
			hthomescore,
			htawayscore,		
			finalhomescore,
			finalawayscore,
			kickofftime,
			eventdate,
			isNeutral,
			betstatus, 	
			eventstatus,
			IsRefund ,
			IsCalRefund,
			goalrecord,
			matchcode,
			isHTCal,
			calculate,
			IsPending
		)
		SELECT	m.sporttype, 	
				m.LeagueID,
				m.matchid, 	
				m.homeID,
				m.awayID,
				ISNULL (e.hthomescore,0) AS hthomescore,
				ISNULL (e.htawayscore,0) AS htawayscore,		
				ISNULL (e.finalhomescore,0) AS finalhomescore ,
				ISNULL (e.finalawayscore,0) AS finalawayscore,
				m.kickofftime,
				m.eventdate,
				m.isNeutral,
				ISNULL(e.betstatus, '') AS betstatus, 	
				CASE WHEN ISNULL(e.betstatus,'') like 'Refund FT%' THEN 'Refund FT' 
					 WHEN ISNULL(e.betstatus,'') like 'Refund HT%' THEN 'Refund HT'
					 WHEN ISNULL(e.betstatus,'') like 'Refund%' THEN 'Refund' 
					ELSE ISNULL(e.eventstatus,'') END as eventstatus,
				isnull(e.refund,0) IsRefund ,
				isnull(e.calrefund,0) IsCalRefund,
				ISNULL(e.goalrecord,'') AS goalrecord,
				m.matchcode,
				ISNULL(e.isHTCal,0) as isHTCal,
				ISNULL(e.calculate,0) as calculate	,
				ISNULL(mr.IsPending,0) as IsPending 
		FROM	(SELECT b.matchId FROM BettransM b WITH (NOLOCK) WHERE b.refno = @refno ) bM
				INNER JOIN match m WITH(NOLOCK) ON bM.matchid = m.matchid
				LEFT OUTER JOIN match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid
				LEFT OUTER JOIN match_remark_ex e WITH(NOLOCK) ON m.matchid = e.matchid
	END
	IF EXISTS (SELECT 1 FROM bettransm14 WITH (NOLOCK) WHERE  refno = @refno)
	BEGIN
		INSERT INTO @tmpParlay (
			sporttype, 	
			LeagueID,
			matchid, 	
			homeID,
			awayID,
			hthomescore,
			htawayscore,		
			finalhomescore,
			finalawayscore,
			kickofftime,
			eventdate,
			isNeutral,
			betstatus, 	
			eventstatus,
			IsRefund ,
			IsCalRefund,
			goalrecord,
			matchcode,
			isHTCal,
			calculate,
			IsPending
		)

		SELECT	m.sporttype, 	
				m.LeagueID,
				m.matchid, 	
				m.homeID,
				m.awayID,
				ISNULL (e.hthomescore,0) AS hthomescore,
				ISNULL (e.htawayscore,0) AS htawayscore,		
				ISNULL (e.finalhomescore,0) AS finalhomescore ,
				ISNULL (e.finalawayscore,0) AS finalawayscore,
				m.kickofftime,
				m.eventdate,
				m.isNeutral,
				ISNULL(e.betstatus, '') AS betstatus, 	
				CASE WHEN ISNULL(e.betstatus,'') like 'Refund FT%' THEN 'Refund FT' 
					 WHEN ISNULL(e.betstatus,'') like 'Refund HT%' THEN 'Refund HT'
					 WHEN ISNULL(e.betstatus,'') like 'Refund%' THEN 'Refund' 
					ELSE ISNULL(e.eventstatus,'') END as eventstatus,
				isnull(e.refund,0) IsRefund ,
				isnull(e.calrefund,0) IsCalRefund,
				ISNULL(e.goalrecord,'') AS goalrecord,
				m.matchcode,
				ISNULL(e.isHTCal,0) as isHTCal,
				ISNULL(e.calculate,0) as calculate	,
				ISNULL(mr.IsPending,0) as IsPending 
		FROM(	SELECT b.matchId FROM BettransM14 b WITH (NOLOCK) WHERE b.refno = @refno ) bM
				INNER JOIN match14 m WITH(NOLOCK) ON bM.matchid = m.matchid
				LEFT OUTER JOIN match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid
				LEFT OUTER JOIN match_remark_ex e WITH(NOLOCK) ON m.matchid = e.matchid
	END
	IF EXISTS (SELECT 1 FROM SVRARC.ArchiveDB.dbo.BettransM  WITH (NOLOCK) WHERE  refno = @refno)
	BEGIN
		INSERT INTO @tmpParlay (
			sporttype, 	
			LeagueID,
			matchid, 	
			homeID,
			awayID,
			hthomescore,
			htawayscore,		
			finalhomescore,
			finalawayscore,
			kickofftime,
			eventdate,
			isNeutral,
			betstatus, 	
			eventstatus,
			IsRefund ,
			IsCalRefund,
			goalrecord,
			matchcode,
			isHTCal,
			calculate,
			IsPending
		)
		SELECT	m.sporttype, 	
				m.LeagueID,
				m.matchid, 	
				m.homeID,
				m.awayID,
				ISNULL (e.hthomescore,0) AS hthomescore,
				ISNULL (e.htawayscore,0) AS htawayscore,		
				ISNULL (e.finalhomescore,0) AS finalhomescore ,
				ISNULL (e.finalawayscore,0) AS finalawayscore,
				m.kickofftime,
				m.eventdate,
				m.isNeutral,
				ISNULL(e.betstatus, '') AS betstatus, 	
				CASE WHEN ISNULL(e.betstatus,'') like 'Refund FT%' THEN 'Refund FT' 
					 WHEN ISNULL(e.betstatus,'') like 'Refund HT%' THEN 'Refund HT'
					 WHEN ISNULL(e.betstatus,'') like 'Refund%' THEN 'Refund' 
					ELSE ISNULL(e.eventstatus,'') END as eventstatus,
				isnull(e.refund,0) IsRefund ,
				isnull(e.calrefund,0) IsCalRefund,
				ISNULL(e.goalrecord,'') AS goalrecord,
				m.matchcode,
				ISNULL(e.isHTCal,0) as isHTCal,
				ISNULL(e.calculate,0) as calculate	,
				ISNULL(mr.IsPending,0) as IsPending			
		FROM(	SELECT b.matchId FROM SVRARC.ArchiveDB.dbo.BettransM b (NOLOCK) WHERE b.refno = @refno ) bM
				INNER JOIN SVRARC.ArchiveDB.dbo.match_BK m WITH(NOLOCK) ON bM.matchid = m.matchid
				LEFT OUTER JOIN match_remark mr WITH(NOLOCK) ON m.matchid = mr.matchid
				LEFT OUTER JOIN match_remark_ex e WITH(NOLOCK) ON m.matchid = e.matchid
	END
	SELECT * FROM @tmpParlay
	ORDER BY LeagueID, eventdate, matchcode	
END
GO 
GRANT EXECUTE ON [dbo].[Age_BetList_SelMatchResultParlay] TO [aplweb]
GO 