CREATE PROCEDURE [dbo].[Dot_Msg_DelMessage]
	@MessageId int
AS
/*
	Created: @TWTeam
	Task: Delete message target and message content
	DB: SVRMSG.bodb_Message 

	Revisions: 
*/
BEGIN
	SET NOCOUNT ON
	DELETE dbo.MsgTarget WHERE MessageID = @MessageId;
	DELETE dbo.Msg WHERE MessageID = @MessageId;
END
