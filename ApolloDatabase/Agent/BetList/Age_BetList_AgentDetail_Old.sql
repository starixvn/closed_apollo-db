
/****** Object:  StoredProcedure [dbo].[Age_BetList_AgentDetail]    Script Date: 3/25/2013 4:44:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_BetList_AgentDetail_Old]
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

EX: EXEC [Age_BetList_AgentDetail_Old] @TransId = 123, @LoggedId = 3, @FromDate = '2013-01-01' , @Todate = '2013-01-30'
  
*/ 
AS
SET NOCOUNT ON

DECLARE @S VARCHAR(500)
SET @S = '	SELECT * 
			INTO #AgentInfo
			FROM OPENQUERY (SVRCUST, '' SELECT	C.AgentId,										
												C.AgentLevel,
												C.Username,												
												C.ParentId
										FROM	CUSTDB.dbo.AgentInfo P WITH (NOLOCK)
										INNER JOIN CUSTDB.dbo.AgentInfo C WITH (NOLOCK)
											ON	C.AgentHId.IsDescendantOf(P.AgentHId) = 1 AND C.AgentLevel >=P.AgentLevel
										WHERE	P.AgentID =' + CONVERT (VARCHAR(50),@LoggedId) +''')'

--EXEC (@s)
--SELECT @s

DECLARE @S1 VARCHAR(8000)
SET @S1 = '

CREATE TABLE #BetListDetail (
		TransID BIGINT,
		AgentID INT,
		Status   VARCHAR(10),
		APositionTaking SMALLMONEY, 
		ADiscount	DECIMAL(9,8),
		AWinlost MONEY,
		AComm MONEY)

CREATE TABLE #AgentIdList ( AgentId INT)

INSERT INTO #AgentIdList 
SELECT	AgentId 
FROM	BetTrans_Agent_BK WITH (NOLOCK)
WHERE	TransID = '+ Convert(varchar(50),@TransId )+'


DECLARE @AgentLevel INT, @Username NVARCHAR(50)

SELECT	@AgentLevel = AgentLevel +1, @Username = Username
FROM	#AgentInfo  WITH (NOLOCK)
WHERE	AgentID = ' + CONVERT (VARCHAR(50),@LoggedId) +'
 

		
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
	FROM	BetTrans_Agent_BK  BA WITH (NOLOCK)
	INNER JOIN	Bettrans_BK B WITH (NOLOCK) 
			ON	B.TransID= BA.TransID 
	LEFT JOIN	#AgentInfo C WITH (NOLOCK)
			ON	C.ParentID = BA.AgentID	AND C.AgentId IN (SELECT AgentId FROM #AgentIdList)	 
	LEFT JOIN BetTrans_Agent_BK D WITH (NOLOCK)
			ON  D.AgentID = C.AgentID AND D.TransID = BA.TransID
	WHERE	BA.TransId = '+ Convert(varchar(50),@TransId )+' 
			AND BA.TransDate BETWEEN '''+ Convert(varchar(50),@Fromdate )+''' AND '''+ Convert(varchar(50),@Todate )+''' 
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
					' + CONVERT (VARCHAR(50),@LoggedId) +' as AgentID,
					--@Username as Username,
					B.Status,
					(1 - B.TPositionTaking) AS APositionTaking,
					NULL AS ADiscount,
					- (B.Winlost - B.Actual_Stake + B.TWinlost) AS AWinLost,				
					- (B.TComm) AS AComm									
			FROM	BetTrans_Agent_BK  BA WITH (NOLOCK)
			INNER JOIN	Bettrans_BK B WITH (NOLOCK) 
					ON	B.TransID= BA.TransID 
			LEFT JOIN	#AgentInfo C WITH (NOLOCK)
					ON	C.ParentID = BA.AgentID	AND C.AgentId IN (SELECT AgentId FROM #AgentIdList)	 
			LEFT JOIN BetTrans_Agent_BK D WITH (NOLOCK)
					ON  D.AgentID = C.AgentID AND D.TransID = BA.TransID
			WHERE	BA.TransId = '+ Convert(varchar(50),@TransId )+'
					AND BA.TransDate BETWEEN '''+ Convert(varchar(50),@Fromdate )+''' AND '''+ Convert(varchar(50),@Todate )+''' 
					AND (BA.bettype < 31 
						OR BA.bettype BETWEEN 121 AND 999 
						OR BA.bettype BETWEEN 1301 AND 1334   
						OR BA.Bettype  BETWEEN 81 AND 120 )
					AND ISNULL(C.AgentLevel,@AgentLevel) >= @AgentLevel 
	END

 	
SELECT	B.* , A.Username , A.AgentLevel
FROM	#BetListDetail B
INNER JOIN #AgentInfo A
	ON	 A.AgentId = B.AgentId
ORDER BY B.TransID, A.AgentLevel
	
		
DROP TABLE #BetListDetail
DROP TABLE #AgentIdList
DROP TABLE #AgentInfo
'
PRINT @S 
PRINT @S1
EXEC (@S+@S1)
 

GO
GRANT EXECUTE ON [dbo].[Age_BetList_AgentDetail_Old] TO [aplweb]