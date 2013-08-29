ALTER PROCEDURE [dbo].[NAP_MailingList_Update]
	@FunctionId			SMALLINT,
	@ToList				NVARCHAR(MAX) = '',
	@CCLIST				NVARCHAR(MAX) = '',
	@BBCList			NVARCHAR(MAX) = '',
	@ModifiedBy			INT	= NULL,
	@ModifiedDate		DATETIME,
	@CurrentUserId		INT,
	@CurrentSiteId		INT,
	@LogDate			DATETIME,
	@LoginIP			VARCHAR(30)		= '',
	@Language			VARCHAR(20)		= 'en-us',
	@ErrCode			INT				= 0	OUTPUT, 
	@ErrMsg				NVARCHAR(1000)	= '' OUTPUT 
AS
SET NOCOUNT ON
	-- For write log
	DECLARE 
		@startRun		DATETIME,
		@endRun			DATETIME,
		@duration		INT,
		@logSPData		VARCHAR(5000),
		@logSPDataOld	VARCHAR(5000),
		@xml			XML,
		@ListID			INT

	SET @startRun = GETDATE()	

	-- write log before update	 
	SET @xml = (
		SELECT 
				ListId		AS '@li'
				,FunctionId	AS '@fi'
				,ToList		AS '@to'
				,CCList		AS '@cc'			
				,BCCList	AS '@bc'		
		FROM	MailingList WITH(NOLOCK)
		WHERE	FunctionId = @FunctionId	
		FOR XML PATH('r'), TYPE
	)	

	SET @logSPDataOld = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')
	

	-- Update function information
	UPDATE	MailingList WITH (ROWLOCK, UPDLOCK)
	SET		ToList = @ToList,
			CCLIST = @CCLIST,
			BCCList = @BBCList,
			ModifiedBy = @ModifiedBy,
			ModifiedDate = @ModifiedDate	
	WHERE	FunctionId = @FunctionId
	
	Select @listID FROM MailingList WITH (NOLOCK)
	WHERE	FunctionId = @FunctionId 

	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 1, 
				@ErrMsg = 'Fail to update information of the FunctionId ' + CONVERT(VARCHAR(10), @FunctionId)
			RETURN
		END		
	ELSE

	-- Write log after update
		SET @xml = (
		SELECT 	ListId		AS '@li'
				,FunctionId	AS '@fi'
				,ToList		AS '@to'
				,CCList		AS '@cc'			
				,BCCList	AS '@bc'		
		FROM	MailingList WITH(NOLOCK)
		WHERE	FunctionId = @FunctionId	
		FOR XML PATH('r'), TYPE
	)	

	SET @logSPData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')
		
	SET @endRun		= GETDATE()  
	SET @duration	= DATEDIFF(MILLISECOND, @startRun, @endRun)

	EXEC bodb_NAPLOG.dbo.NAP_LogRunSp_Insert 
		@UserId			= @CurrentUserId,
		@SPName			= 'NAP_Function_Update',
		@ObjectId		= @ListId,
		@ObjectTypeId	= 7,					-- Object type : Mailing List
		@Language		= @Language,
		@SiteID			= @CurrentSiteId,
		@IP				= @LoginIP,
		@Date			= @LogDate,
		@Data			= @logSPData,
		@OldData		= @logSPDataOld,
		@Duration		= @Duration

GO
GRANT EXECUTE ON [NAP_MailingList_Update] TO [bodbAdminNet]
GO
