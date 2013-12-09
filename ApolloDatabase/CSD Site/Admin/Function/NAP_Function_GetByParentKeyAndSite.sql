USE [bodb_NAP]
GO
/****** Object:  StoredProcedure [dbo].[NAP_Function_GetByParentKeyAndSite]    Script Date: 10/29/2013 1:29:42 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_Function_GetByParentKeyAndSite]
	@ParentKey		NVARCHAR(50),
	@SiteId			INT,
	@Environment	VARCHAR(10)		= 'UAT',	-- 'UAT', 'LIVE'
	@IsActive		BIT				= NULL,
	@RoleId			INT = NULL,
	@UserId			INT = NULL
AS

/**  
 * Created	: 20130927@Quinn
 * Task		: Get all function with a parent key and in a site filter with environment and isactive field
 * DB		: bodb_NAP
 *  
 * Revisions:
 * Param's Explanation: 
 */

BEGIN

	SET NOCOUNT ON

	DECLARE @ParentId INT

	CREATE TABLE #FunctionList (
		FunctionId SMALLINT, 
		FunctionName NVARCHAR(50), 
		Policy TINYINT )

	SELECT @ParentId = FunctionId 
	FROM dbo.Functions WITH (NOLOCK)
	WHERE SiteId = @SiteId AND FunctionKey = @ParentKey

	IF (@RoleId IS NOT NULL AND @UserId IS NOT NULL)
		BEGIN
			INSERT INTO #FunctionList
			SELECT  A.FunctionId, A.FunctionName,
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
						AND f.ParentId = @ParentId
						AND f.IsActive = 1
						AND uf.Policy >= @RoleId 
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
						AND f.ParentId = @ParentId
						AND f.IsActive = 1
						AND gf.Policy >= @RoleId 
				) AS B
				ON A.FunctionId = B.FunctionId

			SELECT 
				f.FunctionId,	
				f.FunctionName,
				f.FunctionKey,
				f.Description,	
				f.CRUD,
				f.DisplayOrder,
				f.IsActive,
				f.CreatedDate,
				f.ModifiedDate,
				f.Environment,
				f.ParentId,							-- parent information
				f.ParentName,
				f.SiteId,							-- site information
				s.SiteName,
				f.CreatedBy		AS CreatorId,			-- creator information
				cb.username		AS CreatorUsername,	
				f.ModifiedBy	AS ModifierId,			-- modifier information
				mb.username		AS ModifierUsername	
			FROM 
				dbo.Functions AS f WITH (NOLOCK)
				INNER JOIN #FunctionList AS fm ON f.FunctionId = fm.FunctionId
				INNER JOIN dbo.Sites AS s WITH (NOLOCK) ON f.SiteId = s.SiteId
				LEFT JOIN RepDB.dbo.AdminInfo AS cb WITH (NOLOCK) ON f.CreatedBy = cb.AdminId
				LEFT JOIN RepDB.dbo.AdminInfo AS mb WITH (NOLOCK) ON f.ModifiedBy = mb.AdminId
			WHERE 
				f.ParentId = @ParentId
				AND (@Environment = 'UAT' OR f.Environment = @Environment)
				AND (@IsActive IS NULL OR f.IsActive = @IsActive)
		END
	ELSE
		BEGIN
			SELECT 
				f.FunctionId,	
				f.FunctionName,
				f.FunctionKey,
				f.Description,	
				f.CRUD,
				f.DisplayOrder,
				f.IsActive,
				f.CreatedDate,
				f.ModifiedDate,
				f.Environment,
				f.ParentId,							-- parent information
				f.ParentName,
				f.SiteId,							-- site information
				s.SiteName,
				f.CreatedBy		AS CreatorId,			-- creator information
				cb.username		AS CreatorUsername,	
				f.ModifiedBy	AS ModifierId,			-- modifier information
				mb.username		AS ModifierUsername	
			FROM 
				dbo.Functions AS f WITH (NOLOCK)
				INNER JOIN dbo.Sites AS s WITH (NOLOCK) ON f.SiteId = s.SiteId
				LEFT JOIN RepDB.dbo.AdminInfo AS cb WITH (NOLOCK) ON f.CreatedBy = cb.AdminId
				LEFT JOIN RepDB.dbo.AdminInfo AS mb WITH (NOLOCK) ON f.ModifiedBy = mb.AdminId
			WHERE 
				f.ParentId = @ParentId
				AND (@Environment = 'UAT' OR f.Environment = @Environment)
				AND (@IsActive IS NULL OR f.IsActive = @IsActive)
		END

	DROP TABLE #FunctionList
END
