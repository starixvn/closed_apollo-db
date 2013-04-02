USE [bodb_Message]
GO
/****** Object:  StoredProcedure [dbo].[Dot_Msg_SetPriMsgRead]    Script Date: 4/2/2013 3:26:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Dot_Msg_SetPriMsgRead]
	@UserId int,
	@UserName nvarchar(20)
AS
BEGIN
SET NOCOUNT ON
	Update dbo.MsgTarget
	SET IsRead = 1
	WHERE IsRead = 0
		AND TargetId = @UserId
		AND TargetName = @UserName
END


