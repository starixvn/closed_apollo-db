
/****** Object:  StoredProcedure [dbo].[Age_BetList_AgentDetail]    Script Date: 3/25/2013 4:44:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_BetList_AgentDetail]
	@TransId BIGINT,
	@LoggedId INT,
	@FromDate SMALLDATETIME,
	@ToDate SMALLDATETIME,
	@MoveBetsDay SMALLDATETIME


/*
Created: 20130301@Sophia
Task : Detail Betlist for Transdate
DB:  SVRAGE.RepDB
Original:  

Revisions:
  
*/ 
AS
SET NOCOUNT ON


CREATE TABLE  #BetListDetail (
		TransID BIGINT,
		AgentID INT,		
		--Username VARCHAR(50),
		Status   VARCHAR(10),		
		APositionTaking SMALLMONEY, 
		ADiscount	DECIMAL(9,8),
		AWinlost MONEY,
		AComm MONEY)

CREATE TABLE  #AgentIdList ( AgentId INT)

INSERT INTO #AgentIdList 
SELECT	AgentId 
FROM	BetTrans_Agent WITH (NOLOCK)
WHERE	TransID = @TransId


DECLARE @AgentLevel INT, @Username NVARCHAR(50)

SELECT	@AgentLevel = AgentLevel +1, @Username = Username
FROM	AgentInfo  WITH (NOLOCK)
WHERE	AgentID = @LoggedId
 

IF @Todate > @MoveBetsDay
BEGIN 
	
	INSERT INTO #BetListDetail
	SELECT	DISTINCT
			BA.TransID,
			BA.AgentID,
			--BA.Username,
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
	WHERE	BA.TransId = @TransId 
			AND BA.TransDate BETWEEN @fromdate AND @todate 
			AND (BA.bettype < 31 
				OR BA.bettype BETWEEN 121 AND 999 
				OR BA.bettype BETWEEN 1301 AND 1334   
				OR BA.Bettype  BETWEEN 81 AND 120 )
			AND ISNULL(C.AgentLevel,@AgentLevel) >= @AgentLevel   


	-----Super View add 1 more row of Super
	IF @AgentLevel = 1 
	BEGIN 
		INSERT INTO #BetListDetail
			SELECT	DISTINCT
					B.TransID,
					@LoggedId as AgentID,
					--@Username as Username,
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
			WHERE	BA.TransId = @TransId 
					AND BA.TransDate BETWEEN @fromdate AND @todate 
					AND (BA.bettype < 31 
						OR BA.bettype BETWEEN 121 AND 999 
						OR BA.bettype BETWEEN 1301 AND 1334   
						OR BA.Bettype  BETWEEN 81 AND 120 )
					AND ISNULL(C.AgentLevel,@AgentLevel) >= @AgentLevel 
	END
	
		
END	

IF @Fromdate <= @MoveBetsDay
BEGIN
			INSERT INTO #BetListDetail
			SELECT	DISTINCT
					BA.TransID,
					BA.AgentID,
					--BA.Username,
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
			WHERE	BA.TransId = @TransId 
					AND BA.TransDate BETWEEN @fromdate AND @todate 
					AND (BA.bettype < 31 
						OR BA.bettype BETWEEN 121 AND 999 
						OR BA.bettype BETWEEN 1301 AND 1334  
						OR BA.bettype  BETWEEN 81 AND 120 ) 
					AND ISNULL(C.AgentLevel,@AgentLevel) >= @AgentLevel 
					  	
	-----Super View add 1 more row of Super
	IF @AgentLevel = 1 
	BEGIN 
		INSERT INTO #BetListDetail
			SELECT	DISTINCT 
					B.TransID,
					@LoggedId as AgentID,
				---	@Username as Username,
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
			WHERE	BA.TransId = @TransId 
					AND BA.TransDate BETWEEN @fromdate AND @todate 
					AND (BA.bettype < 31 
						OR BA.bettype BETWEEN 121 AND 999 
						OR BA.bettype BETWEEN 1301 AND 1334   
						OR BA.Bettype  BETWEEN 81 AND 120 )
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