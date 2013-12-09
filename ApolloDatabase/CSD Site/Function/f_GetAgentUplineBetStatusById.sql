USE [RepDB]
GO
IF EXISTS (SELECT 1 FROM sys.objects WHERE TYPE = 'FN' AND name = 'f_GetAgentUplineBetStatusById')
	DROP FUNCTION [dbo].[f_GetAgentUplineBetStatusById]
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
* DB			: SVRCSD/RepDB
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
GO
