USE [bodb_NAP]
GO
/****** Object:  StoredProcedure [dbo].[NAP_MailingList_GetByName]    Script Date: 10/29/2013 12:39:20 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_MailingList_GetByName]
	@ListName	NVARCHAR(50)
AS

/**  
 * Created	: 20131001@Quinn
 * Task		: Get mailing list by name and site
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
		s.SiteId, 
		s.SiteName, 
		ListFunctionId, 
		mf.FunctionName AS ListFunctionName, 
		m.FunctionId, 
		f.FunctionName
	FROM 
		[dbo].[MailingList] AS m WITH (NOLOCK)
		INNER JOIN [dbo].[Functions] AS mf WITH (NOLOCK) ON m.ListFunctionId = mf.FunctionId
		INNER JOIN [dbo].[Functions] AS f WITH (NOLOCK) ON m.FunctionId = f.FunctionId
		INNER JOIN [dbo].[Sites] AS s WITH (NOLOCK) ON m.SiteId = s.SiteId
	WHERE m.ListName = @ListName

END
