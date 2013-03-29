USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_SearchByUsername]    Script Date: 3/29/2013 9:59:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[Age_Agent_SearchByUsername]
	@Username		VARCHAR(50)		= ''	
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Search agent by username
 * DB			: APL.CustDB
 * Revisions	:
 *	•	20130304@Edward	: Implement
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON
	
	SELECT TOP(10) ai.Username
	FROM AgentInfo AS ai WITH (NOLOCK)
	WHERE ai.Username LIKE '%' + @Username + '%'
END


