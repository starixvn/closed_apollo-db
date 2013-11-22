USE [RepDB]
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE TYPE = 'FN' AND name = 'f_GetAgentUplineStatusById')
	DROP FUNCTION [dbo].[f_GetAgentUplineStatusById]
GO
/****** Object:  UserDefinedFunction [dbo].[f_GetAgentUplineStatusById]    Script Date: 11/22/2013 2:52:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[f_GetAgentUplineStatusById]
(
	 @ParentAgentId INT
)
RETURNS TINYINT
AS
/*
* Created by	: Patrick
* Date			: 20131119
* Task			: Get upline status by agent id
* DB			: SVRAGE.RepDB
* Parameters:
*	output		: 1 is active
				: 2: is stop
* Test string:
	select dbo.f_GetAgentUplineStatusById(107086)

* Revisions	:

*/
BEGIN
	DECLARE @UplineStatus TINYINT = 1
	--++get upline
	;WITH SelfAndAncestor(AgentId, [Status], ParentId)
	AS
	(
		SELECT AgentId, [Status], ParentId
		FROM dbo.AgentInfo WITH (NOLOCK)
		WHERE AgentId = @ParentAgentId

		UNION ALL

		SELECT a.AgentId, a.[Status], a.ParentId
		FROM dbo.AgentInfo AS a WITH (NOLOCK)
		INNER JOIN SelfAndAncestor AS b ON a.AgentId = b.ParentId
		WHERE a.ParentId IS NOT NULL
	)

	--++if exists one upline is stop --> stop
	SELECT TOP(1) @UplineStatus = 2 FROM SelfAndAncestor WHERE [Status] = 2
	RETURN @UplineStatus
END


