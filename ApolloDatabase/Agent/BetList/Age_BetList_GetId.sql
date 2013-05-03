ALTER PROC [dbo].[Age_BetList_GetId]
	@LoggedId INT,
	@IsAgent BIT,
	@Username NVARCHAR(50) = '' ,
	@AgentId INT OUTPUT,
	@CustID INT OUTPUT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT
/*
Created: 20130411@Sophia
Task : Get CustId , AgentId by username
DB:  SVRAGE.RepDB
Original:  

Revisions:

Param's Explanation:  
	+ @IsAgent = 1 : by Agent's Username,
			   = 0 : by Member's Username

EX: 
	DECLARE @AgentID INT , @Custid INT 
	Exec [Age_BetList_GetId] @LoggedId =3, @IsAgent=0, @Username= 'anders-tes-3-35', @AgentID = @AgentID OUTPUT, @Custid = @CustID OUTPUT
	SELECT  @AgentID  , @Custid     
	   
 
*/
AS
SET NOCOUNT ON

SELECT @AgentId = NULL, @CustID = NULL

IF  @Username = ''
	SELECT  @ErrCode = 100, @ErrMsg = 'Invalid data'
ELSE
BEGIN 
	-----By Agent username
		IF @IsAgent = 1 
		BEGIN
				SELECT  @AgentId =C.AgentId, @CustId = -1
				FROM	AgentInfo P WITH (NOLOCK)
				INNER JOIN AgentInfo C WITH (NOLOCK)
					ON	C.AgentHId.IsDescendantOf(P.AgentHId) = 1 
				WHERE	C.Username= @Username	
						AND P.AgentId = @LoggedId

				IF @AgentId IS NULL
					SELECT  @ErrCode = 101, @ErrMsg = 'Invalid data'	 
		END 
	----By Member username
		ELSE
		IF @IsAgent = 0
		BEGIN 
				SELECT	@AgentId = -1, @CustID = M.CustId
				FROM	AgentInfo P WITH (NOLOCK)
				INNER JOIN AgentInfo C WITH (NOLOCK)
					ON	C.AgentHId.IsDescendantOf(P.AgentHId) = 1 
				INNER JOIN CustInfo M WITH (NOLOCK)
					ON M.AgentID = C.AgentID 
				WHERE	M.Username= @Username
						AND P.AgentId = @LoggedId

				IF @CustID IS NULL
					SELECT  @ErrCode = 102, @ErrMsg = 'Invalid data'	 
		END 
END

GO 
GRANT EXECUTE ON [dbo].[Age_BetList_GetId] TO [aplweb]