USE [OnlineDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Admin_ReCheckIn]    Script Date: 12/12/2013 10:01:25 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[Age_Admin_ReCheckIn]	
	@OnUserId			INT 
	,@IsKickedOut		BIT = 0 OUTPUT    
AS

/*  
 * Created: 20120823@Edward
 * Task : User recheckin
 * DB: bodb_NAP
 *  
 * Revisions:   
 *			20130415@Edward : Check user has permission on current site  
 * Param's Explanation: 
*/

BEGIN
	SET NOCOUNT ON	

	DECLARE @userId	INT

	SELECT @userId 	= UserId
	FROM OnAgent WITH (NOLOCK)
	WHERE Id = @OnUserId
	
	IF EXISTS (	SELECT 1 
				FROM OnAgent WITH (NOLOCK) 
				WHERE Id = @OnUserId AND IsKickedOut = 1 )    
		BEGIN    
			SET @IsKickedOut = 1    		
		END    
	ELSE    
		BEGIN    
			SET @IsKickedOut = 0    

			UPDATE OnAgent WITH (ROWLOCK, UPDLOCK)
			SET ReloadTime = GETDATE()     
			WHERE Id = @OnUserId    
		     
			IF @@ROWCOUNT = 0    
				SELECT @IsKickedOut = 1    
		END
END


