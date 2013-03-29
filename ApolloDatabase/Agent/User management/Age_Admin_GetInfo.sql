USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Admin_GetInfo]    Script Date: 3/29/2013 9:55:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Age_Admin_GetInfo]
	@AdminId	INT	
AS

/**
 * Created by	: Kos
 * Date			: 20130305
 * Task			: Get admin information
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

	SELECT 
		AdminId,			
		FirstName,
		LastName,
		CreateDate,
		Creator,
		Username,
		LastLogged,
		PwdExpiry,
		LoginCount,
		IPLogin
	FROM AdminInfo WITH (NOLOCK)
	WHERE AdminId = @AdminId
		
END	