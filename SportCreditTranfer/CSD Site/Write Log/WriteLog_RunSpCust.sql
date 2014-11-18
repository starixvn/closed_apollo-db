USE [LogDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_LogRunSp_Insert]    Script Date: 4/27/2013 9:15:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[WriteLog_RunSpCust]
	@UserId			INT,
	@SPName			NVARCHAR(50)	= NULL,
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
		SPName,
		LogDate,
		CustId,
		ActionId,
		Duration,
		Data,
		OldData )
	SELECT
		@UserId,
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