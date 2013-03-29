USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Admin_GetAll]    Script Date: 3/29/2013 9:49:30 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Age_Admin_GetAll]
	
AS

/**
 * Created by	: Kos
 * Date			: 20130305
 * Task			: Get all admin 
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
		
END	