ALTER PROCEDURE [dbo].[Age_Rpt_Outstanding_Member] 
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
- 20131003@Sophia: Parlay not to care Sporttype 
- 20140225@Sophia: Check condition of Parlay

*/
SET NOCOUNT ON
DECLARE @MemberOutstanding TABLE (Username NVARCHAR(50), CustID INT, Outstanding MONEY, Positiontaking MONEY)

CREATE TABLE #BettypeList (bettype SMALLINT)
INSERT INTO #BettypeList
SELECT val FROM dbo.strSplit_Key(@Bettypes,',')

CREATE TABLE #SportsList (Sporttype TINYINT)
INSERT INTO #SportsList (Sporttype)
SELECT val FROM strSplit_key (@Sporttypes, ',')

-----Member Outstanding
-- Sportsbook
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10)) OR @Bettypes = '0'
	INSERT INTO @MemberOutstanding
	SELECT  C.Username, B.CustID, 
			ISNULL(SUM(ABS(BA.actual_stake)),0) Outstanding,  
			ISNULL(SUM(ABS(BA.actual_stake) * BA.APositiontaking),0) Positiontaking
	FROM	bettrans B WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK)
		ON	BA.TransID = B.TransID AND BA.AgentId = @AgentID  
	INNER JOIN CustInfo C WITH (NOLOCK)
			ON B.CustID = C.CustID AND BA.AgentId = C.AgentId
	WHERE	BA.StatusId IN (0,1)	
			AND BA.matchID > 0
			AND BA.Bettype NOT IN (9,29,10) 
			AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

			AND B.StatusId IN (0,1)	
			AND B.matchID > 0
			AND B.Bettype NOT IN (9,29,10) 
			AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))
						
			AND (@Sporttypes = '0' 
					OR EXISTS (SELECT 1 FROM match (NOLOCK) 
								WHERE matchid = B.matchid AND sporttype IN (SELECT sporttype FROM #SportsList)
								)
					)
	GROUP BY C.Username, B.CustID
	ORDER BY C.Username


--Parlay
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29)) OR (@Bettypes = '0' AND @Sporttypes = '0')
	INSERT INTO @MemberOutstanding
	SELECT  C.Username, B.CustID, 
			ISNULL(SUM(ABS(BA.actual_stake)),0) Outstanding,  
			ISNULL(SUM(ABS(BA.actual_stake) * BA.APositiontaking),0) Positiontaking
	FROM	bettrans B WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK)
		ON	BA.TransID = B.TransID AND BA.AgentId = @AgentID  
	INNER JOIN CustInfo C WITH (NOLOCK)
			ON B.CustID = C.CustID AND BA.AgentId = C.AgentId
			WHERE	BA.StatusId IN (0,1)
					AND BA.matchID IN (9,29)
					AND BA.Bettype IN (9,29) 	
					AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))

					AND B.StatusId IN (0,1)	
					AND B.matchID IN (9,29)
					AND B.Bettype IN (9,29) 
					AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))				 
	GROUP BY C.Username, B.CustID
	ORDER BY C.Username

--- Outright
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype = 10) OR @Bettypes = '0'
	INSERT INTO @MemberOutstanding
	SELECT  C.Username, B.CustID, 
			ISNULL(SUM(ABS(BA.actual_stake) ),0) Outstanding,  
			ISNULL(SUM(ABS(BA.actual_stake) * BA.APositiontaking ),0) Positiontaking			
	FROM	bettrans B WITH (NOLOCK)
	INNER JOIN BetTrans_Agent BA WITH (NOLOCK)
		ON	BA.TransID = B.TransID AND BA.AgentId = @AgentID 
	INNER JOIN CustInfo C WITH (NOLOCK)
			ON B.CustID = C.CustID AND BA.AgentId = C.AgentId
	WHERE	BA.StatusId IN (0,1)
			AND BA.matchID  > 0
			AND BA.Bettype = 10 	

			AND B.StatusId IN (0,1)	
			AND B.matchID  > 0
			AND B.Bettype = 10 	
			AND (@Sporttypes = '0' 
				 OR EXISTS (SELECT	1 
							FROM	Outright M WITH (NOLOCK) 
							INNER JOIN League L WITH (NOLOCK) 
									ON L.leagueid = M.leagueid		
									AND (L.sporttype IN (Select sporttype FROM #SportsList))				
							WHERE	M.orid = B.MatchId
							)	
					)
	GROUP BY C.Username, B.CustID
	ORDER BY C.Username


SELECT Username, CustID , SUM (Outstanding) Outstanding , SUM (Positiontaking) Positiontaking 
FROM @MemberOutstanding 
GROUP BY Username, CustID 
ORDER BY Username ASC
 
GO
GRANT EXECUTE ON [dbo].[Age_Rpt_Outstanding_Member] TO [aplweb]
GO 