ALTER PROC [dbo].[Age_BetList_TotalBets_SelRunningByBettype]
	@AgentId INT,
	@Bettypes VARCHAR(200) = '',
	@Language VARCHAR(2) = 'E'
 AS

/**
 * Created by	: Kaden
 * Date			: 20130301
 * TASk			: Retrieve total bet of Parlay, Clean Sheet, Double Chance, Both/One/Neither Team To Score, To Win To Nil, 3-Way Handicap
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *
 * Parameters:
 *	@AgentId: agent ID
 * 	@Bettype: bettype ID
 *	@Language: default English
 *  
 */

SET NOCOUNT ON
DECLARE @Bettype TABLE (bettype INT)

INSERT INTO  @Bettype
SELECT convert(INT,val) FROM dbo.strSplit_key(@bettypes,'^')

DECLARE @Betlist TABLE (SportType TINYINT, Username NVARCHAR(50), BetType SMALLINT, CustId INT ,TransId BIGINT, RefNo BIGINT,
						MatchId INT, MatchCode NVARCHAR(50), HomeId INT, AwayId INT, Hdp1 SMALLMONEY, Hdp2 SMALLMONEY, Odds SMALLMONEY, MOdds SMALLMONEY,
						Status VARCHAR(10), Stake MONEY, Actual_Stake MONEY, TransDate DATETIME, BetTeam VARCHAR(10), BetId BIGINT, 
						APositionTaking SMALLMONEY, ADiscount DECIMAL (9,8), LeagueId INT, LiveHomeScore SMALLINT, LiveAwayScore SMALLINT,LiveIndicator BIT, 
						IP VARCHAR(40), IsNeutral BIT, OddsType TINYINT, ShowTime NVARCHAR(50),	DoubleCommLosing BIT)


--inlcude mix parlay AND Combination mix parlay
IF EXISTS (SELECT TOP 1 1  FROM @Bettype WHERE Bettype IN (9,29))
BEGIN
	INSERT INTO @Betlist
	SELECT 
		0 AS sporttype,
		B.Username,				
		B.bettype,	
		B.custid,			
		B.transid,
		B.refno,
		0 AS matchid,
		'' matchcode,
		0 AS homeID,
		0 AS awayID,
		0 AS hdp1,
		0 AS hdp2,
		B.Odds,
		B.MOdds,
		B.Status,
		B.Stake,
		B.Actual_Stake,
		B.TransDate,		
		B.BetTeam,
		B.BetId,
		BA.APositionTaking,
		BA.ADiscount,
		'' as LeagueID,
		0 AS LiveHomeScore, 
		0 AS LiveAwayScore,
		0 AS LiveIndicator ,
		B.IP,
		CONVERT(BIT,0) AS IsNeutral,
		0 AS OddStype,
		'' AS ShowTime,
		B.DoubleCommLosing	
	FROM BetTrans AS B  WITH (NOLOCK) 
		INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
	WHERE
		BA.AgentId = @AgentId 	
		AND B.CustID = B.CustID  
		AND B.matchid in (SELECT Bettype FROM @Bettype) AND B.matchid IN (9,29) 
		AND B.bettype in (SELECT Bettype FROM @Bettype) AND B.bettype IN (9,29)
		AND B.StatusId IN (0,1)
END


IF EXISTS (SELECT TOP 1 1  FROM @Bettype WHERE Bettype = 10)
BEGIN
	INSERT INTO @Betlist
	SELECT 
		l.sporttype,
		B.username,
		B.bettype,	
		B.custid,			
		B.transid,
		B.refno,
		0 AS matchid,
		m.matchcode,
		m.teamID AS homeID,
		0 AS awayID,
		B.hdp1, 
		B.hdp2, 
		B.odds,
		B.modds,
		B.Status,
		B.stake,
		B.actual_stake,
		B.transdate,		
		B.betteam,
		B.betID,
		BA.APositionTaking,
		BA.ADiscount,
		m.LeagueID,
		B.livehomescore,
		B.liveawayscore,
		B.liveindicator, 
		B.IP AS IP,
		CONVERT(BIT,0) AS IsNeutral,
		0 AS oddstype,
		'' AS showtime,
		B.DoubleCommLosing
	FROM 		
		bettrans b WITH (NOLOCK)
		INNER JOIN BetTrans_Agent AS ba WITH (NOLOCK) ON BA.TransId = B.TransId
		INNER JOIN SVRPRO.ProdDB.dbo.outright AS m WITH (NOLOCK) on  B.matchid=m.orid
		INNER JOIN SVRPRO.ProdDB.dbo.league l WITH (NOLOCK) on m.leagueid = l.leagueid	
	WHERE 
		BA.AgentId = @AgentId 	
		AND B.bettype = 10
		AND B.StatusId=0 		
END
 
IF EXISTS (SELECT TOP 1 1  FROM @Bettype WHERE Bettype NOT IN (10,9,29))
BEGIN
	INSERT INTO @Betlist
	SELECT
		m.SportType,
		B.Username,
		B.BetType,
		B.CustId,		
		B.TransId,
		B.RefNo,
		m.MatchId,
		m.MatchCode ,
		m.HomeId,
		m.AwayId,
		B.Hdp1, 
		B.Hdp2, 
		B.Odds,
		B.MOdds,
		CASE WHEN B.Status = 'running' AND IsNull(B.SecAcceptFlag, 0) = 1 AND IsNull(B.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
				 ELSE B.Status 
				 END AS Status,
		B.Stake,
		B.Actual_Stake,
		B.TransDate,		
		B.BetTeam,
		B.BetId,
		BA.APositionTaking,
		BA.ADiscount,
		m.LeagueId, 
		B.LiveHomeScore,
		B.LiveAwayScore,
		B.LiveIndicator, 
		B.IP,
		M.IsNeutral,
		B.Oddstype,
		m.ShowTime,
		DoubleCommLosing
 	FROM 	
		BetTrans AS b  WITH (NOLOCK) 
		INNER JOIN BetTrans_Agent AS ba WITH (NOLOCK) ON BA.TransId = B.TransId
		INNER JOIN  Match m WITH (NOLOCK) ON  B.MatchId = m.MatchId 				
	WHERE 
		BA.AgentId = @AgentId 
		AND B.CustID = B.CustID  
		AND B.bettype in (SELECT Bettype FROM @Bettype)
		AND B.StatusId in (0,1)	
END


SELECT * FROM @Betlist
ORDER BY TransID


GO
GRANT VIEW DEFINITION ON [dbo].[Age_BetList_TotalBets_SelRunningByBettype] TO [aplweb]








