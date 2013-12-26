-- =============================================
-- Script Template
-- =============================================
ALTER PROCEDURE [dbo].[Age_Rpt_CustCount]
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
	Date	: 20130401
    Task	: Report Cust Count 
    DB		: SVRAGE.RepDB
     

    Revisions: 
    */
    
SET NOCOUNT ON


CREATE TABLE #CustCountAgent (	AgentID INT, 
								CustID BIGINT)

CREATE TABLE #CustCountMember (CustID BIGINT)


CREATE TABLE #BettypeList (bettype SMALLINT)
INSERT INTO #BettypeList
SELECT val FROM dbo.strSplit_Key(@Bettypes,',')

CREATE TABLE #SportsList (Sporttype TINYINT)
INSERT INTO #SportsList (Sporttype)
SELECT val FROM strSplit_key (@Sporttypes, ',')


BEGIN
	--********************************
	-- Agent Winloss
	--********************************

	EXEC Age_Rpt_CustCount_AgentViewAgent @AgentID = @AgentID, @FromDate = @FromDate, @ToDate = @ToDate, 
										@MoveBetDay =@MoveBetDay, @BalanceUpDay = @BalanceUpDay, @Sporttypes = @Sporttypes, @Bettypes = @Bettypes
	

	--********************************
	---Member winloss
	--********************************	

	EXEC Age_Rpt_CustCount_AgentViewCust @AgentID = @AgentID, @FromDate = @FromDate, @ToDate = @ToDate, 
									     @MoveBetDay =@MoveBetDay, @BalanceUpDay = @BalanceUpDay, @Sporttypes = @Sporttypes, @Bettypes = @Bettypes

END

		 

------- Get Data  
 SELECT	A.AgentId, ---1 as IsAgent,	
		COUNT(DISTINCT A.CustID) as CustCount
FROM	#CustCountAgent A 
GROUP BY A.AgentId 
UNION ALL
SELECT	0 AS AgentId,--- 0 as IsAgent,	
		COUNT(DISTINCT A.CustID) as CustCount
FROM	#CustCountMember A 
HAVING  COUNT(DISTINCT A.CustID) > 0
---ORDER BY AgentId 


DROP TABLE #CustCountAgent
DROP TABLE #CustCountMember

DROP TABLE #BettypeList
DROp TABLE #SportsList

GO
GRANT EXECUTE ON [Age_Rpt_CustCount] TO [aplweb]
 