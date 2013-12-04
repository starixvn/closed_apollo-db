USE [RepDB]
GO
IF EXISTS (SELECT TOP 1 1 FROM sys.objects WHERE type = 'P' AND name = 'Age_Customer_GetByAgent')
	DROP PROC dbo.Age_Customer_GetByAgent
GO
CREATE PROCEDURE [dbo].[Age_Customer_GetByAgent]
(
	@AgentId	INT,
	@Status		INT				= 1,
	@UserName	NVARCHAR(50)	= '',
	@PageSize	INT				= 50,
	@PageIndex	INT				= 1,
	@TotalItems	INT				= 0		OUTPUT
)
AS

/**
 * Created by	: Terry.Nguyen
 * Date			: 20130306
 * Task			: Retrieve all player by agent
 * DB			: SVRCSD/RepDB
 * Test string	:
	declare @TotalItems int
	exec [dbo].[Age_Customer_GetByAgent] 107086, 1, null, 50, 0, @TotalItems out
	select @TotalItems

 * Revisions	:
 *	• 20130328@Terry.Nguyen: get active col. Noted that 0/1/2 is Active/Suspended/Closed
 *  • 20130417@Terry.Nguyen: Remove 3rd table and get status, betstatus columns
 *  • 20130904@Edward.Nguyen: Remove Discount, add CLock status, add revision for @Status
 *  • 20131119@Patrick	: change method get UplineStatus & UplineBetStatus and change method pagging
 *	• 20131203@Patrick	Clone sp from Agent Site
 * Parameters:
 *	• @Status : 1. Active
 *	•			2. Stopped
 *  			3. Locked
 *  			4. C.Lock
 *	• @PageIndex : 0 it mean is page first
 */

BEGIN
	SET NOCOUNT ON
	SET @UserName = ISNULL(@UserName, '')
	DECLARE @UplineStatus TINYINT, @UplineBetStatus TINYINT

	SELECT @UplineStatus = dbo.f_GetAgentUplineStatusById(@AgentId)
	SELECT @UplineBetStatus = dbo.f_GetAgentUplineBetStatusById(@AgentId) 

	--++get total rows
	SELECT @TotalItems = COUNT(ci.CustId)
	FROM dbo.CustInfo AS ci WITH (NOLOCK)
	WHERE ci.AgentId = @AgentId 
		AND (@UserName = '' OR ci.Username LIKE '%' + @UserName + '%')
		AND (@Status = 0 OR @Status = CASE	WHEN @UplineStatus = 2 THEN 4		
											ELSE ci.[Status] END)

	--++get data
	SELECT	ci.CustId, ci.Username, ci.Status, ci.BetStatus, ci.AgentId
			, SUM(ISNULL(b.Winlost, 0) - ISNULL(b.Actual_Stake, 0) + ISNULL(b.PlayerComm, 0)) AS CashBalance
			, @UplineStatus AS 'UplineStatus', @UplineBetStatus AS 'UplineBetStatus'
	FROM dbo.CustInfo AS ci WITH (NOLOCK) 						
	LEFT JOIN dbo.Bettrans b WITH (NOLOCK) ON b.CustID = ci.CustID
	WHERE 
		ci.AgentId = @AgentId
		AND (@UserName = '' OR ci.Username LIKE '%' + @UserName + '%')	
		AND (@Status = 0 OR @Status = CASE	WHEN @UplineStatus = 2 THEN 4		
											ELSE ci.[Status] END)		
	GROUP BY ci.CustId,	ci.Username, ci.UGroup,	ci.Status, ci.BetStatus, ci.AgentId
	ORDER BY ci.Username ASC
	OFFSET @PageIndex * @PageSize ROWS
	FETCH NEXT @PageSize ROWS ONLY
	
END
GO
GRANT EXECUTE ON [dbo].[Age_Customer_GetByAgent] TO [aplweb]
GO
