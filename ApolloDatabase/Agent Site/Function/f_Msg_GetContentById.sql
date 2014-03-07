ALTER FUNCTION [dbo].[f_Msg_GetContentById] (
	@MsgId		INT,
	@Language	NVARCHAR(5)	= 'en-US' 
)
RETURNS NVARCHAR(4000) 
AS

/**
 * Created by	: Kos
 * Date			: 20130425
 * Task			: Get message content by message ID
 * DB			: APL.CustDB
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
 */

BEGIN
	
	DECLARE	@Content NVARCHAR(4000)

	SELECT @Content =	CASE @Language	
							WHEN 'en-US' THEN ContentEN 
							WHEN 'zh-CN' THEN ContentCS
							WHEN 'zh-TW' THEN ContentCT
							WHEN 'th-TH' THEN ContentTH
							WHEN 'ja-JP' THEN ContentJP
							WHEN 'ko-KR' THEN ContentKO
							WHEN 'es-ES' THEN ContentES
							WHEN 'vi-VN' THEN ContentVI
							ELSE ContentEN 
						END
	FROM MsgError WITH (NOLOCK)
	WHERE MsgId = @MsgId

	-- Return the result of the function
	RETURN	@Content

END

GO


