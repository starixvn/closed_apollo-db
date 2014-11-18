USE [MsgDB]
GO
/****** Object:  StoredProcedure [dbo].[Dot_Msg_GetMessage]    Script Date: 6/17/2013 3:56:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Dot_Msg_GetMessage]
	@targetid	INT				= 0, 
	@targetid2	VARCHAR(100)	= '0', 
	@special	INT				= 2, 
	@record		INT				= 1, 
	@sdate		DATETIME		= NULL, 
	@edate		DATETIME		= NULL,
	@IsTest		BIT				= 0,	
	@MatchId	INT				= 0,
	@IsAgent	BIT				= 1
AS

/*  
 * Created		: @TWTeam
 * Task			:
 * DB			: SVRMSG.MsgDB
 * Original		:
 * Revisions	:
 *	• Kos@20130418	: review, add @IsAgent parameter
 *
 *•	Param's Explanation:
 */ 

BEGIN
	SET NOCOUNT ON

	SELECT *
	FROM (
		SELECT DISTINCT 
			m.MessageId, 
			m.Content_en, 
			m.Content_cs, 
			m.Content_ch,
			m.Content_jp, 
			m.Content_th, 
			m.Content_it, 
			m.Content_ko,
			m.Content_es, 
			m.PostTime, 
			m.CreateTime, 
			m.LastUpdateTime,
			m.MsgType, 
			m.IsSticky, 
			m.IsTest, 
			m.MatchId, 
			m.IsBatch,
			m.Creator, 
			m.LastUpdator, 
			mt.TargetId, 
			0 AS BatchId, 
			'' AS BContent_en, 
			'' AS BContent_cs, 
			'' AS BContent_ch, --will remove when dll update
			'' AS BContent_jp, 
			'' AS BContent_th, 
			'' AS BContent_it, 
			'' AS BContent_ko, 
			'' AS BContent_es, --will remove when dll update
			m.CreatorName, 
			m.LastUpdateName, 
			mt.TargetName AS UserName, 
			mt.BettransID,
			DENSE_RANK() OVER(ORDER BY m.PostTime DESC) AS rownum
		FROM 
			dbo.Msg AS m WITH (NOLOCK)
			INNER JOIN dbo.MsgTarget AS mt WITH (NOLOCK) ON m.MessageId = mt.MessageId
		WHERE ((CASE
					WHEN (@targetid = 0) THEN 1
					WHEN (@targetid <> 0 AND m.MsgType = 1 AND mt.TargetId = @targetid AND mt.IsAgent = @IsAgent) THEN 1
				ELSE 0 END = 1) OR
				(CASE
					WHEN (@targetid2 = '0') THEN 1
					WHEN (@targetid2 <> '0' AND m.MsgType = 3 AND mt.TargetId IN (SELECT val FROM dbo.strSplit(@targetid2,',')) AND mt.IsAgent = @IsAgent) THEN 1
				ELSE 0 END = 1))
			AND CASE
					WHEN (@sdate IS NOT NULL AND @edate IS NOT NULL 
						AND m.PostTime BETWEEN @sdate AND @edate) THEN 1
					WHEN (@sdate IS NULL AND @edate IS NULL) THEN 1
					WHEN (@sdate IS NOT NULL AND @edate IS NULL AND m.PostTime >= @sdate) THEN 1
					WHEN (@sdate IS NULL AND @edate IS NOT NULL AND m.PostTime <= @edate) THEN 1
				ELSE 0 END = 1
			AND CASE
					WHEN (@IsTest = 1) THEN 1
					WHEN (m.IsTest = @IsTest) THEN 1
				ELSE 0 END = 1
			AND CASE
					WHEN (@MatchID = 0) THEN 1
					WHEN (m.MatchID = @MatchID) THEN 1
				ELSE 0 END = 1
	) new_table
	WHERE CASE
			WHEN @record <> 0 AND new_table.rownum <= @record THEN 1
			WHEN @record = 0 THEN 1
		ELSE 0 END = 1
END
