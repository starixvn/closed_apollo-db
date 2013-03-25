
CREATE PROCEDURE [dbo].[Dot_Msg_SetUsrMessage]
	@MessageId int,
	@TargetId int,
	@TargetName nvarchar(50) = '',
	@isRead bit = 0,
	@BetTransId varchar(2000) = '',
	@PostTime DATETIME = NULL ,
	@Creator INT =0
AS
/*	Task: Add/Update target message 
	DB: SVRMSG.bodb_Message
	
	Revisions: 

*/

BEGIN
	IF EXISTS (SELECT MessageId FROM dbo.Msg with (nolock) WHERE MessageId = @MessageId)
	BEGIN
		IF EXISTS (SELECT MessageId FROM dbo.MsgTarget with (nolock) WHERE MessageId = @MessageId AND TargetId = @TargetId)
			BEGIN
				-- update
				UPDATE dbo.MsgTarget WITH (rowlock,updlock)
				SET	TargetName = @TargetName, BetTransId = @BetTransId, isDeleted = 0
				WHERE MessageId = @MessageId 
					AND TargetId = @TargetId
			END
		ELSE
			BEGIN
				-- insert
			
				INSERT dbo.MsgTarget(MessageId, TargetId, TargetName, isRead, BetTransId ,PostTime) --messagetype: for old version
				VALUES (@MessageId, @TargetId, @TargetName, @isRead, @BetTransId ,@PostTime)
			END
	END
END

