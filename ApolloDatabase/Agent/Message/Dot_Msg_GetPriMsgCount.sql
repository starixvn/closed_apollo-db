USE [bodb_Message]
GO
<<<<<<< HEAD
/****** Object:  StoredProcedure [dbo].[Dot_Msg_GetPriMsgCount]    Script Date: 5/7/2013 4:07:33 PM ******/
=======
/****** Object:  StoredProcedure [dbo].[Dot_Msg_GetPriMsgCount_xtest]    Script Date: 5/7/2013 1:15:04 PM ******/
>>>>>>> 36bfc951fe3c5aa4030febb2529f938e6cbde213
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER  PROCEDURE [dbo].[Dot_Msg_GetPriMsgCount]
	@TargetId		INT,
	@IsAgent		BIT		= 1	
AS
/**
 * Created by	: TWTeam
 * Date			: 
 * Task			: 
 * DB			: APL.bodb_Message
 * Revisions	:
 *	• Scott@20120109 : add condition for new flag column [isDeleted] to filter deleted data.
 *	• 20130405@Edward	:	Add parameter @IsAgent, remove parameter @UserName, change parameter
 *						from @UserId to @TargetId
 * Parameters:
 *  
 */

BEGIN
	SET NOCOUNT ON

	SELECT COUNT(*) AS COUNT
	FROM dbo.MsgTarget WITH (NOLOCK)
	WHERE
		IsRead			= 0 
		AND TargetId	= @TargetId	
		AND isDeleted	= 0
		AND IsAgent		= @IsAgent

END

