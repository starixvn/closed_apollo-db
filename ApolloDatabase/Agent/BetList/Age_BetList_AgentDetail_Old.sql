
/****** Object:  StoredProcedure [dbo].[Age_BetList_AgentDetail]    Script Date: 3/25/2013 4:44:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Age_BetList_AgentDetail_Old]
	@TransId BIGINT,
	@LoggedId INT,
	@FromDate SMALLDATETIME,
	@ToDate SMALLDATETIME


/*
Created: 20130301@Sophia
Task : Detail Betlist
DB:  SVRARC.ArchiveDB
Original:  

Revisions:
  
*/ 
AS
SET NOCOUNT ON


DECLARE @BetListDetail TABLE(
		TransID BIGINT,
		AgentID INT,
		--Username VARCHAR(50),
		Status   VARCHAR(10),
		--AgentLevel SMALLINT,
		APositionTaking SMALLMONEY, 
		ADiscount	DECIMAL(9,8),
		AWinlost MONEY,
		AComm MONEY)

DECLARE @AgentIdList TABLE ( AgentId INT)

INSERT INTO @AgentIdList 
SELECT	AgentId 
FROM	BetTrans_Agent_BK WITH (NOLOCK)
WHERE	TransID = @TransId 


DECLARE @AgentLevel INT, @Username NVARCHAR(50)

SELECT	@AgentLevel = AgentLevel +1, @Username = Username
FROM	AgentInfo  WITH (NOLOCK)
WHERE	AgentID = @LoggedId
 

			INSERT INTO @BetListDetail
			SELECT	DISTINCT 
					BA.TransID,
					BA.AgentID,
					---BA.Username,
					BA.Status,
					--A.AgentLevel,
					BA.APositionTaking,
					BA.ADiscount,
					BA.AWinlost,				
					BA.AComm - ISNULL(D.Acomm, B.Playercomm) AS AComm									
			FROM	BetTrans_Agent_BK  BA WITH (NOLOCK)
			INNER JOIN	Bettrans_BK B WITH (NOLOCK) 
					ON	B.TransID= BA.TransID 
			LEFT JOIN	SVRCUST.CUSTDB.dbo.AgentInfo C WITH (NOLOCK)
					ON	C.ParentID = BA.AgentID	AND C.AgentId IN (SELECT AgentId FROM @AgentIdList)	 
			LEFT JOIN BetTrans_Agent_BK D WITH (NOLOCK)
					ON  D.AgentID = C.AgentID AND D.TransID = BA.TransID
			WHERE	BA.TransId = @TransId 
					AND BA.TransDate BETWEEN @fromdate AND @todate 
					AND (BA.bettype < 31 
						OR BA.bettype BETWEEN 121 AND 999 
						OR BA.bettype BETWEEN 1301 AND 1334   
						OR BA.Bettype  BETWEEN 81 AND 120 )
					AND ISNULL(C.AgentLevel,@AgentLevel) >= @AgentLevel   
	 
	IF @AgentLevel = 1 
	BEGIN 
		INSERT INTO @BetListDetail
			SELECT	DISTINCT 
					B.TransID,
					@LoggedId as AgentID,
					---@Username as Username,
					B.Status,
					(1 - B.TPositionTaking) AS APositionTaking,
					NULL AS ADiscount,
					- (B.Winlost - B.Actual_Stake + B.TWinlost) AS AWinLost,				
					- (B.TComm) AS AComm									
			FROM	BetTrans_Agent_BK  BA WITH (NOLOCK)
			INNER JOIN	Bettrans_BK B WITH (NOLOCK) 
					ON	B.TransID= BA.TransID 
			LEFT JOIN	SVRCUST.CUSTDB.dbo.AgentInfo C WITH (NOLOCK)
					ON	C.ParentID = BA.AgentID	AND C.AgentId IN (SELECT AgentId FROM @AgentIdList)	 
			LEFT JOIN BetTrans_BK D WITH (NOLOCK)
					ON  D.AgentID = C.AgentID AND D.TransID = BA.TransID
			WHERE	BA.TransId = @TransId 
					AND BA.TransDate BETWEEN @fromdate AND @todate 
					AND (BA.bettype < 31 
						OR BA.bettype BETWEEN 121 AND 999 
						OR BA.bettype BETWEEN 1301 AND 1334   
						OR BA.Bettype  BETWEEN 81 AND 120 )
					AND ISNULL(C.AgentLevel,@AgentLevel) >= @AgentLevel 
	END	

 	
SELECT	B.* , A.Username , A.AgentLevel
FROM	@BetListDetail B
INNER JOIN AgentInfo A
	ON	 A.AgentId = B.AgentId
ORDER BY B.TransID, A.AgentLevel
	
GO
GRANT EXECUTE ON [dbo].[Age_BetList_AgentDetail] TO [aplweb]