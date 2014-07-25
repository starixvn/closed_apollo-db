ALTER PROCEDURE [dbo].[Age_BetList_SelCancelled_AgentViewAgent]
	@LoggedId INT,
	@AgentId INT , 
	@FromDate SMALLDATETIME, 
	@Todate SMALLDATETIME,	
	@Sporttypes VARCHAR(1000) ='0',
	@Bettypes VARCHAR(1000) = '0'
	

 AS
/*
Created: 20140107@Sophia
Task :  Cancelled tickets Report 
DB:  SVRAGE.RepDB
Original:  

Revisions:
  - 20140718@Sophia: Get BetFrom

Param's Explanation:  

Note: get data at Bettrans and bettrans14 table 
	
*/  
SET NOCOUNT ON


CREATE TABLE #Betlist ( TransId BIGINT, RefNo BIGINT, MatchId INT, MatchCode NVARCHAR(50), 
						HomeId INT, AwayId INT, SportType TINYINT, LeagueId INT, IsNeutral BIT, BetStatus NVARCHAR(50),
						Username NVARCHAR(50), BetType SMALLINT, CustId INT , Hdp1 SMALLMONEY, Hdp2 SMALLMONEY, Odds SMALLMONEY, MOdds SMALLMONEY,
						Status VARCHAR(10), Stake MONEY, Actual_Stake MONEY, TransDate DATETIME, BetTeam VARCHAR(10), BetId BIGINT, 
						PlayerDiscount DECIMAL (9,8), Winlost MONEY, PlayerComm MONEY, 
						APositionTaking SMALLMONEY, ADiscount DECIMAL (9,8), AWinlost MONEY, AComm MONEY,
						LiveHomeScore SMALLINT, LiveAwayScore SMALLINT,LiveIndicator BIT, 
						hthomescore SMALLINT,htawayscore SMALLINT, FinalHomeScore SMALLINT, FinalAwayScore SMALLINT,
						IP VARCHAR(40), OddsType TINYINT, DoubleCommLosing BIT, UGroup VARCHAR(3), BetFrom VARCHAR(1))

CREATE TABLE #DirectChild ( AgentId INT)
INSERT INTO #DirectChild 
SELECT	AgentId 
FROM	AgentInfo WITH (NOLOCK)
WHERE	ParentId = @LoggedId

CREATE TABLE #BettypeList (bettype SMALLINT)
IF @Bettypes <> '0' 
INSERT INTO #BettypeList
SELECT val FROM dbo.strSplit_Key(@Bettypes,',')

CREATE TABLE #SportsList (Sporttype TINYINT)
IF @Sporttypes <> '0' 
INSERT INTO #SportsList (Sporttype)
SELECT val FROM strSplit_key (@Sporttypes, ',')


-- table tmp for detail Parlay
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
	isNeutral	BIT )	


------ Check @AgentID is child of @LoggedId
DECLARE @AgentHID HierarchyID 
SELECT @AgentHID = AgentHID FROM dbo.AgentInfo WITH (NOLOCK) Where AgentID = @AgentID

IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.AgentInfo WITH (NOLOCK) WHERE @AgentHID.IsDescendantOf(AgentHID) = 1 AND AgentID = @LoggedID)
BEGIN
	SELECT * FROM #BettypeList
	SELECT * FROM @tmpParlay
	RETURN 
END

------##################################################################################################-----
IF EXISTS  (	SELECT TOP 1 1 
				FROM dbo.Bettrans  AS B  WITH (NOLOCK) 
				INNER JOIN dbo.Bettrans_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId 	
				WHERE   BA.AgentId =  @AgentId
						AND BA.StatusId in (101,102)  
						AND B.TransDate Between @FromDate AND @ToDate
						
			)
BEGIN
 
		--- Sportsbook 
		IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10) ) OR @Bettypes = '0'
		INSERT INTO #Betlist
		SELECT 	B.TransId,
				B.RefNo,
				m.MatchId,
				m.MatchCode ,
				m.HomeId,
				m.AwayId,
				m.SportType,
				m.LeagueId, 
				m.IsNeutral,
				m.BetStatus,
				B.Username,
				B.BetType,
				B.CustId,
				B.Hdp1, 
				B.Hdp2, 
				B.Odds,
				B.MOdds,
				CASE WHEN B.Status = 'running' AND IsNull(B.SecAcceptFlag, 0) = 1 AND IsNull(B.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
							ELSE B.Status 
							END as Status,
				B.Stake,
				B.Actual_Stake,
				B.TransDate,		
				B.BetTeam,
				B.BetId,
				B.PlayerDiscount,
				B.WinLost - B.Actual_Stake as WinLost,
				B.PlayerComm,
				0 as APositionTaking,
				0 as Discount,
				0 as AWinlost,
				0 as AComm,
				B.LiveHomeScore,
				B.LiveAwayScore,
				B.LiveIndicator,
				m.hthomescore,
				m.htawayscore,
				m.FinalHomeScore,
				m.FinalAwayScore,
				B.IP,		
				B.Oddstype,		
				B.DoubleCommLosing,
				'' as UGroup,
				B.BetFrom
 			FROM 	
				dbo.BetTrans AS B  WITH (NOLOCK) 
				INNER JOIN dbo.BetTrans_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId 				
				INNER JOIN dbo.Match m WITH (NOLOCK) ON  B.MatchId = m.MatchId 				 									
			WHERE BA.AgentId =  @AgentId	
				AND BA.StatusId in (101,102)				
				AND (	BA.bettype < 31 
						OR BA.bettype between 121 and 999
						OR BA.bettype between 1301 and 1334 							

					) 
									
				AND B.StatusId in (101,102)  
				AND B.TransDate Between @FromDate AND @ToDate	
				AND (	B.bettype < 31 
						OR B.bettype between 121 and 999
						OR B.bettype between 1301 and 1334 							
					) 			
				AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList)) 
							 						 
				AND (@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList)) 		
			

		-----Parlay
		IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29) )  OR (@Bettypes = '0' AND  @Sporttypes = '0')
		INSERT INTO #Betlist
		SELECT 	B.TransId,
				B.RefNo,
				0 as matchid,
				'' matchcode,
				0 as homeID,
				0 as awayID,
				0 as sporttype,
				'' as LeagueId,
				CONVERT(BIT,0) as IsNeutral,
				'' as BetStatus,
				B.Username,				
				B.BetType,
				B.CustId,
				0 as hdp1,
				0 as hdp2,
				B.Odds,
				B.MOdds,
				B.Status,
				B.Stake,
				B.Actual_Stake,
				B.TransDate,		
				B.BetTeam,
				B.BetId,
				B.PlayerDiscount,
				B.WinLost - B.Actual_Stake as WinLost,
				B.PlayerComm,
				0 as APositionTaking,
				0 as Discount,
				0 as AWinlost,
				0 as AComm,
				0 AS LiveHomeScore, 
				0 AS LiveAwayScore,
				0 AS LiveIndicator,
				0 as hthomescore,
				0 as htawayscore,
				0 as FinalHomeScore,
				0 as FinalAwayScore,
				B.IP,		
				0 as OddStype,		
				B.DoubleCommLosing,
				'' as UGroup,
				B.BetFrom	
			FROM dbo.BetTrans AS B  WITH (NOLOCK) 		
				INNER JOIN dbo.BetTrans_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId
			WHERE BA.AgentId =  @AgentId
				AND BA.StatusId in (101,102) 
				AND BA.BetType IN (9,29) 

				AND B.StatusId in (101,102)  	
				AND B.TransDate Between @FromDate AND @ToDate
				AND B.BetType IN (9,29) 
				AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))	
											

		----- Outright
		IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype = 10 ) OR @Bettypes = '0'
		INSERT INTO #Betlist
		SELECT 				
				B.transid,
				B.refno,
				0 as matchid,
				m.matchcode,
				m.teamID as homeID,
				0 as awayID,
				lg.sporttype,
				m.LeagueID,
				CONVERT(BIT,0) as IsNeutral,
				'' as BetStatus,
				B.username,
				B.bettype,	
				B.custid,
				B.hdp1, 
				B.hdp2, 
				B.odds,
				B.modds,
				B.status,
				B.stake,
				B.actual_stake,
				B.transdate,		
				B.betteam,
				B.betID,
				B.PlayerDiscount,
				B.WinLost - B.Actual_Stake as WinLost,
				B.PlayerComm,
				0 as APositionTaking,
				0 as Discount,
				0 as AWinlost,
				0 as AComm,	
				B.livehomescore,
				B.liveawayscore,
				B.liveindicator, 
				0 as hthomescore,
				0 as htawayscore,
				0 as FinalHomeScore,
				0 as FinalAwayScore,
				B.IP as IP,		
				0 as oddstype,		
				B.DoubleCommLosing,
				'' as UGroup,
				B.BetFrom
			FROM 		
				dbo.bettrans B WITH (NOLOCK)
				INNER JOIN dbo.BetTrans_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId	
							
				INNER JOIN dbo.outright as m WITH (NOLOCK) on  B.matchid=m.orid
				INNER JOIN dbo.league lg WITH (NOLOCK) on m.leagueid = lg.leagueid
			
			WHERE BA.AgentId = @AgentId 
				AND BA.StatusId in (101,102) 
				AND BA.bettype = 10

				AND B.StatusId in (101,102)  
				AND B.TransDate Between @FromDate AND @ToDate
				AND B.bettype = 10
				AND (@Sporttypes = '0' OR lg.sporttype IN (Select sporttype FROM #SportsList))


	----====================================================================================================---- 
		UPDATE B
		SET	APositionTaking = L.APositionTaking,
			ADiscount = L.ADiscount,
			AWinlost = L.AWinlost,
			AComm = L.AComm - ISNULL(D.AComm, B.PlayerComm),	
			UGroup = C.UGroup
		FROM #Betlist B
		INNER JOIN dbo.Bettrans_Agent AS L WITH (NOLOCK, INDEX = IX_TransID_AgentID) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
		LEFT JOIN  dbo.Bettrans_Agent D WITH (NOLOCK) 
				ON	D.TransID = B.TransID 
					AND D.AgentID IN (SELECT AgentId FROM #DirectChild) 
		INNER JOIN dbo.CustInfo C WITH (NOLOCK)
				ON  C.CustId = B.CustId	

END


-----##################################################################################################-----
	-- Get data at bettrans14
		IF EXISTS  (
						SELECT TOP 1 1 
						FROM dbo.Bettrans14 AS B  WITH (NOLOCK) 
						INNER JOIN dbo.Bettrans14_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId 	
						WHERE BA.AgentId =  @AgentId
							  AND BA.StatusId in (101,102) 
							  AND B.TransDate Between @FromDate AND @ToDate
							  
					)
		BEGIN 
			---Sportsbook
			IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10) ) OR @Bettypes = '0'
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
					m.BetStatus,
					B.Username,
					B.BetType,
					B.CustId,
					B.Hdp1, 
					B.Hdp2, 
					B.Odds,
					B.MOdds,
					CASE WHEN B.Status = 'running' AND IsNull(B.SecAcceptFlag, 0) = 1 AND IsNull(B.checktime, CURRENT_TIMESTAMP) > CURRENT_TIMESTAMP THEN 'waiting'
								ELSE B.Status 
								END as Status,
					B.Stake,
					B.Actual_Stake,
					B.TransDate,		
					B.BetTeam,
					B.BetId,
					B.PlayerDiscount,
					B.WinLost - B.Actual_Stake as WinLost,
					B.PlayerComm,
					0 as APositionTaking,
					0 as ADiscount,
					0 as AWinlost,
					0 as AComm,		
					B.LiveHomeScore,
					B.LiveAwayScore,
					B.LiveIndicator,
					m.hthomescore,
					m.htawayscore,
					m.FinalHomeScore,
					m.FinalAwayScore,
					B.IP,		
					B.Oddstype,		
					B.DoubleCommLosing,
					'' as UGroup,
					B.BetFrom
 				FROM 	
					dbo.Bettrans14 AS B  WITH (NOLOCK) 
					INNER JOIN dbo.Bettrans14_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId	
					INNER JOIN dbo.Match14 m WITH (NOLOCK) ON  B.MatchId = m.MatchId 		
												
				WHERE BA.AgentId =  @AgentId			
					AND BA.StatusId in (101,102) 
					AND (	BA.bettype < 31 
							OR BA.bettype between 121 and 999
							OR BA.bettype between 1301 and 1334 							

						) 

					AND B.TransDate Between @FromDate AND @ToDate	
					AND (	B.bettype < 31 
							OR B.bettype between 121 and 999
							OR B.bettype between 1301 and 1334 							
						) 
					AND B.StatusId in (101,102)  			
					AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList)) 			
											 
					AND (@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList)) 		
			 
			-----Parlay
			IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29)) OR (@Bettypes = '0' AND  @Sporttypes = '0')
			INSERT INTO #Betlist
			SELECT 	
					B.TransId,
					B.RefNo,
					0 as matchid,
					'' matchcode,
					0 as homeID,
					0 as awayID,
					0 as sporttype,
					'' as LeagueId,
					CONVERT(BIT,0) as IsNeutral,
					'' as BetStatus,
					B.Username,				
					B.BetType,
					B.CustId,
					0 as hdp1,
					0 as hdp2,
					B.Odds,
					B.MOdds,
					B.Status,
					B.Stake,
					B.Actual_Stake,
					B.TransDate,		
					B.BetTeam,
					B.BetId,
					B.PlayerDiscount,
					B.WinLost - B.Actual_Stake as WinLost,
					B.PlayerComm,
					0 as APositionTaking,
					0 as ADiscount,
					0 as AWinlost,
					0 as AComm,		
					0 AS LiveHomeScore, 
					0 AS LiveAwayScore,
					0 AS LiveIndicator,
					0 as hthomescore,
					0 as htawayscore,
					0 as FinalHomeScore,
					0 as FinalAwayScore,
					B.IP,		
					0 as OddStype,		
					B.DoubleCommLosing,
					'' as UGroup,
					B.BetFrom	
				FROM dbo.Bettrans14 AS B  WITH (NOLOCK) 		
					INNER JOIN dbo.Bettrans14_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId					
				WHERE BA.AgentId =  @AgentId	
					AND BA.BetType IN (9,29) 
					AND BA.StatusId in (101,102)  
				
					AND B.TransDate Between @FromDate AND @ToDate
					AND B.BetType IN (9,29)
					AND B.StatusId in (101,102)  
					AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))					
						 

			----- Outright14
			IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype =10 ) OR @Bettypes = '0'
			INSERT INTO #Betlist
			SELECT 		
					B.transid,
					B.refno,
					0 as matchid,
					m.matchcode,
					m.teamID as homeID,
					0 as awayID,
					lg.sporttype,
					m.LeagueID,
					CONVERT(BIT,0) as IsNeutral,
					'' as BetStatus,
					B.username,
					B.bettype,	
					B.custid,
					B.hdp1, 
					B.hdp2, 
					B.odds,
					B.modds,
					B.status,
					B.stake,
					B.actual_stake,
					B.transdate,		
					B.betteam,
					B.betID,
					B.PlayerDiscount,
					B.WinLost - B.Actual_Stake as WinLost,
					B.PlayerComm,
					0 as APositionTaking,
					0 as ADiscount,
					0 as AWinlost,
					0 as AComm,	
					B.livehomescore,
					B.liveawayscore,
					B.liveindicator, 
					0 as hthomescore,
					0 as htawayscore,
					0 as FinalHomeScore,
					0 as FinalAwayScore,
					B.IP as IP,		
					0 as oddstype,		
					B.DoubleCommLosing,
					'' as UGroup,
					B.BetFrom
				FROM 		
					dbo.Bettrans14 B WITH (NOLOCK)
					INNER JOIN dbo.Bettrans14_Agent AS BA WITH (NOLOCK) ON BA.TransId = B.TransId					
					INNER JOIN dbo.Outright14 as m WITH (NOLOCK) on  B.matchid=m.orid
					INNER JOIN dbo.league lg WITH (NOLOCK) on m.leagueid = lg.leagueid
				WHERE 
					BA.AgentId = @AgentId 					  
					AND BA.StatusId in (101,102)  				
					AND BA.bettype = 10						
													
					AND B.TransDate Between @FromDate AND @ToDate
					AND B.StatusId in (101,102)  
					AND B.bettype = 10								 
																		 
					AND (@Sporttypes = '0' OR lg.sporttype IN (Select sporttype FROM #SportsList))



	-----====================================================================================================---- 
			UPDATE B
			SET	APositionTaking = L.APositionTaking,
				ADiscount = L.ADiscount,
				AWinlost = L.AWinlost,
				AComm = L.AComm - ISNULL(D.AComm, B.PlayerComm) ,	
				UGroup = C.UGroup
			FROM #Betlist B
			INNER JOIN dbo.Bettrans14_Agent AS L WITH (NOLOCK, INDEX = IX_TransID_AgentID) ON B.TransId = L.TransId AND L.AgentID = @LoggedId
			LEFT JOIN dbo.Bettrans14_Agent D WITH (NOLOCK) 
				ON D.TransID = B.TransID 
					AND D.AgentID IN (SELECT AgentId FROM #DirectChild)					
			INNER JOIN dbo.CustInfo C WITH (NOLOCK) ON  C.CustId = B.CustId	

		END
		
	-----====================================================================================================---- 
	-- Get Betlist
		SELECT		* 
		FROM		#Betlist 
		ORDER BY	TransID DESC



------##################################################################################################-----
---- Detail Parlay 


IF EXISTS  (SELECT 1 FROM #Betlist WHERE Bettype IN (9,29))
BEGIN 

	IF EXISTS (SELECT 1 FROM dbo.bettransm WITH (NOLOCK) WHERE refno IN (SELECT RefNo FROM #Betlist WHERE Bettype IN (9,29)))
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
				FROM	dbo.BettransM with (nolock)
						WHERE refno IN (SELECT RefNo FROM #Betlist WHERE Bettype IN (9,29))         
			) AS b		
				inner join dbo.match as m with (nolock) on b.matchid=m.matchid
	END


	IF EXISTS (SELECT 1 FROM dbo.bettransm14 WITH (NOLOCK) WHERE refno IN (SELECT RefNo FROM #Betlist WHERE Bettype IN (9,29)))
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
				FROM	dbo.BettransM14 with (nolock)
						WHERE refno IN (SELECT RefNo FROM #Betlist WHERE Bettype IN (9,29))             
			) AS b		
				inner join dbo.match14 as m with (nolock) on b.matchid=m.matchid
	END


	IF EXISTS (SELECT 1 FROM SVRARC.ArchiveDB.dbo.BettransM WITH (NOLOCK) WHERE refno IN (SELECT RefNo FROM #Betlist WHERE Bettype IN (9,29)))
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
						WHERE refno IN (SELECT RefNo FROM #Betlist WHERE Bettype IN (9,29))         
			) AS b		
				inner join SVRARC.ArchiveDB.dbo.match_bk as m with (nolock) on b.matchid=m.matchid	
	END 
END

 
SELECT	DISTINCT * 
FROM	@tmpParlay
ORDER BY TransID DESC
---------------

DROP TABLE #Betlist
DROP TABLE #DirectChild
DROP TABLE #BettypeList
DROP TABLE #SportsList


GO
GRANT EXECUTE ON [dbo].[Age_BetList_SelCancelled_AgentViewAgent] TO [aplweb]
GO 