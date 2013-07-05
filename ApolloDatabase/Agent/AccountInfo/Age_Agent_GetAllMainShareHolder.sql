ALTER PROCEDURE [dbo].[Age_Agent_GetAllMainShareHolder]
	@Bettypes VARCHAR(500) = '0'
AS

/**
 * Created by	: Ricky
 * Date			: 20130426
 * Task			: Get all Main Shareholder Id and UserName
 * DB			: SVRAGE.RepDB
 * Revisions	:
	-  20130508@Sophia: Check Main Shareholder's member having running tickets and filter by bettypes
	-  20130703@Sophia: Revise
 * Parameters:
 *	•
 *	•
 *  
 */
	
SET NOCOUNT ON
	
IF @Bettypes = '0'
	SELECT	DISTINCT A.AgentId, 
			A.Username
	FROM	AgentInfo A WITH (NOLOCK)
	INNER JOIN  Bettrans_Agent BA WITH (NOLOCK) 
			ON A.AgentID = BA.AgentID
	WHERE	A.ParentId = 0				
			AND BA.StatusID IN (0,1)
	ORDER BY A.Username

ELSE  
BEGIN 
	DECLARE @BettypeList  table (bettype SMALLINT)
	INSERT INTO @BettypeList 
	SELECT val FROM dbo.strSplit_Key(@Bettypes,',')
	/*
	SELECT	DISTINCT A.AgentId, A.Username
	FROM	AgentInfo A WITH (NOLOCK)
	INNER JOIN  Bettrans_Agent BA WITH (NOLOCK) 
			ON A.AgentID = BA.AgentID
	WHERE	A.ParentId = 0				
			AND BA.Bettype  IN (SELECT Bettype FROM @BettypeList )
			AND BA.StatusID IN (0,1)
	ORDER BY A.Username
	*/
	SELECT  A.AgentId, A.Username
	FROM	AgentInfo A WITH (NOLOCK)
	WHERE	A.ParentId = 0	
	and exists (select 1
			from Bettrans_Agent BA WITH (NOLOCK) 
			where A.AgentID = BA.AgentID
			AND BA.Bettype IN (SELECT Bettype FROM @BettypeList)
			AND BA.StatusID IN (0,1)
			)
END 

