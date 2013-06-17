USE [MsgDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Msg_UpdateRead]    Script Date: 5/7/2013 4:21:02 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
 
 ALTER PROCEDURE [dbo].[Age_Msg_UpdateRead]
	@TargetId		INT				= 0,
	@IsAgent		BIT				= 1,
	@MessageIDs		VARCHAR(4000)	= ''
AS
/*
	Created: Johnson
	Date: 20110719
	DB: SVRMSG.MsgDB
	Task: Update personal message to is read

	Revisions:
		- 20111028@Johnson: Fix bugs Split message
		- 20120112@Lukas: Exclude messages with isDeleted = 1
		- 20120208@Jamie: Add log into MsgLog table
		- 202130405@Edward : Add parameter @IsAgent and review,change parameter from @UserId to @TargetId 
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @tmpMsg TABLE(messageID INT)

	INSERT INTO @tmpMsg
	SELECT val
	FROM strSplit(@MessageIDs, ',')
	
	UPDATE MsgTarget WITH (UPDLOCK, ROWLOCK)
	SET IsRead = 1 
	WHERE 
		TargetID = @TargetId
		AND IsAgent = @IsAgent 
		AND messageID IN (SELECT messageID FROM @tmpMsg)
		AND isDeleted = 0

	-- Write Log 
	INSERT INTO dbo.MsgLog (
		[Site],
		[OpratorID],
		[MessageId],
		[LogContent],
		[ActionType],
		[Method],
		[LogDate])
	SELECT DISTINCT
		1,						-- Agent Site
		@TargetId,
		messageID,
		'Public Message',
		'E',
		'Age_Msg_UpdateRead',
		GETDATE()
	FROM @tmpMsg

END