ALTER PROCEDURE [dbo].[Age_Rpt_Outstanding_Member_Xtest] 
	@AgentId int,	
	@Sporttypes VARCHAR(MAX)= '0',
	@Bettypes VARCHAR(MAX) = '0'
AS

/*
Created: Sophia
Date: 20130329 
Task : Report Outstanding Detail Member
DB:  SVRAGE.RepDB
Original: [Age_Rpt_Outstanding_Ag]
Revisions:

*/
SET NOCOUNT ON
DECLARE @MemberOutstanding TABLE (Username NVARCHAR(50), CustID INT, Outstanding MONEY, Positiontaking MONEY, Outstanding_NG MONEY, Positiontaking_NG MONEY)


CREATE TABLE #BettypeList (bettype SMALLINT)
INSERT INTO #BettypeList
SELECT val FROM dbo.strSplit_Key(@Bettypes,',')

CREATE TABLE #SportsList (Sporttype TINYINT)
INSERT INTO #SportsList (Sporttype)
SELECT val FROM strSplit_key (@Sporttypes, ',')


-----Member Outstanding
-- Sportsbook
	INSERT INTO @MemberOutstanding
	SELECT  C.Username, B.CustID, 
			ISNULL(SUM(CASE when BA.bettype < 31 OR BA.bettype between 121 and 999 OR BA.bettype between 1301 and 1334 then ABS(BA.actual_stake) END),0) Outstanding,  
			ISNULL(SUM(CASE when BA.bettype < 31 OR BA.bettype between 121 and 999 OR BA.bettype between 1301 and 1334 then ABS(BA.actual_stake) * BA.APositiontaking END),0) Positiontaking,
			ISNULL(SUM(CASE when BA.bettype BETWEEN 81 and 120 then ABS(BA.actual_stake) END),0) Outstanding_NG,
			ISNULL(SUM(CASE when BA.bettype BETWEEN 81 and 120 then ABS(BA.actual_stake) * BA.APositiontaking END),0) Positiontaking_NG
	FROM	bettrans B WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK)
		ON	BA.TransID = B.TransID
	INNER JOIN CustInfo C WITH (NOLOCK)
			ON B.CustID = C.CustID AND BA.AgentId = C.AgentId
	INNER JOIN Match M WITH (NOLOCK) 
			ON M.MatchId = B.MatchId
	WHERE	BA.AgentId = @AgentID 
			AND BA.StatusId IN (0,1)	
			AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

			AND B.StatusId IN (0,1)	
			AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))
			AND (@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList))
	GROUP BY C.Username, B.CustID
	ORDER BY C.Username


--Parlay
	INSERT INTO @MemberOutstanding
	SELECT  B.Username, B.CustID, 
			ISNULL(SUM(CASE when B.bettype < 31 OR B.bettype between 121 and 999 OR B.bettype between 1301 and 1334 then ABS(B.actual_stake) END),0) Outstanding,  
			ISNULL(SUM(CASE when B.bettype < 31 OR B.bettype between 121 and 999 OR B.bettype between 1301 and 1334 then ABS(B.actual_stake) * B.APositiontaking END),0) Positiontaking,
			ISNULL(SUM(CASE when B.bettype BETWEEN 81 and 120 then ABS(B.actual_stake) END),0) Outstanding_NG,
			ISNULL(SUM(CASE when B.bettype BETWEEN 81 and 120 then ABS(B.actual_stake) * B.APositiontaking END),0) Positiontaking_NG
	FROM (
			SELECT  DISTINCT C.Username, B.CustID, 
					BA.bettype ,BA.actual_stake, BA.APositiontaking
			FROM	bettrans B WITH (NOLOCK)
			INNER JOIN BetTrans_Agent BA WITH (NOLOCK)
				ON	BA.TransID = B.TransID
			INNER JOIN CustInfo C WITH (NOLOCK)
					ON B.CustID = C.CustID AND BA.AgentId = C.AgentId
			INNER JOIN BettransM BM WITH (NOLOCK)
					ON BM.RefNo = B.RefNo
			INNER JOIN Match M WITH (NOLOCK) 
					ON M.MatchId = BM.MatchId	
			WHERE	BA.AgentId = @AgentID 
					AND BA.StatusId IN (0,1)
					AND BA.Bettype IN (9,29) 	
					AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

					AND B.StatusId IN (0,1)	
					AND B.Bettype IN (9,29) 
					AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))
					AND (@Sporttypes = '0' OR m.sporttype IN (Select sporttype FROM #SportsList))
			
			) B
	GROUP BY B.Username, B.CustID
	ORDER BY B.Username

--- Outright
	INSERT INTO @MemberOutstanding
	SELECT  C.Username, B.CustID, 
			ISNULL(SUM(CASE when BA.bettype < 31 OR BA.bettype between 121 and 999 OR BA.bettype between 1301 and 1334 then ABS(BA.actual_stake) END),0) Outstanding,  
			ISNULL(SUM(CASE when BA.bettype < 31 OR BA.bettype between 121 and 999 OR BA.bettype between 1301 and 1334 then ABS(BA.actual_stake) * BA.APositiontaking END),0) Positiontaking,
			ISNULL(SUM(CASE when BA.bettype BETWEEN 81 and 120 then ABS(BA.actual_stake) END),0) Outstanding_NG,
			ISNULL(SUM(CASE when BA.bettype BETWEEN 81 and 120 then ABS(BA.actual_stake) * BA.APositiontaking END),0) Positiontaking_NG
	FROM	bettrans B WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK)
		ON	BA.TransID = B.TransID
	INNER JOIN CustInfo C WITH (NOLOCK)
			ON B.CustID = C.CustID AND BA.AgentId = C.AgentId
	INNER JOIN Outright M WITH (NOLOCK) 
			ON M.orid = B.MatchId
	INNER JOIN League l WITH (NOLOCK)
			ON l.LeagueId = M.LeagueId	
	WHERE	BA.AgentId = @AgentID 
			AND BA.StatusId IN (0,1)
			AND BA.Bettype = 10 	
			AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

			AND B.StatusId IN (0,1)	
			AND B.Bettype = 10 	
			AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))
			AND (@Sporttypes = '0' OR l.sporttype IN (Select sporttype FROM #SportsList))
	GROUP BY C.Username, B.CustID
	ORDER BY C.Username


SELECT Username, CustID , SUM (Outstanding) Outstanding , SUM (Positiontaking) Positiontaking , SUM(Outstanding_NG) Outstanding_NG , SUM (Positiontaking_NG)Positiontaking_NG 
FROM @MemberOutstanding 
GROUP BY Username, CustID 
ORDER BY Username ASC
 
GO
GRANT EXECUTE ON [dbo].[Age_Rpt_Outstanding_Member] TO [aplweb]
GO
--GRANT VIEW DEFINITION ON [dbo].[Age_Rpt_Outstanding_Member] TO [vnteam]

