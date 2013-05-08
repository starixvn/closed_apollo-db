USE [bodb_Message]
GO
<<<<<<< HEAD
/****** Object:  StoredProcedure [dbo].[Dot_Msg_GetPublicMessage]    Script Date: 5/7/2013 2:25:12 PM ******/
=======
/****** Object:  StoredProcedure [dbo].[Dot_Msg_GetPublicMessage]    Script Date: 5/7/2013 1:16:57 PM ******/
>>>>>>> 36bfc951fe3c5aa4030febb2529f938e6cbde213
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Dot_Msg_GetPublicMessage]
<<<<<<< HEAD
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
 *	• 20130418@Edward	: review, add @IsAgent parameter, check isDeleted
 *
 *•	Param's Explanation:
 */ 

=======
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
    Created: @TWTeam
    Task: 
    DB: DB07
    Original:
    Revisions:
		20130418@Edward	: Reformat and add @IsAgent, check isDeleted
    Param's Explanation:
    */
>>>>>>> 36bfc951fe3c5aa4030febb2529f938e6cbde213
BEGIN
	SET NOCOUNT ON

	SELECT *
	FROM (
		SELECT DISTINCT 
<<<<<<< HEAD
			m.MessageId
			,m.Content_en
			,m.Content_cs
			,m.Content_ch
			,m.Content_jp
			,m.Content_th
			,m.Content_it
			,m.Content_ko
			,m.Content_es
			,m.PostTime
			,m.CreateTime
			,m.LastUpdateTime
			,m.MsgType
			,m.IsSticky
			,m.IsTest
			,m.MatchId
			,m.IsPublic
			,m.Creator
			,m.LastUpdator
			,m.CreatorName
			,m.LastUpdateName
			,m.IsBatch
			,mt.BettransID
			,mt.TargetId
			,mt.TargetName AS UserName
			,DENSE_RANK() OVER(ORDER BY m.PostTime DESC) AS ROWNUM
		FROM 
			dbo.Msg AS m WITH (NOLOCK)
			INNER JOIN dbo.MsgTarget AS mt WITH (NOLOCK) ON m.MessageId = mt.MessageId
		WHERE 
			m.MsgType		= 3
=======
				m.MessageId
				,m.Content_en
				,m.Content_cs
				,m.Content_ch
				,m.Content_jp
				,m.Content_th
				,m.Content_it
				,m.Content_ko
				,m.Content_es
				,m.PostTime
				,m.CreateTime
				,m.LastUpdateTime
				,m.MsgType
				,m.IsSticky
				,m.IsTest
				,m.MatchId
				,m.IsPublic
				,m.Creator
				,m.LastUpdator
				,m.CreatorName
				,m.LastUpdateName
				,m.IsBatch
				,mt.BettransID
				,mt.TargetId
				,mt.TargetName AS UserName
				,DENSE_RANK() OVER(ORDER BY m.PostTime DESC) AS ROWNUM
		FROM dbo.Msg AS	m WITH (NOLOCK)
			INNER JOIN dbo.MsgTarget AS mt WITH (NOLOCK) 
			ON m.MessageId = mt.MessageId
		WHERE m.MsgType		= 3
>>>>>>> 36bfc951fe3c5aa4030febb2529f938e6cbde213
			AND m.isDeleted	= 0
			AND mt.isDeleted= 0	
			AND CASE
					WHEN ((@Special IN (0,1) AND m.IsSticky = @Special)) THEN 1
					WHEN (@Special = 2) THEN 1
					ELSE 0 
				END = 1
			AND CASE 
					WHEN (@TargetId2 = '0') THEN 1
					WHEN (@TargetId2 <> '0' AND mt.TargetID IN (SELECT val FROM dbo.strSplit(@TargetId2, ','))) THEN 1
					ELSE 0 
				END = 1
			AND CASE
					WHEN (@Sdate IS NOT NULL AND @Edate IS NOT NULL 
						AND m.PostTime BETWEEN @Sdate AND @Edate) THEN 1
					WHEN (@Sdate IS NULL AND @Edate IS NULL) THEN 1
					WHEN (@Sdate IS NOT NULL AND @Edate IS NULL AND m.PostTime >= @Sdate) THEN 1
					WHEN (@Sdate IS NULL AND @Edate IS NOT NULL AND m.PostTime <= @Edate) THEN 1
					ELSE 0 
				END = 1
			AND (@IsTest = 1 OR (@IsTest <> 1 AND m.IsTest = @IsTest))
<<<<<<< HEAD
			AND (@MatchId = 0 OR (@MatchId <> 0 AND m.MatchId = @MatchId))
=======
			AND (@MatchId = 0 OR (@MatchId <> 0 AND m.MatchId = @MatchId))			
>>>>>>> 36bfc951fe3c5aa4030febb2529f938e6cbde213
	) new_table
	WHERE CASE
			WHEN (@Record <> 0 AND new_table.rownum <= @Record) THEN 1
			WHEN (@Record = 0) THEN 1
			ELSE 0 
		END = 1
	ORDER BY posttime DESC
END
