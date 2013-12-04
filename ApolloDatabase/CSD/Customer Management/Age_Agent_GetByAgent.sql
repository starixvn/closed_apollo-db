USE [RepDB]
GO
IF EXISTS (SELECT TOP 1 1 FROM sys.objects WHERE type = 'P' AND name = 'Age_Agent_GetByAgent')
	DROP PROC dbo.Age_Agent_GetByAgent
GO
CREATE PROCEDURE [dbo].[Age_Agent_GetByAgent]
(
	@AgentId	INT,
	@Status		INT				= 1,
	@UserName	NVARCHAR(50)	= '',
	@PageSize	INT				= 50,
	@PageIndex	INT				= 0,	
	@TotalItems	INT				= 0		OUTPUT
)
AS

/**
 * Created by	: Kos
 * Date			: 20130305
 * Task			: Get all children agent of an agent
 * DB			: SVRAGE/RepDB
 * Test string:
	declare @TotalItems int
	exec [dbo].[Age_Agent_GetByAgent] 6466, 1, null, 50, 0, @TotalItems out
	select @TotalItems

 * Revisions	:
 *	• 20130306@Terry.Nguyen: Paging and Get more infor
 *	• 20130326@Ricky.Nguyen: Get Agent Level Col
 *  • 20130328@Terry.Nguyen: Get Active Col. Noted that 0/1/2 is Active/Suspended/Closed
 *  • 20130417@Terry.Nguyen: Remove 3rd table and get status, betstatus columns
 *  • 20130904@Edward.Nguyen: Remove Discount, add CLock status, add revision for @Status
 *  • 20131120@Patick	: change method get UplineStatus & UplineBetStatus and change method pagging
 *	• 20131203@Patrick	Clone sp from Agent Site
 * Parameters:
 *	• @Status : 1. Active
 *	•			2. Stopped
 *  			3. Locked
 *  			4. C.Lock
 */

BEGIN
	
	SET NOCOUNT ON
	DECLARE @UplineStatus TINYINT, @UplineBetStatus TINYINT, @ParentAgentId INT
	SET @UserName = ISNULL(@UserName, '')

	--++Get UplineStatus
	SELECT @UplineStatus = dbo.f_GetAgentUplineStatusById(@AgentId)
	--++Get UplineBetStatus
	SELECT @UplineBetStatus = dbo.f_GetAgentUplineBetStatusById(@AgentId) 

	SELECT @TotalItems = COUNT(ai.AgentId)
	FROM dbo.AgentInfo AS ai WITH (NOLOCK)
	INNER JOIN dbo.AgentUser AS au WITH (NOLOCK) ON (ai.AgentId = au.AgentId)
	WHERE ParentId = @AgentId 
		AND (@UserName = '' OR ai.Username LIKE '%' + @UserName + '%')
		AND au.IsMaster = 1
		AND (@Status = 0 OR @Status = CASE	WHEN @UplineStatus = 2 THEN 4 
											ELSE CASE WHEN ai.[Status] = 1 THEN au.[Status] ELSE ai.[Status] END 
										END)
			
	SELECT ai.AgentId, ai.Username, ai.AgentLevel, ai.BetStatus
		, @UplineStatus AS 'UplineStatus', @UplineBetStatus AS 'UplineBetStatus'
		, CASE 
			WHEN ai.Status = 1 THEN au.Status 
			ELSE ai.Status 
			END AS [Status]
		, (SELECT COUNT(1) FROM dbo.AgentInfo AS aa WITH (NOLOCK) WHERE aa.ParentId = ai.AgentId) AS NumberOfAgent
		, (SELECT COUNT(1) FROM dbo.CustInfo AS pp WITH (NOLOCK) WHERE pp.AgentId = ai.AgentId) AS NumberOfMember
	FROM dbo.AgentInfo AS ai WITH (NOLOCK)				
	INNER JOIN dbo.AgentUser AS au WITH (NOLOCK) ON (ai.AgentId = au.AgentId)
	WHERE ai.ParentId = @AgentId
		AND (@UserName = '' OR ai.Username LIKE '%' + @UserName + '%')
		AND au.IsMaster = 1
		AND (@Status = 0 OR @Status = CASE	WHEN @UplineStatus = 2 THEN 4 
											ELSE CASE WHEN ai.[Status] = 1 THEN au.[Status] ELSE ai.[Status] END 
										END)		
	GROUP BY ai.AgentId, ai.Username, ai.AgentLevel, ai.BetStatus, ai.[Status], au.[Status]
	ORDER BY ai.Username ASC
	OFFSET @PageIndex * @PageSize ROWS
	FETCH  NEXT @PageSize ROWS ONLY

END	

GO
GRANT EXECUTE ON [dbo].[Age_Agent_GetByAgent] TO [aplweb]
GO

