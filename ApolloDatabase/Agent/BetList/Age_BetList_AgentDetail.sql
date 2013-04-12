
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
Task : Detail Betlist
DB:  SVRAGE.RepDB
Original:  

Revisions:
  
*/ 
AS
SET NOCOUNT ON


DECLARE @BetListDetail TABLE(
		TransID BIGINT,
		AgentID INT,
		--AgentHID HIERARCHYID,
		Username VARCHAR(50),
		Status   VARCHAR(10),
		--AgentLevel SMALLINT,
		APositionTaking SMALLMONEY, 
		ADiscount	DECIMAL(9,8),
		AWinlost MONEY,
		AComm MONEY)

DECLARE @AgentIdList TABLE ( AgentId INT)

INSERT INTO @AgentIdList 
SELECT	AgentId 
FROM	BetTrans_Agent WITH (NOLOCK)
WHERE	TransID = @TransId


DECLARE @AgentLevel INT

SELECT	@AgentLevel = AgentLevel +1
FROM	AgentInfo  WITH (NOLOCK)
WHERE	AgentID =@LoggedId
 

IF @Todate > @MoveBetsDay
BEGIN 
	BEGIN
			INSERT INTO @BetListDetail
			SELECT	BA.TransID,
					BA.AgentID,
					--A.AgentHID,
					BA.Username,
					BA.Status,
					--A.AgentLevel,
					BA.APositionTaking,
					BA.ADiscount,
					BA.AWinlost,				
					 BA.AComm - ISNULL(D.Acomm, B.Playercomm) AS AComm									
			FROM	BetTrans_Agent  BA WITH (NOLOCK)
			INNER JOIN	Bettrans B WITH (NOLOCK) 
					ON	B.TransID= BA.TransID 
			LEFT JOIN	AgentInfo C WITH (NOLOCK)
					ON	C.ParentID = BA.AgentID	AND C.AgentId IN (SELECT AgentId FROM @AgentIdList)	 
			LEFT JOIN BetTrans_Agent D WITH (NOLOCK)
					ON  D.AgentID = C.AgentID AND D.TransID = BA.TransID
			WHERE	BA.TransId = @TransId 
					AND BA.Winlostdate BETWEEN @fromdate AND @todate 
					AND (BA.bettype < 31 
						OR BA.bettype BETWEEN 121 AND 999 
						OR BA.bettype BETWEEN 1301 AND 1334   
						OR BA.Bettype  BETWEEN 81 AND 120 )
					AND ISNULL(C.AgentLevel,@AgentLevel) >= @AgentLevel   
	END
	
END	

IF @Fromdate <= @MoveBetsDay
BEGIN
			INSERT INTO @BetListDetail
			SELECT	BA.TransID,
					BA.AgentID,
					--A.AgentHID,
					BA.Username,
					BA.Status,
					--A.AgentLevel,
					BA.APositionTaking,
					BA.ADiscount,
					BA.AWinlost,				
					BA.AComm - ISNULL(D.Acomm, B.Playercomm) AS AComm									
			FROM	BetTrans14_Agent  BA WITH (NOLOCK)
			INNER JOIN	Bettrans14 B WITH (NOLOCK) 
					ON	B.TransID= BA.TransID 
			LEFT JOIN	AgentInfo C WITH (NOLOCK)
					ON	C.ParentID = BA.AgentID	AND C.AgentId IN (SELECT AgentId FROM @AgentIdList)	 
			LEFT JOIN BetTrans14_Agent D WITH (NOLOCK)
					ON  D.AgentID = C.AgentID AND D.TransID = BA.TransID
			WHERE	BA.TransId = @TransId 
					AND BA.winlostdate BETWEEN @fromdate AND @todate 
					AND (BA.bettype < 31 
						OR BA.bettype BETWEEN 121 AND 999 
						OR BA.bettype BETWEEN 1301 AND 1334  
						OR BA.bettype  BETWEEN 81 AND 120 ) 
					AND ISNULL(C.AgentLevel,@AgentLevel) >= @AgentLevel   		
	
END		
 	
SELECT DISTINCT * FROM @BetListDetail
ORDER BY TransID

	
GO
GRANT EXECUTE ON [dbo].[Age_BetList_AgentDetail] TO [aplweb]