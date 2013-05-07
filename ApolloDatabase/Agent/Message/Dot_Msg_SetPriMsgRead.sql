USE [bodb_Message]
GO
<<<<<<< HEAD
/****** Object:  StoredProcedure [dbo].[Dot_Msg_SetPriMsgRead]    Script Date: 5/7/2013 2:46:47 PM ******/
=======
/****** Object:  StoredProcedure [dbo].[Dot_Msg_SetPriMsgRead]    Script Date: 5/7/2013 1:14:27 PM ******/
>>>>>>> 36bfc951fe3c5aa4030febb2529f938e6cbde213
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Dot_Msg_SetPriMsgRead]
	@TargetId	INT,
<<<<<<< HEAD
	@IsAgent	BIT
=======
	@IsAgent	BIT		= 1
>>>>>>> 36bfc951fe3c5aa4030febb2529f938e6cbde213
AS

/**
 * Created by	: TWTeam
 * Date			: 
 * Task			: Set private message read
<<<<<<< HEAD
 * DB			: SVRMSG.bodb_Message
=======
 * DB			: APL.bodb_Message
>>>>>>> 36bfc951fe3c5aa4030febb2529f938e6cbde213
 * Revisions	:
 *	• 20130405@Kos	:	Add parameter @IsAgent, remove parameter @UserName, change parameter
 *						from @UserId to @TargetId
 * Parameters:
 *  
 */

BEGIN
	UPDATE dbo.MsgTarget
	SET IsRead = 1
	WHERE 
		IsRead = 0
		AND IsDeleted = 0
		AND TargetId = @TargetId
		AND IsAgent = @IsAgent
END
<<<<<<< HEAD
=======

>>>>>>> 36bfc951fe3c5aa4030febb2529f938e6cbde213
