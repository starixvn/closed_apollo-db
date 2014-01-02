USE [OnlineDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Admin_Logout]    Script Date: 12/12/2013 10:00:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[Age_Admin_Logout]
	@OnUserID INT	OUTPUT
AS

/*  
 * Created: 05232013@Edward
 * Task : User logout
 * DB: ON_USER
 *  
 * Revisions:     
 * Param's Explanation: 		
*/

BEGIN
	SET NOCOUNT ON
	
	DELETE FROM OnAgent WHERE Id = @OnUserID

	IF @@ERROR = 0
		SET @OnUserId = 0
END

