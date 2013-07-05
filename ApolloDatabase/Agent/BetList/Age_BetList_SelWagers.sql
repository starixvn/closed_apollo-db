ALTER PROCEDURE [dbo].[Age_BetList_SelWagers]
	@LoggedId INT = 0,
	@FromDate Date,
	@UGroup varchar(3) = 'ALL',
	@IsDirectMem BIT = 0,
	@LiveIndicator BIT = 0,
	@LeagueId INT,
	@MatchID INT, 
	@Sporttypes VARCHAR(1000) ='0',
	@Bettypes VARCHAR(1000) = '0',
	@Betteam VARCHAR(10) = '0'
 AS
 
/*
Created:  Sophia
Date: 20130701
Task: Betlist for Wagers
DB: SVRAGE.REPDB
 
Revisions:    
	
Parameters
	@IsDirectMem : 1: Direct Member
				   0: All Member
 
*/

SET NOCOUNT ON


CREATE TABLE #BettypeList (bettype SMALLINT)
INSERT INTO #BettypeList
SELECT val FROM dbo.strSplit_Key(@Bettypes,',')

CREATE TABLE #SportsList (Sporttype TINYINT)
INSERT INTO #SportsList (Sporttype)
SELECT val FROM strSplit_key (@Sporttypes, ',')


CREATE TABLE #Betlist  (TransId BIGINT PRIMARY KEY, RefNo BIGINT, MatchId INT, MatchCode NVARCHAR(50), 
						HomeId INT, AwayId INT, SportType TINYINT, LeagueId INT, IsNeutral BIT,  Showtime NVARCHAR(50),
						Username NVARCHAR(50), BetType SMALLINT, CustId INT , Hdp1 SMALLMONEY, Hdp2 SMALLMONEY, Odds SMALLMONEY, MOdds SMALLMONEY,
						Status VARCHAR(10), Stake MONEY, Actual_Stake MONEY, PlayerDiscount decimal(9,8), TransDate DATETIME, BetTeam VARCHAR(10), BetId BIGINT, 
						LiveHomeScore SMALLINT, LiveAwayScore SMALLINT,LiveIndicator BIT, 
						IP VARCHAR(40), OddsType TINYINT, DoubleCommLosing BIT, 
						UGroup varchar(3))


		--inlcude mix parlay AND Combination mix parlay
		IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29) OR @Bettypes = '0')
		BEGIN
			INSERT INTO #Betlist
			SELECT 	DISTINCT		
				B.transid,
				B.refno,
				0 AS matchid,
				'' matchcode,
				0 AS homeID,
				0 AS awayID,
				0 AS sporttype,
				'' as LeagueID,
				CONVERT(BIT,0) AS IsNeutral,
				'' AS ShowTime,
				B.Username,				
				B.bettype,	
				B.custid,	
				0 AS hdp1,
				0 AS hdp2,
				B.Odds,
				B.MOdds,
				B.Status,
				B.Stake,
				B.Actual_Stake,
				B.PlayerDiscount,
				B.TransDate,		
				B.BetTeam,
				B.BetId,
		
				0 AS LiveHomeScore, 
				0 AS LiveAwayScore,
				0 AS LiveIndicator ,
				B.IP,		
				0 AS OddStype,		
				B.DoubleCommLosing,
				C.UGroup
			FROM		Bettrans B WITH (NOLOCK)
			INNER JOIN	Bettrans_Agent BA WITH (NOLOCK)
				ON		B.TransId = BA.TransId AND BA.AgentID = @LoggedId  
						AND BA.Bettype IN (9,29) AND (@Bettypes = '0' OR BA.Bettype IN (Select Bettype FROM #BettypeList)) 
						AND BA.StatusId IN (0,1)
			INNER JOIN  BetTransM BM WITH (NOLOCK) 
				ON		BM.Refno = B.RefNo
			INNER JOIN	Match M WITH (NOLOCK)
				ON		M.matchID = BM.MatchID
			INNER JOIN  CustInfo C WITH (NOLOCK)
				ON		C.CustID = B.CustID
			WHERE		B.Bettype IN (9,29)
						AND (@Bettypes = '0' OR B.Bettype IN (Select Bettype FROM #BettypeList))
						AND B.StatusId IN (0,1)							
						AND B.LiveIndicator = @LiveIndicator 
						AND M.MatchId = @MatchID 
						AND (@Sporttypes = '0' OR M.sporttype IN (Select sporttype FROM #SportsList))
						
						AND M.Eventdate = @Fromdate
						AND M.EventStatus = 'running'
						AND (M.Leagueid = @LeagueId OR @LeagueId = 0)

						AND (C.UGroup = @UGroup OR @UGroup = 'ALL')
						AND (C.AgentID = @LoggedId OR @IsDirectMem = 0)	
			GROUP BY	B.transid, B.refno, B.Username, B.bettype, B.custid, B.Odds, B.MOdds, B.Status,	B.Stake, B.Actual_Stake, B.PlayerDiscount,
						B.TransDate, B.BetTeam, B.BetId,B.IP, B.DoubleCommLosing, C.UGroup
				 
		END

		--- Outright
		IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype = 10 OR @Bettypes = '0')
		BEGIN
			INSERT INTO #Betlist
			SELECT 				
				B.transid,
				B.refno,
				0 AS matchid,
				m.matchcode,
				m.teamID AS homeID,
				0 AS awayID,
				l.sporttype,
				m.LeagueID,
				CONVERT(BIT,0) AS IsNeutral,
				'' AS showtime,
				B.username,
				B.bettype,	
				B.custid,	
				B.hdp1, 
				B.hdp2, 
				B.odds,
				B.modds,
				B.Status,
				B.stake,
				B.actual_stake,
				B.PlayerDiscount,
				B.transdate,		
				B.betteam,
				B.betID,					
				B.livehomescore,
				B.liveawayscore,
				B.liveindicator, 
				B.IP AS IP,		
				0 AS oddstype,		
				B.DoubleCommLosing,
				C.UGroup
			FROM Bettrans B WITH (NOLOCK)
			INNER JOIN	BetTrans_Agent AS BA WITH (NOLOCK) 
				ON		B.TransId = BA.TransId AND BA.AgentID = @LoggedID 
						AND BA.Bettype = 10	
						AND BA.StatusId IN (0,1)
			INNER JOIN CustInfo C  WITH (NOLOCK) ON  C.CustId = B.CustId
			INNER JOIN outright AS m WITH (NOLOCK) on  B.matchid=m.orid
			INNER JOIN league l WITH (NOLOCK) on m.leagueid = l.leagueid	
			WHERE		BA.AgentId = @LoggedId
			
						AND B.Bettype = 10						
						AND B.StatusId IN (0,1)							
						AND B.LiveIndicator = @LiveIndicator
												
						AND M.Eventdate = @Fromdate
						AND M.Oddsstatus = 'running'
						AND (M.Leagueid = @LeagueId OR @LeagueId = 0)
						AND M.orid = @MatchID 						
						AND (@Sporttypes = '0' OR L.sporttype IN (Select sporttype FROM #SportsList))
						
						AND (C.UGroup = @UGroup OR @UGroup = 'ALL')
						AND (C.AgentID = @LoggedId OR @IsDirectMem = 0)	
		END
 
		IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (10,9,29) OR @Bettypes = '0')
		BEGIN
			INSERT INTO #Betlist
			SELECT			
				B.TransId,
				B.RefNo,
				m.MatchId,
				m.MatchCode ,
				m.HomeId,
				m.AwayId,
				m.SportType,
				m.LeagueId,
				m.IsNeutral,
				m.ShowTime,
				B.Username,
				B.BetType,
				B.CustId,
				B.Hdp1, 
				B.Hdp2, 
				B.Odds,
				B.MOdds,
				CASE WHEN B.Status = 'running' AND IsNull(B.SecAcceptFlag, 0) = 1 AND IsNull(B.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
						 ELSE B.Status 
						 END AS Status,
				B.Stake,
				B.Actual_Stake,
				B.PlayerDiscount,
				B.TransDate,		
				B.BetTeam,
				B.BetId,					 
				B.LiveHomeScore,
				B.LiveAwayScore,
				B.LiveIndicator, 
				B.IP,		
				B.Oddstype,		
				B.DoubleCommLosing,
				C.UGroup
			
 			FROM		Bettrans B WITH (NOLOCK)
			INNER JOIN	Bettrans_Agent BA WITH (NOLOCK)
				ON		B.TransId = BA.TransId AND BA.AgentID = @LoggedID 
						AND (@Bettypes = '0' OR BA.Bettype IN (Select Bettype FROM #BettypeList)) 
						AND BA.StatusId IN (0,1)
			INNER JOIN	Match M WITH (NOLOCK)
				ON		M.matchID = B.MatchID
			INNER JOIN  CustInfo C WITH (NOLOCK)
				ON		C.CustID = B.CustID
			WHERE		(@Bettypes = '0' OR B.Bettype IN (Select Bettype FROM #BettypeList ))
						AND B.StatusId IN (0,1)							
						AND B.LiveIndicator = @LiveIndicator
						AND (B.betteam = @Betteam OR @betteam = '0')
						
						AND M.MatchId = @MatchID 
						AND (@Sporttypes = '0' OR M.sporttype IN (Select sporttype FROM #SportsList))
						AND M.Eventdate = @Fromdate
						AND M.EventStatus = 'running'
						AND (M.Leagueid = @LeagueId OR @LeagueId = 0)
						
						AND (C.UGroup = @UGroup OR @UGroup = 'ALL')
						AND (C.AgentID = @LoggedId OR @IsDirectMem = 0)				
			 				 
		END
		


SELECT * FROM #Betlist
ORDER BY TransID

DROP TABLE #Betlist
DROP TABLE #BettypeList
DROP TABLE #SportsList

GO
GRANT EXECUTE ON [dbo].[Age_BetList_SelWagers ] TO [aplweb]

  