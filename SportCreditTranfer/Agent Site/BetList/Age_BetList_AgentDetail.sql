
/****** Object:  StoredProcedure [dbo].[Age_BetList_AgentDetail]    Script Date: 3/25/2013 4:44:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_BetList_AgentDetail]
	@TransId BIGINT,
	@LoggedId INT 


/*
Created: 20130301@Sophia
Task : Detail Betlist 
DB:  SVRAGE.RepDB
Original:  

Revisions:
	- 20130723@Sophia: Not Filter data by @FromDate, @Todate
  
*/ 
AS
SET NOCOUNT ON


CREATE TABLE  #BetListDetail (
		TransID BIGINT,
		AgentID INT,		
		Status   VARCHAR(10),		
		APositionTaking SMALLMONEY, 
		ADiscount	DECIMAL(9,8),
		AWinlost MONEY,
		AComm MONEY)

CREATE TABLE  #AgentIdList ( AgentId INT)

DECLARE @AgentLevel INT 

SELECT	@AgentLevel = AgentLevel +1 
FROM	AgentInfo  WITH (NOLOCK)
WHERE	AgentID = @LoggedId
   
BEGIN 

	INSERT INTO #AgentIdList 
	SELECT	AgentId 
	FROM	BetTrans_Agent WITH (NOLOCK)
	WHERE	TransID = @TransId

	
	INSERT INTO #BetListDetail
	SELECT	DISTINCT
			BA.TransID,
			BA.AgentID,
			BA.Status,
			BA.APositionTaking,
			BA.ADiscount,
			BA.AWinlost,				
			BA.AComm - ISNULL(D.Acomm, B.Playercomm) AS AComm									
	FROM	BetTrans_Agent  BA WITH (NOLOCK)
	INNER JOIN	Bettrans B WITH (NOLOCK) 
			ON	B.TransID= BA.TransID 
	LEFT JOIN	AgentInfo C WITH (NOLOCK)
			ON	C.ParentID = BA.AgentID	AND C.AgentId IN (SELECT AgentId FROM #AgentIdList)	 
	LEFT JOIN BetTrans_Agent D WITH (NOLOCK)
			ON  D.AgentID = C.AgentID AND D.TransID = BA.TransID
	WHERE	B.TransId = @TransId 			 
			AND ISNULL(C.AgentLevel,@AgentLevel) >= @AgentLevel   


	-----Super View add 1 more row of Super
	IF @AgentLevel = 1 
	BEGIN 
		INSERT INTO #BetListDetail
			SELECT	DISTINCT
					B.TransID,
					@LoggedId as AgentID,
					B.Status,
					(1 - B.TPositionTaking) AS APositionTaking,
					NULL AS ADiscount,
					- (B.Winlost - B.Actual_Stake + B.TWinlost) AS AWinLost,				
					- (B.TComm) AS AComm									
			FROM	BetTrans_Agent  BA WITH (NOLOCK)
			INNER JOIN	Bettrans B WITH (NOLOCK) 
					ON	B.TransID= BA.TransID 
			LEFT JOIN	AgentInfo C WITH (NOLOCK)
					ON	C.ParentID = BA.AgentID	AND C.AgentId IN (SELECT AgentId FROM #AgentIdList)	 
			LEFT JOIN BetTrans_Agent D WITH (NOLOCK)
					ON  D.AgentID = C.AgentID AND D.TransID = BA.TransID
			WHERE	B.TransId = @TransId 					
					AND ISNULL(C.AgentLevel,@AgentLevel) >= @AgentLevel 
	END
	
		
END	

------If not have data in Bettrans then check data in bettrans14
IF NOT EXISTS (SELECT TOP 1 1 FROM #BetListDetail )
BEGIN

			INSERT INTO #AgentIdList 
			SELECT	AgentId 
			FROM	BetTrans14_Agent WITH (NOLOCK)
			WHERE	TransID = @TransId


			INSERT INTO #BetListDetail
			SELECT	DISTINCT
					BA.TransID,
					BA.AgentID,
					BA.Status,
					BA.APositionTaking,
					BA.ADiscount,
					BA.AWinlost,				
					BA.AComm - ISNULL(D.Acomm, B.Playercomm) AS AComm									
			FROM	BetTrans14_Agent  BA WITH (NOLOCK)
			INNER JOIN	Bettrans14 B WITH (NOLOCK) 
					ON	B.TransID= BA.TransID 
			LEFT JOIN	AgentInfo C WITH (NOLOCK)
					ON	C.ParentID = BA.AgentID	AND C.AgentId IN (SELECT AgentId FROM #AgentIdList)	 
			LEFT JOIN BetTrans14_Agent D WITH (NOLOCK)
					ON  D.AgentID = C.AgentID AND D.TransID = BA.TransID
			WHERE	B.TransId = @TransId 					 
					AND ISNULL(C.AgentLevel,@AgentLevel) >= @AgentLevel 
					  	
	-----Super View add 1 more row of Super
	IF @AgentLevel = 1 
	BEGIN 
		INSERT INTO #BetListDetail
			SELECT	DISTINCT 
					B.TransID,
					@LoggedId as AgentID,
					B.Status,
					(1 - B.TPositionTaking) AS APositionTaking,
					NULL AS ADiscount,
					- (B.Winlost - B.Actual_Stake + B.TWinlost) AS AWinLost,			
					- (B.TComm) AS AComm								
			FROM	BetTrans14_Agent  BA WITH (NOLOCK)
			INNER JOIN	Bettrans14 B WITH (NOLOCK) 
					ON	B.TransID= BA.TransID 
			LEFT JOIN	AgentInfo C WITH (NOLOCK)
					ON	C.ParentID = BA.AgentID	AND C.AgentId IN (SELECT AgentId FROM #AgentIdList)	 
			LEFT JOIN BetTrans14_Agent D WITH (NOLOCK)
					ON  D.AgentID = C.AgentID AND D.TransID = BA.TransID
			WHERE	B.TransId = @TransId
					AND ISNULL(C.AgentLevel,@AgentLevel) >= @AgentLevel 
	END	
	
END		
 	
SELECT	B.* , A.Username, A.AgentLevel
FROM	#BetListDetail B
INNER JOIN AgentInfo A
	ON	 A.AgentId = B.AgentId
ORDER BY B.TransID, A.AgentLevel


DROP TABLE #BetListDetail
DROP TABLE #AgentIdList
	
GO
GRANT EXECUTE ON [dbo].[Age_BetList_AgentDetail] TO [aplweb]