ALTER PROCEDURE [dbo].[Age_Rpt_Outstanding_Xtest] 
	@AgentId int,
	@Sporttypes VARCHAR(MAX)= '0',
	@Bettypes VARCHAR(MAX) = '0'
AS

/*
Created: Sophia
Date: 20130329
Task : Report Outstanding
DB:  SVRAGE.RepDB
Original: [Age_Rpt_Outstanding_Ag]

Revisions:
- 20130708@Sophia: Change SuperId from 0 to 1 (@AgentID = 1)

*/
SET NOCOUNT ON
DECLARE @AgentOutstanding TABLE (Username NVARCHAR(50), AgentID INT, IsAgent BIT, Outstanding MONEY, Positiontaking MONEY)
DECLARE @MemberOutstanding TABLE (Username NVARCHAR(50), AgentID INT, IsAgent BIT, Outstanding MONEY, Positiontaking MONEY)


CREATE TABLE #BettypeList (bettype SMALLINT)
INSERT INTO #BettypeList
SELECT val FROM dbo.strSplit_Key(@Bettypes,',')

CREATE TABLE #SportsList (Sporttype TINYINT)
INSERT INTO #SportsList (Sporttype)
SELECT val FROM strSplit_key (@Sporttypes, ',')

		 
IF @AgentId = 1
BEGIN 
	----Super view
	--Sportsbook
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10) OR @Bettypes = '0')
	INSERT INTO @AgentOutstanding
	SELECT  C.Username, C.AgentID, 1 as IsAgent,
			ISNULL(SUM (ABS(B.actual_stake)),0) as Outstanding,
			ISNULL(SUM(ABS(B.actual_stake) * (1-B.TPositiontaking)),0) as Positiontaking
	FROM AgentInfo C WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK) -- MAIN SH 
			ON BA.AgentID = C.AgentID		
	INNER JOIN Bettrans B WITH (NOLOCK) 
			ON B.TransID = BA.TransID
	INNER JOIN Match M WITH (NOLOCK) 
			ON M.MatchId = B.MatchId			
	WHERE	C.ParentId = 1 
			AND B.StatusID IN (0,1) 
			AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))
			AND B.MatchID >0

			AND BA.StatusID IN (0,1) 
			AND (@Bettypes = '0' OR BA.Bettype in (Select bettype FROM #BettypeList))
			AND BA.MatchID > 0

			AND (@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList))						
	GROUP BY  C.Username, C.AgentID

	--Parlay
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29) OR @Bettypes = '0')
	INSERT INTO @AgentOutstanding
	SELECT		B.Username, B.AgentID, 1 as IsAgent,
				ISNULL(SUM (ABS(B.actual_stake)),0) as Outstanding,
				ISNULL(SUM(ABS(B.actual_stake) * (1-B.TPositiontaking)),0) as Positiontaking
	FROM (
			SELECT  DISTINCT C.Username, C.AgentID, 1 as IsAgent,
					B.bettype , B.actual_stake, B.TPositiontaking
			FROM AgentInfo C WITH (NOLOCK)
			INNER JOIN BetTrans_Agent BA WITH (NOLOCK) ---Main SH
					ON BA.AgentID = C.AgentID		
			INNER JOIN Bettrans B WITH (NOLOCK) 
					ON B.TransID = BA.TransID
			INNER JOIN BettransM BM WITH (NOLOCK)
					ON BM.RefNo = B.RefNo  
			INNER JOIN Match M WITH (NOLOCK) 
					ON M.MatchId = BM.MatchId			
			WHERE	C.ParentId = 1 
					AND BA.StatusID IN (0,1)
					AND BA.MatchID IN (9,29)
					AND BA.Bettype IN (9,29) 					
					AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

					AND B.StatusID IN (0,1)
					AND B.MatchID IN (9,29)
					AND B.Bettype IN (9,29) 
					AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))

					AND (@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList))
				) B
	GROUP BY  B.Username, B.AgentID


	--Outright
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype=10 OR @Bettypes = '0')
	INSERT INTO @AgentOutstanding
	SELECT  DISTINCT C.Username, C.AgentID, 1 as IsAgent,
			ISNULL(SUM (ABS(B.actual_stake)),0) as Outstanding,
			ISNULL(SUM(ABS(B.actual_stake) * (1-B.TPositiontaking)),0) as Positiontaking
	FROM AgentInfo C WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK)  --- Main SH 
			ON BA.AgentID = C.AgentID		
	INNER JOIN Bettrans B WITH (NOLOCK ) 
			ON B.TransID = BA.TransID	
	INNER JOIN Outright M WITH (NOLOCK) 
			ON M.orid = B.MatchId
	INNER JOIN League l WITH (NOLOCK)
			ON l.LeagueId = M.LeagueId						
	WHERE	C.ParentId = @AgentID 
			AND BA.StatusID IN (0,1)
			AND BA.MatchID > 0
			AND BA.Bettype = 10
			AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

			AND B.StatusID IN (0,1)
			AND B.matchID > 0
			AND B.Bettype = 10
			AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))

			AND (@Sporttypes = '0' OR l.sporttype IN (Select sporttype FROM #SportsList))					
	GROUP BY  C.Username, C.AgentID

END
ELSE 
BEGIN
	----- Agent Outstanding
	---Sportsbook
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10) OR @Bettypes = '0')
	INSERT INTO @AgentOutstanding
	SELECT  C.Username, C.AgentID, 1 as IsAgent,
			ISNULL(SUM (ABS(BP.actual_stake)),0) as Outstanding,
			ISNULL(SUM(ABS(BP.actual_stake) * BP.APositiontaking),0) as Positiontaking
	FROM	AgentInfo C  WITH (NOLOCK)
	INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK) -- child
			ON BA.AgentID = C.AgentID
	INNER JOIN BetTrans_Agent AS BP WITH (NOLOCK) --- parent
			ON BP.TransID = BA.TransID AND BP.AgentID = @AgentID
	INNER JOIN Match M WITH (NOLOCK) 
			ON M.MatchId = BA.MatchId
	WHERE	C.ParentId = @AgentID 
			AND BA.StatusID IN (0,1)	
			AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))
			AND BA.MatchID > 0

			AND BP.StatusID IN (0,1)	
			AND (@Bettypes = '0' OR BP.Bettype IN (Select bettype FROM #BettypeList))
			AND BP.MatchID >0
			AND (@Sporttypes = '0' OR M.sporttype IN (Select sporttype FROM #SportsList))		
	GROUP BY C.Username, C.AgentID


	----- Parlay
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29) OR @Bettypes = '0')
	INSERT INTO @AgentOutstanding 
	SELECT	B.Username, B.AgentID, 1 as IsAgent,
			ISNULL(SUM (ABS(B.actual_stake)),0) as Outstanding,
			ISNULL(SUM(ABS(B.actual_stake) * B.APositiontaking),0) as Positiontaking
	FROM 
	( 
		SELECT  DISTINCT C.Username, C.AgentID,  BP.bettype, BP.actual_stake, BP.APositiontaking  
		FROM	AgentInfo C  WITH (NOLOCK)
		INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK)
				ON BA.AgentID = C.AgentID
		INNER JOIN BetTrans_Agent AS BP WITH (NOLOCK)
				ON BP.TransID = BA.TransID AND BP.AgentID = @AgentID
		INNER JOIN BettransM BM WITH (NOLOCK)
				ON BM.RefNo = BA.RefNo
		INNER JOIN Match M WITH (NOLOCK) 
				ON M.MatchId = BM.MatchId
		WHERE	C.ParentId = @AgentID 
				AND BA.StatusID IN (0,1)	
				AND BA.MatchID IN (9,29)
				AND BA.Bettype IN (9,29)
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

				AND BP.StatusID IN (0,1)
				AND BP.MatchID IN (9,29)
				AND BP.Bettype IN (9,29)	
				AND (@Bettypes = '0' OR BP.Bettype IN (Select bettype FROM #BettypeList))

				AND (@Sporttypes = '0' OR M.sporttype IN (Select sporttype FROM #SportsList))	
		) B	
		GROUP BY B.Username, B.AgentID 

	----- Outright
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype = 10 OR @Bettypes = '0')
	INSERT INTO @AgentOutstanding
	SELECT  C.Username, C.AgentID, 1 as IsAgent,
			ISNULL(SUM (ABS(BP.actual_stake)),0) as Outstanding,
			ISNULL(SUM(ABS(BP.actual_stake) * BP.APositiontaking),0) as Positiontaking
	FROM	AgentInfo C  WITH (NOLOCK)
	INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK)
			ON BA.AgentID = C.AgentID
	INNER JOIN BetTrans_Agent AS BP WITH (NOLOCK)
			ON BP.TransID = BA.TransID AND BP.AgentID = @AgentID	
	INNER JOIN Outright M WITH (NOLOCK) 
			ON M.orid = BA.MatchId
	INNER JOIN League l WITH (NOLOCK)
			ON l.LeagueId = M.LeagueId
	WHERE	C.ParentId = @AgentID 
			AND BA.StatusID IN (0,1)	
			AND BA.MatchID > 0
			AND BA.Bettype = 10
			AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

			AND BP.StatusID IN (0,1)
			AND BP.MatchID > 0
			AND BP.Bettype = 10
			AND (@Bettypes = '0' OR BP.Bettype IN (Select bettype FROM #BettypeList))

			AND (@Sporttypes = '0' OR L.sporttype IN (Select sporttype FROM #SportsList))		
	GROUP BY C.Username, C.AgentID




 

-----Member Outstanding
	-- SportsBook 
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10) OR @Bettypes = '0')
	INSERT INTO @MemberOutstanding 
	SELECT  '', C.AgentId, 0 as IsAgent,
			ISNULL(SUM (ABS(BA.actual_stake)),0) as Outstanding,
			ISNULL(SUM(ABS(BA.actual_stake) * BA.APositiontaking),0) as Positiontaking
	FROM Bettrans B WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK) 
		ON BA.TransID = B.TransID AND BA.AgentId = @AgentID 
	INNER JOIN CustInfo C WITH (NOLOCK)
		ON B.CustID = C.CustID AND C.AgentId =@AgentID
	INNER JOIN Match M WITH (NOLOCK) 
		ON M.MatchId = BA.MatchId 
	WHERE	 BA.StatusId IN (0,1)
			AND BA.matchID > 0
			AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))
			
			AND B.StatusId IN (0,1)
			AND B.matchID > 0
			AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))
			AND (@Sporttypes = '0' OR M.sporttype IN (Select sporttype FROM #SportsList))	
	GROUP BY C.AgentId

	-- Parlay 
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29) OR @Bettypes = '0')
	INSERT INTO @MemberOutstanding 
	SELECT  '', B.AgentId, 0 as IsAgent,
			ISNULL(SUM (ABS(B.actual_stake)),0) as Outstanding,
			ISNULL(SUM(ABS(B.actual_stake) * B.APositiontaking),0) as Positiontaking
	FROM (
			SELECT  DISTINCT C.AgentId, BA.bettype, BA.actual_stake, BA.APositiontaking
			FROM Bettrans B WITH (NOLOCK)
			INNER JOIN BetTrans_Agent BA WITH (NOLOCK) 
				ON BA.TransID = B.TransID AND BA.AgentId = @AgentID 				
			INNER JOIN CustInfo C WITH (NOLOCK)
				ON B.CustID = C.CustID AND C.AgentId =@AgentID
			INNER JOIN BettransM BM WITH (NOLOCK)
					ON BM.RefNo = BA.RefNo
			INNER JOIN Match M WITH (NOLOCK) 
					ON M.MatchId = BM.MatchId
			WHERE	BA.StatusId IN (0,1)
					AND BA.matchID IN (9,29)
					AND BA.Bettype In (9,29)
					AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

					AND B.StatusId IN (0,1)
					AND B.matchID IN (9,29)
					AND B.Bettype In (9,29)
					AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))

					AND (@Sporttypes = '0' OR M.sporttype IN (Select sporttype FROM #SportsList))	
				) B
	GROUP BY B.AgentId

	-- Outright 
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype = 10 OR @Bettypes = '0')
	INSERT INTO @MemberOutstanding 
	SELECT  '', C.AgentId, 0 as IsAgent,
			ISNULL(SUM (ABS(BA.actual_stake)),0) as Outstanding,
			ISNULL(SUM(ABS(BA.actual_stake) * BA.APositiontaking),0) as Positiontaking
	FROM Bettrans B WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK) 
		ON BA.TransID = B.TransID AND BA.AgentId = @AgentID 
	INNER JOIN CustInfo C WITH (NOLOCK)
		ON B.CustID = C.CustID AND C.AgentId =@AgentID
	INNER JOIN Outright M WITH (NOLOCK) 
			ON M.orid = BA.MatchId
	INNER JOIN League l WITH (NOLOCK)
			ON l.LeagueId = M.LeagueId
	WHERE	 BA.StatusId IN (0,1)
			AND BA.matchID > 0
			AND BA.Bettype = 10
			AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

			AND B.StatusId IN (0,1)
			AND B.matchID > 0
			AND B.Bettype = 10
			AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))
			AND (@Sporttypes = '0' OR L.sporttype IN (Select sporttype FROM #SportsList))	
	GROUP BY C.AgentId

END
	 
SELECT Username, AgentID , IsAgent , SUM (Outstanding) Outstanding , SUM (Positiontaking) Positiontaking --, SUM(Outstanding_NG) Outstanding_NG , SUM (Positiontaking_NG)Positiontaking_NG 
FROM @AgentOutstanding
GROUP BY  Username, AgentID , IsAgent 
UNION ALL
SELECT Username, AgentID , IsAgent , SUM (Outstanding) Outstanding , SUM (Positiontaking) Positiontaking --, SUM(Outstanding_NG) Outstanding_NG , SUM (Positiontaking_NG)Positiontaking_NG 
FROM @MemberOutstanding 
GROUP BY Username, AgentID , IsAgent 
ORDER BY IsAgent DESC, Username ASC





