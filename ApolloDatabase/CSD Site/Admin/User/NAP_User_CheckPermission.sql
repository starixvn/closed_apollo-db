ALTER PROCEDURE [dbo].[NAP_User_CheckPermission]
	@UserId		INT,
	@FunctionId	INT,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

/*  
	Created: 20130918@Sophia
	Task : Check policy of user function
	DB: SVRNAP.bodb_NAP

	Revisions:
	Param's Explanation: 
*/

SET NOCOUNT ON

	DECLARE @Policy TINYINT 

	SELECT @Policy = 
		CASE 
			WHEN ISNULL(A.Policy, 0) < ISNULL(B.Policy, 0) THEN ISNULL(B.Policy, 0) 
			ELSE ISNULL(A.Policy, 0) 
		END 
	FROM 
		(
			-- Get function permission of user in a site
			SELECT 
				uf.FunctionId, 
				uf.Policy
			FROM 
				dbo.UserFunction AS uf WITH (NOLOCK)
				INNER JOIN dbo.Functions AS f WITH(NOLOCK) ON uf.FunctionId = f.FunctionId
			WHERE 
				uf.UserId = @UserId 
				AND uf.FunctionId = @FunctionId
				AND f.IsActive = 1
		) AS A

		FULL OUTER JOIN

		(
			-- Get function permission of group of user in a site
			SELECT 
				gf.FunctionId, 
				gf.Policy
			FROM 
				dbo.GroupFunction AS gf WITH (NOLOCK)
				INNER JOIN dbo.Users AS u WITH (NOLOCK) ON u.GroupId = gf.GroupId
				INNER JOIN dbo.Functions AS f WITH(NOLOCK) ON gf.FunctionId = f.FunctionId
			WHERE 
				u.UserId = @UserId
				AND gf.FunctionId = @FunctionId
				AND f.IsActive = 1
		) AS B
		ON A.FunctionId = B.FunctionId


		IF @Policy <2
		BEGIN
			SELECT @ErrMsg = N'You are not authorized on this function.',		
				   @ErrCode = 500
			RETURN 
		END
		ELSE
			SET @ErrCode=0


GO
GRANT EXECUTE ON [dbo].[NAP_User_CheckPermission] TO [bodbAdminNet]
GO

