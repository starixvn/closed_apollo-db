ALTER PROCEDURE [dbo].[Age_Rpt_LineSportCredits]
	@LoggedId INT = 1 ,
	@Username NVARCHAR(50) = 'super'
AS


/*
Created:  20130802@Sophia
Task :	Shows the Total Remaining Credit and Total Outstanding Credit of direct members grouped by Level
DB:		SVRAGE/REPDB
Original: 

Revisions:
		- 20150212@Sophia: Modify Remaining Credit by Sport Credit + Member direct  [RedmineId:#30989]
Param's Explanation:

*/

SET NOCOUNT ON 
 
CREATE TABLE #LineSportCredits (AgentLevel SMALLINT, Outstanding MONEY, Remaining MONEY, AgentId INT )

DECLARE @LoggedHId HierarchyId, @AgentId INT, @AgentHId HierarchyId, @AgentLevel SMALLINT

SELECT	@LoggedHId = AgentHId
FROM	AgentInfo WITH (NOLOCK)
WHERE	AgentId = @LoggedId

SELECT	@AgentId = AgentId
FROM	AgentInfo A WITH (NOLOCK)
WHERE	A.Username = @Username
		AND A.AgentHID.IsDescendantOf(@LoggedHId) = 1
 
  
IF @AgentId IS NOT NULL
BEGIN 
	CREATE TABLE #TableAgent (AgentId INT,AgentLevel SMALLINT)
	CREATE TABLE #TableCust (AgentLevel SMALLINT,CustId INT, AgentId INT)

	INSERT INTO #TableAgent (AgentId, AgentLevel)
	SELECT cai.AgentId, cai.AgentLevel
	FROM AgentInfo AS ai WITH (NOLOCK)
		INNER JOIN AgentInfo AS cai WITH (NOLOCK)
			ON cai.AgentHId.IsDescendantOf(ai.AgentHId) = 1
	WHERE ai.AgentId = @AgentId
	
	INSERT INTO #TableCust (AgentLevel, CustId, AgentId)
	SELECT  A.AgentLevel, C.CustId, A.AgentId
	FROM CustInfo C WITH (NOLOCK) 
	RIGHT JOIN #TableAgent A 
		ON A.AgentId = C.AgentId

			
	INSERT INTO #LineSportCredits (AgentLevel,AgentId, Outstanding,Remaining  )
	SELECT	C.AgentLevel, C.AgentId,
			SUM(CASE WHEN StatusID IN (0,1) AND B.Bettype <= 19000 THEN ABS(ISNULL(B.actual_stake,0)) ELSE 0 END) AS Outstanding,
			ISNULL(SUM(B.Winlost - B.Actual_Stake + B.PlayerComm),0) AS Remaining
	FROM Bettrans B WITH (NOLOCK)
	RIGHT JOIN #TableCust C
		ON C.CustId = b.CustID	
	GROUP BY C.AgentLevel, C.AgentId

	DROP TABLE #TableAgent
	DROP TABLE #TableCust

	----------------------
	 
	UPDATE	L
	SET		Remaining = Remaining + ISNULL(Balance,0)
	FROM	#LineSportCredits L
		LEFT JOIN CreditBalance_Agent C 
			ON C.AgentId = L.AgentId 

END
 

SELECT  AgentLevel, SUM(Outstanding) AS Outstanding , CASE WHEN AgentLevel > 1 THEN SUM(Remaining) ELSE 0 END AS Remaining
FROM	#LineSportCredits
GROUP BY AgentLevel 
ORDER BY AgentLevel  
 
DROP TABLE #LineSportCredits

GO 
GRANT EXECUTE ON [Age_Rpt_LineSportCredits] To [Aplweb]
GO
 