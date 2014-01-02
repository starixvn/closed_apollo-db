USE [bodb_NAP]
GO
/****** Object:  StoredProcedure [dbo].[NAP_MailingList_UpdateStatus]    Script Date: 10/29/2013 12:40:36 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_MailingList_UpdateStatus]
	@ListId				INT,
	@IsActive			BIT,
	@ModifiedBy			INT, 
	@ModifiedDate		DATETIME,
	@CurrentUserId		INT,
	@CurrentSiteId		INT	,
	@LogDate			DATETIME,
	@LoginIP			VARCHAR(30)			= '',
	@Language			VARCHAR(20)			= 'en-us',
	@ErrCode			INT					= 0			OUTPUT, 
	@ErrMsg				NVARCHAR(1000)		= ''		OUTPUT 
AS

/*  
 * Created	: 20131001@Quinn
 * Task		: Update status of mailing list
 * DB		: bodb_NAP
 *  
 * Revisions:     
 * Param's Explanation: 
	• Main	:	
				<root><xml path="r" />
					<row item="ListName" alias="ln" />
					<row item="IsActive" alias="i" />
				</root>
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

	-- Write log before update
	SET @xml = (
		SELECT 
			ListName	AS '@li', 
			IsActive	AS '@i'
		FROM dbo.MailingList WITH (NOLOCK)
		WHERE ListId = @ListId
		FOR XML PATH('r'), TYPE
	)

	SET @logSPDataOld = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')	

	-- Update menu item information
	UPDATE dbo.MailingList WITH (ROWLOCK, UPDLOCK)
	SET	
		IsActive		= @IsActive,
		ModifiedBy		= @ModifiedBy,
		ModifiedDate	= @ModifiedDate
	WHERE ListId = @ListId

	-- Check error
	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 1, 
				@ErrMsg = 'Fail to update status of the ListId ' + CONVERT(VARCHAR(10), @ListId)
			RETURN
		END		

	-- Write log after update
	SET @xml = (
		SELECT 
			ListName	AS '@li', 
			@IsActive	AS '@i'
		FROM dbo.MailingList WITH (NOLOCK)
		WHERE ListId = @ListId
		FOR XML PATH('r'), TYPE
	)	

	SET @logSPData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')
		
	SET @endRun = GETDATE()
	SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun)

	EXEC bodb_NAPLOG.dbo.NAP_LogRunSp_Insert 
		@UserId			= @CurrentUserId,
		@SPName			= 'NAP_MailingList_UpdateStatus',
		@ObjectId		= @ListId,
		@ObjectTypeId	= 7,			--Object type : Mailing list item
		@Language		= @Language,
		@SiteID			= @CurrentSiteId,
		@IP				= @LoginIP,
		@Date			= @LogDate,
		@Data			= @logSPData,
		@OldData		= @logSPDataOld,
		@Duration		= @Duration

END

