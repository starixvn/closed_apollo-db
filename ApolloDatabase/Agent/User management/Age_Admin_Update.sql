USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Admin_Update]    Script Date: 3/29/2013 10:07:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Admin_Update]
	@AdminId		INT,			
	@FirstName		VARCHAR(50),
	@LastName		VARCHAR(50),
	@Username		VARCHAR(50),
	@PwdExpiry		DATETIME,
	@LoginCount		TINYINT			= 0,
	@IPLogin		VARCHAR(40),
	@ErrCode		INT				= 0		OUTPUT,
	@ErrMsg			NVARCHAR(1000)	= ''	OUTPUT 
AS

/**
 * Created by	: Kos
 * Date			: 20130305
 * Task			: Update admin 
 * DB			: APL.CustDB
 * Revisions	:
 *	• 
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON	

	UPDATE AdminInfo WITH (ROWLOCK, UPDLOCK)
	SET
		FirstName = @FirstName,
		LastName = @LastName,
		Username = @Username,
		PwdExpiry = @PwdExpiry,
		LoginCount = @LoginCount,
		IPLogin = @IPLogin
	WHERE AdminId = @AdminId

	---- Not support for multiple language
	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 1, 
				@ErrMsg = 'Failed to insert admin [AdminId = ' + COALESCE(CAST(@AdminId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END
		
END	
