IF EXISTS (SELECT TOP 1 1 FROM sys.objects WHERE type = 'P' AND name = 'Acc_Msg_GetMessageById')
	DROP PROC dbo.Acc_Msg_GetMessageById
GO
CREATE PROC dbo.Acc_Msg_GetMessageById
(
	@MessageId INT
)
AS
/*
* Created by	: Patrick
* Date			: 20131114
* Task			: Get message by id
* DB			: SVRMSG/MsgDB
* Parameters:
* Test string:
	exec dbo.Acc_Msg_GetMessageById 224013
* Revisions	:

*/
BEGIN
	SET NOCOUNT ON
	SELECT Content_ch, Content_cs, Content_en, Content_jp
			, Content_ko, Content_th, Content_vn, MessageId
			, IsSticky AS 'IsSpecial', MsgType, PostTime
	FROM dbo.Msg WITH(NOLOCK)
	WHERE MessageId = @MessageId
END
GO
GRANT EXECUTE ON [dbo].[Acc_Msg_GetMessageById] TO [aplweb]
GO
