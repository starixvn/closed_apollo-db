IF EXISTS (SELECT 1 FROM sys.objects WHERE type = 'P' AND name = 'Acc_Msg_GetListMessage')
	DROP PROC dbo.Acc_Msg_GetListMessage
GO
CREATE PROC dbo.Acc_Msg_GetListMessage
(
	@TopNewMsg INT = 100 --default value 100
	, @MsgType TINYINT = NULL --++1 is private msg, 3 is public msg
	, @Special BIT = NULL
	, @FromDate DATETIME = NULL
	, @ToDate DATETIME = NULL
)
AS
/*
* Created by	: Patrick
* Date			: 20131111
* Task			: Get list mesg
* DB			: SVRMSG/MsgDB
* Revisions	:
	20131213@Patrick	: Public msg containt of agent level
* Test string:
	declare @FromDate datetime, @ToDate datetime
	set @FromDate = '2012-03-01'
	set @ToDate = '2012-03-28'
	exec dbo.Acc_Msg_GetListMessage 2, null, null, @FromDate, @ToDate	
*/
BEGIN
	SET NOCOUNT ON
	SELECT a.PostTime, a.Content_ch, a.Content_cs, a.Content_en, a.Content_jp
			, a.Content_ko, a.Content_th, a.Content_vn
			, a.MsgType, IsSpecial, a.CreatorName, a.TargetId
			, Recipient, a.MessageId, MsgTargetId
	FROM
	(
		SELECT  ROW_NUMBER() OVER(ORDER BY a.PostTime DESC) AS RowNumber
			, a.PostTime, a.Content_ch, a.Content_cs, a.Content_en, a.Content_jp
			, a.Content_ko, a.Content_th, a.Content_vn
			, a.MsgType, a.IsSticky AS 'IsSpecial', a.CreatorName, b.TargetId
			, CASE WHEN AgentLevel IS NULL THEN b.TargetName
					WHEN AgentLevel = 0 THEN 'Super'
					WHEN AgentLevel = 1 THEN 'Main Shareholder'
					WHEN AgentLevel = 2 THEN 'Shareholder'
					WHEN AgentLevel = 3 THEN 'Main Agent'
			END AS 'Recipient'
			, a.MessageId, MsgTargetId
		FROM dbo.Msg a WITH(NOLOCK) 
		INNER JOIN dbo.MsgTarget b WITH(NOLOCK) ON a.MessageId = b.MessageId
		WHERE a.PostTime >= @FromDate AND a.PostTime <= @ToDate
			AND (@MsgType IS NULL OR (@MsgType IS NOT NULL AND a.MsgType = @MsgType))
			AND (@Special IS NULL OR (@Special IS NOT NULL AND a.IsSticky = @Special))
			AND a.isDeleted = 0 AND b.isDeleted = 0
			AND a.IsBatch = 0 /*normal msg*/
	) a
	WHERE RowNumber <= @TopNewMsg
END

GO
GRANT EXECUTE ON [dbo].[Acc_Msg_GetListMessage] TO [aplweb]
GO
