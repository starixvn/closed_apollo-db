USE [bodb_NAP]
GO
/****** Object:  StoredProcedure [dbo].[NAP_MailingList_Insert]    Script Date: 10/29/2013 12:39:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_MailingList_Insert]
	@ListId			    INT							OUTPUT,	
	@ListName			NVARCHAR(50),	
	@ListKey			NVARCHAR(50),	
	@Description		NVARCHAR(200)	= NULL,
	@SiteId				INT,	
	@Environment		VARCHAR(10)		= 'UAT',	-- 'UAT', 'LIVE'	
	@ListFunctionId		INT,
	@FunctionId			INT,	
	@ToList				NVARCHAR(MAX)	= NULL,
	@CCList				NVARCHAR(MAX)	= NULL,
	@BCCList			NVARCHAR(MAX)	= NULL,
	@IsInternal			BIT,	
	@IsActive			BIT,	
	@CreatedBy			INT				= NULL, 
	@CreatedDate		DATETIME,
	@CurrentUserId		INT,
	@CurrentSiteId		INT,
	@LogDate			DATETIME,
	@LoginIP			VARCHAR(30)		= '',
	@Language			VARCHAR(20)		= 'en-us',
	@ErrCode			INT				= 0			OUTPUT, 
	@ErrMsg				NVARCHAR(1000)	= ''		OUTPUT 
AS

/*  
 * Created	: 20120927@Quinn
 * Task		: Add a new mailing list
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
		@ListFunctionName	VARCHAR(50),
		@startRun			DATETIME,
		@endRun				DATETIME,
		@duration			INT,
		@logSPData			VARCHAR(5000),
		@logSPDataOld		VARCHAR(5000),	
		@xml				XML

	SET @startRun = GETDATE()	

	-- Inserts function
	INSERT dbo.MailingList (
		ListKey,
		ListName,
		Description,
		SiteId,
		Environment,
		ListFunctionId,
		FunctionId,
		ToList,
		CCList,
		BCCList,
		IsInternal,
		IsActive,
		CreatedBy,
		CreatedDate,
		ModifiedBy,
		ModifiedDate
	)
	VALUES (
		@ListKey,
		@ListName,
		@Description,
		@SiteId,	
		@Environment,
		@ListFunctionId,
		@FunctionId,	
		@ToList,
		@CCList,
		@BCCList,
		@IsInternal,	
		@IsActive,	
		@CreatedBy, 
		@CreatedDate,
		@CreatedBy, 
		@CreatedDate
	)
	
	-- Get ListId, current insert
	SET @ListId = SCOPE_IDENTITY()

	-- Write log after insert
	IF @@ERROR > 0
	BEGIN
		SELECT 
			@ErrCode = 1, 
			@ErrMsg = 'Failed to insert Mailing List [ListId = ' + COALESCE(CAST(@ListId AS VARCHAR(10)), SPACE(1)) + ']'
		RETURN
	END		

	SELECT @ListFunctionName = FunctionName FROM dbo.Functions WHERE FunctionId = @ListFunctionId

	-- Write log after insert
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
END
