USE [bodb_Message]
GO
/****** Object:  StoredProcedure [dbo].[Dot_Msg_GetTopPriMessage24]    Script Date: 4/2/2013 3:26:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Eddie Chen
-- Create date: <Create Date,,>
-- Description:	To temporary solve ref private message high loading to web server
-- =============================================
ALTER PROCEDURE [dbo].[Dot_Msg_GetTopPriMessage24]
	@UserID int,
	@IsTest bit = 0,
	@LatestMsgID int = 0 -- Check new msg count that newer than this messageid
AS
/*
Created: @TWTeam
Task: 
DB: DB07
Original:
Revisions:
    Don@20090923 : adapt for new design (Drop table BatchMsg)
Param's Explanation:
*/

SET NOCOUNT ON;


IF @IsTest=0
BEGIN
	--IF EXISTS (SELECT 1 FROM MsgTarget with (nolock) where targetid=@UserID)
	SELECT TOP 1 m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
					 m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
					 m.Content_es, m.PostTime, m.CreateTime, m.LastUpdateTime,
					 m.MsgType, m.IsSticky, m.IsTest, m.MatchId, m.IsPublic,
					 m.Creator, m.LastUpdator, m.CreatorName, m.LastUpdateName, 
					 m.IsBatch, 
					 mt.BettransID, mt.TargetId, mt.TargetName as UserName
	FROM dbo.Msg m with (nolock)
		INNER JOIN  dbo.MsgTarget  mt with (Nolock) ON m.MessageId = mt.MessageId 
	WHERE m.posttime > dateadd(d,-1,getdate()) and m.MsgType=1 and mt.TargetId=@UserID
	AND m.MessageId > @LatestMsgID
	AND m.IsSticky = 0
	AND m.IsTest=0
	ORDER BY m.PostTime DESC
END
ELSE
BEGIN
	SELECT TOP 1 m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
					 m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
					 m.Content_es, m.PostTime, m.CreateTime, m.LastUpdateTime,
					 m.MsgType, m.IsSticky, m.IsTest, m.MatchId, m.IsPublic,
					 m.Creator, m.LastUpdator, m.CreatorName, m.LastUpdateName, 
					 m.IsBatch, 
					 mt.BettransID, mt.TargetId, mt.TargetName as UserName
	FROM dbo.Msg m with (nolock)
		INNER JOIN dbo.MsgTarget mt with (nolock) ON m.MessageId = mt.MessageId 
	WHERE m.posttime > dateadd(d,-1,getdate()) and m.MsgType=1 and mt.TargetId=@UserID
	AND m.MessageId > @LatestMsgID
	AND m.IsSticky = 0
	--AND m.IsTest = 1
	ORDER BY m.PostTime DESC
END


