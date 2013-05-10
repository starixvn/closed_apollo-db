USE [bodb_Message]
GO
<<<<<<< HEAD
/****** Object:  StoredProcedure [dbo].[Dot_Msg_GetTopPriMessage24]    Script Date: 5/7/2013 2:29:06 PM ******/
=======
/****** Object:  StoredProcedure [dbo].[Dot_Msg_GetTopPriMessage24]    Script Date: 5/7/2013 1:15:50 PM ******/
>>>>>>> 36bfc951fe3c5aa4030febb2529f938e6cbde213
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER  PROCEDURE [dbo].[Dot_Msg_GetTopPriMessage24]
	@TargetId		INT,
	@IsAgent		BIT		= 1,
	@IsTest			BIT		= 0,
	@LatestMsgID	INT		= 0 -- Check new msg count that newer than this messageid
AS
<<<<<<< HEAD

/*
 * Created		: @TWTeam
 * Task			: 
 * DB			: SVRMSG.bodb_Message
 * Original		:
 * Revisions	:
 *	• Don@20090923 : adapt for new design (Drop table BatchMsg)
 *	• 20120109@Scott(DB07): add condition for new flag column [isDeleted] to filter deleted data.
 *	• 20130405@Edward : Add parameter @IsAgent and review, change parameter from @UserId to @TargetId
 *   Param's Explanation :
 */

 BEGIN
=======
BEGIN
/*
*   Created		: @TWTeam
*   Task		: 
*   DB			: APL.bodb_Message
*   Original	:
*   Revisions	:
*		• Don@20090923 : adapt for new design (Drop table BatchMsg)
*		• 20120109@Scott(DB07): add condition for new flag column [isDeleted] to filter deleted data.
*		• 202130405@Edward : Add parameter @IsAgent and review,change parameter
*						from @UserId to @TargetId
*   Param's Explanation :
*/
>>>>>>> 36bfc951fe3c5aa4030febb2529f938e6cbde213
	SET NOCOUNT ON
	
	-- SELECT min(m.MessageId) FROM msg m (nolock) WHERE m.posttime > dateadd(d,-1,getdate()) and m.MsgType=1 AND m.IsSticky = 0
	--IF @LatestMsgID = 0 
	--	SET @LatestMsgID = 261210
	
<<<<<<< HEAD
	IF @IsTest = 0
		BEGIN
			IF EXISTS (SELECT 1 FROM MsgTarget WITH (NOLOCK) WHERE TargetId = @TargetId AND IsAgent = @IsAgent)
				BEGIN
					SELECT TOP 1 
						m.MessageId
						,m.Content_en
						,m.Content_cs
						,m.Content_ch
						,m.Content_jp
						,m.Content_th
						,m.Content_it
						,m.Content_ko
						,m.Content_es
						,m.Content_vn
						,m.Content_id
						,m.Content_el
						,m.Content_mx
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
						,m.CreatorName
						,m.LastUpdateName
						,mt.TargetName		AS UserName
						,mt.BettransID
						,mt.TargetId
					FROM 
						dbo.Msg AS m WITH (NOLOCK)
						INNER JOIN  dbo.MsgTarget AS mt WITH (NOLOCK) ON m.MessageId = mt.MessageId 
					WHERE 
						m.posttime > DATEADD(d, -1, GETDATE()) 
						AND m.MsgType	= 1 
						AND mt.TargetId	= @TargetId
						AND mt.IsAgent	= @IsAgent
						AND m.MessageId > @LatestMsgID
						AND m.IsSticky	= 0
						AND m.IsTest	= 0
						AND m.isDeleted = 0 
						AND mt.isDeleted= 0
					ORDER BY m.PostTime DESC
				END
			ELSE
				BEGIN
					SELECT 
						m.MessageId
						,m.Content_en
						,m.Content_cs
						,m.Content_ch
						,m.Content_jp
						,m.Content_th
						,m.Content_it
						,m.Content_ko
						,m.Content_es
						,m.Content_vn
						,m.Content_id
						,m.Content_el
						,m.Content_mx
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
						,m.CreatorName
						,m.LastUpdateName
						,mt.TargetName		AS UserName
						,mt.BettransID
						,mt.TargetId
					FROM 
						dbo.Msg AS m WITH (NOLOCK)
						INNER JOIN  dbo.MsgTarget AS mt WITH (NOLOCK) ON m.MessageId = mt.MessageId 
					WHERE m.MessageId = 0
				END
		END
	ELSE
		BEGIN
			SELECT TOP 1 
=======
	IF @IsTest = 0	
	BEGIN
		IF EXISTS (SELECT 1 FROM MsgTarget WITH (NOLOCK) WHERE TargetId = @TargetId AND IsAgent = @IsAgent)
		BEGIN
			SELECT TOP 1 
					m.MessageId
					,m.Content_en
					,m.Content_cs
					,m.Content_ch
					,m.Content_jp
					,m.Content_th
					,m.Content_it
					,m.Content_ko
					,m.Content_es
					,m.Content_vn
					,m.Content_id
					,m.Content_el
					,m.Content_mx
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
					,m.CreatorName
					,m.LastUpdateName
					,mt.TargetName		AS UserName
					,mt.BettransID
					,mt.TargetId
			FROM dbo.Msg AS m WITH (NOLOCK)
				INNER JOIN  dbo.MsgTarget AS mt WITH (NOLOCK) ON m.MessageId = mt.MessageId 
			WHERE 
				m.posttime > DATEADD(d,-1,GETDATE()) 
				AND m.MsgType	= 1 
				AND mt.TargetId	= @TargetId
				AND mt.IsAgent	= @IsAgent				
				AND m.MessageId > @LatestMsgID
				AND m.IsSticky	= 0
				AND m.IsTest	= 0
				AND m.isDeleted = 0 
				AND mt.isDeleted= 0
			ORDER BY m.PostTime DESC
		END
		ELSE
		BEGIN
			SELECT 
>>>>>>> 36bfc951fe3c5aa4030febb2529f938e6cbde213
				m.MessageId
				,m.Content_en
				,m.Content_cs
				,m.Content_ch
				,m.Content_jp
				,m.Content_th
				,m.Content_it
				,m.Content_ko
				,m.Content_es
				,m.Content_vn
				,m.Content_id
				,m.Content_el
				,m.Content_mx
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
				,m.CreatorName
				,m.LastUpdateName
				,mt.TargetName		AS UserName
				,mt.BettransID
				,mt.TargetId
<<<<<<< HEAD
			FROM 
				dbo.Msg AS m WITH (NOLOCK)
				INNER JOIN dbo.MsgTarget AS mt WITH (NOLOCK) ON m.MessageId = mt.MessageId 
			WHERE 
				m.posttime > DATEADD(d,-1,GETDATE()) 
				AND m.MsgType = 1 
				AND mt.TargetId = @TargetId
				AND mt.IsAgent = @IsAgent
				AND m.MessageId > @LatestMsgID
				AND m.IsSticky = 0
				AND m.isDeleted = 0
				AND mt.isDeleted = 0
			ORDER BY m.PostTime DESC
		END
=======
			FROM dbo.Msg AS m WITH (NOLOCK)
				INNER JOIN  dbo.MsgTarget AS mt WITH (NOLOCK) ON m.MessageId = mt.MessageId 
			WHERE m.MessageId = 0
		END
	END
	ELSE
	BEGIN
		SELECT TOP 1 
			m.MessageId
			,m.Content_en
			,m.Content_cs
			,m.Content_ch
			,m.Content_jp
			,m.Content_th
			,m.Content_it
			,m.Content_ko
			,m.Content_es
			,m.Content_vn
			,m.Content_id
			,m.Content_el
			,m.Content_mx
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
			,m.CreatorName
			,m.LastUpdateName
			,mt.TargetName		AS UserName
			,mt.BettransID
			,mt.TargetId
		FROM dbo.Msg AS m WITH (NOLOCK)
			INNER JOIN dbo.MsgTarget AS mt WITH (NOLOCK) ON m.MessageId = mt.MessageId 
		WHERE 
			m.posttime > DATEADD(d,-1,GETDATE()) 
			AND m.MsgType	= 1 
			AND mt.TargetId	= @TargetId
			AND mt.IsAgent	= @IsAgent
			AND m.MessageId > @LatestMsgID
			AND m.IsSticky	= 0
			AND m.isDeleted	= 0
			AND mt.isDeleted= 0
		ORDER BY m.PostTime DESC
	END
>>>>>>> 36bfc951fe3c5aa4030febb2529f938e6cbde213
END

