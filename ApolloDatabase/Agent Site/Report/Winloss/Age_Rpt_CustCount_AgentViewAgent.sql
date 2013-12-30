ALTER PROCEDURE [dbo].[Age_Rpt_CustCount_AgentViewAgent]
	@AgentID 	INT,
	@FromDate 	DATE,
	@ToDate 	DATE,	
	@MoveBetDay DATE, 
	@BalanceUpDay DATE,	
	@Sporttypes VARCHAR(MAX) = '0',
	@Bettypes VARCHAR(MAX) = '0'
 	
AS
    /*
    Created	: Sophia
	Date	: 20130726
    Task	: Report Cust Count(AgentViewAgent)
    DB		: SVRAGE.RepDB

    Revisions:
     
    */
    
SET NOCOUNT ON

--------------------------------------------------------------------------------------------------------

IF @Todate > @MoveBetDay
BEGIN   
	-----All Bettype and All Sport
	IF @Bettypes = '0' AND  @Sporttypes = '0'
	BEGIN				 
			INSERT INTO #CustCountAgent 
			SELECT	A.AgentId, C.CustID						 
			FROM	bettrans_agent A WITH(NOLOCK)
			INNER JOIN AgentInfo AP  WITH(NOLOCK)
					ON AP.AgentId = A.AgentId
			INNER JOIN AgentInfo AC  WITH(NOLOCK)
					ON AC.AgentHId.IsDescendantOf(AP.AgentHId ) =1	 
			INNER JOIN bettrans C WITH (NOLOCK)
					ON C.TransID = A.TransID						
			WHERE	AP.ParentID = @AgentId 
					AND A.WinLostDate BETWEEN @FromDate AND @ToDate 
					AND A.Bettype <=19000 
					AND A.StatusID NOT IN (0,1) 			 							 
					AND C.WinLostDate BETWEEN @FromDate AND @ToDate 
					AND C.Bettype <=19000  		
					AND C.StatusID NOT IN (0,1) 					
			GROUP BY A.AgentId, C.CustID	
	END


	------Sportsbook
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10) OR @Bettypes = '0')	 AND  @Sporttypes <> '0'
	BEGIN		
		IF (@Bettypes = '0')
		BEGIN				
			INSERT INTO #CustCountAgent 
			SELECT	A.AgentId, C.CustID						 
			FROM	bettrans_agent A WITH(NOLOCK)
			INNER JOIN AgentInfo AP  WITH(NOLOCK)
					ON AP.AgentId = A.AgentId
			INNER JOIN AgentInfo AC  WITH(NOLOCK)
					ON AC.AgentHId.IsDescendantOf(AP.AgentHId ) =1	 
			INNER JOIN bettrans C WITH (NOLOCK)
					ON C.TransID = A.TransID						
			WHERE	AP.ParentID = @AgentId 
					AND A.WinLostDate BETWEEN @FromDate AND @ToDate 
					AND A.Bettype <=19000 AND A.bettype NOT IN (9,29,10)	
					AND A.StatusID NOT IN (0,1) 		
					AND (@Sporttypes = '0' OR EXISTS ( SELECT 1 FROM Match (NOLOCK) WHERE Matchid = A.Matchid AND sporttype IN (SELECT sporttype FROM #SportsList)) )								 
					AND C.WinLostDate BETWEEN @FromDate AND @ToDate 
					AND C.Bettype <=19000 AND C.bettype NOT IN (9,29,10)
					AND C.StatusID NOT IN (0,1) 			
					AND (@Sporttypes = '0' OR EXISTS ( SELECT 1 FROM Match (NOLOCK) WHERE Matchid = C.Matchid AND sporttype IN (SELECT sporttype FROM #SportsList)) )					
			GROUP BY A.AgentId, C.CustID	
		END
		ELSE 
		BEGIN 
			INSERT INTO #CustCountAgent 
			SELECT	A.AgentId, C.CustID						 
			FROM	bettrans_agent A WITH(NOLOCK)
			INNER JOIN AgentInfo AP  WITH(NOLOCK)
					ON AP.AgentId = A.AgentId
			INNER JOIN AgentInfo AC  WITH(NOLOCK)
					ON AC.AgentHId.IsDescendantOf(AP.AgentHId ) =1		 
			INNER JOIN bettrans C WITH (NOLOCK)
					ON C.TransID = A.TransID						
			WHERE	AP.ParentID = @AgentId 
					AND A.WinLostDate BETWEEN @FromDate AND @ToDate 
					AND (@Sporttypes = '0' OR EXISTS ( SELECT 1 FROM Match (NOLOCK) WHERE Matchid = A.Matchid AND sporttype IN (SELECT sporttype FROM #SportsList)) )	 
					AND A.Bettype IN (Select bettype FROM #BettypeList) 	
					AND A.StatusID NOT IN (0,1) 				 
					AND C.WinLostDate BETWEEN @FromDate AND @ToDate 
					AND (@Sporttypes = '0' OR EXISTS ( SELECT 1 FROM Match (NOLOCK) WHERE Matchid = C.Matchid AND sporttype IN (SELECT sporttype FROM #SportsList)) )	 
					AND C.Bettype IN (Select bettype FROM #BettypeList)
					AND C.StatusID NOT IN (0,1) 		
			GROUP BY A.AgentId, C.CustID
		END 			
	END

	-----Parlay	
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29) OR @Bettypes = '0') AND  @Sporttypes <> '0'
	BEGIN 
			INSERT INTO #CustCountAgent 
			SELECT	A.AgentId,C.CustID						 
			FROM	bettrans_agent A WITH(NOLOCK)
			INNER JOIN AgentInfo AP  WITH(NOLOCK)
					ON AP.AgentId = A.AgentId
			INNER JOIN AgentInfo AC  WITH(NOLOCK)
					ON AC.AgentHId.IsDescendantOf(AP.AgentHId) =1		 
			INNER JOIN bettrans C WITH (NOLOCK)
					ON C.TransID = A.TransID						
			WHERE	AP.ParentID = @AgentId 
					AND A.WinLostDate BETWEEN @FromDate AND @ToDate 
					AND A.StatusID NOT IN (0,1) 	
					AND A.Bettype IN (9,29)	AND (@Bettypes = '0' OR A.Bettype IN (SELECT bettype FROM #BettypeList))
					AND C.WinLostDate BETWEEN @FromDate AND @ToDate 
					AND C.StatusID NOT IN (0,1) 						 
					AND C.Bettype IN (9,29)			 
					AND (@Bettypes = '0' OR C.Bettype IN (SELECT bettype FROM #BettypeList))
			GROUP BY A.AgentId, C.CustID
	END

	
	-----Outright
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (10) OR @Bettypes = '0') AND  @Sporttypes <> '0'
	BEGIN
		INSERT INTO #CustCountAgent 
		SELECT	A.AgentId, C.CustID						 
		FROM	BetTrans_Agent A WITH(NOLOCK)
			INNER JOIN AgentInfo AP  WITH(NOLOCK)
					ON AP.AgentId = A.AgentId
			INNER JOIN AgentInfo AC  WITH(NOLOCK)
					ON AC.AgentHId.IsDescendantOf(AP.AgentHId) =1		 
			INNER JOIN BetTrans C WITH (NOLOCK)
					ON C.TransID = A.TransID						
		WHERE	AP.ParentID = @AgentId 
				AND A.Winlostdate BETWEEN @FromDate AND @ToDate
				AND A.StatusID NOT IN (0,1) 	 			 
				AND A.Bettype =10
				AND (@Bettypes = '0' OR A.Bettype IN (Select bettype FROM #BettypeList))					
				AND (@Sporttypes = '0' 
						OR EXISTS (	SELECT	1 
									FROM Outright m  WITH (NOLOCK) 									
									INNER JOIN  League l WITH (NOLOCK)
											ON	l.leagueID = m.leagueId
											AND (l.sporttype IN (Select sporttype FROM #SportsList))							
									WHERE	m.orid = A.MatchID
									)				
						)
				AND C.Winlostdate BETWEEN @FromDate AND @ToDate 	
				AND C.StatusID NOT IN (0,1) 			 
				AND C.Bettype =10
				AND (@Bettypes = '0' OR C.Bettype IN (Select bettype FROM #BettypeList))					
				AND (@Sporttypes = '0' 
						OR EXISTS (	SELECT	1 
									FROM Outright m  WITH (NOLOCK) 									
									INNER JOIN  League l WITH (NOLOCK)
											ON	l.leagueID = m.leagueId
											AND (l.sporttype IN (Select sporttype FROM #SportsList))							
									WHERE	m.orid = C.MatchID
									)				
						)
		GROUP BY A.AgentId, C.CustID
	END

END 
------------------------------------------------DATA [14] ----------------------------------------------

IF @FromDate <= @MoveBetDay and @ToDate >= @BalanceUpDay
	 BEGIN
		DECLARE @tmpdate DATE  

		IF @FromDate < @BalanceUpDay 
			SET @tmpdate = @BalanceUpDay
		ELSE 
			SET @tmpdate = @FromDate
		 

	    INSERT INTO #CustCountAgent
	    SELECT	AP.AgentId, C.CustID			
	    FROM	AgentInfo AP  WITH(NOLOCK)
		INNER JOIN AgentInfo AC  WITH(NOLOCK)
				 ON AC.AgentHId.IsDescendantOf(AP.AgentHId ) =1  	 
		INNER JOIN Sum_WinLoss_Cust C WITH (NOLOCK)
				ON C.AgentId = AC.AgentId						
		WHERE	AP.ParentID = @AgentId 			
				AND C.WinLostDate BETWEEN @tmpdate AND @ToDate 
				AND (@Sporttypes = '0' OR C.sporttype IN (Select sporttype FROM #SportsList))
				AND (@Bettypes = '0' OR C.Bettype IN (Select bettype FROM #BettypeList))	
	    GROUP BY AP.AgentId,C.CustID
	END


------------------------------------------------DATA [BK] ----------------------------------------------
 
IF @FromDate < @BalanceUpDay 
 BEGIN    	
		IF @todate >= DATEADD(dd, -1, @BalanceUpDay)
		SELECT @ToDate = DATEADD(dd, -1, @BalanceUpDay)	   

		INSERT INTO #CustCountAgent
	    SELECT	AP.AgentId, C.CustID	
	    FROM	AgentInfo AP  WITH(NOLOCK)			
		INNER JOIN AgentInfo AC  WITH(NOLOCK)
				 ON AC.AgentHId.IsDescendantOf(AP.AgentHId ) =1   
		INNER JOIN SummaryDB.dbo.Sum_WinLoss_Cust_Old C WITH (NOLOCK)--, index = CIX_sum_winloss_cust)
				ON C.AgentId = AC.AgentId						
		WHERE	AP.ParentID = @AgentId 
				AND C.WinLostDate BETWEEN @FromDate AND @ToDate 
				AND (@Sporttypes = '0' OR C.sporttype IN (Select sporttype FROM #SportsList))
				AND (@Bettypes = '0' OR C.Bettype IN (Select bettype FROM #BettypeList))	
	    GROUP BY AP.AgentId, C.CustID

	END 
	
-------------------------------------------------------------------------------------------------------
GO 
GRANT EXECUTE ON [Age_Rpt_CustCount_AgentViewAgent] TO [aplweb]

