ALTER PROCEDURE [dbo].[Age_API_GetUserAccountStatus]
(	
	@UserId		INT
	,@UserType  TINYINT
	,@ErrCode	INT				= 0	 OUTPUT
	,@ErrMsg	NVARCHAR(1000)	= '' OUTPUT 	
)
AS
/*
 Created:	20141014@Sophia
 Task :		Get Status, Betstatus of an account (API call)
 DB:		SVRAGE/RepDB
 Original:  
  
 Revisions: 
 
   			
 Param's Explanation:  
	 @UserType: 0 = Member, 1 = Agent, 2 = SubAgent

	- Status, BetStatus:
		1: Active
		2: Stopped
		3: Locked

 Exam: 
	DECLARE @ErrCode INT, @ErrMsg NVARCHAR(1000)
	EXEC [Age_API_GetUserAccountStatus] @UserId = 1 , @UserType = 1, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	SELECT @ErrCode, @ErrMsg


*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @Status TINYINT, @BetStatus TINYINT
	DECLARE @AgentId INT
	
	---------------- ## Member ##-------------
	IF @UserType= 0 
	BEGIN 		
		-- Check if Customer ID not exist
		IF NOT EXISTS (SELECT 1 FROM dbo.CustInfo WITH (NOLOCK) WHERE CustId = @UserId)
			BEGIN
				SELECT 
					@ErrCode = 5200, 
					@ErrMsg = 'Customer ID not exist [CustId = ' + COALESCE(CAST(@UserId AS VARCHAR(10)), SPACE(1)) + ']'
				RETURN
			END	

		SELECT @Status = Status, @BetStatus = BetStatus FROM dbo.CustInfo WITH (NOLOCK) WHERE CustId = @UserId					 
		 	
	END 
	
	---------------- ## Agent ##-------------
	ELSE IF @UserType IN (1,2) 
	BEGIN 
		-- Check if agent user ID not exist
		IF NOT EXISTS ( SELECT 1 FROM dbo.AgentUser WITH (NOLOCK) WHERE AgentUserId = @UserId )
			BEGIN
				SELECT 
					@ErrCode = 5300, 
					@ErrMsg = 'Agent user ID not exist [AgentUserId = ' + COALESCE(CAST(@UserId AS VARCHAR(10)), SPACE(1)) + ']'
				RETURN
			END	
			
		SELECT	@AgentId = AgentId, @Status = Status 
		FROM	dbo.AgentUser WITH (NOLOCK) 
		WHERE	AgentUserId = @UserId 

		-- Check if agent ID not exist
		IF ISNULL(@AgentId,0) = 0
			BEGIN
				SELECT 
					@ErrCode = 5100, 
					@ErrMsg = 'Agent ID not exist'
				RETURN
			END			

		SELECT  @BetStatus = BetStatus
		FROM	dbo.AgentInfo WITH (NOLOCK)
		WHERE	AgentId = @AgentId

	END
	
	SELECT @Status AS Status, @BetStatus AS BetStatus
 
END
GO 
GRANT EXECUTE ON [dbo].[Age_API_GetUserAccountStatus] TO [aplweb]
Go

GO
GRANT EXECUTE ON [dbo].[Age_API_GetUserAccountStatus] TO [apollo_srv] AS [dbo]
GO
