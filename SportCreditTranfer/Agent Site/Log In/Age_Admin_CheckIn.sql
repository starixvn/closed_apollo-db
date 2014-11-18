ALTER PROCEDURE [dbo].[Age_Admin_CheckIn]
	@UserId			INT,
	@NetSessionId	VARCHAR(30),
	@OnUserId		INT				OUTPUT,
	@IP				VARCHAR(50) = ''	
AS

/*  
 * Created: 05232013@Edward
 * Task : User check in
 * DB: OnAgent
 *  
 * Revisions:     
	-20121026@Edward add input param LoginDate
	-20131212@Dan: add reloadtime
 * Param's Explanation: 
*/

BEGIN
	SET NOCOUNT ON	

	UPDATE OnAgent WITH (ROWLOCK, UPDLOCK)
	SET IsKickedOut = 1 
	WHERE UserId = @UserId 		

	INSERT INTO OnAgent(UserId,IsKickedOut, IP, NetSessionId, ReloadTime)
	VALUES (@UserId,0, @IP, @NetSessionID, getdate())
	
	SET  @OnUserId = SCOPE_IDENTITY()
END

