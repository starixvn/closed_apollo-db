USE [LogDB]
GO
/****** Object:  StoredProcedure [dbo].[ReadLog_RunSpAgent]    Script Date: 11/21/2013 1:00:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[ReadLog_RunSpAgent]	
	@ActorAgentId	INT	
	,@Username		NVARCHAR(50)	= ''	
	,@ActionTypeId	INT				= 0
	,@From			DATETIME
	,@To			DATETIME
	,@PageIndex		INT
	,@PageSize		INT
	,@TotalRows		INT				= 0		OUTPUT
	,@Language		VARCHAR(5)		= 'en-US'	
AS

/*  
 * Created: 05162013@Edward
 * Task : Search execute SP log
 * DB: SVRLOG.LogDB
 *  
 * Revisions:	
 - 20131129@Sophia: Enhance Sps		
 * Param's Explanation: 
*/

BEGIN
	
	SET NOCOUNT ON
	
	--CREATE TABLE  #TempUsername  (
	--	AgentId		INT,
	--	AgentHId	HIERARCHYID )
	
	--CREATE TABLE  #TempActor  (	
	--	AgentHId	HIERARCHYID	 )


	DECLARE 
		@agentId		INT,
		@agentHId		HIERARCHYID,
		@actorAgentHId	HIERARCHYID,
		@isCheck		BIT = 1 

	--SELECT @Str = 'SELECT * FROM OPENQUERY(SVRAGE, ''SELECT AgentId, AgentHId FROM [RepDB].[dbo].[AgentInfo] WITH (NOLOCK) WHERE username = '''''+ @Username+''''' '')'  ----OR AgentId = '+ CONVERT(VARCHAR(20),@ActorAgentId)+ ''')'  
	--PRINT @Str

	--INSERT INTO #TempUsername
	--EXEC (@Str)
	
	--SELECT 	@agentId = AgentId,
	--		@agentHId = AgentHId
	--FROM	#TempUsername

 -------------------------------------------------
	
	--SELECT @Str2 = 'SELECT * FROM OPENQUERY(SVRAGE, ''SELECT AgentHId FROM [RepDB].[dbo].[AgentInfo] WITH (NOLOCK) WHERE AgentId = '+ CONVERT(VARCHAR(20),@ActorAgentId)+ ''')'  
	--PRINT @Str2

	--INSERT INTO #TempActor
	--EXEC (@Str2)

	--SELECT @actorAgentHId = AgentHId
	--FROM  #TempActor


	
	SELECT 	@agentId = AgentId,
			@agentHId = AgentHId
	FROM	RepDB.dbo.AgentInfo WITH (NOLOCK)
	WHERE	Username = @Username

 ----------------------------------------------- 

	SELECT @actorAgentHId = AgentHId
	FROM RepDB.dbo.AgentInfo WITH (NOLOCK) 
	WHERE AgentId = @ActorAgentId
	

	IF @agentHId.IsDescendantOf(@actorAgentHId) <> 1
	BEGIN
		---SET @isCheck = 0	
		
		SELECT 
			CONVERT (bigint, 0) as LogId,
			CONVERT (datetime, '') as LogDate,
			CONVERT (nvarchar(50), '') as Username,
			CONVERT (nvarchar(50), '') as AdminUsername,
			CONVERT (int, 0) as ActionTypeId,
			CONVERT (nvarchar(256), '') as ActionName,
			CONVERT (nvarchar(max), '') as OldData,
			CONVERT (nvarchar(max), '') as Data 
		WHERE 1 = 2
		RETURN  
	END

	-- gets total rows
	SET @TotalRows = (	SELECT COUNT(1)
						FROM 
							dbo.RunSpAgent AS rsa WITH (NOLOCK)
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON rsa.ActionId = la.ActionId
						WHERE 
							(@ActionTypeId = 0 OR la.ActionTypeId  = @ActionTypeId OR (@ActionTypeId = 5 AND la.ActionTypeId =6))
							AND rsa.LogDate BETWEEN @From AND @To
							AND rsa.AgentID = @agentId
							AND @isCheck = 1
						)
 
	SELECT 
		rsa.LogId,
		rsa.LogDate,
		ag.username as Username,
		adi.Username AS AdminUsername,
		CASE WHEN la.ActionTypeId = 6 THEN 5 ELSE la.ActionTypeId END AS ActionTypeId,
		CASE @Language	
			WHEN 'en-US' THEN la.ActionNameEN 
			WHEN 'zh-CN' THEN la.ActionNameCT	
			WHEN 'zh-TW' THEN la.ActionNameCS
			WHEN 'th-TH' THEN la.ActionNameTH
			WHEN 'ja-JP' THEN la.ActionNameJP
			WHEN 'ko-KR' THEN la.ActionNameKO
			WHEN 'es-ES' THEN la.ActionNameES
			WHEN 'vi-VN' THEN la.ActionNameVI
			ELSE la.ActionNameEN 
		END	AS ActionName,
		rsa.OldData,
		rsa.Data 
	FROM 
		dbo.RunSpAgent AS rsa WITH (NOLOCK)			
		INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON rsa.ActionId = la.ActionId
		LEFT JOIN RepDB.dbo.AdminInfo AS adi WITH (NOLOCK) ON rsa.AdminId = adi.AdminId
		LEFT JOIN RepDB.dbo.AgentInfo AS ag WITH (NOLOCK) ON rsa.userId= ag.AgentId
	WHERE 
		(@ActionTypeId = 0 OR la.ActionTypeId  = @ActionTypeId OR (@ActionTypeId = 5 AND la.ActionTypeId =6))
		AND rsa.LogDate BETWEEN @From AND @To
		AND rsa.AgentID = @agentId
		AND @isCheck = 1

	ORDER BY rsa.LogDate DESC, rsa.LogId DESC 
	OFFSET (@PageIndex-1)*@PageSize ROWS
	FETCH NEXT @PageSize ROWS ONLY

	--DROP TABLE #TempActor
	--DROP TABLE #TempUsername

END


