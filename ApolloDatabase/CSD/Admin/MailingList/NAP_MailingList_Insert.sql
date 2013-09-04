ALTER PROCEDURE [dbo].[NAP_MailingList_Insert]
	@FunctionId			SMALLINT,
	@ToList				NVARCHAR(MAX) = '',
	@CCLIST				NVARCHAR(MAX) = '',
	@BCCList			NVARCHAR(MAX) = '',
	@CreatedBy			INT	= NULL,
	@CreatedDate		DATETIME,
	@CurrentUserId		INT,
	@CurrentSiteId		INT,
	@LogDate			DATETIME,
	@LoginIP			VARCHAR(30)		= '',
	@Language			VARCHAR(20)		= 'en-us',
	@ErrCode			INT				= 0	OUTPUT, 
	@ErrMsg				NVARCHAR(1000)	= '' OUTPUT 
AS

/*  
 * Created	: 20130827@Sophia
 * Task		: Add a new Mailing List
 * DB		:  bodb_NAP
 *  
 * Revisions:
 * Param's Explanation:	
	• Main	:	<root><xml path="r" />
					<row item="ListId" alias="li" />
					<row item="FunctionId" alias="fi" />
					<row item="ToList" alias="to" />
					<row item="CCList" alias="cc" />
					<row item="BCCList" alias="bc" />
				</root>
*/

SET NOCOUNT ON

-- For write log
DECLARE 
	@startRun		DATETIME,
	@endRun			DATETIME,
	@duration		INT,
	@logSPData		VARCHAR(5000),
	@logSPDataOld	VARCHAR(5000),	
	@xml			XML,
	@ListId			SMALLINT

SET @startRun = GETDATE()	

-- Inserts Mailing List
INSERT INTO MailingList (		
		FunctionId,
		ToList,
		CCLIST,
		BCCList,
		CreatedBy,
		CreatedDate,
		ModifiedBy,
		ModifiedDate )
VALUES(	@FunctionId,
		@ToList,
		@CCLIST,
		@BCCList,
		@CreatedBy,
		@CreatedDate,
		@CreatedBy,
		@CreatedDate
		)

 	-- Get ListId, current insert
	SET @ListId = SCOPE_IDENTITY()

	IF @@ERROR > 0
			BEGIN
				SELECT 
					@ErrCode = 1, 
					@ErrMsg = 'Failed to insert Mailing List [ListId = ' + COALESCE(CAST(@ListId AS VARCHAR(10)), SPACE(1)) + ']'
				RETURN
			END		


	-- Write log after insert
	SET @xml = (
		SELECT 
			@ListId			AS '@li'
			,@FunctionId	AS '@fi'
			,@ToList		AS '@to'
			,@CCList		AS '@cc'			
			,@BCCList		AS '@bc'			
		FOR XML PATH('r'), TYPE
	)	

	SET @logSPData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')		
		
	SET @endRun		= GETDATE()
	SET @duration	= DATEDIFF(MILLISECOND, @startRun, @endRun)   

	EXEC bodb_NAPLOG.dbo.NAP_LogRunSp_Insert 
		@UserId			= @CurrentUserId,
		@SPName			= 'NAP_MailingList_Insert',
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
GRANT EXECUTE ON [NAP_MailingList_Insert] TO [bodbAdminNet]
GO


