USE [MsgDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Msg_GetByCustomer]    Script Date: 5/7/2013 4:20:42 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Msg_GetByCustomer]
	@TargetId		INT				= 0,
	@TargetId2		VARCHAR(100)	= '0',
	@IsAgent		BIT				= 1,
	@LastPostTime	DATETIME		= '9999-12-31',
	@TotalMessage	INT				= 10,
	@IsTest			BIT				= 0
AS

/**
 * Created by	: Johnson
 * Date			: 20110523
 * Task			: Get annoucement
 * DB			: SVRMSG.MsgDB
 * Revisions	:
 *	• 20132702@Kos		: Review
 *	• 20130405@Edward	: Add parameter @IsAgent
 * Parameters:
 *  
 */
 BEGIN

	SET NOCOUNT ON

	DECLARE @startDate DATETIME
	SELECT @startDate = DATEADD(MONTH, -1, CURRENT_TIMESTAMP)

	SET ROWCOUNT @TotalMessage 

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
		m.MsgType, 
		m.IsSticky, 
		m.LastUpdateTime, 
		mt.bettransid, 
		mt.isRead
	FROM 
		dbo.Msg AS m WITH (NOLOCK)
		INNER JOIN MsgTarget AS mt WITH (NOLOCK) ON m.MessageId = mt.MessageId 
	WHERE	
		m.Posttime	>= @startDate
		AND m.Posttime < @LastPostTime
		AND mt.TargetID IN (
			SELECT val FROM dbo.strSplit(@TargetId2, ',')
			UNION ALL 
			SELECT @TargetId
		)
		AND (@IsTest = 1 OR (@IsTest <> 1 AND m.isTest = @IsTest))
		AND mt.isDeleted	= 0
		AND m.isDeleted		= 0
		AND mt.IsAgent		= @IsAgent
	ORDER BY m.Posttime DESC

	SET ROWCOUNT 0

END