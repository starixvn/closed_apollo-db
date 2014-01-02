ALTER PROCEDURE [dbo].[ReadLog_RunSpCust_xtest]
	@ActorAgentId		INT	
	,@Username			NVARCHAR(50)	= ''
	,@ActionTypeId		INT				= 0
	,@From				DATETIME
	,@To				DATETIME
	,@PageIndex			INT
	,@PageSize			INT
	,@TotalRows			INT				= 0	OUTPUT	
	,@Language			VARCHAR(5)		= 'en-US'
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

	DECLARE @dynamicQuery			NVARCHAR(MAX)
			,@dynamicQueryTotalItem	NVARCHAR(MAX)
			,@dynamicActorAgentHId	VARCHAR(MAX)		

	DECLARE @actorAgentHId	HIERARCHYID
	DECLARE @TableAgentHId	TABLE(AgentHId HIERARCHYID)

	IF @Language IS NULL 
		SET @Language = 'en-US'	


	SET @dynamicActorAgentHId = 'SELECT * FROM OPENQUERY(SVRAGE,''
		SELECT AgentHId
		FROM RepDB.dbo.AgentInfo WITH (NOLOCK)
		WHERE AgentId = ' + CAST(@ActorAgentId AS VARCHAR) + ''''+')'

	INSERT INTO @TableAgentHId
	EXEC (@dynamicActorAgentHId)

	SELECT TOP(1) @actorAgentHId = AgentHId
	FROM @TableAgentHId
	
	-- gets total rows
	SET @dynamicQueryTotalItem = 'SELECT * FROM OPENQUERY(SVRAGE,''
		SELECT COUNT(1)
		FROM 
			SVRLOG.LogDB.dbo.RunSpCust AS rsc WITH (NOLOCK)
			INNER JOIN RepDB.dbo.CustInfo AS ci WITH (NOLOCK) ON rsc.CustId	= ci.CustId
			INNER JOIN RepDB.dbo.AgentInfo AS ui WITH (NOLOCK) ON rsc.UserId = ui.AgentId
			INNER JOIN SVRLOG.LogDB.dbo.LogAction AS la WITH (NOLOCK) ON rsc.ActionId = la.ActionId
		WHERE 
			(' + CAST(@ActionTypeId AS VARCHAR) + ' = 0 OR la.ActionTypeId  = ' + CAST(@ActionTypeId AS VARCHAR) + ' OR (' + CAST(@ActionTypeId AS VARCHAR) + ' = 5 AND la.ActionTypeId = 6))
			AND rsc.LogDate BETWEEN ''''' + CAST(@From AS VARCHAR) + ''''' AND ''''' + CAST(@To AS VARCHAR) + '''''
			AND ci.Username = '''''+CAST(@Username AS NVARCHAR)+'''''			
			AND (ui.AgentHId.IsDescendantOf(''''' + CAST(@actorAgentHId AS VARCHAR) + ''''') = 1 OR ui.AgentId = 1 )'+''')'		
	 
	SET @dynamicQuery = 'SELECT * FROM OPENQUERY(SVRAGE,''
		DECLARE 
			@FirstRec INT
			,@LastRec INT

		SELECT 
			@FirstRec	= (('+CAST(@PageIndex AS VARCHAR)+' - 1) * '+CAST(@PageSize AS VARCHAR)+') + 1
			,@LastRec	= (('+CAST(@PageIndex AS VARCHAR)+'* '+CAST(@PageSize AS VARCHAR)+' + 1)) - 1	

		DECLARE 
			@agentHId		HIERARCHYID,		
			@agentId		INT,
			@uGroup			VARCHAR(3),
			@isCheck		BIT				= 1		

		SELECT 
			@agentId = AgentId,
			@uGroup	= UGroup
		FROM RepDB.dbo.CustInfo WITH (NOLOCK) 
		WHERE Username = '''''+CAST(@Username AS NVARCHAR)+'''''

		SELECT @agentHId = AgentHId
		FROM RepDB.dbo.AgentInfo WITH (NOLOCK)
		WHERE AgentId = @agentId

		IF @agentHId.IsDescendantOf(''''' + CAST(@actorAgentHId AS VARCHAR) + ''''') <> 1
			BEGIN
				SET @isCheck = 0	
			END

		-- gets data
		SELECT TOP ('+CAST(@PageSize AS VARCHAR)+') *
		FROM (
				SELECT 
					rsc.LogId,
					rsc.LogDate,
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
					rsc.OldData,
					rsc.Data,
					ROW_NUMBER() OVER (ORDER BY rsc.LogDate DESC) AS num
				FROM 
					SVRLOG.LogDB.dbo.RunSpCust AS rsc WITH (NOLOCK)
					INNER JOIN RepDB.dbo.CustInfo AS ci WITH (NOLOCK) ON rsc.CustId = ci.CustId
					INNER JOIN RepDB.dbo.AgentInfo AS ui WITH (NOLOCK) ON rsc.UserId = ui.AgentId
					INNER JOIN SVRLOG.LogDB.dbo.LogAction AS la WITH (NOLOCK) ON rsc.ActionId = la.ActionId
					LEFT JOIN RepDB.dbo.AdminInfo AS adi WITH (NOLOCK) ON rsc.AdminId = adi.AdminId
				WHERE 
					('+CAST(@ActionTypeId AS VARCHAR)+' = 0 OR la.ActionTypeId  = '+CAST(@ActionTypeId AS VARCHAR)+' OR ('+CAST(@ActionTypeId AS VARCHAR)+' = 5 AND la.ActionTypeId =6))
					AND rsc.LogDate BETWEEN '''''+CAST(@From AS VARCHAR)+''''' AND '''''+CAST(@To AS VARCHAR)+'''''
					AND ci.Username = '''''+CAST(@Username AS NVARCHAR)+'''''
					AND (ui.AgentHId.IsDescendantOf(''''' + CAST(@actorAgentHId AS VARCHAR) + ''''') = 1 OR ui.AgentId = 1 )
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

