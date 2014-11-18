USE [CustDB]
GO
/****** Object:  UserDefinedFunction [dbo].[f_Bet_GetNameByType]    Script Date: 5/8/2013 9:45:54 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER FUNCTION [dbo].[f_Bet_GetNameByType] (
	@Bettype	TINYINT,
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
	DECLARE	@betName	NVARCHAR(100)

	SELECT @betName =	CASE @Language	
							WHEN 'en-US' THEN typenamee 
							WHEN 'zh-CN' THEN typenamecn
							WHEN 'zh-TW' THEN typenamec_uni
							WHEN 'th-TH' THEN typenameth
							WHEN 'ja-JP' THEN typenamej
							WHEN 'ko-KR' THEN typenameko
							WHEN 'es-ES' THEN typenamees
							WHEN 'vi-VN' THEN typenamevn
							ELSE typenamee 
						END
	FROM SVRPRO.ProdDB.dbo.bettype WITH (NOLOCK)
	WHERE typeid = @Bettype
	
	IF (@betName IS NULL OR @betName = '')
		SELECT	@betName = typenamee 
		FROM	SVRAGE.RepDB.dbo.bettype WITH (NOLOCK)
		WHERE	typeid = @Bettype

	-- Return the result of the function
	RETURN	@betName

END
