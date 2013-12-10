USE [bodb_NAP]
GO
/****** Object:  StoredProcedure [dbo].[NAP_MailingList_GetByUserAndSiteIncludeGroup]    Script Date: 10/29/2013 12:39:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_MailingList_GetByUserAndSiteIncludeGroup]
	@UserId			INT,
	@SiteId			INT,	
	@Environment	VARCHAR(10)	= 'UAT',	-- 'UAT', 'LIVE'
	@IsActive		BIT			= NULL,
	@IsInternal		BIT			= 1
AS

/**  
 * Created	: 20120810@Kos
 * Task		: Get all mailing list in a site filter with environment, isactive and isinternal field
 * DB		: bodb_NAP
 *  
 * Revisions:
 *		
 * Param's Explanation: 
 */

BEGIN

	SET NOCOUNT ON

	DECLARE @TableFunction TABLE (
		FunctionId INT
	)

	DECLARE @TableFunctionList TABLE (
		FunctionId INT,
		FunctionName NVARCHAR(50), 
		Policy TINYINT
	)

	INSERT INTO @TableFunction (FunctionId)
	SELECT DISTINCT ListFunctionId
	FROM MailingList WITH (NOLOCK)

	INSERT INTO @TableFunctionList
	SELECT  
		A.FunctionId, 
		A.FunctionName,
		CASE 
			WHEN ISNULL(A.Policy, 0) < ISNULL(B.Policy, 0) THEN ISNULL(B.Policy, 0) 
			ELSE ISNULL(A.Policy, 0) 
		END AS Policy
	FROM 
		(
			-- Get function permission of user in a site
			SELECT 
				uf.FunctionId, 
				f.FunctionName,
				uf.Policy
			FROM 
				UserFunction AS uf WITH (NOLOCK)
				INNER JOIN Functions AS f WITH (NOLOCK) ON uf.FunctionId = f.FunctionId
			WHERE 
				uf.UserId = @UserId 
				AND f.FunctionId IN (SELECT FunctionId FROM @TableFunction)
		) AS A
		FULL OUTER JOIN
		(
			-- Get function permission of group of user in a site
			SELECT 
				gf.FunctionId, 
				f.FunctionName,
				gf.Policy
			FROM 
				GroupFunction AS gf WITH (NOLOCK)
				INNER JOIN Users AS u WITH (NOLOCK) ON u.GroupId = gf.GroupId
				INNER JOIN Functions AS f WITH (NOLOCK) ON gf.FunctionId = f.FunctionId
			WHERE 
				u.UserId = @UserId
				AND f.FunctionId IN (SELECT FunctionId FROM @TableFunction)
		) AS B
		ON A.FunctionId = B.FunctionId

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
		mf.Policy,
		s.SiteId, 
		s.SiteName, 
		ListFunctionId, 
		mf.FunctionName AS ListFunctionName, 
		m.FunctionId, 
		f.FunctionName
	FROM 
		[dbo].[MailingList] AS m WITH (NOLOCK)
		INNER JOIN @TableFunctionList AS mf ON m.ListFunctionId = mf.FunctionId
		INNER JOIN [dbo].[Functions] AS f WITH (NOLOCK) ON m.FunctionId = f.FunctionId
		INNER JOIN [dbo].[Sites] AS s WITH (NOLOCK) ON m.SiteId = s.SiteId
	WHERE 
		m.SiteId = @SiteId 
		AND (@Environment = 'UAT' OR m.Environment = @Environment)
		AND (@IsActive IS NULL OR m.IsActive = @IsActive)
		AND (@IsInternal = 1 OR m.IsInternal = @IsInternal)
			
END
