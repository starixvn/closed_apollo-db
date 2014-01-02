USE [RepDB]
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE TYPE = 'FN' AND name = 'f_GetAgentUplineBetStatusById')
	DROP FUNCTION [dbo].[f_GetAgentUplineBetStatusById]
GO
/****** Object:  UserDefinedFunction [dbo].[f_GetAgentUplineBetStatusById]    Script Date: 11/22/2013 2:56:09 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[f_GetAgentUplineBetStatusById]
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
	select dbo.f_GetAgentUplineBetStatusById(107086)

* Revisions	:

*/
BEGIN
	
	DECLARE @UplineBetStatus TINYINT = 1
	--++get upline
	;WITH SelfAndAncestor(AgentId, BetStatus, ParentId)
	AS
	(
		SELECT AgentId, BetStatus, ParentId
		FROM dbo.AgentInfo WITH (NOLOCK)
		WHERE AgentId = @ParentAgentId

		UNION ALL

		SELECT a.AgentId, a.BetStatus, a.ParentId
		FROM dbo.AgentInfo AS a WITH (NOLOCK)
		INNER JOIN SelfAndAncestor AS b ON a.AgentId = b.ParentId
		WHERE a.ParentId IS NOT NULL
	)

	--++if exists one upline is stop --> stop
	SELECT TOP(1) @UplineBetStatus = 2 FROM SelfAndAncestor WHERE BetStatus = 2
	RETURN @UplineBetStatus
END

