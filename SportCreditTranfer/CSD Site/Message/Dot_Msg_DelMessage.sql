USE [MsgDB]
GO
/****** Object:  StoredProcedure [dbo].[Dot_Msg_DelMessage]    Script Date: 6/17/2013 3:52:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Dot_Msg_DelMessage]
	@MessageId int
AS
/*
	Created: @TWTeam
	Task: Delete message target and message content
	DB: SVRMSG.MsgDB 

	Revisions: 
*/
BEGIN
	SET NOCOUNT ON
	DELETE dbo.MsgTarget WHERE MessageID = @MessageId;
	DELETE dbo.Msg WHERE MessageID = @MessageId;
END
