USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetAllMainShareHolder]    Script Date: 5/6/2013 2:02:39 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_GetAllMainShareHolder]
AS

/**
 * Created by	: Ricky
 * Date			: 20130426
 * Task			: Get all Main Shareholder Id and UserName
 * DB			: SVRAGE.RepDB
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
		AgentId, 
		Username
	FROM AgentInfo WITH (NOLOCK)
	WHERE ParentId = 0

END
