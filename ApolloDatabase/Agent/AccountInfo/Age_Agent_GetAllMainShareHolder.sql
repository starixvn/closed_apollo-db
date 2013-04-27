USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetAllMainShareHolder]    Script Date: 4/27/2013 9:16:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/**
 * Created by	: Ricky
 * Date			: 20130426
 * Task			: Get all Main Shareholder Id and UserName
 * DB			: APL.CustDB
 * Revisions	:
 *	• 
 * Parameters:
 *	•
 *	•
 *  
 */
ALTER PROCEDURE [dbo].[Age_Agent_GetAllMainShareHolder]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT AgentId , Username
	FROM AgentInfo
	WHERE ParentId = 0
END
