IF EXISTS (SELECT TOP 1 1 FROM sys.objects WHERE type = 'P' AND name = 'Acc_Msg_UpdateMessage')
	DROP PROC dbo.Acc_Msg_UpdateMessage
GO
CREATE PROC dbo.Acc_Msg_UpdateMessage
(
	 @MsgId INT
	, @UserLoginId INT = NULL
	, @UserLoginName NVARCHAR(20) = NULL
	, @Content_en NVARCHAR(4000) = NULL
	, @Content_ch NVARCHAR(4000) = NULL
	, @Content_cs NVARCHAR(4000) = NULL
	, @Content_th NVARCHAR(4000) = NULL
	, @Content_jp NVARCHAR(4000) = NULL
	, @Content_ko NVARCHAR(4000) = NULL
	, @Content_vn NVARCHAR(4000) = NULL
 
)
AS
/*
* Created by	: Patrick
* Date			: 20131112
* Task			: Update msg
* DB			: SVRMSG/MsgDB
* Parameters:
* Test string:
	exec dbo.Acc_Msg_UpdateMessage null, null, null, null

* Revisions	:

*/
BEGIN
	SET NOCOUNT ON
	IF @MsgId IS NULL
		RETURN

	UPDATE dbo.Msg WITH(ROWLOCK, UPDLOCK)
	SET Content_ch = @Content_ch
		, Content_cs = @Content_cs
		, Content_en = @Content_en
		, Content_th = @Content_th
		, Content_jp = @Content_jp
		, Content_ko = @Content_ko
		, Content_vn = @Content_vn
		, LastUpdator = @UserLoginId
		, LastUpdateName = @UserLoginName
		, LastUpdateTime = GETDATE()
		, PostTime = GETDATE()
	WHERE MessageId = @MsgId

	--++for write log
	DECLARE @LogContent VARCHAR(50)
	SELECT @LogContent = CASE WHEN MsgType = 1 THEN 'Private Message'
							  WHEN MsgType = 3 THEN 'Site Message'
						 END
	FROM dbo.Msg WITH(NOLOCK)
	WHERE MessageId = @MsgId
	--++
	INSERT INTO dbo.MsgLog([Site], OpratorID, MessageId, LogContent, ActionType, Method, LogDate)
	VALUES(1, @UserLoginId, @MsgId, @LogContent, 'U', 'Acc_Msg_UpdateMessage', GETDATE())

END
GO
GRANT EXECUTE ON [dbo].[Acc_Msg_UpdateMessage] TO [aplweb]
GO
