ALTER PROCEDURE [dbo].[Age_BetList_TotalBets_SelRunningByBettype]
	@LoggedId INT,
	@AgentId INT,
	@Bettypes VARCHAR(200) = ''
 AS

/**
  Created by	: Kaden
  Date			: 20130301
  TASk			: Retrieve total bet of Parlay, Clean Sheet, Double Chance, Both/One/Neither Team To Score, To Win To Nil, 3-Way Handicap
  DB			: SVRAGE.RepDB
  Revisions	:
	- 20130409@Sophia: revise all, change #Bettype to #Bettypes 
	- 20130507@Sophia: Add @AgentID for Super view total bets of Main shareholder
	- 20130510@Sophia: Change @splitter of strSplit_Key from '^', to ','
	- 20130627@Sophia: Add UGroup for Singbet
	- 20130708@Sophia: Change SuperId from 0 to 1 (@AgentID = 1)
	- 20140212@Sophia: Expand Parlay detail
  Parameters:
 		@AgentId: agent ID
  		#Bettypes: string of bettypes , seperate by ,
 		@Language: default English

    
 */

SET NOCOUNT ON
CREATE TABLE #Bettype (bettype INT)

INSERT INTO #Bettype
SELECT val FROM dbo.strSplit_Key(@Bettypes,',')

DECLARE @Betlist TABLE (TransId BIGINT PRIMARY KEY, RefNo BIGINT, MatchId INT, MatchCode NVARCHAR(50), 
						HomeId INT, AwayId INT, SportType TINYINT, LeagueId INT, IsNeutral BIT,  Showtime NVARCHAR(50),
						Username NVARCHAR(50), BetType SMALLINT, CustId INT , Hdp1 SMALLMONEY, Hdp2 SMALLMONEY, Odds SMALLMONEY, MOdds SMALLMONEY,
						Status VARCHAR(10), Stake MONEY, Actual_Stake MONEY, TransDate DATETIME, BetTeam VARCHAR(10), BetId BIGINT, 
						APositionTaking SMALLMONEY, ADiscount DECIMAL (9,8),  LiveHomeScore SMALLINT, LiveAwayScore SMALLINT,LiveIndicator BIT, 
						IP VARCHAR(40), OddsType TINYINT, DoubleCommLosing BIT, UGroup varchar(3),PlayerDiscount decimal(9,8))

IF @LoggedId = 1 
BEGIN 
		--inlcude mix parlay AND Combination mix parlay
		IF EXISTS (SELECT TOP 1 1  FROM #Bettype WHERE Bettype IN (9,29))
		BEGIN
			INSERT INTO @Betlist
			SELECT 			
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
				B.TransDate,		
				B.BetTeam,
				B.BetId,
				(1-B.TPositionTaking) AS APositionTaking,
				NULL AS ADiscount,
		
				0 AS LiveHomeScore, 
				0 AS LiveAwayScore,
				0 AS LiveIndicator ,
				B.IP,		
				0 AS OddStype,		
				B.DoubleCommLosing,
				C.UGroup,
				B.PlayerDiscount 
			FROM BetTrans B  WITH (NOLOCK) 
				INNER JOIN BetTrans_Agent BA WITH (NOLOCK) ON BA.TransId = B.TransId
				INNER JOIN CustInfo C  WITH (NOLOCK) ON  C.CustId = B.CustId
			WHERE
				BA.AgentId = @AgentId
				AND B.CustID = B.CustID  
				AND B.bettype in (SELECT Bettype FROM #Bettype) AND B.bettype IN (9,29)
				AND B.StatusId IN (0,1)
		END

		--- Outright
		IF EXISTS (SELECT TOP 1 1  FROM #Bettype WHERE Bettype = 10)
		BEGIN
			INSERT INTO @Betlist
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
				B.transdate,		
				B.betteam,
				B.betID,
				(1-B.TPositionTaking) AS APositionTaking,
				NULL AS ADiscount,		
				B.livehomescore,
				B.liveawayscore,
				B.liveindicator, 
				B.IP AS IP,		
				0 AS oddstype,		
				B.DoubleCommLosing,
				C.UGroup,
				B.PlayerDiscount 
			FROM 		
				bettrans b WITH (NOLOCK)
				INNER JOIN BetTrans_Agent AS ba WITH (NOLOCK) ON BA.TransId = B.TransId
				INNER JOIN CustInfo C  WITH (NOLOCK) ON  C.CustId = B.CustId
				INNER JOIN outright AS m WITH (NOLOCK) on  B.matchid=m.orid
				INNER JOIN league l WITH (NOLOCK) on m.leagueid = l.leagueid	
			WHERE 
				BA.AgentId = @AgentId
				AND B.CustID = B.CustID
				AND B.bettype = 10
				AND B.StatusId=0 		
		END
 
		IF EXISTS (SELECT TOP 1 1  FROM #Bettype WHERE Bettype NOT IN (10,9,29))
		BEGIN
			INSERT INTO @Betlist
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
				B.TransDate,		
				B.BetTeam,
				B.BetId,
				(1-B.TPositionTaking) AS APositionTaking,
				NULL AS ADiscount,		 
				B.LiveHomeScore,
				B.LiveAwayScore,
				B.LiveIndicator, 
				B.IP,		
				B.Oddstype,		
				B.DoubleCommLosing,
				C.UGroup,
				B.PlayerDiscount 
 			FROM 	
				BetTrans AS b  WITH (NOLOCK) 
				INNER JOIN BetTrans_Agent AS ba WITH (NOLOCK) ON BA.TransId = B.TransId
				INNER JOIN  Match m WITH (NOLOCK) ON  B.MatchId = m.MatchId
				INNER JOIN CustInfo C  WITH (NOLOCK) ON  C.CustId = B.CustId				
			WHERE 
				BA.AgentId = @AgentId 
				AND B.CustID = B.CustID  
				AND B.bettype in (SELECT Bettype FROM #Bettype)
				AND B.StatusId in (0,1)	
		END
END 
ELSE
BEGIN 
		--inlcude mix parlay AND Combination mix parlay
		IF EXISTS (SELECT TOP 1 1  FROM #Bettype WHERE Bettype IN (9,29))
		BEGIN
			INSERT INTO @Betlist
			SELECT 			
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
				B.TransDate,		
				B.BetTeam,
				B.BetId,
				BA.APositionTaking,
				BA.ADiscount,
		
				0 AS LiveHomeScore, 
				0 AS LiveAwayScore,
				0 AS LiveIndicator ,
				B.IP,		
				0 AS OddStype,		
				B.DoubleCommLosing,
				C.UGroup,
				B.PlayerDiscount 
			FROM BetTrans AS B  WITH (NOLOCK) 
				INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
				INNER JOIN CustInfo C  WITH (NOLOCK) ON  C.CustId = B.CustId
			WHERE
				BA.AgentId = @AgentId 
				AND B.CustID = B.CustID  
				AND B.bettype in (SELECT Bettype FROM #Bettype) AND B.bettype IN (9,29)
				AND B.StatusId IN (0,1)
		END

		--- Outright
		IF EXISTS (SELECT TOP 1 1  FROM #Bettype WHERE Bettype = 10)
		BEGIN
			INSERT INTO @Betlist
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
				B.transdate,		
				B.betteam,
				B.betID,
				BA.APositionTaking,
				BA.ADiscount,		
				B.livehomescore,
				B.liveawayscore,
				B.liveindicator, 
				B.IP AS IP,		
				0 AS oddstype,		
				B.DoubleCommLosing,
				C.UGroup,
				B.PlayerDiscount 
			FROM 		
				bettrans b WITH (NOLOCK)
				INNER JOIN BetTrans_Agent AS ba WITH (NOLOCK) ON BA.TransId = B.TransId
				INNER JOIN outright AS m WITH (NOLOCK) on  B.matchid=m.orid
				INNER JOIN league l WITH (NOLOCK) on m.leagueid = l.leagueid	
				INNER JOIN CustInfo C  WITH (NOLOCK) ON  C.CustId = B.CustId
			WHERE 
				BA.AgentId = @AgentId 
				AND B.CustID = B.CustID
				AND B.bettype = 10
				AND B.StatusId=0 		
		END
 
		IF EXISTS (SELECT TOP 1 1  FROM #Bettype WHERE Bettype NOT IN (10,9,29))
		BEGIN
			INSERT INTO @Betlist
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
				B.TransDate,		
				B.BetTeam,
				B.BetId,
				BA.APositionTaking,
				BA.ADiscount,		 
				B.LiveHomeScore,
				B.LiveAwayScore,
				B.LiveIndicator, 
				B.IP,		
				B.Oddstype,		
				B.DoubleCommLosing,
				C.UGroup,
				B.PlayerDiscount 
 			FROM 	
				BetTrans AS b  WITH (NOLOCK) 
				INNER JOIN BetTrans_Agent AS ba WITH (NOLOCK) ON BA.TransId = B.TransId
				INNER JOIN  Match m WITH (NOLOCK) ON  B.MatchId = m.MatchId 	
				INNER JOIN CustInfo C  WITH (NOLOCK) ON  C.CustId = B.CustId			
			WHERE 
				BA.AgentId = @AgentId
				AND B.CustID = B.CustID  
				AND B.bettype in (SELECT Bettype FROM #Bettype)
				AND B.StatusId in (0,1)	
		END
END

SELECT * FROM @Betlist
ORDER BY TransID


------------
---- Detail Parlay
IF EXISTS (SELECT TOP 1 1  FROM #Bettype WHERE Bettype IN (9,29))
BEGIN 
DECLARE	@tmpParlay	TABLE(
	RefNo		BIGINT,
	transid		BIGINT,
	sporttype	TINYINT,
	leagueid	INT,
	bettype		INT,
	MatchId		INT,
	homeid		INT,
	awayid		INT,
	hdp1		FLOAT,
	hdp2		FLOAT,
	odds		SMALLMONEY,
	betteam		NVARCHAR(50),
	statusid	INT,
	livehomescore	SMALLINT,
	liveawayscore	SMALLINT,
	liveindicator	BIT,
	HtHomeScore	SMALLINT,
	HtAwayScore	SMALLINT,
	FinalHomeScore	SMALLINT,
	FinalAwayScore	SMALLINT,
	betstatus	NVARCHAR(50),
	isNeutral	BIT
)	

IF EXISTS  (SELECT 1 FROM @Betlist WHERE Bettype IN (9,29))
BEGIN 

	IF EXISTS (SELECT 1 FROM bettransm WITH (NOLOCK) WHERE refno IN (SELECT RefNo FROM @Betlist WHERE Bettype IN (9,29)))
	BEGIN
		INSERT INTO @tmpParlay (
			RefNo,
			transid,
			sporttype,
			leagueid,
			bettype,
			MatchId,
			homeid,
			awayid,
			hdp1,
			hdp2,
			odds,
			betteam,
			statusid,
			livehomescore,
			liveawayscore,
			liveindicator,
			HtHomeScore,
			HtAwayScore,
			FinalHomeScore,
			FinalAwayScore,
			betstatus,
			isNeutral
		)
		SELECT
			b.RefNo,
			b.transid,
			m.Sporttype,
			m.LeagueID,		
			b.Bettype ,
			m.MatchId,
			m.homeID,
			m.awayID,
			convert(float, b.hdp1) as Hdp1, 
			convert(float, b.hdp2) as Hdp2, 
			b.odds,
			b.Betteam,
			b.statusid,
			b.livehomescore,
			b.liveawayscore,
			b.liveindicator,
			m.HtHomeScore,
			m.HtAwayScore,
			m.FinalHomeScore,
			m.FinalAwayScore,
			m.betstatus,
			m.isNeutral
		FROM(	SELECT	RefNo,
						transid,
						matchid,  
						Bettype, 
						hdp1, 
						hdp2, 
						odds, 
						betteam, 
						statusid,
						livehomescore,
						liveawayscore,
						liveindicator
				FROM	BettransM with (nolock)
						WHERE refno IN (SELECT RefNo FROM @Betlist WHERE Bettype IN (9,29))         
			) AS b		
				inner join match as m with (nolock) on b.matchid=m.matchid
	END


	IF EXISTS (SELECT 1 FROM bettransm14 WITH (NOLOCK) WHERE refno IN (SELECT RefNo FROM @Betlist WHERE Bettype IN (9,29)))
	BEGIN
		INSERT INTO @tmpParlay (
			RefNo,
			transid,
			sporttype,
			leagueid,
			bettype,
			MatchId,
			homeid,
			awayid,
			hdp1,
			hdp2,
			odds,
			betteam,
			statusid,
			livehomescore,
			liveawayscore,
			liveindicator,
			HtHomeScore,
			HtAwayScore,
			FinalHomeScore,
			FinalAwayScore,
			betstatus,
			isNeutral
		)
		SELECT
			b.RefNo,
			b.transid,
			m.Sporttype,
			m.LeagueID,		
			b.Bettype ,
			m.MatchId,
			m.homeID,
			m.awayID,
			convert(float, b.hdp1) as Hdp1, 
			convert(float, b.hdp2) as Hdp2, 
			b.odds,
			b.Betteam,
			b.statusid,
			b.livehomescore,
			b.liveawayscore,
			b.liveindicator,
			m.HtHomeScore,
			m.HtAwayScore,
			m.FinalHomeScore,
			m.FinalAwayScore,
			m.betstatus,
			m.isNeutral
		FROM(	SELECT	RefNo,
						transid,
						matchid,  
						Bettype, 
						hdp1, 
						hdp2, 
						odds, 
						betteam, 
						statusid,
						livehomescore,
						liveawayscore,
						liveindicator
				FROM	BettransM14 with (nolock)
						WHERE refno IN (SELECT RefNo FROM @Betlist WHERE Bettype IN (9,29))             
			) AS b		
				inner join match14 as m with (nolock) on b.matchid=m.matchid
	END


	IF EXISTS (SELECT 1 FROM SVRARC.ArchiveDB.dbo.BettransM WITH (NOLOCK) WHERE refno IN (SELECT RefNo FROM @Betlist WHERE Bettype IN (9,29)))
	BEGIN
		INSERT INTO @tmpParlay (
			RefNo,
			transid,
			sporttype,
			leagueid,
			bettype,
			MatchId,
			homeid,
			awayid,
			hdp1,
			hdp2,
			odds,
			betteam,
			statusid,
			livehomescore,
			liveawayscore,
			liveindicator,
			HtHomeScore,
			HtAwayScore,
			FinalHomeScore,
			FinalAwayScore,
			betstatus,
			isNeutral
		)
		SELECT
			b.RefNo,
			b.transid,
			m.Sporttype,
			m.LeagueID,		
			b.Bettype ,
			m.MatchId,
			m.homeID,
			m.awayID,
			convert(float, b.hdp1) as Hdp1, 
			convert(float, b.hdp2) as Hdp2, 
			b.odds,
			b.Betteam,
			b.statusid,
			b.livehomescore,
			b.liveawayscore,
			b.liveindicator,
			m.HtHomeScore,
			m.HtAwayScore,
			m.FinalHomeScore,
			m.FinalAwayScore,
			m.betstatus,
			m.isNeutral
		FROM(	SELECT  RefNo,
						transid,
						matchid,  
						Bettype, 
						hdp1, 
						hdp2, 
						odds, 
						betteam, 
						statusid,
						livehomescore,
						liveawayscore,
						liveindicator
				FROM	SVRARC.ArchiveDB.dbo.BettransM with (nolock)
						WHERE refno IN (SELECT RefNo FROM @Betlist WHERE Bettype IN (9,29))         
			) AS b		
				inner join SVRARC.ArchiveDB.dbo.match_bk as m with (nolock) on b.matchid=m.matchid	
	END 
END

 
SELECT DISTINCT * FROM @tmpParlay
ORDER BY transID DESC
END 
-----------------


GRANT EXECUTE ON [dbo].[Age_BetList_TotalBets_SelRunningByBettype] TO [aplweb]
GO