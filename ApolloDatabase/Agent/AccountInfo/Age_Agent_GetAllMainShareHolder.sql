USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetAllMainShareHolder]    Script Date: 5/8/2013 9:46:54 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_GetAllMainShareHolder]
	@Bettypes VARCHAR(500) = '1, 2, 3, 4, 5, 6, 7, 8, 12, 13, 15, 20, 21, 24, 25, 26, 27, 28, 30, 121, 122, 123, 9, 29, 10'
AS

/**
 * Created by	: Ricky
 * Date			: 20130426
 * Task			: Get all Main Shareholder Id and UserName
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	• 20130508@Sophia: Check Main Shareholder's member having running tickets and filter by bettypes
 * Parameters:
 *	•
 *	•
 *  
 */
 
BEGIN	
	SET NOCOUNT ON
		
	SELECT	DISTINCT A.AgentId, 
			A.Username
	FROM	AgentInfo A WITH (NOLOCK)
	INNER JOIN  Bettrans_Agent BA WITH (NOLOCK) 
			ON A.AgentID = BA.AgentID
	WHERE	A.ParentId = 0
			AND BA.StatusID IN (0,1)
			AND BA.Bettype IN (SELECT val FROM dbo.strSplit_Key (@Bettypes, ','))
	ORDER BY A.Username
END
 
 GO
 GRANT EXECUTE ON [Age_Agent_GetAllMainShareHolder] TO aplweb


 