ALTER PROCEDURE [dbo].[ReadLog_RunSpAgent_xtest]	
	@ActorAgentId	INT	
	,@Username		NVARCHAR(50)	= ''	
	,@ActionTypeId	INT				= 0
	,@From			DATETIME
	,@To			DATETIME
	,@PageIndex		INT
	,@PageSize		INT
	,@TotalRows		INT				= 0			OUTPUT
	,@Language		VARCHAR(5)		= 'en-US'	
AS

/*  
 * Created: 05162013@Edward
 * Task : Search execute SP log
 * DB: SVRLOG.LogDB
 *  
 * Revisions:		
 * Param's Explanation: 
*/

BEGIN
	
	SET NOCOUNT ON

	DECLARE 
		@dynamicQuery			NVARCHAR(MAX)
		,@dynamicQueryTotalItem	NVARCHAR(MAX)

	IF @Language IS NULL 
		SET @Language = 'en-US'

	SET @dynamicQueryTotalItem = 'SELECT * FROM OPENQUERY(SVRAGE,''		
		SELECT COUNT(1)
		FROM 
			SVRLOG.LogDB.dbo.RunSpAgent AS rsa WITH (NOLOCK)
			INNER JOIN [RepDB].[dbo].[AgentInfo] AS ai ON rsa.AgentId = ai.AgentId
			LEFT JOIN [RepDB].[dbo].[AgentInfo] AS ui ON rsa.UserId = ui.AgentId
			INNER JOIN SVRLOG.LogDB.dbo.LogAction AS la WITH (NOLOCK) ON rsa.ActionId = la.ActionId
		WHERE 
			('+CAST(@ActionTypeId AS VARCHAR)+' = 0 OR la.ActionTypeId  = '+CAST(@ActionTypeId AS VARCHAR)+' OR ('+CAST(@ActionTypeId AS VARCHAR)+' = 5 AND la.ActionTypeId =6))
			AND rsa.LogDate BETWEEN '''''+CAST(@From AS VARCHAR)+''''' AND '''''+CAST(@To AS VARCHAR)+'''''
			AND ai.Username = '''''+CAST(@Username AS NVARCHAR)+''''''+''')'

	SET @dynamicQuery = 'SELECT * FROM OPENQUERY(SVRAGE,''
		DECLARE @TotalRows INT
		,@FirstRec INT
		,@LastRec INT

	SELECT 
		@FirstRec	= (('+CAST(@PageIndex AS VARCHAR)+' - 1) * '+CAST(@PageSize AS VARCHAR)+') + 1
		,@LastRec	= (('+CAST(@PageIndex AS VARCHAR)+'* '+CAST(@PageSize AS VARCHAR)+' + 1)) - 1	
	
	DECLARE 
		@agentId		INT,
		@agentHId		HIERARCHYID,
		@actorAgentHId	HIERARCHYID,
		@isCheck		BIT				= 1

	SELECT @actorAgentHId = AgentHId
	FROM [RepDB].[dbo].[AgentInfo] WITH (NOLOCK)
	WHERE AgentId = '+CAST(@ActorAgentId AS VARCHAR)+'

	SELECT 
		@agentId = AgentId,
		@agentHId = AgentHId
	FROM [RepDB].[dbo].[AgentInfo] WITH (NOLOCK)
	WHERE Username = '''''+CAST(@Username AS NVARCHAR)+'''''

	IF @agentHId.IsDescendantOf(@actorAgentHId) <> 1
		BEGIN
			SET @isCheck = 0	
		END	

	-- gets data
	SELECT TOP ('+CAST(@PageSize AS VARCHAR)+') *
	FROM (
			SELECT 
				rsa.LogId,
				rsa.LogDate,
				ui.Username,
				adi.Username AS AdminUsername,
				CASE WHEN la.ActionTypeId = 6 THEN 5 ELSE la.ActionTypeId END AS ActionTypeId,
				CASE '''''+CAST(@Language AS VARCHAR)+'''''	
					WHEN '''''+ CAST('en-US' AS VARCHAR(5)) + ''''' THEN la.ActionNameEN 
					WHEN '''''+ CAST('zh-CN' AS VARCHAR(5)) + ''''' THEN la.ActionNameCT	
					WHEN '''''+ CAST('zh-TW' AS VARCHAR(5)) + ''''' THEN la.ActionNameCS
					WHEN '''''+ CAST('th-TH' AS VARCHAR(5)) + ''''' THEN la.ActionNameTH
					WHEN '''''+ CAST('ja-JP' AS VARCHAR(5)) + ''''' THEN la.ActionNameJP
					WHEN '''''+ CAST('ko-KR' AS VARCHAR(5)) + ''''' THEN la.ActionNameKO
					WHEN '''''+ CAST('es-ES' AS VARCHAR(5)) + ''''' THEN la.ActionNameES
					WHEN '''''+ CAST('vi-VN' AS VARCHAR(5)) + ''''' THEN la.ActionNameVI
					ELSE la.ActionNameEN 
				END	AS ActionName,
				rsa.OldData,
				rsa.Data,
				ROW_NUMBER() OVER (ORDER BY rsa.LogDate DESC) AS num
			FROM 
				SVRLOG.LogDB.dbo.RunSpAgent AS rsa WITH (NOLOCK)
				INNER JOIN [RepDB].[dbo].[AgentInfo] AS ai ON rsa.AgentId = ai.AgentId	
				LEFT JOIN [RepDB].[dbo].[AgentInfo] AS ui ON rsa.UserId	= ui.AgentId
				INNER JOIN SVRLOG.LogDB.dbo.LogAction AS la WITH (NOLOCK) ON rsa.ActionId = la.ActionId
				LEFT JOIN SVRAGE.RepDB.dbo.AdminInfo AS adi WITH (NOLOCK) ON rsa.AdminId = adi.AdminId
			WHERE 
				('+CAST(@ActionTypeId AS VARCHAR)+' = 0 OR la.ActionTypeId  = '+CAST(@ActionTypeId AS VARCHAR)+' OR ('+CAST(@ActionTypeId AS VARCHAR)+' = 5 AND la.ActionTypeId =6))
				AND rsa.LogDate BETWEEN '''''+CAST(@From AS VARCHAR)+''''' AND '''''+CAST(@To AS VARCHAR)+'''''
				AND ai.Username = '''''+CAST(@Username AS NVARCHAR)+'''''
		) AS Temp
	WHERE 
		@isCheck = 1 
		AND Temp.num BETWEEN @FirstRec AND @LastRec
	ORDER BY Temp.num'+''')'
	
	DECLARE @out TABLE (TotalItem INT)	
	INSERT INTO @out
	EXEC (@dynamicQueryTotalItem)

	SELECT TOP(1) @TotalRows  = TotalItem
	FROM @out
	
	EXEC (@dynamicQuery)
END

