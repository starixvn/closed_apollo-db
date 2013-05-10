USE [bodb_Message]
GO
/****** Object:  StoredProcedure [dbo].[Acc_Msg_GetTopPubMessage]    Script Date: 5/7/2013 4:23:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Acc_Msg_GetTopPubMessage]
	@MessageType	INT,
	@Site1			VARCHAR(10),
	@Site2			VARCHAR(10)		= '',
	@Site3			VARCHAR(10)		= '',
	@Site4			VARCHAR(10)		= '',
	@Site5			VARCHAR(10)		= '',
	@LatestMsgID	INT				= 0,  -- Check new msg count that newer than this messageid
	@IsTest			BIT
AS

/**
 * Created by	: Jamie
 * Date			: 20120112
 * Task			: Get public message
 * DB			: APL.bodb_Message
 * Revisions	:
 *	• 20130401@Kos	: Review
 * Parameters:
 *  
 */
		
BEGIN
    
	SET NOCOUNT ON

	DECLARE @site6 CHAR(4)
	DECLARE @site7 CHAR(4)
	DECLARE @site8 CHAR(4)

	SET @site6 = ''
	SET @site7 = ''
	SET @site8 = ''

	-- 20111230(Vivi): chage @LatestMsgID to provide good performance. (175903 posttime is 2011-11-1)
	IF @LatestMsgID = 0 SET @LatestMsgID = 175903

	IF @Site1 <> '' SET @Site1 = dbo.FixSiteID(@Site1)
	IF @Site2 <> '' SET @Site2 = dbo.FixSiteID(@Site2)
	IF @Site3 <> '' SET @Site3 = dbo.FixSiteID(@Site3)
	IF @Site4 <> '' SET @Site4 = dbo.FixSiteID(@Site4)
	IF @Site5 <> '' SET @Site5 = dbo.FixSiteID(@Site5)

	IF @Site1 <> '' SET @site6 = dbo.FixSiteID2(@Site1)
	IF @Site2 <> '' SET @site7 = dbo.FixSiteID2(@Site2)
	IF @Site3 <> '' SET @site8 = dbo.FixSiteID2(@Site3)
	
	DECLARE @site1i INT
	DECLARE @site2i INT
	DECLARE @site3i INT
	DECLARE @site4i INT
	DECLARE @site5i INT
	DECLARE @site6i INT
	DECLARE @site7i INT
	DECLARE @site8i INT
	
	SELECT
		@site1i = @Site1,
		@site2i = @Site2,
		@site3i = @Site3,
		@site4i = @Site4,
		@site5i = @Site5,
		@site6i = @site6,
		@site7i = @site7,
		@site8i = @site8
		
	SELECT TOP 1 
		m.MessageId, 
		m.Content_en, 
		m.Content_cs, 
		m.Content_ch,
		m.Content_jp, 
		m.Content_th, 
		m.Content_it, 
		m.Content_ko,
		m.Content_es, 
		m.Content_vn, 
		m.Content_id, 
		m.Content_el,
		m.Content_mx,
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
		m.CreatorName, 
		m.LastUpdateName,
		mt.TargetName AS UserName, 
		mt.BettransID, 
		mt.TargetId
	FROM 
		dbo.Msg AS m WITH (NOLOCK)
		INNER JOIN dbo.MsgTarget AS mt WITH (NOLOCK) ON m.MessageId = mt.MessageId
	WHERE 
		m.MsgType = @MessageType
		AND mt.TargetID IN (@site1i, @site2i, @site3i, @site4i, @site5i, @site6i, @site7i, @site8i)
		AND m.MessageId > @LatestMsgID
		AND (@IsTest = 1 OR (@IsTest <> 1 AND m.IsTest = @IsTest))			
		AND m.isDeleted = 0
		AND mt.isDeleted = 0
	ORDER BY m.PostTime DESC
		
END
