IF EXISTS (SELECT TOP 1 1 FROM sys.objects WHERE type = 'P' AND name = 'Acc_Msg_DeleteMessage')
	DROP PROC dbo.Acc_Msg_DeleteMessage
GO
CREATE PROC dbo.Acc_Msg_DeleteMessage
(
	@MsgId INT
	, @MsgTargetId INT
	, @UserLoginId INT
)
AS
/*
* Created by	: Patrick
* Date			: 20131112
* Task			: Delete msg
* DB			: SVRMSG/MsgDB
* Parameters:
* Test string:
	exec dbo.Acc_Msg_DeleteMessage null, null, null, null

* Revisions	:

*/
BEGIN
	SET NOCOUNT ON
	IF @MsgId IS NULL
		RETURN
			
	UPDATE dbo.MsgTarget WITH(ROWLOCK, UPDLOCK)
	SET isDeleted = 1
	WHERE MsgTargetId = @MsgTargetId
	
	--++for write log
	DECLARE @LogContent VARCHAR(50)
	SELECT @LogContent = CASE WHEN MsgType = 1 THEN 'Private Message'
							  WHEN MsgType = 3 THEN 'Site Message'
						 END
	FROM dbo.Msg WITH(NOLOCK)
	WHERE MessageId = @MsgId

	INSERT INTO dbo.MsgLog([Site], OpratorID, MessageId, LogContent, ActionType, Method, LogDate)
	VALUES(1, @UserLoginId, @MsgId, @LogContent, 'D', 'Acc_Msg_DeleteMessage', GETDATE())
GO
GRANT EXECUTE ON [dbo].[Acc_Msg_DeleteMessage] TO [aplweb]
GO
