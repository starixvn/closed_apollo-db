USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Agent_GetByUserName]    Script Date: 3/29/2013 10:46:12 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Agent_GetByUserName] @UserName VARCHAR(50)
AS
BEGIN
	SELECT 
	au.AgentUserId
	, au.Username
	, au.IsMaster
		, au.PageAccess
		, au.AgentId
		, ai.AgentLevel 
		, ai.Username AS [AgentName]
		, ai.Currency		
	FROM AgentUser au WITH (NOLOCK)
	INNER JOIN AgentInfo ai WITH (NOLOCK) ON au.AgentId = ai.AgentId
	WHERE au.Username = @UserName
END
