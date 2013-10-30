USE [bodb_NAP]
GO
/****** Object:  StoredProcedure [dbo].[NAP_MailingList_Update]    Script Date: 10/29/2013 12:39:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_MailingList_Update]
	@ListId				INT,	
	@ListFunctionId		INT,
	@FunctionId			INT,	
	@SiteId				INT,	
	@ListName			NVARCHAR(50),	
	@ListKey			NVARCHAR(50),	
	@Description		NVARCHAR(200)		= NULL,		
	@ToList				NVARCHAR(MAX)		= NULL,	
	@CcList				NVARCHAR(MAX)		= NULL,	
	@BccList			NVARCHAR(MAX)		= NULL,		
	@IsInternal			BIT,
	@IsActive			BIT,
	@ModifiedBy			INT					= NULL, 
	@ModifiedDate		DATETIME,
	@Environment		VARCHAR(10)			= 'UAT',				-- 'UAT', 'LIVE'
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
 * Task		: Update mailing list item information
 * DB		: bodb_NAP
 *  
 * Revisions:     	
 * Param's Explanation: 	
	• Main	:	
				<root><xml path="r" />
					<row item="ListId" alias="li" />
					<row item="ListKey" alias="lk" />
					<row item="ListName" alias="ln" />
					<row item="Description" alias="d" />
					<row item="SiteId" alias="si" />
					<row item="SiteName" alias="sn" />
					<row item="Environment" alias="ev" />
					<row item="ListFunctionId" alias="lf" />
					<row item="ListFunctionName" alias="lfn" />		
					<row item="FunctionId" alias="fi" />
					<row item="FunctionName" alias="f" />
					<row item="ToList" alias="tl" />					
					<row item="CcList" alias="cl" />
					<row item="BccList" alias="bl" />
					<row item="IsInternal" alias="in" />	
					<row item="IsActive" alias="i" />
				</root>
*/

BEGIN

	SET NOCOUNT ON
	
	-- For write log
	DECLARE
		@ListFunctionName	NVARCHAR(50), 
		@startRun			DATETIME,
		@endRun				DATETIME,
		@duration			INT,
		@logSPData			VARCHAR(5000),
		@logSPDataOld		VARCHAR(5000),
		@xml				XML

	SET @startRun = GETDATE()

	-- write log before update
	SET @xml = (
		SELECT 
				m.ListId			AS '@li'
				,m.ListKey			AS '@lk'
				,m.ListName			AS '@ln'
				,m.Description		AS '@d'
				,m.SiteId			AS '@si'
				,s.SiteName			AS '@sn'
				,m.Environment		AS '@ev'
				,m.ListFunctionId	AS '@lf'
				,fl.FunctionName	AS '@lfn'
				,m.FunctionId		AS '@fi'
				,f.FunctionName		AS '@f'
				,m.ToList			AS '@tl'
				,m.CCList			AS '@cl'			
				,m.BCCList			AS '@bl'
				,m.IsInternal		AS '@in'
				,m.IsActive			AS '@i'
		FROM 
			MailingList AS m WITH (NOLOCK)
			INNER JOIN Functions AS f WITH (NOLOCK) ON m.FunctionId = f.FunctionId
			INNER JOIN Functions AS fl WITH (NOLOCK) ON m.ListFunctionId = fl.FunctionId
			INNER JOIN Sites AS s WITH (NOLOCK) ON f.SiteId = s.SiteId
		WHERE m.ListId = @ListId
		FOR XML PATH('r'), TYPE
	)	

	SET @logSPDataOld = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')	

	-- Update mailing list item information
	UPDATE dbo.MailingList WITH (ROWLOCK, UPDLOCK)
	SET	
		ListFunctionId	= @ListFunctionId,
		FunctionId		= @FunctionId,
		SiteId			= @SiteId,
		ListName		= @ListName,
		Description		= @Description,
		ToList			= @ToList,
		CcList			= @CcList,
		BccList			= @BccList,
		IsInternal		= @IsInternal,		
		IsActive		= @IsActive,
		ModifiedBy		= @ModifiedBy,
		ModifiedDate	= @ModifiedDate,
		Environment		= @Environment
	WHERE ListId	= @ListId

	-- Check error
	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 1, 
				@ErrMsg = 'Fail to update information of the ListId ' + CONVERT(VARCHAR(10), @ListId)
			RETURN
		END
	ELSE		

	SELECT @ListFunctionName = FunctionName FROM dbo.Functions WHERE FunctionId = @ListFunctionId

	-- Write log after update
	SET @xml = (
		SELECT 
			@ListId				AS '@li'
			,@ListKey			AS '@lk'
			,@ListName			AS '@ln'
			,@Description		AS '@d'
			,@SiteId			AS '@si'
			,s.SiteName			AS '@sn'
			,@Environment		AS '@ev'
			,@ListFunctionId	AS '@lf'
			,@ListFunctionName	AS '@lfn'
			,@FunctionId		AS '@fi'
			,f.FunctionName		AS '@f'
			,@ToList			AS '@tl'
			,@CCList			AS '@cl'			
			,@BCCList			AS '@bl'
			,@IsInternal		AS '@in'
			,@IsActive			AS '@i'
		FROM 
			dbo.Functions AS f WITH (NOLOCK)
			INNER JOIN dbo.Sites AS s WITH (NOLOCK) ON f.SiteId = s.SiteId
		WHERE f.FunctionId = @FunctionId		
		FOR XML PATH('r'), TYPE
	)	

	SET @logSPData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')
		
	SET @endRun		= GETDATE()
	SET @duration	= DATEDIFF(MILLISECOND, @startRun, @endRun)   

	EXEC bodb_NAPLOG.dbo.NAP_LogRunSp_Insert 
		@UserId			= @CurrentUserId,
		@SPName			= 'NAP_MailingList_Update',
		@ObjectId		= @ListId,
		@ObjectTypeId	= 7,			--Object type : Mailing list
		@Language		= @Language,
		@SiteID			= @CurrentSiteId,
		@IP				= @LoginIP,
		@Date			= @LogDate,
		@Data			= @logSPData,
		@OldData		= @logSPDataOld,
		@Duration		= @Duration

END

