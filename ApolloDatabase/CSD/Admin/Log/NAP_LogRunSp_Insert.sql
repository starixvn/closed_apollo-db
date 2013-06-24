USE [bodb_NAPLOG]
GO
/****** Object:  StoredProcedure [dbo].[NAP_LogRunSp_Insert]    Script Date: 6/21/2013 1:47:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[NAP_LogRunSp_Insert]  
	@UserId			INT,	
	@SPName			NVARCHAR(50)	= NULL,		
	@ObjectId		INT				= NULL,
	@ObjectTypeId	INT				= NULL,
	@Language       VARCHAR(20)		= NULL,
	@SiteID			tinyint			= NULL,
	@IP				varchar(50)		= NULL,
	@Date			DATETIME,
	@Data			NVARCHAR(MAX)	= NULL,
	@OldData		NVARCHAR(MAX)	= NULL,
	@Duration		INT				= NULL  
AS
/**
 * Created: 20121311@Kos
 * Task: Add new log user run sp
 * DB: bodb_NAP
 *  
 * Revisions:     
 * Param's Explanation: 
 *  - @UserId: UserId perform this action  
 *  - @CustId:
 *  - @ActionId: Log action ID
 *  - @TrackingValue: XML string format
 */

SET NOCOUNT ON

	DECLARE @langid tinyint, @actionid smallint
	IF @Language is NOT NULL
		SELECT @langid = [langid] 
		FROM dbo.NAPLog_Language WITH(NOLOCK) 
		WHERE language = @language
	
	SELECT @actionid = actionID
	FROM dbo.NAPLog_Action WITH(NOLOCK)
	WHERE SPName = @SPName

	INSERT INTO dbo.NAPLog_RUNSP(
		UserId, SPName, ActionId, ObjectId, ObjectTypeId, 
		langID, siteID, IP, LogDate, Duration
	)
	VALUES (@UserId, @SPName, @actionid, @ObjectId, @ObjectTypeId, 
		@langid, @SiteID, @IP, @Date, @Duration	
	)

	IF @@ERROR = 0
	INSERT INTO dbo.NAPLOG_RUNSP_Detail(ID, ActionID, Data, OldData)
	VALUES(@@IDENTITY, @actionid, @Data, @OldData)
	 

