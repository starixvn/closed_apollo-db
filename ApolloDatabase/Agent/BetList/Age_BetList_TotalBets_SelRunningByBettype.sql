ALTER PROC [dbo].[Age_BetList_TotalBets_SelRunningByBettype]
	@AgentId INT,
	@Bettype int,
	@Language varchar(2) = 'E'
 AS

/**
 * Created by	: Kaden
 * Date			: 20130301
 * Task			: Retrieve total bet of Parlay, Clean Sheet, Double Chance, Both/One/Neither Team To Score, To Win To Nil, 3-Way Handicap
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *
 * Parameters:
 *	@AgentId: agent ID
  *	@Bettype: bettype ID
 *	@Language: default English
 *  
 */

SET NOCOUNT ON
IF @bettype IN ( 9, 29)--inlcude mix parlay AND Combination mix parlay
BEGIN
	SELECT 
		0 as sporttype,
		bt.Username,				
		bt.CustId,
		bt.BetType,
		bt.TransId,
		bt.RefNo,
		0 as matchid,
		'' matchcode,
		0 as homeID,
		0 as awayID,
		'' hdp1,
		'' hdp2,
		bt.Odds,
		bt.MOdds,
		bt.Status,
		bt.Stake,
		bt.Actual_Stake,
		bt.TransDate,		
		bt.BetTeam,
		bt.BetId,
		0 AS LiveHomeScore, 
		0 AS LiveAwayScore,
		0 AS LiveIndicator ,
		bta.APositionTaking,
		bta.ADiscount,
		bt.IP,
		CONVERT(BIT,0) as IsNeutral,
		0 as OddStype,
		'' as ShowTime,
		bt.DoubleCommLosing	
	FROM BetTrans AS bt  WITH (NOLOCK) 
		INNER JOIN BetTrans_Agent AS bta WITH (NOLOCK) ON bta.TransId = bt.TransId
	WHERE
		bta.AgentId = @AgentId AND
		bt.BetType = @bettype AND
		bt.matchid = @bettype AND
		bt.Status='running' AND
		bt.statusID BETWEEN 0 AND 1 AND 
		bt.ruben=0 
		
	order by bt.status, bt.transid
	RETURN
END

if @bettype<=19000
BEGIN
	SELECT 
		m.SportType,
		bt.Username,
		m.LeagueId, 
		bt.BetType,
		bt.CustId,		
		bt.TransId,
		bt.RefNo,
		m.MatchId,
		m.MatchCode,
		m.HomeId,
		m.AwayId,
		convert(float, bt.Hdp1) as Hdp1, 
		convert(float, bt.Hdp2) as Hdp2, 
		bt.Odds,
		bt.MOdds,
		CASE WHEN bt.Status = 'running' AND IsNull(bt.SecAcceptFlag, 0) = 1 AND IsNull(bt.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
				 ELSE bt.Status 
				 END as Status,
		bt.Stake,
		bt.Actual_Stake,
		bt.TransDate,		
		bt.BetTeam,
		bt.BetId,
		bta.APositionTaking,
		bta.ADiscount,
		bt.LiveHomeScore,
		bt.LiveAwayScore,
		bt.LiveIndicator, 
		bt.IP,
		isnull(m.isNeutral, CONVERT(BIT,0)) as IsNeutral,
		bt.OddStype,
		m.ShowTime,
		DoubleCommLosing
 	from 	
		BetTrans AS bt  WITH (NOLOCK) 
		INNER JOIN BetTrans_Agent AS bta WITH (NOLOCK) ON bta.TransId = bt.TransId
		INNER JOIN  Match m WITH (NOLOCK) ON  bt.MatchId = m.MatchId 				
	where 
		bta.AgentId = @AgentId 
		AND bt.BetType=@bettype 
		AND bt.Status='running'
		AND bt.StatusId in (0,1)
		
	order by bt.Status, bt.TransId
END

GO
GRANT VIEW DEFINITION ON [dbo].[Age_BetList_TotalBets_SelRunningByBettype] TO [aplweb]






