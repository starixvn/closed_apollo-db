USE [bodb_Message]
GO
<<<<<<< HEAD
/****** Object:  StoredProcedure [dbo].[Dot_Msg_GetNotSpecialMessage]    Script Date: 5/7/2013 2:29:37 PM ******/
=======
/****** Object:  StoredProcedure [dbo].[Dot_Msg_GetNotSpecialMessage]    Script Date: 5/7/2013 1:17:37 PM ******/
>>>>>>> 36bfc951fe3c5aa4030febb2529f938e6cbde213
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Dot_Msg_GetNotSpecialMessage]
	@TargetId	INT				= 0,  	
	@TargetId2	VARCHAR(100)	= '0', 	
	@IsAgent	BIT				= 1,
	@Special	INT				= 2,  
	@Record		INT				= 1,  
	@Sdate		DATETIME		= NULL,  
	@Edate		DATETIME		= NULL,  
	@IsTest		BIT				= 0,  
	@MatchId	BIT				= 0
AS

/*
 * Created		: @TWTeam
 * Task			: 
 * DB			: SVRMSG.bodb_Message
 * Original		:
 * Revisions	:
 *	• 20090923@Don : adapt for new design (Drop table BatchMsg)
 *	• 20091016@twTeam: put the default value for batchid and batch content while waiting updated DLL 
 *	• 20130418@Edward	: review and add @IsAgent, check isDeleted
 *   Param's Explanation :
 */

BEGIN
	SET NOCOUNT ON

	SELECT *
	FROM (
		SELECT DISTINCT 
			m.MessageId
			,m.Content_en
			,m.Content_cs
			,m.Content_ch
			,m.Content_jp
			,m.Content_th
			,m.Content_it
			,m.content_ko
			,m.Content_es
			,m.PostTime
			,m.CreateTime
			,m.LastUpdateTime
			,m.MsgType
			,m.IsSticky
			,m.IsTest
			,m.MatchId
			,m.IsBatch
			,m.Creator
			,m.LastUpdator
			,mt.TargetId
			,0 AS BatchId	   --will remove when dll update
			,'' AS BContent_en
			,'' AS BContent_cs
			,'' AS BContent_ch 
			,'' AS BContent_jp
			,'' AS BContent_th
			,'' AS BContent_it
			,'' AS BContent_ko
			,'' AS BContent_es --will remove when dll update
			,m.CreatorName
			,m.LastUpdateName
			,mt.TargetName as UserName
			,mt.BettransID
			,DENSE_RANK() OVER(ORDER BY m.PostTime desc) AS rownum
		FROM 
			dbo.Msg AS m WITH (NOLOCK)
			INNER JOIN dbo.MsgTarget AS mt WITH (NOLOCK) ON m.MessageId = mt.MessageId
		WHERE m.IsSticky		= 0
			AND m.isDeleted		= 0
			AND mt.isDeleted	= 0
			AND (
				(mt.TargetID = @TargetId AND mt.IsAgent = @IsAgent)
				OR mt.TargetId IN (SELECT val FROM dbo.strSplit(@TargetId2,','))
			)
			AND CASE
					WHEN (@Sdate IS NOT NULL AND @Edate IS NOT NULL 
						AND m.PostTime BETWEEN @Sdate AND @Edate) THEN 1
					WHEN (@Sdate IS NULL AND @Edate IS NULL) THEN 1
					WHEN (@Sdate IS NOT NULL AND @Edate IS NULL AND m.PostTime >= @Sdate) THEN 1
					WHEN (@Sdate IS NULL AND @Edate IS NOT NULL AND m.PostTime <= @Edate) THEN 1
					ELSE 0 
				END = 1
			AND CASE @IsTest 
					WHEN 1 THEN 1
					WHEN m.IsTest THEN 1
				END = 1
			AND CASE @MatchID
					WHEN 0 THEN 1
					WHEN m.MatchID THEN 1
				END = 1
	) new_table
	WHERE CASE
			WHEN (@record <> 0 AND new_table.rownum <= @record) THEN 1
			WHEN (@record = 0) THEN 1
			ELSE 0 
		END = 1
END
