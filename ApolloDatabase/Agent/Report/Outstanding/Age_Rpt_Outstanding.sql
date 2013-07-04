alter PROCEDURE [dbo].[Age_Rpt_Outstanding_Xtest] 
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

*/
SET NOCOUNT ON
DECLARE @AgentOutstanding TABLE (Username NVARCHAR(50), AgentID INT, IsAgent BIT, Outstanding MONEY, Positiontaking MONEY, Outstanding_NG MONEY, Positiontaking_NG MONEY)
DECLARE @MemberOutstanding TABLE (Username NVARCHAR(50), AgentID INT, IsAgent BIT, Outstanding MONEY, Positiontaking MONEY, Outstanding_NG MONEY, Positiontaking_NG MONEY)


CREATE TABLE #BettypeList (bettype SMALLINT)
INSERT INTO #BettypeList
SELECT val FROM dbo.strSplit_Key(@Bettypes,',')

CREATE TABLE #SportsList (Sporttype TINYINT)
INSERT INTO #SportsList (Sporttype)
SELECT val FROM strSplit_key (@Sporttypes, ',')

		 
IF @AgentId = 0
BEGIN 
	----Super view
	--Sportsbook
	INSERT INTO @AgentOutstanding
	SELECT  C.Username, C.AgentID, 1 as IsAgent,
		ISNULL(SUM(CASE when BA.bettype < 31 OR BA.bettype between 121 and 999 OR BA.bettype between 1301 and 1334 then ABS(BA.actual_stake) END),0) Outstanding,  
		ISNULL(SUM(CASE when BA.bettype < 31 OR BA.bettype between 121 and 999 OR BA.bettype between 1301 and 1334 then ABS(BA.actual_stake) * (1-B.TPositiontaking) END),0) Positiontaking,
		ISNULL(SUM(CASE when BA.bettype BETWEEN 81 and 120 then  ABS(BA.actual_stake) END),0) Outstanding_NG,
		ISNULL(SUM(CASE when BA.bettype BETWEEN 81 and 120 then  ABS(BA.actual_stake) * (1-B.TPositiontaking) END),0) Positiontaking_NG
	FROM AgentInfo C WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK)
			ON BA.AgentID = C.AgentID		
	INNER JOIN Bettrans B WITH (NOLOCK) 
			ON B.TransID = BA.TransID
	INNER JOIN Match M WITH (NOLOCK) 
			ON M.MatchId = B.MatchId			
	WHERE	C.ParentId = @AgentID 
			AND B.StatusID IN (0,1) 
			AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))

			AND BA.StatusID IN (0,1) 
			AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

			AND (@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList))						
	GROUP BY  C.Username, C.AgentID

	--Parlay
	INSERT INTO @AgentOutstanding
	SELECT		B.Username, B.AgentID, 1 as IsAgent,
				ISNULL(SUM(CASE when B.bettype < 31 OR B.bettype between 121 and 999 OR B.bettype between 1301 and 1334 then ABS(B.actual_stake) END),0) Outstanding,  
				ISNULL(SUM(CASE when B.bettype < 31 OR B.bettype between 121 and 999 OR B.bettype between 1301 and 1334 then ABS(B.actual_stake) * (1-B.TPositiontaking) END),0) Positiontaking,
				ISNULL(SUM(CASE when B.bettype BETWEEN 81 and 120 then  ABS(B.actual_stake) END),0) Outstanding_NG,
				ISNULL(SUM(CASE when B.bettype BETWEEN 81 and 120 then  ABS(B.actual_stake) * (1-B.TPositiontaking) END),0) Positiontaking_NG
	FROM (
			SELECT  DISTINCT C.Username, C.AgentID, 1 as IsAgent,
					BA.bettype , BA.actual_stake, B.TPositiontaking
			FROM AgentInfo C WITH (NOLOCK)
			INNER JOIN BetTrans_Agent BA WITH (NOLOCK)
					ON BA.AgentID = C.AgentID		
			INNER JOIN Bettrans B WITH (NOLOCK) 
					ON B.TransID = BA.TransID
			INNER JOIN BettransM BM WITH (NOLOCK)
					ON BM.RefNo = B.RefNo
			INNER JOIN Match M WITH (NOLOCK) 
					ON M.MatchId = BM.MatchId			
			WHERE	C.ParentId = @AgentID 
					AND BA.StatusID IN (0,1)
					AND BA.Bettype IN (9,29) 
					AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

					AND B.StatusID IN (0,1)
					AND B.Bettype IN (9,29) 
					AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))

					AND (@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList))
				) B
	GROUP BY  B.Username, B.AgentID


	--Outright
	INSERT INTO @AgentOutstanding
	SELECT  DISTINCT C.Username, C.AgentID, 1 as IsAgent,
		ISNULL(SUM(CASE when BA.bettype < 31 OR BA.bettype between 121 and 999 OR BA.bettype between 1301 and 1334 then ABS(BA.actual_stake) END),0) Outstanding,  
		ISNULL(SUM(CASE when BA.bettype < 31 OR BA.bettype between 121 and 999 OR BA.bettype between 1301 and 1334 then ABS(BA.actual_stake) * (1-B.TPositiontaking) END),0) Positiontaking,
		ISNULL(SUM(CASE when BA.bettype BETWEEN 81 and 120 then  ABS(BA.actual_stake) END),0) Outstanding_NG,
		ISNULL(SUM(CASE when BA.bettype BETWEEN 81 and 120 then  ABS(BA.actual_stake) * (1-B.TPositiontaking) END),0) Positiontaking_NG
	FROM AgentInfo C WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK)
			ON BA.AgentID = C.AgentID		
	INNER JOIN Bettrans B WITH (NOLOCK) 
			ON B.TransID = BA.TransID	
	INNER JOIN Outright M WITH (NOLOCK) 
			ON M.orid = B.MatchId
	INNER JOIN League l WITH (NOLOCK)
			ON l.LeagueId = M.LeagueId						
	WHERE	C.ParentId = @AgentID 
			AND BA.StatusID IN (0,1)
			AND BA.Bettype = 10
			AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

			AND B.StatusID IN (0,1)
			AND B.Bettype = 10
			AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))

			AND (@Sporttypes = '0' OR l.sporttype IN (Select sporttype FROM #SportsList))					
	GROUP BY  C.Username, C.AgentID

END
ELSE 
BEGIN
	----- Agent Outstanding
	---Sportsbook
	INSERT INTO @AgentOutstanding
	SELECT  C.Username, C.AgentID, 1 as IsAgent,
		ISNULL(SUM(CASE when BA.bettype < 31 OR BA.bettype between 121 and 999 OR BA.bettype between 1301 and 1334 then ABS(BA.actual_stake) END),0) Outstanding,  
		ISNULL(SUM(CASE when BA.bettype < 31 OR BA.bettype between 121 and 999 OR BA.bettype between 1301 and 1334 then ABS(BA.actual_stake) * BP.APositiontaking END),0) Positiontaking,
		ISNULL(SUM(CASE when BA.bettype BETWEEN 81 and 120 then ABS(BA.actual_stake) END),0) Outstanding_NG,
		ISNULL(SUM(CASE when BA.bettype BETWEEN 81 and 120 then ABS(BA.actual_stake) * BP.APositiontaking END),0) Positiontaking_NG
	FROM	AgentInfo C  WITH (NOLOCK)
	INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK)
			ON BA.AgentID = C.AgentID
	INNER JOIN BetTrans_Agent AS BP WITH (NOLOCK)
			ON BP.TransID = BA.TransID AND BP.AgentID = @AgentID
	INNER JOIN Match M WITH (NOLOCK) 
			ON M.MatchId = BA.MatchId
	WHERE	C.ParentId = @AgentID 
			AND BA.StatusID IN (0,1)	
			AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

			AND BP.StatusID IN (0,1)	
			AND (@Bettypes = '0' OR BP.Bettype IN (Select bettype FROM #BettypeList))

			AND (@Sporttypes = '0' OR M.sporttype IN (Select sporttype FROM #SportsList))		
	GROUP BY C.Username, C.AgentID


	----- Parlay
	INSERT INTO @AgentOutstanding 
	SELECT DISTINCT	B.Username, B.AgentID, 1 as IsAgent,
		ISNULL(SUM(CASE when B.bettype < 31 OR B.bettype between 121 and 999 OR B.bettype between 1301 and 1334 then ABS(B.actual_stake) END),0) Outstanding,  
		ISNULL(SUM(CASE when B.bettype < 31 OR B.bettype between 121 and 999 OR B.bettype between 1301 and 1334 then ABS(B.actual_stake) * B.APositiontaking END),0) Positiontaking,
		ISNULL(SUM(CASE when B.bettype BETWEEN 81 and 120 then ABS(B.actual_stake) END),0) Outstanding_NG,
		ISNULL(SUM(CASE when B.bettype BETWEEN 81 and 120 then ABS(B.actual_stake) * B.APositiontaking END),0) Positiontaking_NG
	
	FROM 
	( 
		SELECT  C.Username, C.AgentID,  BA.bettype, BA.actual_stake, BP.APositiontaking  
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
				AND BA.Bettype IN (9,29)
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

				AND BP.StatusID IN (0,1)
				AND BP.Bettype IN (9,29)	
				AND (@Bettypes = '0' OR BP.Bettype IN (Select bettype FROM #BettypeList))

				AND (@Sporttypes = '0' OR M.sporttype IN (Select sporttype FROM #SportsList))	
		) B	
		GROUP BY B.Username, B.AgentID 

	----- Outright
	INSERT INTO @AgentOutstanding
	SELECT  C.Username, C.AgentID, 1 as IsAgent,
		ISNULL(SUM(CASE when BA.bettype < 31 OR BA.bettype between 121 and 999 OR BA.bettype between 1301 and 1334 then ABS(BA.actual_stake) END),0) Outstanding,  
		ISNULL(SUM(CASE when BA.bettype < 31 OR BA.bettype between 121 and 999 OR BA.bettype between 1301 and 1334 then ABS(BA.actual_stake) * BP.APositiontaking END),0) Positiontaking,
		ISNULL(SUM(CASE when BA.bettype BETWEEN 81 and 120 then ABS(BA.actual_stake) END),0) Outstanding_NG,
		ISNULL(SUM(CASE when BA.bettype BETWEEN 81 and 120 then ABS(BA.actual_stake) * BP.APositiontaking END),0) Positiontaking_NG
	FROM	AgentInfo C  WITH (NOLOCK)
	INNER JOIN BetTrans_Agent AS BA WITH (NOLOCK)
			ON BA.AgentID = C.AgentID
	INNER JOIN BetTrans_Agent AS BP WITH (NOLOCK)
			ON BP.TransID = BA.TransID AND BP.AgentID = @AgentID
	INNER JOIN BettransM BM WITH (NOLOCK)
			ON BM.RefNo = BA.RefNo
	INNER JOIN Outright M WITH (NOLOCK) 
			ON M.orid = BA.MatchId
	INNER JOIN League l WITH (NOLOCK)
			ON l.LeagueId = M.LeagueId
	WHERE	C.ParentId = @AgentID 
			AND BA.StatusID IN (0,1)	
			AND BA.Bettype = 10
			AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

			AND BP.StatusID IN (0,1)
			AND BP.Bettype = 10
			AND (@Bettypes = '0' OR BP.Bettype IN (Select bettype FROM #BettypeList))

			AND (@Sporttypes = '0' OR L.sporttype IN (Select sporttype FROM #SportsList))		
	GROUP BY C.Username, C.AgentID


END

 

-----Member Outstanding
	-- SportsBook 
	INSERT INTO @MemberOutstanding 
	SELECT  '', C.AgentId, 0 as IsAgent,
			ISNULL(SUM(CASE when BA.bettype < 31 OR BA.bettype between 121 and 999 OR BA.bettype between 1301 and 1334 then ABS(BA.actual_stake) END),0) Outstanding,  
			ISNULL(SUM(CASE when BA.bettype < 31 OR BA.bettype between 121 and 999 OR BA.bettype between 1301 and 1334 then ABS(BA.actual_stake) * BA.APositiontaking END),0) Positiontaking,
			ISNULL(SUM(CASE when BA.bettype BETWEEN 81 and 120 then ABS(BA.actual_stake) END),0) Outstanding_NG,
			ISNULL(SUM(CASE when BA.bettype BETWEEN 81 and 120 then ABS(BA.actual_stake) * BA.APositiontaking END),0) Positiontaking_NG
	FROM Bettrans B WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK) 
		ON BA.TransID = B.TransID 
	INNER JOIN CustInfo C WITH (NOLOCK)
		ON B.CustID = C.CustID AND C.AgentId =@AgentID
	INNER JOIN Match M WITH (NOLOCK) 
		ON M.MatchId = BA.MatchId 
	WHERE	BA.AgentId = @AgentID 
			AND BA.StatusId IN (0,1)
			AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))
			
			AND B.StatusId IN (0,1)
			AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))
			AND (@Sporttypes = '0' OR M.sporttype IN (Select sporttype FROM #SportsList))	
	GROUP BY C.AgentId

	-- Parlay 
	INSERT INTO @MemberOutstanding 
	SELECT  DISTINCT '', B.AgentId, 0 as IsAgent,
			ISNULL(SUM(CASE when B.bettype < 31 OR B.bettype between 121 and 999 OR B.bettype between 1301 and 1334 then ABS(B.actual_stake) END),0) Outstanding,  
			ISNULL(SUM(CASE when B.bettype < 31 OR B.bettype between 121 and 999 OR B.bettype between 1301 and 1334 then ABS(B.actual_stake) * B.APositiontaking END),0) Positiontaking,
			ISNULL(SUM(CASE when B.bettype BETWEEN 81 and 120 then ABS(B.actual_stake) END),0) Outstanding_NG,
			ISNULL(SUM(CASE when B.bettype BETWEEN 81 and 120 then ABS(B.actual_stake) * B.APositiontaking END),0) Positiontaking_NG
	FROM (
	SELECT  C.AgentId, BA.bettype, BA.actual_stake, BA.APositiontaking
	FROM Bettrans B WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK) 
		ON BA.TransID = B.TransID 
	INNER JOIN CustInfo C WITH (NOLOCK)
		ON B.CustID = C.CustID AND C.AgentId =@AgentID
	INNER JOIN BettransM BM WITH (NOLOCK)
			ON BM.RefNo = BA.RefNo
	INNER JOIN Match M WITH (NOLOCK) 
			ON M.MatchId = BM.MatchId
	WHERE	BA.AgentId = @AgentID 
			AND BA.StatusId IN (0,1)
			AND BA.Bettype In (9,29)
			AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

			AND B.StatusId IN (0,1)
			AND B.Bettype In (9,29)
			AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))

			AND (@Sporttypes = '0' OR M.sporttype IN (Select sporttype FROM #SportsList))	
		) B
	GROUP BY B.AgentId

	-- Outright 
	INSERT INTO @MemberOutstanding 
	SELECT  '', C.AgentId, 0 as IsAgent,
			ISNULL(SUM(CASE when BA.bettype < 31 OR BA.bettype between 121 and 999 OR BA.bettype between 1301 and 1334 then ABS(BA.actual_stake) END),0) Outstanding,  
			ISNULL(SUM(CASE when BA.bettype < 31 OR BA.bettype between 121 and 999 OR BA.bettype between 1301 and 1334 then ABS(BA.actual_stake) * BA.APositiontaking END),0) Positiontaking,
			ISNULL(SUM(CASE when BA.bettype BETWEEN 81 and 120 then ABS(BA.actual_stake) END),0) Outstanding_NG,
			ISNULL(SUM(CASE when BA.bettype BETWEEN 81 and 120 then ABS(BA.actual_stake) * BA.APositiontaking END),0) Positiontaking_NG
	FROM Bettrans B WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK) 
		ON BA.TransID = B.TransID 
	INNER JOIN CustInfo C WITH (NOLOCK)
		ON B.CustID = C.CustID AND C.AgentId =@AgentID
	INNER JOIN Outright M WITH (NOLOCK) 
			ON M.orid = BA.MatchId
	INNER JOIN League l WITH (NOLOCK)
			ON l.LeagueId = M.LeagueId
	WHERE	BA.AgentId = @AgentID 
			AND BA.StatusId IN (0,1)
			AND BA.Bettype = 10
			AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

			AND B.StatusId IN (0,1)
			AND B.Bettype = 10
			AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))
			AND (@Sporttypes = '0' OR L.sporttype IN (Select sporttype FROM #SportsList))	
	GROUP BY C.AgentId
	 
SELECT Username, AgentID , IsAgent , SUM (Outstanding) Outstanding , SUM (Positiontaking) Positiontaking , SUM(Outstanding_NG) Outstanding_NG , SUM (Positiontaking_NG)Positiontaking_NG 
FROM @AgentOutstanding
GROUP BY  Username, AgentID , IsAgent 
UNION ALL
SELECT Username, AgentID , IsAgent , SUM (Outstanding) Outstanding , SUM (Positiontaking) Positiontaking , SUM(Outstanding_NG) Outstanding_NG , SUM (Positiontaking_NG)Positiontaking_NG 
FROM @MemberOutstanding 
GROUP BY Username, AgentID , IsAgent 
ORDER BY IsAgent DESC, Username ASC





