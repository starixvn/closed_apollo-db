USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_BetList_AgentDetail]    Script Date: 3/25/2013 4:44:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_BetList_AgentDetail]
	@TransId BIGINT,
	@AgentId INT,
	@FromDate SMALLDATETIME,
	@ToDate SMALLDATETIME,
	@MoveBetsDay SMALLDATETIME,
	@ShowSB BIT = 1,
	@ShowNG BIT = 0
AS

/*
Created: 20130301@Sophia
Task : Detail Betlist
DB:  SVRAGE.RepDB
Original:  

Revisions:
  
*/ 
SET NOCOUNT ON


DECLARE @BetListDetail TABLE(
		TransID BIGINT,
		AgentID INT,
		AgentHID HIERARCHYID,
		Username VARCHAR(50),
		Status   VARCHAR(10),
		AgentLevel SMALLINT,
		APositionTaking SMALLMONEY, 
		ADiscount	DECIMAL(9,8),
		AWinlost MONEY,
		AComm MONEY)

DECLARE @AgentLevel INT

SELECT	@AgentLevel = AgentLevel
FROM	AgentInfo  WITH (NOLOCK)
WHERE	AgentID = @AgentID 

IF @Todate > @MoveBetsDay
BEGIN
 	IF @ShowSB = 1
	BEGIN
			INSERT INTO @BetListDetail
			SELECT	BA.TransID,
					BA.AgentID,
					A.AgentHID,
					BA.Username,
					BA.Status,
					A.AgentLevel,
					BA.APositionTaking,
					BA.ADiscount,
					BA.AWinlost,				
					BA.AComm - D.AComm AS AComm									
			FROM	BetTrans_Agent AS BA WITH (NOLOCK)
			INNER JOIN 	AgentInfo AS A WITH (NOLOCK)
					ON A.AgentID = BA.AgentID
			INNER JOIN AgentInfo AS C WITH (NOLOCK)
					ON C.AgentHId.IsDescendantOf(A.AgentHId) = 1 AND C.AgentID = BA.AgentID
			INNER JOIN BetTrans_Agent D WITH (NOLOCK)
					ON C.AgentID = D.AgentID AND D.TransID = BA.TransID 
			WHERE	BA.TransId = @TransId 
					AND BA.Winlostdate BETWEEN @fromdate AND @todate 
					AND (BA.bettype < 31 
						OR BA.bettype BETWEEN 121 AND 999 
						OR BA.bettype BETWEEN 1301 AND 1334 )  
					AND BA.Bettype NOT BETWEEN 81 AND 120  
					AND A.AgentLevel >= @AgentLevel
		
	END
	
	---Number Game
	IF @ShowNG = 1
	BEGIN	
			INSERT INTO @BetListDetail
			SELECT	BA.TransID,
					BA.AgentID,
					A.AgentHID,
					BA.Username,
					BA.Status,
					A.AgentLevel,
					BA.APositionTaking,
					BA.ADiscount,
					BA.AWinlost,				
					BA.AComm	- D.AComm AS AComm									
			FROM	BetTrans_Agent AS BA WITH (NOLOCK)
			INNER JOIN 	AgentInfo AS A WITH (NOLOCK)
					ON A.AgentID = BA.AgentID
			INNER JOIN AgentInfo AS C WITH (NOLOCK)
					ON C.AgentHId.IsDescendantOf(A.AgentHId) = 1 AND C.AgentID = BA.AgentID
			INNER JOIN BetTrans_Agent D WITH (NOLOCK)
					ON C.AgentID = D.AgentID  AND D.TransID = BA.TransID 
			WHERE	BA.TransId = @TransId 
					AND BA.WinLostDate BETWEEN @FromDate AND @ToDate 
					AND BA.Bettype  BETWEEN 81 AND 120  
					AND A.AgentLevel >= @AgentLevel

	END
END	

IF @Fromdate <= @MoveBetsDay
BEGIN
	IF @ShowSB = 1
	BEGIN
			INSERT INTO @BetListDetail
			SELECT	BA.TransID,
					BA.AgentID,
					A.AgentHID,
					BA.Username,
					BA.Status,
					A.AgentLevel,
					BA.APositionTaking,
					BA.ADiscount,
					BA.AWinlost,				
					BA.AComm	- D.AComm AS AComm									
			FROM	BetTrans14_Agent AS BA WITH (NOLOCK)
			INNER JOIN 	AgentInfo AS A WITH (NOLOCK)
					ON A.AgentID = BA.AgentID
			INNER JOIN AgentInfo AS C WITH (NOLOCK)
					ON C.AgentHId.IsDescendantOf(A.AgentHId) = 1 AND C.AgentID = BA.AgentID
			INNER JOIN BetTrans14_Agent D WITH (NOLOCK)
					ON C.AgentID = D.AgentID  AND D.TransID = BA.TransID 
			WHERE	BA.TransId = @TransId 
					AND BA.winlostdate BETWEEN @fromdate AND @todate 
					AND (BA.bettype < 31 
						OR BA.bettype BETWEEN 121 AND 999 
						OR BA.bettype BETWEEN 1301 AND 1334 ) 
					AND BA.bettype NOT BETWEEN 81 AND 120  
					AND A.AgentLevel >= @AgentLevel				
	END
	
	---Number Game
	IF @ShowNG = 1
	BEGIN	
			INSERT INTO @BetListDetail
			SELECT	BA.TransID,
					BA.AgentID,
					A.AgentHID,
					BA.Username,
					BA.Status,
					A.AgentLevel,
					BA.APositionTaking,
					BA.ADiscount,
					BA.AWinlost,				
					BA.AComm	- D.AComm AS AComm									
			FROM	BetTrans14_Agent AS BA WITH (NOLOCK)
			INNER JOIN 	AgentInfo AS A WITH (NOLOCK)
					ON A.AgentID = BA.AgentID
			INNER JOIN AgentInfo AS C WITH (NOLOCK)
					ON C.AgentHId.IsDescendantOf(A.AgentHId) = 1 AND C.AgentID = BA.AgentID
			INNER JOIN BetTrans14_Agent D WITH (NOLOCK)
					ON C.AgentID = D.AgentID  AND D.TransID = BA.TransID 
			WHERE	BA.TransId = @TransId 
					AND BA.WinLostDate BETWEEN @FromDate AND @ToDate 
					AND BA.Bettype  BETWEEN 81 AND 120  
					AND A.AgentLevel >= @AgentLevel
	END
	
END		
 	
	SELECT * FROM @BetListDetail
	ORDER BY TransID


