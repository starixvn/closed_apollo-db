ALTER PROCEDURE [dbo].[Age_Rpt_CustCount_AgentViewCust]
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
    Task	: Report Cust Count (AgentViewCust)
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
			INSERT INTO #CustCountMember 
			SELECT	B.CustID				 
			FROM	Bettrans B WITH (NOLOCK)
			INNER JOIN BetTrans_Agent BA WITH (NOLOCK) 
				ON	BA.TransID = B.TransID 
				AND BA.AgentId = @AgentID 
				AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND BA.StatusID NOT IN (0,1)
				AND BA.Bettype <= 19000 		
			INNER JOIN CustInfo C WITH (NOLOCK)
				ON	B.CustID = C.CustID AND C.AgentId = @AgentID			
			WHERE	B.Winlostdate BETWEEN @FromDate AND @ToDate 
					AND B.StatusID NOT IN (0,1)
					AND B.Bettype <= 19000  
			GROUP BY B.CustID
	END

	------Sportsbook
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype NOT IN (9,29,10) OR @Bettypes = '0')	AND @Sporttypes <> '0'
	BEGIN		
		IF (@Bettypes = '0')
		BEGIN				
			INSERT INTO #CustCountMember
			SELECT	B.CustID				 
			FROM	Bettrans B WITH (NOLOCK)
			INNER JOIN BetTrans_Agent BA WITH (NOLOCK) 
				ON	BA.TransID = B.TransID 
				AND BA.AgentId = @AgentID 
				AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND BA.StatusID NOT IN (0,1)
				AND BA.Bettype <= 19000 AND BA.Bettype NOT IN (9,29,10)				
			INNER JOIN CustInfo C WITH (NOLOCK)
				ON	B.CustID = C.CustID AND C.AgentId = @AgentID			
			WHERE	B.Winlostdate BETWEEN @FromDate AND @ToDate 
					AND B.StatusID NOT IN (0,1)
					AND B.Bettype <= 19000 AND B.Bettype NOT IN (9,29,10)				
					AND (@Sporttypes = '0' OR EXISTS ( SELECT 1 FROM Match (NOLOCK) WHERE Matchid = B.Matchid AND sporttype IN (SELECT sporttype FROM #SportsList)) )	
			GROUP BY B.CustID
		END
		ELSE 
		BEGIN 
			INSERT INTO #CustCountMember
			SELECT	B.CustID				 
			FROM	Bettrans B WITH (NOLOCK)
			INNER JOIN BetTrans_Agent BA WITH (NOLOCK) 
				ON	BA.TransID = B.TransID 
				AND BA.AgentId = @AgentID 
				AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND BA.StatusID NOT IN (0,1)
				AND BA.Bettype <= 19000
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))
			INNER JOIN CustInfo C WITH (NOLOCK)
				ON	B.CustID = C.CustID AND C.AgentId = @AgentID					
			WHERE	B.Winlostdate BETWEEN @FromDate AND @ToDate 
					AND B.StatusID NOT IN (0,1)
					AND B.Bettype <= 19000
					AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))
					AND (@Sporttypes = '0' OR EXISTS ( SELECT 1 FROM Match (NOLOCK) WHERE Matchid = B.Matchid AND sporttype IN (SELECT sporttype FROM #SportsList)) )	
			GROUP BY B.CustID
		END 			
	END

	-----Parlay	
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (9,29) OR @Bettypes = '0') AND @Sporttypes <> '0'
	BEGIN 
		INSERT INTO #CustCountMember 
		SELECT	B.CustID	
		FROM	Bettrans B WITH (NOLOCK)
		INNER JOIN BetTrans_Agent BA WITH (NOLOCK ) 
			ON	BA.TransID = B.TransID 
				AND BA.AgentId = @AgentID 
				AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND BA.StatusID NOT IN (0,1)
				AND BA.Bettype IN (9,29)
				AND (@Bettypes = '0' OR BA.Bettype IN (Select bettype FROM #BettypeList))
		INNER JOIN CustInfo C WITH (NOLOCK)
			ON	B.CustID = C.CustID AND C.AgentId = @AgentID			
		WHERE	B.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND B.StatusID NOT IN (0,1)
				AND B.Bettype IN (9,29)
				AND (@Bettypes = '0' OR B.Bettype IN (Select bettype FROM #BettypeList))
	END

	
	-----Outright
	IF EXISTS (SELECT TOP 1 1  FROM #BettypeList WHERE Bettype IN (10) OR @Bettypes = '0') AND @Sporttypes <> '0'
	BEGIN
		INSERT INTO #CustCountMember
		SELECT	B.CustID			 
		FROM	Bettrans B WITH (NOLOCK)
		INNER JOIN BetTrans_Agent BA WITH (NOLOCK ) 
			ON	BA.TransID = B.TransID
				AND BA.AgentId = @AgentID 
				AND BA.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND BA.StatusID NOT IN (0,1)
				AND BA.Bettype = 10			
		INNER JOIN CustInfo C WITH (NOLOCK)
			ON	B.CustID = C.CustID AND C.AgentId = @AgentID	
		WHERE   B.Winlostdate BETWEEN @FromDate AND @ToDate 
				AND B.StatusID NOT IN (0,1)
				AND B.Bettype = 10
				AND (@Sporttypes = '0' 
					OR EXISTS (	SELECT	1 
								FROM Outright m  WITH (NOLOCK) 									
								INNER JOIN  League l WITH (NOLOCK)
										ON	l.leagueID = m.leagueId
										AND (l.sporttype IN (Select sporttype FROM #SportsList))							
								WHERE	m.orid = B.MatchID
								)				
						)
			GROUP BY B.CustID
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
		 

	    INSERT INTO #CustCountMember
	    SELECT	A.CustID			
	    FROM	Sum_WinLoss_Cust A WITH(NOLOCK)		
		WHERE	AgentId = @AgentId 
				AND WinLostDate BETWEEN @tmpdate AND @ToDate 
				AND (@Sporttypes = '0' OR A.sporttype IN (Select sporttype FROM #SportsList))
				AND (@Bettypes = '0' OR A.Bettype IN (Select bettype FROM #BettypeList))		 
		GROUP BY A.CustID
	END


------------------------------------------------DATA [BK] ----------------------------------------------
 
IF @FromDate < @BalanceUpDay 
 BEGIN    	
		IF @todate >= DATEADD(dd, -1, @BalanceUpDay)
		SELECT @ToDate = DATEADD(dd, -1, @BalanceUpDay)	   

		INSERT INTO #CustCountMember
	    SELECT	A.CustID	
	    FROM	SummaryDB.dbo.Sum_WinLoss_Cust_Old A WITH(NOLOCK, index =CIX_sum_winloss_cust)		
		WHERE	AgentId = @AgentId 
				AND WinLostDate BETWEEN @FromDate AND @ToDate 
				AND (@Sporttypes = '0' OR A.sporttype IN (Select sporttype FROM #SportsList))
				AND (@Bettypes = '0' OR A.Bettype IN (Select bettype FROM #BettypeList))
	    GROUP BY A.CustID

	END 
	
-------------------------------------------------------------------------------------------------------

GO
GRANT EXECUTE ON [Age_Rpt_CustCount_AgentViewCust] TO [aplweb]
 