ALTER PROCEDURE  [dbo].[Admin_AutoSettlement_ClearFailActionOutright]			
	@leagueid int,		
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created by:Dan
	Date:20130702
	Task: clear failed auto settlement action for a match
	DB: SVRPROD/ProdDB	
	Revisions:		

	Param explanation:										
			
*/
BEGIN
SET NOCOUNT ON
	
	BEGIN TRY
		UPDATE dbo.outright_ex WITH (ROWLOCK, UPDLOCK)
		SET	FailedActionID = NULL
		WHERE orid_ex in (SELECT o.orid
				FROM dbo.outright o WITH(NOLOCK) 
				WHERE o.leagueID = @LeagueID)
	END TRY
	BEGIN CATCH
		Select @ErrMsg = 'Data updating process failed!!'
			,@ErrCode = 101		
	END CATCH

END
		
GO 
GRANT EXECUTE ON [dbo].[Admin_AutoSettlement_ClearFailActionOutright] TO [aplweb]	