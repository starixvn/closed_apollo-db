IF EXISTS (SELECT TOP 1 1 FROM sys.objects WHERE type = 'P' AND name = 'Acc_Msg_InsertMessage')
	DROP PROC dbo.Acc_Msg_InsertMessage
GO
CREATE PROC dbo.Acc_Msg_InsertMessage
(
	 @MsgType			TINYINT			= 1--++1 is private msg, 3 is public msg
	, @IsSpecialMsg		BIT				= 0
	, @UserLoginId		INT				= NULL
	, @UserLoginName	NVARCHAR(50)	= NULL
	, @Recipient		NVARCHAR(MAX)
	, @ContentEn		NVARCHAR(4000)	= NULL
	, @ContentCh		NVARCHAR(4000)	= NULL
	, @ContentCs		NVARCHAR(4000)	= NULL
	, @ContentTh		NVARCHAR(4000)	= NULL
	, @ContentJp		NVARCHAR(4000)	= NULL
	, @ContentKo		NVARCHAR(4000)	= NULL
	, @ContentVn		NVARCHAR(4000)	= NULL
)
AS
/*
* Created by	: Patrick
* Date			: 20131111
* Task			: Create SPs for feature Upload Message
* DB			: SVRMSG/MsgDB
* Parameters:
	@Recipient:
		<ROOT>
			<Recipient TargetId="1" TargetName="super" IsAgent="0" AgentLevel="1"></Recipient>
			<Recipient TargetId="3" TargetName="799" IsAgent="1" AgentLevel="-1"></Recipient>
			<Recipient TargetId="4" TargetName="799" IsAgent="1"></Recipient>
		</ROOT>
* Revisions	:
	20131126@Patrick	: Set default value for language except english language
	20131213@Patrick	: Public msg containt of agent level
* Test string:
	--++for public message
	declare @Recipient nvarchar(max)
	set @Recipient = '<ROOT>
						<Recipient TargetId="3000000" TargetName="Agent Site" IsAgent="0" AgentLevel="0"></Recipient>
						<Recipient TargetId="3000000" TargetName="Agent Site" IsAgent="0" AgentLevel="1"></Recipient>
					   </ROOT>'
	exec dbo.Acc_Msg_InsertMessage_xtest 3, 0, 1, 'sa', @Recipient, 'Test upload public msg with agent level'
	
*/
BEGIN
	SET NOCOUNT ON
	IF @Recipient IS NULL OR @Recipient = ''
		RETURN;

	DECLARE @CurrentDate datetime, @IsPublic BIT, @MsgId INT
	SET @CurrentDate = GETDATE()
	
	--++calc
	IF @MsgType = 1
		SET @IsPublic = 0
	ELSE IF @MsgType = 3
		SET @IsPublic = 1

	--++insert msg
	INSERT INTO dbo.Msg(PostTime, IsSticky, IsPublic, Creator, CreatorName, MsgType
		, LastUpdator, LastUpdateName, IsTest, MatchId, IsBatch, MsgContentsType
		, CreateTime, LastUpdateTime, isDeleted, Content_en, Content_ch, Content_cs
		, Content_th, Content_jp, Content_ko, Content_vn)
	VALUES(@CurrentDate, @IsSpecialMsg, @IsPublic, @UserLoginId, @UserLoginName, @MsgType
		, @UserLoginId, @UserLoginName, 0, 0, 0, 0
		, @CurrentDate, @CurrentDate, 0, @ContentEn, ISNULL(@ContentCh, @ContentEn), ISNULL(@ContentCs, @ContentEn)
		, ISNULL(@ContentTh, @ContentEn), ISNULL(@ContentJp, @ContentEn), ISNULL(@ContentKo, @ContentEn), ISNULL(@ContentVn, @ContentEn))

	SET @MsgId = SCOPE_IDENTITY()

	DECLARE @TableRecipient AS TABLE(TargetId INT, TargetName NVARCHAR(50), IsAgent BIT, AgentLevel SMALLINT)
	DECLARE @DocHandler INT
	-- begin read xml					
	EXEC sp_xml_preparedocument @DocHandler OUTPUT, @Recipient

	INSERT INTO @TableRecipient(TargetId, TargetName, IsAgent, AgentLevel)
	(
		SELECT Data.TargetId, Data.TargetName, Data.IsAgent, Data.AgentLevel
		FROM OPENXML (@DocHandler, '/ROOT/Recipient', 1) 
		WITH (TargetId INT, TargetName NVARCHAR(50), IsAgent BIT, AgentLevel SMALLINT) AS Data
	)
	EXEC sp_xml_removedocument @DocHandler
	--++end read xml
	
	--++insert target msg
	INSERT INTO dbo.MsgTarget(MessageId, TargetId, TargetName, IsRead, isDeleted, IsAgent, AgentLevel)
	(
		SELECT DISTINCT @MsgId, ISNULL(TargetId, 0), TargetName, 0, 0, ISNULL(IsAgent, 0), IIF(AgentLevel = -1, null, AgentLevel)
		FROM @TableRecipient
	)

	--++for write log
	DECLARE @LogContent VARCHAR(50)
	IF @MsgType = 1
		SET @LogContent = 'Private Message'
	ELSE IF @MsgType = 3
		SET @LogContent = 'Site Message'
	INSERT INTO dbo.MsgLog([Site], OpratorID, MessageId, LogContent, ActionType, Method, LogDate)
	VALUES(1, @UserLoginId, @MsgId, @LogContent, 'A', 'Acc_Msg_InsertMessage', GETDATE())
END
GO
GRANT EXECUTE ON [dbo].[Acc_Msg_InsertMessage] TO [aplweb]
GO
