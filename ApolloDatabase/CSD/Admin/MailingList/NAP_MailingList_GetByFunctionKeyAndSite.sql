USE [bodb_NAP]
GO
/****** Object:  StoredProcedure [dbo].[NAP_MailingList_GetByFunctionKeyAndSite]    Script Date: 10/29/2013 12:38:17 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_MailingList_GetByFunctionKeyAndSite]
	@FunctionKey	NVARCHAR(50)	= '',
	@SiteId			INT,
	@IsInternal		BIT				= NULL
AS

/**  
 * Created	: 20131004@Quinn
 * Task		: Get mailing list by Function Key and site
 * DB		: bodb_NAP
 *  
 * Revisions:
 * Param's Explanation: 
 */
BEGIN

	SET NOCOUNT ON
	
	SELECT 
		ListId, 
		ListName, 
		ListKey, 
		m.Description, 
		ToList, 
		CcList, 
		BccList, 
		IsInternal, 
		m.IsActive, 
		m.CreatedBy, 
		m.CreatedDate,
		m.ModifiedBy, 
		m.ModifiedDate, 
		m.Environment, 
		si.SiteId, 
		si.SiteName, 
		ListFunctionId, 
		mf.FunctionName AS ListFunctionName, 
		m.FunctionId, 
		f.FunctionName
	FROM 
		[dbo].[MailingList] AS m WITH (NOLOCK)
		INNER JOIN [dbo].[Functions] AS mf WITH (NOLOCK) ON m.ListFunctionId = mf.FunctionId
		INNER JOIN [dbo].[Functions] AS f WITH (NOLOCK) ON m.FunctionId = f.FunctionId
		INNER JOIN [dbo].[Sites] AS si WITH (NOLOCK) ON m.SiteId = si.SiteId
	WHERE 
		f.SiteId = @SiteId 
		AND f.FunctionKey = @FunctionKey
		AND m.IsActive = 1
		AND (@IsInternal IS NULL OR m.IsInternal = @IsInternal)

END
