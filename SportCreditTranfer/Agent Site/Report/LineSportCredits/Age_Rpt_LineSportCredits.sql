ALTER PROCEDURE [dbo].[Age_Rpt_LineSportCredits]
	@LoggedId INT = 1 ,
	@Username NVARCHAR(50) = 'super'
AS

SET NOCOUNT ON 
 
CREATE TABLE #LineSportCredits (AgentLevel SMALLINT, Outstanding MONEY, Remaining MONEY)

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
	CREATE TABLE #TableCust (AgentLevel SMALLINT,CustId INT )

	INSERT INTO #TableAgent (AgentId, AgentLevel)
	SELECT cai.AgentId, cai.AgentLevel
	FROM AgentInfo AS ai WITH (NOLOCK)
		INNER JOIN AgentInfo AS cai WITH (NOLOCK)
			ON cai.AgentHId.IsDescendantOf(ai.AgentHId) = 1
	WHERE ai.AgentId = @AgentId
	
	INSERT INTO #TableCust 
	SELECT  A.AgentLevel, C.CustId
	FROM CustInfo C WITH (NOLOCK) 
	RIGHT JOIN #TableAgent A 
		ON A.AgentId = C.AgentId
			
	INSERT INTO #LineSportCredits
	SELECT C.AgentLevel, SUM(CASE WHEN StatusID IN (0,1) THEN ABS(ISNULL(B.actual_stake,0)) ELSE 0 END) AS Outstanding, ISNULL(SUM(B.Winlost - B.Actual_Stake + B.PlayerComm),0) AS Remaining
	FROM Bettrans B WITH (NOLOCK)
	RIGHT JOIN #TableCust C
		ON C.CustId = b.CustID
	GROUP BY C.AgentLevel

	DROP TABLE #TableAgent
	DROP TABLE #TableCust
END


SELECT * FROM #LineSportCredits
ORDER BY AgentLevel  
 
DROP TABLE #LineSportCredits

GO 
GRANT EXECUTE ON [Age_Rpt_LineSportCredits] To [Aplweb]
GO
 