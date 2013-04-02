USE [bodb_Message]
GO
/****** Object:  StoredProcedure [dbo].[Dot_Msg_GetPriMsgCount]    Script Date: 4/2/2013 3:25:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Dot_Msg_GetPriMsgCount]
	@UserId int,
	@UserName nvarchar(20)
AS
BEGIN
	SET NOCOUNT ON
	Select Count(*) As Count From dbo.MsgTarget with (nolock)
	Where IsRead =0 
	AND TargetId = @UserId
	AND TargetName = @UserName
END


