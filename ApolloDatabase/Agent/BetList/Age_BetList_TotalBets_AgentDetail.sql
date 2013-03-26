USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_BetList_TotalBets_AgentDetail]    Script Date: 3/25/2013 4:42:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER  PROCEDURE [dbo].[Age_BetList_TotalBets_AgentDetail]
	@TransId BIGINT,
	@AgentId INT
AS

/*
Created: 20130301@Sophia
Task : Detail Betlist for total bet
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
		ADiscount	DECIMAL(9,8))
		--AWinlost MONEY,
		--AComm MONEY)
 
DECLARE @AgentLevel INT

SELECT	@AgentLevel = AgentLevel
FROM	AgentInfo  WITH (NOLOCK)
WHERE	AgentID = @AgentID 
	 
INSERT INTO @BetListDetail
SELECT  B.TransID,
		B.AgentID,
		A.AgentHID,
		B.Username,
		B.Status,
		A.AgentLevel,
		B.APositionTaking,
		B.ADiscount
		--B.AWinlost,				
		--B.AComm	- D.AComm AS AComm									
FROM	BetTrans_Agent AS B WITH (NOLOCK)
INNER JOIN 	AgentInfo AS A WITH (NOLOCK)
		ON A.AgentID = B.AgentID
--INNER JOIN AgentInfo AS C WITH (NOLOCK)
--		ON C.AgentHId.IsDescendantOf(A.AgentHId) = 1 AND C.AgentID = B.AgentID
--INNER JOIN BetTrans_Agent D WITH (NOLOCK)
--		ON C.AgentID = D.AgentID AND D.TransID = B.TransID 
WHERE	B.TransId = @TransId AND	
		B.Bettype < 19001 AND
		B.Bettype NOT BETWEEN 81 AND 120 AND 
		A.AgentLevel >= @AgentLevel AND
		B.StatusId IN (0,1) 
				
	
 	
SELECT  * FROM @BetListDetail
ORDER BY TransID


