USE [bodb_Message]
GO
/****** Object:  StoredProcedure [dbo].[Dot_Msg_GetPrivateMessage]    Script Date: 4/18/2013 2:40:21 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Dot_Msg_GetPrivateMessage]  
	 @TargetId	INT				= 0,  	 
	 @IsAgent	BIT				= 0,  
	 @Special	INT				= 2,  
	 @Record	INT				= 1,  
	 @Sdate		DATETIME		= NULL,  
	 @Edate		DATETIME		= NULL,  
	 @IsTest	BIT				= 0,  
	 @MatchId	BIT				= 0  
AS  
/*  
*	Created: @TWTeam  
*	Task:   
*	DB: DB07  
*   Original:  
*   Revisions:  
*	•	Don@20090923 : adapt for new design (Drop table BatchMsg)  
*	•	Scott@20120109 : add condition for new flag column [isDeleted] to filter deleted data. 
*	•	Edward@20130418	: reformat and add @IsAgent, remove @targetid2 not used 
*
*•	Param's Explanation:  
*/ 
BEGIN      
    SET NOCOUNT ON  
  
	IF	@TargetId > 0 
		AND @Special	= 2 
		AND @IsTest		= 0
		AND @Sdate IS NOT NULL 
		AND @Edate IS NOT NULL 
		AND @MatchID = 0  
	BEGIN  
		DECLARE @topm TABLE (MessageId INT, TargetId INT)  
	  
		INSERT INTO @topm (MessageId, TargetId)  
		SELECT TOP (@Record) m.MessageId, mt.TargetId  
		FROM dbo.Msg m WITH (NOLOCK)  
			INNER JOIN dbo.MsgTarget mt WITH (NOLOCK) ON m.MessageId = mt.MessageId  
		WHERE   
			m.PostTime BETWEEN @Sdate AND @Edate  
			AND m.MsgType	= 1  
			AND m.isDeleted	= 0 
			AND mt.isDeleted= 0  
			AND m.IsTest	= @IsTest  
			AND mt.TargetID = @TargetId  
			AND mt.IsAgent	= @IsAgent
		ORDER BY m.PostTime DESC  
	  
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
			,mt.TargetName	AS UserName
			,mt.BettransID
			,mt.TargetId
			,0				AS ROWNUM
		FROM dbo.Msg AS m WITH (NOLOCK)  
			INNER JOIN @topm AS topm 
				ON m.MessageId = topm.MessageId  
			INNER JOIN dbo.MsgTarget AS mt WITH (NOLOCK) 
				ON mt.MessageId = topm.MessageId 
				AND mt.TargetId = topm.TargetId  
		ORDER BY m.PostTime DESC  
	END  
	ELSE  
	BEGIN  
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
				,mt.TargetName AS UserName
				,mt.BettransID
				,mt.TargetId
				,DENSE_RANK() OVER(ORDER BY m.PostTime desc) AS ROWNUM
			FROM dbo.Msg AS m WITH (NOLOCK)  
				INNER JOIN dbo.MsgTarget AS mt WITH (NOLOCK) 
					ON m.MessageId = mt.MessageId  
			WHERE m.MsgType		= 1  
				AND m.isDeleted = 0 
				AND mt.isDeleted= 0  
				AND CASE  
						WHEN ((@Special IN (0,1)) AND m.IsSticky = @Special) THEN 1  
						WHEN (@Special = 2) THEN 1  
						ELSE 0 
					END = 1  
				AND CASE 
						WHEN (@TargetId = 0) THEN 1  
						WHEN (@TargetId <>0 AND mt.TargetID = @TargetId AND mt.IsAgent = @IsAgent) THEN 1  
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
				AND CASE  
						WHEN (@IsTest = 1) THEN 1  
						WHEN (m.IsTest = @IsTest) THEN 1 
						ELSE 0 
					END = 1  
				AND CASE  
						WHEN (@MatchID = 0) THEN 1  
						WHEN (m.MatchID = @MatchID) THEN 1  
						ELSE 0 
					END = 1  
		) new_table  
		WHERE CASE  
				WHEN (@Record <> 0 AND new_table.rownum <= @Record) THEN 1  
				WHEN (@Record = 0) THEN 1  
				ELSE 0 
			END = 1  
		ORDER BY PostTime DESC  
	END    
END
