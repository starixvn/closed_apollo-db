USE [bodb_Message]
GO
/****** Object:  StoredProcedure [dbo].[Dot_Msg_SetPriMsgRead]    Script Date: 5/7/2013 1:14:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Dot_Msg_SetPriMsgRead]
	@TargetId	INT,
	@IsAgent	BIT		= 1
AS

/**
 * Created by	: TWTeam
 * Date			: 
 * Task			: Set private message read
 * DB			: APL.bodb_Message
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

