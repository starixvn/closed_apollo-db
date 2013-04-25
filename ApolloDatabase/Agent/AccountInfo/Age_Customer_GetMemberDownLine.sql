USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetMemberDownLine]    Script Date: 4/25/2013 9:57:22 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_GetMemberDownLine]
	@AgentId INT,
	@PageSize INT = 50,
	@PageIndex	INT = 1,
	@TotalPages	INT = 1 OUTPUT
AS

/**
 * Created by	: Quinn
 * Date			: 20130314
 * Task			: Retrieve members of agent which is searched
 * DB			: APL.DB05
 * Revisions	:
 *	•
 * Parameters:
 *	@AgentId: agent ID
 */

SET NOCOUNT ON

DECLARE @RowCount INT, 
		@RowStart INT, 
		@RowEnd	INT,
		@TotalItems INT
SELECT	@PageIndex = @PageIndex - 1,
		@RowStart = @PageSize * @PageIndex + 1,
		@RowEnd = @RowStart + @PageSize - 1

SELECT 
	@TotalItems = COUNT(CustId), 
	@TotalPages = @TotalItems/@PageSize + CASE WHEN @TotalItems % @PageSize > 0 THEN 1 ELSE 0 END
FROM CustInfo p WITH(NOLOCK) 				 
WHERE AgentId = @AgentId

SELECT 
	CustId AS Id,
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
	WHERE 
		AgentId = @AgentId
) p
WHERE 
	p.RowNumber BETWEEN @RowStart AND @RowEnd
