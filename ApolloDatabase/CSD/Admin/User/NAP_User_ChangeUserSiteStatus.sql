USE [bodb_NAP]
GO
/****** Object:  StoredProcedure [dbo].[NAP_User_ChangeUserSiteStatus]    Script Date: 6/20/2013 4:14:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_User_ChangeUserSiteStatus]
	@UserId		INT
	,@SiteId	INT
	,@IsActive	BIT
AS

/*  
 * Created: 20120820@Edward
 * Task : Change user site status
 * DB: bodb_NAP
 *  
 * Revisions:     
 * Param's Explanation: 
*/

BEGIN
	SET NOCOUNT ON

	UPDATE dbo.UserSite
	SET IsActive = @IsActive
	WHERE UserId = @UserId AND SiteId = @SiteId
END
