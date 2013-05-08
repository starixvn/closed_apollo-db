USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetAllMainShareHolder]    Script Date: 5/8/2013 9:46:54 AM ******/
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
 *	• 20130508@Sophia: Check Main Shareholder's member having running tickets 
 * Parameters:
 *	•
 *	•
 *  
 */
 
BEGIN
	
	SET NOCOUNT ON

	SELECT	A.AgentId, 
			A.Username
	FROM	AgentInfo A WITH (NOLOCK)
	INNER JOIN  Bettrans_Agent BA WITH (NOLOCK) 
			ON A.AgentID = BA.AgentID
	WHERE	A.ParentId = 0
			AND BA.StatusID IN (0,1)

END
 