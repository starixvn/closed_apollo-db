ALTER  PROCEDURE [dbo].[Age_AgentUser_AssignFunction_xtest]	
	@ActorAgentId		INT				= NULL
	,@AdminId			INT				= NULL
	,@AgentUserId		INT	
	,@Permission		VARCHAR(MAX)
	,@IsApplyDownLine	SMALLINT		= 0
	,@Language			VARCHAR(5)		= 'en-US'
	,@ErrCode			INT				= 0			OUTPUT
	,@ErrMsg			NVARCHAR(1000)	= ''		OUTPUT	
AS

/**
 * Created by	: Edward
 * Date			: 20131002
 * Task			: Get assign function to agent user
 * DB			: SVRCUST.CustDB
 * Revisions	:
 *	• 20131113@Sophia: Add execrep, change param @IsApplyDownLine
 * Parameters:
 *	• @Permission : '<ROOT><FunctionPolicy FunctionId="1" Policy="2"></ROOT>'
 *	• @IsApplyDownLine =   
				+ Check : Yes = 1
						  No = 0
				+ Uncheck: = -1 
 *  
 */

BEGIN
	
	SET NOCOUNT ON			  	

	-- For write log
    DECLARE 
		@startRun		DATETIME,
		@endRun			DATETIME,
		@duration		INT,
		@logSPData		VARCHAR(5000),
		@logSPDataOld	VARCHAR(5000),
		@xml			XML

	SET @startRun = GETDATE()

	DECLARE @AgentId		INT
			,@AgentHId		HIERARCHYID
			,@IsMaster		BIT
			,@ParentId		INT
			,@ParentAgentId	INT
			,@AgentUsername	NVARCHAR(50)

	DECLARE @FunctionPolicy TABLE (FunctionId SMALLINT, Policy TINYINT)

	SELECT @AgentId			= AgentId
			,@IsMaster		= IsMaster
			,@AgentUsername	= CASE WHEN IsMaster = 0 THEN Username ELSE '' END
	FROM AgentUser WITH (NOLOCK)
	WHERE AgentUserId = @AgentUserId

	SELECT @AgentHId		= AgentHId
		  ,@ParentAgentId	= ParentId
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @AgentId

	-- write log before update
				
	SET @xml = (
		SELECT  
			f.FunctionKey		AS '@f'			
			,fg.GroupKey		AS '@fg'						
			,auf.Policy			AS '@pl'			
		FROM AgentUserFunction AS auf WITH (NOLOCK)			
			INNER JOIN [Function] AS f WITH (NOLOCK)
				ON auf.FunctionId = f.FunctionId	
			INNER JOIN FunctionGroup AS fg WITH (NOLOCK)
				ON f.FunctionGroupId = fg.FunctionGroupId		
		WHERE AgentUserId = @AgentUserId	
			AND f.IsActive = 1		
		ORDER BY fg.DisplayOrder, f.DisplayOrder
		FOR XML PATH('z')
	)

	SET @logSPDataOld = '<r u="'+@AgentUsername+'" ia="'+CONVERT(VARCHAR(2),@IsApplyDownLine)+'">'+ REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')+'</r>'

	-- end write log			

	IF @ActorAgentId <>  @AgentId
	BEGIN
		-- Check update permission
		DECLARE @hasPermission BIT

		EXEC dbo.Age_Agent_CheckUpdatePermission @ActorAgentId, @AgentId, 1, @hasPermission OUTPUT 
	
		IF @hasPermission = 0
			BEGIN
				SELECT	
					@ErrCode = 5317,
					@ErrMsg = 
						CASE @Language
							WHEN 'en-US' THEN 'Sorry! You need permission to perform this action.'
							ELSE [dbo].f_Msg_GetContentById (5317, @Language)
						END
				RETURN
			END			
	END

	-- For read xml
	DECLARE @DocHandler INT

	EXEC sp_xml_preparedocument @DocHandler OUTPUT, @Permission

	INSERT INTO @FunctionPolicy (
		FunctionId
		,Policy)
	SELECT
		Data.FunctionId,
		Data.Policy
	FROM OPENXML (@DocHandler, '/ROOT/FunctionPolicy',1) 
	WITH (			
		FunctionId		SMALLINT,
		Policy			TINYINT
	) AS Data

	EXEC sp_xml_removedocument @DocHandler
	-- end read xml

	-- Get parent id
	IF @IsMaster = 1 
	BEGIN
		SELECT @ParentId = AgentUserId
		FROM AgentUser WITH (NOLOCK)
		WHERE AgentId		= @ParentAgentId
			AND IsMaster	= 1		
	END
	ELSE
	BEGIN
		SELECT @ParentId = AgentUserId
		FROM AgentUser WITH (NOLOCK)
		WHERE AgentId		= @AgentId
			AND IsMaster	= 1				
	END

	IF EXISTS( SELECT TOP(1) *
				FROM AgentUserFunction AS auf WITH (NOLOCK)
					INNER JOIN @FunctionPolicy AS fp 
						ON auf.FunctionId = fp.FunctionId
				WHERE auf.AgentUserId = @ParentId
					AND fp.Policy > auf.Policy)
	BEGIN
		SELECT	
				@ErrCode = 5317,
				@ErrMsg = 
					CASE @Language
						WHEN 'en-US' THEN 'Sorry! You need permission to perform this action.'
						ELSE [dbo].f_Msg_GetContentById (5317, @Language)
					END
		RETURN
	END


	--Update Policy = 0 for function not set to user and his downline	
	IF @IsMaster = 1
	BEGIN
		EXEC Acc_ExecRep_00 @AgentId = @AgentId, @Permission = @Permission, @IsApplyDownline = @IsApplyDownline
	END
	
	
	---  Itself or shadow only 
	UPDATE auf
	SET auf.Policy = f.Policy
	FROM AgentUserFunction AS auf WITH (ROWLOCK, UPDLOCK)	
		INNER JOIN @FunctionPolicy AS f
			ON auf.FunctionId = f.FunctionId			
	WHERE auf.AgentUserId = @AgentUserId			
	
	-- write log after update
				
	SET @xml = (
		SELECT  
			f.FunctionKey		AS '@f'			
			,fg.GroupKey		AS '@fg'						
			,auf.Policy			AS '@pl'					
		FROM AgentUserFunction AS auf WITH (NOLOCK)
			INNER JOIN [Function] AS f WITH (NOLOCK)
				ON auf.FunctionId = f.FunctionId	
			INNER JOIN FunctionGroup AS fg WITH (NOLOCK)
				ON f.FunctionGroupId = fg.FunctionGroupId				
		WHERE AgentUserId = @AgentUserId			
			AND f.IsActive = 1
		ORDER BY fg.DisplayOrder, f.DisplayOrder
		FOR XML PATH('z')
	)

	SET @logSPData = '<r u="'+@AgentUsername+'" ia="'+CONVERT(VARCHAR(2),@IsApplyDownLine)+'">'+REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')+'</r>'

	-- end write log

	SET @endRun		= GETDATE()
	SET @duration	= DATEDIFF(MILLISECOND, @startRun, @endRun) 
		
	IF @@ERROR = 0
		BEGIN TRY
			EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpAgent
				@UserId		= @ActorAgentId,
				@AdminId	= @AdminId,
				@SPName		= 'Age_AgentUser_AssignFunction',
				@LogDate	= @startRun,
				@AgentId	= @AgentId,
				@Duration	= @Duration,
				@Data		= @logSPData,
				@OldData	= @logSPDataOld
		END	TRY
		BEGIN CATCH
			EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpAgent
				@UserId		= @ActorAgentId,
				@AdminId	= @AdminId,
				@SPName		= 'Age_AgentUser_AssignFunction',
				@LogDate	= @startRun,
				@AgentId	= @AgentId,
				@Duration	= @Duration,
				@Data		= @logSPData,
				@OldData	= @logSPDataOld
		END CATCH 
END						  



