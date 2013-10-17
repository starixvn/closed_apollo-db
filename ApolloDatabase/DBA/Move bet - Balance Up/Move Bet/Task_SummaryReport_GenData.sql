--Task_SummaryReport_GenData '2013/06/01'
ALTER PROCEDURE Task_SummaryReport_GenData
   @WinlostDate date
WITH RECOMPILE
AS 
/*
Created by: Dan
Date: 20131003
Task:	generate sata for summary winlost report
DB: SVRTXN/TransDB
Revisions:		

 */


CREATE TABLE #Tmp(
	Username nvarchar(50), AgentID int, ParentID int,  		
	BetAmount money, BetCount int, CommBase money,	Winlost money, PlayerComm money, 				
	UplineWinlost money, UplineComm money, AWinlost money, AComm money, 
	BetType smallint, sporttype	tinyint
)


-- =====================
--Agent from shareholder (agentlevel > 1)
-- =====================

--Sportbook
	INSERT INTO #Tmp(Username, AgentID, ParentID ,  		
			BetAmount , BetCount , CommBase ,	Winlost , PlayerComm , 				
			UplineWinlost , UplineComm , AWinlost , AComm , 
			BetType , sporttype)
	SELECT  C.Username, C.AgentID,   --- k+1
			C.ParentID, --- k
			SUM(ABS(B.Stake)) AS BetAmount,
			COUNT(B.TransID) as BetCount,
			SUM(CASE WHEN B.StatusID IN (112,113) AND (ABS(B.MOdds) <> 0.25 OR B.Bettype IN (9,29,10)) THEN ABS(B.Stake) 
						ELSE CASE WHEN B.StatusID IN (112,113) AND ABS(B.MOdds) =0.25 AND B.Bettype NOT IN (9,29,10) THEN  ABS(B.Stake)*0.5 ELSE 0 END END)  AS CommBase,				
			SUM(B.Winlost - B.Actual_Stake) AS Winlost,	
			SUM(B.PlayerComm) as PlayerComm, 				
			SUM(BP.AWinlost) AS UplineWinlost,	---- k winlost
			SUM(BP.AComm) AS UplineComm,  ---- k Comm  
			SUM(BA.AWinlost)  as AWinlost, ----k+1 Winlost
			SUM(BA.AComm) as AComm  , ---- k+1 Comm					
			b.BetType,	m.sporttype				
	FROM	Bettrans14 B  WITH (NOLOCK,INDEX (IX_bettrans14)) 
	INNER JOIN Bettrans14_Agent BP WITH (NOLOCK,INDEX (IX_bettrans14_Agent)) 
			ON BP.TransID = B.TransID ----Parent (k)
	INNER JOIN AgentInfo C WITH (NOLOCK) --- Child direct (k+1)
			ON C.ParentID =  BP.AgentID		
	INNER JOIN Bettrans14_Agent BA WITH (NOLOCK, INDEX (IX_bettrans14_Agent)) 
			ON C.AgentID = BA.AgentID AND BA.TransID = B.TransID ---- Child direct (k+1) 
	JOIN match (nolock) m on m.matchid=b.matchid
	WHERE	BA.bettype <=19000
			AND BA.StatusID NOT IN (0,1)	
			AND BA.Winlostdate = @WinlostDate	
			AND BA.MatchId > 0				
			AND BP.bettype <=19000
			AND BP.StatusID NOT IN (0,1) 
			AND BP.Winlostdate = @WinlostDate 
			AND BP.MatchId > 0
			AND B.bettype <=19000
			AND B.StatusID NOT IN (0,1)	
			AND B.Winlostdate = @WinlostDate	
			AND B.MatchId > 0
	GROUP BY C.Username, C.AgentID, C.ParentId, b.BetType, m.sporttype --	,b.Transid
		

	INSERT INTO dbo.Sum_Winloss_Agent_Tmp
				(WinLostDate, AgentId, AgentUsername, ParentID, BetAmount, BetCount, CommBase,Winlost, PlayerComm,
				AWinLost, AComm, UplineWinlost, UplineComm,GrossTotal,DownlineEffStake, UplineEffStake, SportType, BetType)	
	SELECT  WinlostDate, 
			AgentID, Username, ParentID, BetAmount, BetCount, 
			CommBase, Winlost, PlayerComm,  
			AWinlost, AComm,  
			UplineWinlost, UplineComm,	
			SUM(GrossTotal) GrossTotal,  --- money k+1 gives to k							
			SUM(DownlineEffStake) DownlineEffStake, 				
			SUM(UplineEffStake) UplineEffStake,				
			SportType, BetType
	FROM (
		SELECT @WinlostDate WinlostDate, 
				T.AgentID, T.Username, T.ParentID, T.BetAmount, T.BetCount, T.CommBase,
				T.Winlost, T.PlayerComm,  
				T.AWinlost, T.AComm,  
				T.UplineWinlost, T.UplineComm,						
					
				(1 - SUM (BA.APositionTaking)) * MAX(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END) -- CommBase
				as DownlineEffStake,		

				SUM(BA.AWinlost) + MAX(B.Winlost - B.Actual_Stake) + MAX(BP.AComm)  AS GrossTotal,  --- money k+1 gives to k							
				((1 - SUM (BA.APositionTaking)) - MAX(BP1.APositionTaking)) * MAX(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  -- COMMBASE
				as UplineEffStake,	
								
				T.SportType, T.BetType
				, BA.TransID				
		FROM AgentInfo P WITH (NOLOCK)  
		INNER JOIN #Tmp T ON T.AgentID = P.AgentID
		INNER JOIN AgentInfo C WITH(NOLOCK) 
				ON C.AgentHId.IsDescendantOf(P.AgentHId ) =1  AND C.AgentLevel >= P.AgentLevel  --- Children of k+1 (k+1 -> k+...)
		INNER JOIN Bettrans14_Agent BA WITH (NOLOCK, index (IX_bettrans14_Agent)) --child agent 
				ON BA.AgentID = C.AgentID	AND BA.BetType=t.BetType	
		JOIN Bettrans14 B  WITH (NOLOCK)  ON b.TransId=ba.TransId --main ticket
		JOIN Bettrans14_Agent BP WITH (NOLOCK, index (IX_bettrans14_Agent)) --current agent k
				ON BP.AgentID = T.AgentID and BA.TransId=BP.TransId
		JOIN Bettrans14_Agent BP1 WITH (NOLOCK, index (IX_bettrans14_Agent)) --Parent agent of agent k
				ON BP1.AgentID = T.ParentId and BA.TransId=BP1.TransId
		JOIN match (nolock) m on m.matchid=ba.matchid AND m.sporttype=T.sporttype 

		WHERE	BA.StatusID NOT IN (0,1) 					
				AND BA.Winlostdate = @WinlostDate	
				AND BP.StatusID NOT IN (0,1) 
				AND BP.MatchId > 0
				AND BP.Winlostdate =  @WinlostDate						
				AND BP1.StatusID NOT IN (0,1) 
				AND BP1.MatchId > 0
				AND BP1.Winlostdate =  @WinlostDate						
		GROUP BY T.AgentID, T.Username, T.ParentID, T.BetAmount, T.BetCount, T.CommBase,
				T.Winlost, T.PlayerComm,  
				T.AWinlost, T.AComm,  
				T.UplineWinlost, T.UplineComm,
				T.SportType, T.BetType, BA.TransID
		)	A
	GROUP BY
			WinlostDate, 
			AgentID, Username, ParentID, 
			BetAmount, BetCount, CommBase,
			Winlost, PlayerComm,  
			AWinlost, AComm,  
			UplineWinlost, UplineComm,				
			SportType, BetType
					
	DELETE #Tmp

--Parlay
	INSERT INTO #Tmp(Username, AgentID, ParentID ,  		
			BetAmount , BetCount , CommBase ,	Winlost , PlayerComm , 				
			UplineWinlost , UplineComm , AWinlost , AComm , 
			BetType , sporttype)
	SELECT  C.Username, C.AgentID,   --- k+1
			C.ParentID, --- k
		   	SUM(ABS(B.Stake)) AS BetAmount,
			COUNT(B.TransID) as BetCount,
			SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END)  AS CommBase,				
			SUM(B.Winlost - B.Actual_Stake) AS Winlost,	
			SUM(B.PlayerComm) as PlayerComm, 				
			SUM(BP.AWinlost) AS UplineWinlost,	---- k winlost
			SUM(BP.AComm) AS UplineComm,  ---- k Comm  
			SUM(BA.AWinlost)  as AWinlost, ----k+1 Winlost
			SUM(BA.AComm) as AComm  , ---- k+1 Comm					
			b.BetType,	0 as sporttype						
	FROM	Bettrans14 B  WITH (NOLOCK,INDEX (IX_bettrans14)) 
	INNER JOIN Bettrans14_Agent BP WITH (NOLOCK,INDEX (IX_bettrans14_Agent)) 
			ON BP.TransID = B.TransID ----Parent (k)
	INNER JOIN AgentInfo C WITH (NOLOCK) --- Child direct (k+1)
			ON C.ParentID =  BP.AgentID		
	INNER JOIN Bettrans14_Agent BA WITH (NOLOCK, INDEX (IX_bettrans14_Agent)) 
			ON C.AgentID = BA.AgentID AND BA.TransID = B.TransID ---- Child direct (k+1) 
		
	WHERE	BA.bettype IN (9,29)
			AND BA.StatusID NOT IN (0,1)	
			AND BA.Winlostdate = @WinlostDate	
			AND BA.MatchId IN (9,29)
			AND BP.bettype IN (9,29)
			AND BP.StatusID NOT IN (0,1) 
			AND BP.Winlostdate = @WinlostDate 
			AND BP.MatchId IN (9,29)
			AND B.bettype IN (9,29)
			AND B.StatusID NOT IN (0,1)	
			AND B.Winlostdate = @WinlostDate	
			AND B.MatchId IN (9,29)
	GROUP BY C.Username, C.AgentID, C.ParentId, b.BetType
		

	INSERT INTO dbo.Sum_Winloss_Agent_Tmp
				(WinLostDate, AgentId, AgentUsername, ParentID, BetAmount, BetCount, CommBase,Winlost, PlayerComm,
				AWinLost, AComm, UplineWinlost, UplineComm,GrossTotal,DownlineEffStake, UplineEffStake, SportType, BetType)	
	SELECT  WinlostDate, 
			AgentID, Username, ParentID, BetAmount, BetCount, 
			CommBase, Winlost, PlayerComm,  
			AWinlost, AComm,  
			UplineWinlost, UplineComm,	
			SUM(GrossTotal) GrossTotal,  --- money k+1 gives to k							
			SUM(DownlineEffStake) DownlineEffStake, 				
			SUM(UplineEffStake) UplineEffStake,				
			SportType, BetType
	FROM (
		SELECT @WinlostDate WinlostDate, 
				T.AgentID, T.Username, T.ParentID, T.BetAmount, T.BetCount, T.CommBase,
				T.Winlost, T.PlayerComm,  
				T.AWinlost, T.AComm,  
				T.UplineWinlost, T.UplineComm,											
				(1 - SUM (BA.APositionTaking)) * MAX(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END) -- CommBase
				as DownlineEffStake,		

				SUM(BA.AWinlost) + MAX(B.Winlost - B.Actual_Stake) + MAX(BP.AComm)  AS GrossTotal,  --- money k+1 gives to k							
				((1 - SUM (BA.APositionTaking)) - MAX(BP1.APositionTaking)) * MAX(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END)  -- COMMBASE
				as UplineEffStake,	
								
				T.SportType, T.BetType
				, BA.TransID				
		FROM AgentInfo P WITH (NOLOCK)  
		INNER JOIN #Tmp T ON T.AgentID = P.AgentID
		INNER JOIN AgentInfo C WITH(NOLOCK) 
				ON C.AgentHId.IsDescendantOf(P.AgentHId ) =1  AND C.AgentLevel >= P.AgentLevel  --- Children of k+1 (k+1 -> k+...)
		INNER JOIN Bettrans14_Agent BA WITH (NOLOCK, index (IX_bettrans14_Agent)) --child agent 
				ON BA.AgentID = C.AgentID	AND BA.BetType=t.BetType	
		JOIN Bettrans14 B  WITH (NOLOCK)  ON b.TransId=ba.TransId --main ticket
		JOIN Bettrans14_Agent BP WITH (NOLOCK, index (IX_bettrans14_Agent)) --current agent k
				ON BP.AgentID = T.AgentID and BA.TransId=BP.TransId
		JOIN Bettrans14_Agent BP1 WITH (NOLOCK, index (IX_bettrans14_Agent)) --Parent agent of agent k
				ON BP1.AgentID = T.ParentId and BA.TransId=BP1.TransId			

		WHERE	BA.StatusID NOT IN (0,1) 					
				AND BA.Winlostdate = @WinlostDate	
				AND BA.bettype IN (9,29)
				AND BA.MatchId IN (9,29)

				AND BP.StatusID NOT IN (0,1) 
				AND BP.bettype IN (9,29)
				AND BP.MatchId IN (9,29)
				AND BP.Winlostdate =  @WinlostDate						

				AND BP1.StatusID NOT IN (0,1) 
				AND BP1.MatchId IN (9,29)
				AND BP1.bettype IN (9,29)
				AND BP1.Winlostdate =  @WinlostDate	
										
				AND B.StatusID NOT IN (0,1) 
				AND B.bettype IN (9,29)
				AND B.MatchId IN (9,29)					
		GROUP BY T.AgentID, T.Username, T.ParentID, T.BetAmount, T.BetCount, T.CommBase,
				T.Winlost, T.PlayerComm,  
				T.AWinlost, T.AComm,  
				T.UplineWinlost, T.UplineComm,
				T.SportType, T.BetType, BA.TransID
		)	A
	GROUP BY
			WinlostDate, 
			AgentID, Username, ParentID, 
			BetAmount, BetCount, CommBase,
			Winlost, PlayerComm,  
			AWinlost, AComm,  
			UplineWinlost, UplineComm,				
			SportType, BetType
		
	DELETE	#Tmp


--Outright
	INSERT INTO #Tmp(Username, AgentID, ParentID ,  		
				BetAmount , BetCount , CommBase ,	Winlost , PlayerComm , 				
				UplineWinlost , UplineComm , AWinlost , AComm , 
				BetType , sporttype)
	SELECT  C.Username, C.AgentID,   --- k+1
			C.ParentID, --- k
		   	SUM(ABS(B.Stake)) AS BetAmount,
			COUNT(B.TransID) as BetCount,
			SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END)  AS CommBase,
			SUM(B.Winlost - B.Actual_Stake) AS Winlost,	
			SUM(B.PlayerComm) as PlayerComm, 				
			SUM(BP.AWinlost) AS UplineWinlost,	---- k winlost
			SUM(BP.AComm) AS UplineComm,  ---- k Comm  
			SUM(BA.AWinlost)  as AWinlost, ----k+1 Winlost
			SUM(BA.AComm) as AComm  , ---- k+1 Comm					
			b.BetType,	l.sporttype		
	FROM	Bettrans14 B  WITH (NOLOCK,INDEX (IX_bettrans14)) 
	INNER JOIN Bettrans14_Agent BP WITH (NOLOCK,INDEX (IX_bettrans14_Agent)) 
			ON BP.TransID = B.TransID ----Parent (k)
	INNER JOIN AgentInfo C WITH (NOLOCK) --- Child direct (k+1)
			ON C.ParentID =  BP.AgentID		
	INNER JOIN Bettrans14_Agent BA WITH (NOLOCK, INDEX (IX_bettrans14_Agent)) 
			ON C.AgentID = BA.AgentID AND BA.TransID = B.TransID ---- Child direct (k+1) 
	INNER JOIN Outright (nolock) o on o.orid=b.matchid
	INNER JOIN  League l WITH (NOLOCK)	ON	l.leagueID = o.leagueId		
	WHERE	BA.bettype = 10
			AND BA.StatusID NOT IN (0,1)	
			AND BA.Winlostdate = @WinlostDate	
			AND BA.MatchId > 0				
			AND BP.bettype = 10
			AND BP.StatusID NOT IN (0,1) 
			AND BP.Winlostdate = @WinlostDate 
			AND BP.MatchId > 0
			AND B.bettype = 10
			AND B.StatusID NOT IN (0,1)	
			AND B.Winlostdate = @WinlostDate	
			AND B.MatchId > 0
	GROUP BY C.Username, C.AgentID, C.ParentId, b.BetType, l.sporttype 
		

	INSERT INTO dbo.Sum_Winloss_Agent_Tmp
				(WinLostDate, AgentId, AgentUsername, ParentID, BetAmount, BetCount, CommBase,Winlost, PlayerComm,
				AWinLost, AComm, UplineWinlost, UplineComm,GrossTotal,DownlineEffStake, UplineEffStake, SportType, BetType)	
	SELECT  WinlostDate, 
			AgentID, Username, ParentID, BetAmount, BetCount, 
			CommBase, Winlost, PlayerComm,  
			AWinlost, AComm,  
			UplineWinlost, UplineComm,	
			SUM(GrossTotal) GrossTotal,  --- money k+1 gives to k							
			SUM(DownlineEffStake) DownlineEffStake, 				
			SUM(UplineEffStake) UplineEffStake,				
			SportType, BetType
	FROM (
		SELECT @WinlostDate WinlostDate, 
				T.AgentID, T.Username, T.ParentID, T.BetAmount, T.BetCount, T.CommBase,
				T.Winlost, T.PlayerComm,  
				T.AWinlost, T.AComm,  
				T.UplineWinlost, T.UplineComm,																
				(1 - SUM (BA.APositionTaking)) * MAX(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END) -- CommBase
				as DownlineEffStake,		

				SUM(BA.AWinlost) + MAX(B.Winlost - B.Actual_Stake) + MAX(BP.AComm)  AS GrossTotal,  --- money k+1 gives to k							
				((1 - SUM (BA.APositionTaking)) - MAX(BP1.APositionTaking)) * MAX(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END)  -- COMMBASE
				as UplineEffStake,	
								
				T.SportType, T.BetType
				, BA.TransID				
		FROM AgentInfo P WITH (NOLOCK)  
		INNER JOIN #Tmp T ON T.AgentID = P.AgentID
		INNER JOIN AgentInfo C WITH(NOLOCK) 
				ON C.AgentHId.IsDescendantOf(P.AgentHId ) =1  AND C.AgentLevel >= P.AgentLevel  --- Children of k+1 (k+1 -> k+...)
		INNER JOIN Bettrans14_Agent BA WITH (NOLOCK, index (IX_bettrans14_Agent)) --child agent 
				ON BA.AgentID = C.AgentID	AND BA.BetType=t.BetType	
		JOIN Bettrans14 B  WITH (NOLOCK)  ON b.TransId=ba.TransId --main ticket
		JOIN Bettrans14_Agent BP WITH (NOLOCK, index (IX_bettrans14_Agent)) --current agent k
				ON BP.AgentID = T.AgentID and BA.TransId=BP.TransId
		JOIN Bettrans14_Agent BP1 WITH (NOLOCK, index (IX_bettrans14_Agent)) --Parent agent of agent k
				ON BP1.AgentID = T.ParentId and BA.TransId=BP1.TransId
		INNER JOIN Outright (nolock) o on o.orid=b.matchid
		INNER JOIN  League l WITH (NOLOCK)	ON	l.leagueID = o.leagueId		and l.sporttype=T.sporttype

		WHERE	BA.StatusID NOT IN (0,1) 					
				AND BA.Winlostdate = @WinlostDate	
				AND BP.StatusID NOT IN (0,1) 
				AND BA.bettype=10

				AND BP.MatchId > 0
				AND BP.Winlostdate =  @WinlostDate						
				AND BP.bettype=10
				AND BP.Winlostdate =  @WinlostDate						

				AND BP1.StatusID NOT IN (0,1) 
				AND BP1.MatchId > 0
				AND BP1.bettype=10
				AND BP1.Winlostdate =  @WinlostDate						
					
				AND B.bettype=10
		GROUP BY T.AgentID, T.Username, T.ParentID, T.BetAmount, T.BetCount, T.CommBase,
				T.Winlost, T.PlayerComm,  
				T.AWinlost, T.AComm,  
				T.UplineWinlost, T.UplineComm,
				T.SportType, T.BetType, BA.TransID
		)	A
	GROUP BY
			WinlostDate, 
			AgentID, Username, ParentID, 
			BetAmount, BetCount, CommBase,
			Winlost, PlayerComm,  
			AWinlost, AComm,  
			UplineWinlost, UplineComm,				
			SportType, BetType
		
	DROP TABLE #Tmp

-- ==========================================================
-- INSERT MAINSHARE HOLDER (LEVEL=1) AND VALUE FROM SUPPER
--==========================================================

--Sportbook
		INSERT INTO dbo.Sum_Winloss_Agent_Tmp
					(WinLostDate, AgentId, AgentUsername, ParentID, BetAmount, BetCount, CommBase,Winlost, PlayerComm,
					AWinLost, AComm, UplineWinlost, UplineComm,GrossTotal,DownlineEffStake, UplineEffStake, SportType, BetType)	
		SELECT  @WinlostDate WinlostDate,
				C.AgentID, C.Username, C.ParentID,
		   		SUM(ABS(B.Stake)) AS BetAmount,		
				COUNT(B.TransID) as BetCount,		
				SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  AS CommBase,
				SUM (B.WinLost - B.Actual_Stake) as Winlost,
				SUM (B.PlayerComm) as PlayerComm,
				SUM(BA.AWinlost)  as AWinlost, ----Main SH Winlost
				SUM(BA.AComm) as AComm  , ---- Main SH Comm		
				- SUM(B.Winlost - B.Actual_Stake + B.TWinlost) AS UplineWinlost,	 ---super Winlost
				0 AS UplineComm,			---super comm				
				(SUM(B.Winlost - B.Actual_Stake + B.TWinlost) + SUM (B.TComm)) AS GrossTotal,
				SUM(CASE WHEN ABS(B.MOdds) <> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) =0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END * (1-B.TPositionTaking))  AS DownlineEffStake , 				
				0 AS UplineEffStake ,
				m.sporttype, b.BetType						
		FROM		AgentInfo C WITH (NOLOCK)
		INNER JOIN	BetTrans14_Agent BA WITH (NOLOCK, INDEX(IX_bettrans14_Agent)) 
				ON	BA.AgentID = C.AgentID		
		INNER JOIN	Bettrans14 B WITH (NOLOCK) 	
				ON	B.TransID = BA.TransID			
		JOIN match (nolock) m on m.matchid=b.matchid
		WHERE		C.ParentId = 1 --super id
					AND B.StatusID NOT IN (0,1)
					AND B.Winlostdate = @WinlostDate	
					AND B.Bettype <=19000			   
					AND BA.Winlostdate = @WinlostDate	  
					AND BA.StatusID NOT IN (0,1)
					AND BA.Bettype <=19000			   
		GROUP BY	C.Username, C.AgentID, C.ParentID,	m.sporttype	, b.BetType
		

--Parlay
		INSERT INTO dbo.Sum_Winloss_Agent_Tmp
					(WinLostDate, AgentId, AgentUsername, ParentID, BetAmount, BetCount, CommBase,Winlost, PlayerComm,
					AWinLost, AComm, UplineWinlost, UplineComm,GrossTotal,DownlineEffStake, UplineEffStake, SportType, BetType)	
		SELECT  @WinlostDate WinlostDate,
				C.AgentID, C.Username, C.ParentID,
		   		SUM(ABS(B.Stake)) AS BetAmount,		
				COUNT(B.TransID) as BetCount,						
				SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END)  AS CommBase,			
				SUM (B.WinLost - B.Actual_Stake) as Winlost,
				SUM (B.PlayerComm) as PlayerComm,
				SUM(BA.AWinlost)  as AWinlost, ----Main SH Winlost
				SUM(BA.AComm) as AComm  , ---- Main SH Comm		
				- SUM(B.Winlost - B.Actual_Stake + B.TWinlost) AS UplineWinlost,	 ---super Winlost
				0 AS UplineComm,			---super comm				
				(SUM(B.Winlost - B.Actual_Stake + B.TWinlost) + SUM (B.TComm)) AS GrossTotal,				
				SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END * (1-B.TPositionTaking))  AS DownlineEffStake , 
				0 AS UplineEffStake ,
				0 as sporttype, b.BetType	
		FROM		AgentInfo C WITH (NOLOCK)
		INNER JOIN	BetTrans14_Agent BA WITH (NOLOCK, INDEX(IX_bettrans14_Agent)) 
				ON	BA.AgentID = C.AgentID		
		INNER JOIN	Bettrans14 B WITH (NOLOCK) 	
				ON	B.TransID = BA.TransID					
		WHERE		C.ParentId = 1 --super id
					AND B.StatusID NOT IN (0,1)
					AND B.Winlostdate = @WinlostDate						
					AND B.Bettype IN (9,29)
					AND BA.Winlostdate = @WinlostDate	  
					AND BA.StatusID NOT IN (0,1)					
					AND BA.Bettype IN (9,29)
		GROUP BY	C.Username, C.AgentID, C.ParentID, b.BetType

--Outright
		INSERT INTO dbo.Sum_Winloss_Agent_Tmp
					(WinLostDate, AgentId, AgentUsername, ParentID, BetAmount, BetCount, CommBase,Winlost, PlayerComm,
					AWinLost, AComm, UplineWinlost, UplineComm,GrossTotal,DownlineEffStake, UplineEffStake, SportType, BetType)	
		SELECT  @WinlostDate WinlostDate,
				C.AgentID, C.Username, C.ParentID,
		   		SUM(ABS(B.Stake)) AS BetAmount,		
				COUNT(B.TransID) as BetCount,						
				SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END)  AS CommBase,
				SUM (B.WinLost - B.Actual_Stake) as Winlost,
				SUM (B.PlayerComm) as PlayerComm,
				SUM(BA.AWinlost)  as AWinlost, ----Main SH Winlost
				SUM(BA.AComm) as AComm  , ---- Main SH Comm		
				- SUM(B.Winlost - B.Actual_Stake + B.TWinlost) AS UplineWinlost,	 ---super Winlost
				0 AS UplineComm,			---super comm				
				(SUM(B.Winlost - B.Actual_Stake + B.TWinlost) + SUM (B.TComm)) AS GrossTotal,				
				SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END * (1-B.TPositionTaking))  AS DownlineEffStake , 
				0 AS UplineEffStake ,
				l.sporttype, b.BetType						
		FROM		AgentInfo C WITH (NOLOCK)
		INNER JOIN	BetTrans14_Agent BA WITH (NOLOCK, INDEX(IX_bettrans14_Agent)) 		
				ON	BA.AgentID = C.AgentID		
		INNER JOIN	Bettrans14 B WITH (NOLOCK) 	
				ON	B.TransID = BA.TransID			
		INNER JOIN Outright (nolock) o on o.orid=b.matchid
		INNER JOIN  League l WITH (NOLOCK)	ON	l.leagueID = o.leagueId		
		WHERE		C.ParentId = 1 --super id
					AND B.StatusID NOT IN (0,1)
					AND B.Winlostdate = @WinlostDate	
					AND B.bettype = 10	   
					AND BA.Winlostdate = @WinlostDate	  
					AND BA.StatusID NOT IN (0,1)							   
					AND BA.bettype = 10	   
		GROUP BY	C.Username, C.AgentID, C.ParentID,	l.sporttype	, b.BetType

-- ===================================================		
---	Member
-- ===================================================

--Sportbook
		INSERT INTO Sum_Winloss_Cust_Tmp
				(WinLostDate, CustId, Username, AgentId, BetAmount, BetCount, CommBase, 
				WinLost, PlayerComm, UplineWinLost, UplineComm, UplineEffStake, SportType, BetType)
		SELECT  @WinlostDate, C.CustID, C.Username, C.AgentID, 						
		   		SUM(ABS(B.Stake)) AS BetAmount,
				COUNT(B.TransID) as BetCount, 	
				SUM(CASE WHEN ABS(B.MOdds)<> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) = 0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END)  as CommBase,
				SUM(B.WinLost - B.Actual_Stake) AS WinLost,				
				SUM(B.PlayerComm) AS PlayerComm,				
				SUM(BA.AWinLost) AS UplineWinlost,	
				SUM(BA.AComm)  AS UplineComm,
				SUM(CASE WHEN ABS(B.MOdds)<> 0.25 AND B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE CASE WHEN ABS(B.MOdds) = 0.25 AND B.StatusID IN (112,113) THEN  ABS(B.Stake)*0.5  ELSE 0 END END * (1-BA.APositionTaking))   as UplineEffStake,			
				m.sporttype, b.BetType
		FROM		Bettrans14 B WITH (NOLOCK)
		INNER JOIN	BetTrans14_Agent BA WITH (NOLOCK, INDEX(IX_bettrans14_Agent))
				ON	BA.TransID = B.TransID
		INNER JOIN	CustInfo C WITH (NOLOCK)
				ON	B.CustID = C.CustID AND  C.AgentId = BA.AgentId		
		JOIN match (nolock) m on m.matchid=b.matchid
		WHERE		BA.WinlostDate = @WinlostDate
				AND BA.bettype <= 19000	
				AND BA.StatusID NOT IN (0,1)
				AND BA.WinlostDate = B.WinlostDate
				AND BA.bettype = B.bettype
				AND BA.StatusID = B.StatusID					
		GROUP BY C.Username, C.CustID, C.AgentId, sporttype, b.BetType

--Parlay
		INSERT INTO Sum_Winloss_Cust_Tmp
				(WinLostDate, CustId, Username, AgentId, BetAmount, BetCount, CommBase, 
				WinLost, PlayerComm, UplineWinLost, UplineComm, UplineEffStake, SportType, BetType)
		SELECT  @WinlostDate, C.CustID, C.Username, C.AgentID, 						
		   		SUM(ABS(B.Stake)) AS BetAmount,
				COUNT(B.TransID) as BetCount, 					
				SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END)  as CommBase,
				SUM(B.WinLost - B.Actual_Stake) AS WinLost,				
				SUM(B.PlayerComm) AS PlayerComm,				
				SUM(BA.AWinLost) AS UplineWinlost,	
				SUM(BA.AComm)  AS UplineComm,				
				SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END * (1-BA.APositionTaking))  as UplineEffStake,
				0 AS sporttype, b.BetType
		FROM		Bettrans14 B WITH (NOLOCK)
		INNER JOIN	BetTrans14_Agent BA WITH (NOLOCK, INDEX(IX_bettrans14_Agent))
				ON	BA.TransID = B.TransID
		INNER JOIN	CustInfo C WITH (NOLOCK)
				ON	B.CustID = C.CustID AND  C.AgentId = BA.AgentId				
		WHERE		BA.WinlostDate = @WinlostDate				
				AND BA.bettype IN (9,29)
				AND BA.MatchId IN (9,29)
				AND BA.StatusID NOT IN (0,1)
				AND B.WinlostDate = @WinlostDate				
				AND B.bettype IN (9,29)
				AND B.MatchId IN (9,29)
				AND B.StatusID NOT IN (0,1)
		GROUP BY C.Username, C.CustID, C.AgentId, b.BetType

--Outright

		INSERT INTO Sum_Winloss_Cust_Tmp
				(WinLostDate, CustId, Username, AgentId, BetAmount, BetCount, CommBase, 
				WinLost, PlayerComm, UplineWinLost, UplineComm, UplineEffStake, SportType, BetType)
		SELECT  @WinlostDate, C.CustID, C.Username, C.AgentID, 						
		   		SUM(ABS(B.Stake)) AS BetAmount,
				COUNT(B.TransID) as BetCount, 					
				SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END)  as CommBase,
				SUM(B.WinLost - B.Actual_Stake) AS WinLost,				
				SUM(B.PlayerComm) AS PlayerComm,				
				SUM(BA.AWinLost) AS UplineWinlost,	
				SUM(BA.AComm)  AS UplineComm,				
				SUM(CASE WHEN B.StatusID IN (112,113) THEN ABS(B.Stake) ELSE 0 END * (1-BA.APositionTaking))  as UplineEffStake,
				sporttype, b.BetType
		FROM		Bettrans14 B WITH (NOLOCK)
		INNER JOIN	BetTrans14_Agent BA WITH (NOLOCK, INDEX(IX_bettrans14_Agent))
				ON	BA.TransID = B.TransID
		INNER JOIN	CustInfo C WITH (NOLOCK)
				ON	B.CustID = C.CustID AND  C.AgentId = BA.AgentId		
		INNER JOIN Outright (nolock) o on o.orid=b.matchid
		INNER JOIN  League l WITH (NOLOCK)	ON	l.leagueID = o.leagueId		
		WHERE		BA.WinlostDate = @WinlostDate				
				AND BA.bettype =10
				AND BA.MatchId > 0	
				AND BA.StatusID NOT IN (0,1)
				AND B.WinlostDate = @WinlostDate	
				AND B.bettype =10
				AND B.MatchId > 0	
				AND B.StatusID NOT IN (0,1)
		GROUP BY C.Username, C.CustID, C.AgentId, sporttype, b.BetType

-- =====================

Declare @loop varchar(1)

SET NOCOUNT ON
SET @loop = 'y'
WHILE @loop = 'y'
BEGIN
		BEGIN TRANSACTION
			DELETE TOP(280) FROM dbo.Sum_WinLoss_Agent
			WHERE winlostdate = @winlostdate

			IF @@ROWCOUNT = 0 SET @loop = 'n'
		COMMIT TRANSACTION


	WAITFOR DELAY '000:00:01.4'
END

SET @loop = 'y'
WHILE @loop = 'y'
BEGIN
		BEGIN TRANSACTION
			DELETE TOP(600) FROM dbo.Sum_Winloss_Agent_Tmp
			WHERE winlostdate = @winlostdate
	
			IF @@ROWCOUNT = 0 SET @loop = 'n'
		COMMIT TRANSACTION

	WAITFOR DELAY '000:00:01.4'
END


SET @loop = 'y'
WHILE @loop = 'y'
BEGIN
		BEGIN TRANSACTION
			DELETE TOP(600) FROM dbo.Sum_Winloss_Cust
			WHERE winlostdate = @winlostdate
	
			IF @@ROWCOUNT = 0 SET @loop = 'n'
		COMMIT TRANSACTION

	WAITFOR DELAY '000:00:01.4'
END

SET @loop = 'y'
WHILE @loop = 'y'
BEGIN
		BEGIN TRANSACTION
			DELETE TOP(600) FROM dbo.Sum_Winloss_Cust_Tmp
			WHERE winlostdate = @winlostdate
	
			IF @@ROWCOUNT = 0 SET @loop = 'n'
		COMMIT TRANSACTION

	WAITFOR DELAY '000:00:01.4'
END

