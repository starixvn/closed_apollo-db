USE [MsgDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Msg_GetByCustomer]    Script Date: 7/7/2013 9:44:38 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Msg_GetByCustomer]
	@TargetId		INT				= 0,
	@TargetId2		VARCHAR(100)	= '0',
	@IsAgent		BIT				= 1,
	@StartDate		DATETIME		= NULL,	
	@LastPostTime	DATETIME		= '9999-12-31',	
	@DateMode		INT				= 0,
	@IsTest			BIT				= 0,
	@Content		NVARCHAR(100)	= '',	
	@Language		VARCHAR(5)		= 'en-US'		
AS

/**
 * Created by	: Johnson
 * Date			: 20110523
 * Task			: Get annoucement
 * DB			: SVRMSG.MsgDB
 * Revisions	:
 *	• 20132702@Kos		: Review
 *	• 20130405@Edward	: Add parameter @IsAgent
 *	• 20130625@Edward	: Remove @TotalMessage and add @content
 * Parameters:

 */
 BEGIN

	SET NOCOUNT ON	

	IF @StartDate IS NULL
		SELECT @startDate = DATEADD(MONTH, -1, CURRENT_TIMESTAMP)	

	SELECT DISTINCT 
		m.MessageId, 
		m.Content_en, 
		m.Content_cs, 
		m.Content_ch,
		m.Content_jp, 
		m.Content_th, 
		m.Content_vn, 
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
		 CAST(m.Posttime AS DATE) BETWEEN  CAST(@startDate AS DATE) AND  CAST(@LastPostTime AS DATE)		
		AND mt.TargetID IN (
			SELECT val FROM dbo.strSplit(@TargetId2, ',')
			UNION ALL 
			SELECT @TargetId
		)
		AND (@IsTest = 1 OR (@IsTest <> 1 AND m.isTest = @IsTest))
		AND mt.isDeleted	= 0
		AND m.isDeleted		= 0
		AND mt.IsAgent		= @IsAgent
		AND CASE @Language	
							WHEN 'en-US' THEN m.Content_en 
							WHEN 'zh-CN' THEN m.Content_cs
							WHEN 'zh-TW' THEN m.Content_ch
							WHEN 'th-TH' THEN m.Content_th
							WHEN 'ja-JP' THEN m.Content_jp
							WHEN 'ko-KR' THEN m.Content_ko
							WHEN 'es-ES' THEN m.Content_es
							WHEN 'vi-VN' THEN m.Content_vn
							ELSE m.Content_en  
						END LIKE '%' + @Content + '%'
	ORDER BY m.Posttime DESC

END