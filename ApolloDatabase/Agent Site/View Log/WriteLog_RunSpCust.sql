USE [LogDB]
GO
/****** Object:  StoredProcedure [dbo].[WriteLog_RunSpCust]    Script Date: 7/17/2013 4:25:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[WriteLog_RunSpCust]
	@UserId			INT,
	@AdminId		INT				= NULL,
	@SPName			VARCHAR(50)		= NULL,
	@LogDate		DATETIME,
	@CustId			INT				= NULL,
	@Duration		INT				= NULL,
	@Data			NVARCHAR(MAX)	= NULL,
	@OldData		NVARCHAR(MAX)	= NULL
AS

/**
 * Created by	: Kos
 * Date			: 20130427
 * Task			: Write log user run store procedure on customer
 * DB			: SVRLOG.LogDB
 * Revisions	:
 *	• 
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN

	SET NOCOUNT ON
	
	INSERT INTO RunSpCust (
		UserId,
		AdminId,
		SPName,
		LogDate,
		CustId,
		ActionId,
		Duration,
		Data,
		OldData )
	SELECT
		@UserId,
		@AdminId,
		@SPName,
		@LogDate,
		@CustId,
		ActionId,
		@Duration,
		@Data,
		@OldData
	FROM LogAction WITH (NOLOCK)
	WHERE SPName = @SPName

END