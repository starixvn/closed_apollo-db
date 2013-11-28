IF EXISTS (SELECT TOP 1 1 FROM sys.objects WHERE type = 'P' AND name = 'Acc_Msg_UpdateMessage')
	DROP PROC dbo.Acc_Msg_UpdateMessage
GO
CREATE PROC dbo.Acc_Msg_UpdateMessage
(
	 @MsgId INT
	, @UserLoginId INT = NULL
	, @UserLoginName NVARCHAR(20) = NULL
	, @ContentEn NVARCHAR(4000) = NULL
	, @ContentCh NVARCHAR(4000) = NULL
	, @ContentCs NVARCHAR(4000) = NULL
	, @ContentTh NVARCHAR(4000) = NULL
	, @ContentJp NVARCHAR(4000) = NULL
	, @ContentKo NVARCHAR(4000) = NULL
	, @ContentVn NVARCHAR(4000) = NULL
 
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
	SET Content_ch = @ContentCh
		, Content_cs = @ContentCs
		, Content_en = @ContentEn
		, Content_th = @ContentTh
		, Content_jp = @ContentJp
		, Content_ko = @ContentKo
		, Content_vn = @ContentVn
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
