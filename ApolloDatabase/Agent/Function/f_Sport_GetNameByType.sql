USE [CustDB]
GO
/****** Object:  UserDefinedFunction [dbo].[f_Get_SportNameBySporttype]    Script Date: 5/2/2013 4:17:42 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[f_Sport_GetNameByType] (
	@Sporttype	TINYINT,
	@Language	VARCHAR(5)	= 'en-US'
)
RETURNS NVARCHAR(100) 
AS

/**
 * Created by	: Edward
 * Date			: 20130320
 * Task			: Get the sport name from sporttype by language
 * DB			: SVRCUST.CustDB
 * Revisions	:
 *	• 
 * Parameters:
 *	• @Language	: language culture name (http://msdn.microsoft.com/en-us/library/ee825488%28v=cs.20%29.aspx)
 *	•	en-US	: English - United States 
 *	•	zh-CN	: Chinese Simplified (Chinese - China)
 *	•	zh-TW	: Chinese Traditional (Chinese - Taiwan)
 *	•	th-TH	: Thai - Thailand 
 *	•	ja-JP	: Japanese - Japan 
 *	•	ko-KR	: Korean - Korea 
 *	•	es-ES	: Spanish - Spain 
 *	•	vi-VN	: Vietnamese - Vietnam
 *	•
 *  
 */

BEGIN
	-- Declare the return variable here
	DECLARE	@sportName	NVARCHAR(100)

	SELECT @sportName =	CASE @Language	
							WHEN 'en-US' THEN SportName 
							WHEN 'zh-CN' THEN SportNameCs
							WHEN 'zh-TW' THEN SportNameCh
							WHEN 'th-TH' THEN SportNameTh
							WHEN 'ja-JP' THEN SportNameJp
							WHEN 'ko-KR' THEN SportNameKo
							WHEN 'es-ES' THEN SportNameES
							WHEN 'vi-VN' THEN SportNameVN
							ELSE SportName 
						END
	FROM RepDB.dbo.Sports WITH (NOLOCK)
	WHERE SportType = @Sporttype
	
	IF (@sportName = '' OR @sportName IS NULL)
		SELECT	@sportName = SportName 
		FROM	RepDB.dbo.Sports WITH (NOLOCK)
		WHERE	SportType = @Sporttype

	-- Return the result of the function
	RETURN	@sportName

END

