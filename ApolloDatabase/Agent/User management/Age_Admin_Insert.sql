USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Admin_Insert]    Script Date: 3/29/2013 10:07:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Admin_Insert]
	@AdminId		INT,			
	@FirstName		VARCHAR(50),
	@LastName		VARCHAR(50),
	@CreateDate		DATETIME,
	@Creator		INT,
	@Username		VARCHAR(50),
	@UserPwd		VARCHAR(40),
	@LastLogged		DATETIME,
	@PwdExpiry		DATETIME,
	@LoginCount		TINYINT			= 0,
	@IPLogin		VARCHAR(40),
	@ErrCode		INT				= 0		OUTPUT,
	@ErrMsg			NVARCHAR(1000)	= ''	OUTPUT 
AS

/**
 * Created by	: Kos
 * Date			: 20130305
 * Task			: Add new admin 
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

	INSERT INTO AdminInfo (
		AdminId,			
		FirstName,
		LastName,
		CreateDate,
		Creator,
		Username,
		UserPwd,
		LastLogged,
		PwdExpiry,
		LoginCount,
		IPLogin)
	VALUES (
		@AdminId,			
		@FirstName,
		@LastName,
		@CreateDate,
		@Creator,
		@Username,
		@UserPwd,
		@LastLogged,
		@PwdExpiry,
		@LoginCount,
		@IPLogin)

	---- Not support for multiple language
	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 1, 
				@ErrMsg = 'Failed to insert admin [AdminId = ' + COALESCE(CAST(@AdminId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END
		
END	
