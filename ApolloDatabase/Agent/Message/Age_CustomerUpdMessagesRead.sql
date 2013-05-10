USE [bodb_Message]
GO
<<<<<<< HEAD
/****** Object:  StoredProcedure [dbo].[Age_CustomerUpdMessagesRead]    Script Date: 5/7/2013 4:24:08 PM ******/
=======
/****** Object:  StoredProcedure [dbo].[Age_CustomerUpdMessagesRead]    Script Date: 5/7/2013 1:18:33 PM ******/
>>>>>>> 36bfc951fe3c5aa4030febb2529f938e6cbde213
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
 
 ALTER PROCEDURE [dbo].[Age_CustomerUpdMessagesRead]
	@TargetId		INT				= 0,
	@IsAgent		BIT				= 1,
	@MessageIDs		VARCHAR(4000)	= ''
	
/*
	Created: Johnson
	Date: 2011-07-19
	DB: APL.bodb_Message	
	Task: Update personal message to is read

	Revisions:
		- 20111028@Johnson: Fix bugs Split message
		- 20120112@Lukas: Exclude messages with isDeleted = 1
		- 20120208@Jamie: Add log into MsgLog table
		- 202130405@Edward : Add parameter @IsAgent and review,change parameter
						from @UserId to @TargetId 
*/
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @tmpMsg TABLE(messageID INT)

	INSERT INTO @tmpMsg
	SELECT val
	FROM strSplit(@MessageIDs,',')


	UPDATE MsgTarget WITH(UPDLOCK,ROWLOCK)
	SET IsRead = 1 
	WHERE 
		TargetID	= @TargetId
		AND IsAgent	= @IsAgent 
		AND messageID IN (SELECT messageID FROM @tmpMsg)
		AND isDeleted = 0

	-- Write Log 
	INSERT INTO [bodb_Message].[dbo].[MsgLog]
			   ([Site]
			   ,[OpratorID]
			   ,[MessageId]
			   ,[LogContent]
			   ,[ActionType]
			   ,[Method]
			   ,[LogDate])	
	SELECT	DISTINCT	
				1, -- Agent Site
				@TargetId,
				messageID,
				'Public Message',
				'E',
				'Age_CustomerUpdMessagesRead',
				GETDATE()	
		FROM	@tmpMsg

END