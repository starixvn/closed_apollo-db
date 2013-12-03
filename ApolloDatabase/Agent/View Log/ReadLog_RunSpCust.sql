USE [LogDB]
GO
/****** Object:  StoredProcedure [dbo].[ReadLog_RunSpCust]    Script Date: 11/22/2013 11:13:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[ReadLog_RunSpCust]
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
 - 20131129@Sophia: Enhance Sps	
 * Param's Explanation: 
*/

BEGIN
	
	SET NOCOUNT ON
	
	--CREATE TABLE  #TempUsername  (
	--	AgentId		INT,
	--	CustId		INT,
	--	UGroup		VARCHAR(3) )
	
	--CREATE TABLE  #TempAgent  (	
	--	AgentID		INT,
	--	AgentHId	HIERARCHYID,
	--	Username	NVARCHAR(50) )


	DECLARE 
		@agentHId		HIERARCHYID,
		@actorAgentHId	HIERARCHYID,
		@agentId		INT,
		@CustId			INT,
		@UGroup			VARCHAR(3),
		@isCheck		BIT	= 1	


	--SELECT @Str = 'SELECT * FROM OPENQUERY(SVRAGE, ''SELECT AgentId, CustId, UGroup FROM [RepDB].[dbo].[CustInfo] WITH (NOLOCK) WHERE Username = '''''+ @Username+''''' '')' 
	----PRINT @Str

	--INSERT INTO #TempUsername
	--EXEC (@Str)
		
	--SELECT 	@AgentId = AgentId,
	--		@CustId= CustId,
	--		@UGroup = UGroup
	--FROM	#TempUsername
	 
	----------------------------

	--SELECT @Str2 = 'SELECT * FROM OPENQUERY(SVRAGE, ''SELECT AgentID, AgentHId, Username FROM [RepDB].[dbo].[AgentInfo] WITH (NOLOCK) WHERE AgentId IN ('+ CONVERT(VARCHAR(20),@ActorAgentId)+ ' , '+CONVERT(VARCHAR(20),@AgentId)+')'')'  
	----PRINT @Str2

	--INSERT INTO #TempAgent
	--EXEC (@Str2)

	--SELECT	@actorAgentHId = AgentHId, @ActorUsername = Username
	--FROM	#TempAgent
	--WHERE	AgentID = @ActorAgentId
	
	  
	--SELECT	@agentHId = AgentHId
	--FROM	#TempAgent
	--WHERE	AgentId = @agentId
	 
	--------------------------	

	SELECT 	@AgentId = AgentId,
			@CustId= CustId,
			@UGroup = UGroup
	FROM	RepDB.dbo.CustInfo WITH (NOLOCK)
	WHERE	Username = @Username


	SELECT	@actorAgentHId = AgentHId
	FROM	RepDB.dbo.AgentInfo WITH (NOLOCK)
	WHERE	AgentID = @ActorAgentId
	
	  
	SELECT	@agentHId = AgentHId
	FROM	RepDB.dbo.AgentInfo WITH (NOLOCK)
	WHERE	AgentId = @agentId


	--------------------------	

	IF @agentHId.IsDescendantOf(@actorAgentHId) <> 1
		BEGIN
			--SET @isCheck = 0

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
	SET @TotalRows = (
						SELECT COUNT(1)
						FROM RunSpCust AS rsc WITH (NOLOCK)	
							INNER JOIN LogAction AS la WITH (NOLOCK) ON rsc.ActionId = la.ActionId
						WHERE 
							(@ActionTypeId = 0 OR la.ActionTypeId = @ActionTypeId OR (@ActionTypeId = 5 AND la.ActionTypeId =6))
							AND rsc.LogDate BETWEEN @From AND @To
							AND rsc.CustID = @CustId
							AND @isCheck = 1 
					 )						 
						

			SELECT 
				rsc.LogId,
				rsc.LogDate,
				ui.Username,
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
				rsc.OldData,
				rsc.Data 
			FROM 
				RunSpCust AS rsc WITH (NOLOCK)			
				INNER JOIN LogAction AS la WITH (NOLOCK) ON rsc.ActionId = la.ActionId
				INNER JOIN RepDB.dbo.AgentInfo AS ui ON rsc.UserId = ui.AgentId
				LEFT JOIN RepDB.dbo.AdminInfo AS adi WITH (NOLOCK) ON rsc.AdminId = adi.AdminId
			WHERE 
				(@ActionTypeId = 0 OR la.ActionTypeId  = @ActionTypeId OR (@ActionTypeId = 5 AND la.ActionTypeId =6))
				AND rsc.LogDate BETWEEN @From AND @To
				AND rsc.CustId = @CustId
				AND @isCheck = 1 
			ORDER BY rsc.LogDate DESC , rsc.LogId DESC 
			OFFSET (@PageIndex-1)*@PageSize ROWS
			FETCH NEXT @PageSize ROWS ONLY

		
END