USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_GetMemberDownline]    Script Date: 5/2/2013 1:31:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_GetMemberDownline]
	@AgentId	INT,
	@PageSize	INT = 50,
	@PageIndex	INT = 1,
	@TotalPages	INT = 1		OUTPUT
AS

/**
 * Created by	: Quinn
 * Date			: 20130314
 * Task			: Retrieve direct members of agent
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	•
 * Parameters:
 *	@AgentId	: agent ID
 *	@PageSize	: page size
 *	@PageIndex	: page index
 *	@TotalPages	: total pages
 */

BEGIN

	SET NOCOUNT ON

	DECLARE 
		@rowCount	INT, 
		@rowStart	INT, 
		@rowEnd		INT,
		@totalItems	INT

	SELECT
		@PageIndex = @PageIndex - 1,
		@rowStart = @PageSize * @PageIndex + 1,
		@rowEnd = @rowStart + @PageSize - 1

	SELECT 
		@totalItems = COUNT(CustId), 
		@TotalPages = @TotalItems/@PageSize + CASE WHEN @totalItems % @PageSize > 0 THEN 1 ELSE 0 END
	FROM CustInfo WITH (NOLOCK)
	WHERE AgentId = @AgentId

	SELECT 
		CustId,
		Username,
		AgentId
	FROM 
		(
			SELECT 
				CustId,
				Username,
				AgentId,
				ROW_NUMBER() OVER(ORDER BY Username) AS RowNumber 
			FROM CustInfo WITH (NOLOCK) 
			WHERE AgentId = @AgentId
		) AS p
	WHERE p.RowNumber BETWEEN @rowStart AND @rowEnd

END
