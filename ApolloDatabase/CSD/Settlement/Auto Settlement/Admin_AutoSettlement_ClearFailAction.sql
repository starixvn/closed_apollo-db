CREATE PROCEDURE  [dbo].[Admin_AutoSettlement_ClearFailAction]		
	@creator int,
	@matchid int,		
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
		@isTurnOn: 0-off; 1-on
		@matchid: 0-all; >0: a specific match
			
*/
BEGIN
SET NOCOUNT ON

	BEGIN TRY
		UPDATE dbo.match_remark_ex WITH (ROWLOCK, UPDLOCK)
		SET	FailedActionID = NULL
		WHERE matchid=@matchid
	END TRY
	BEGIN CATCH
		Select @ErrMsg = 'Data updating process failed!!'
			,@ErrCode = 101		
	END CATCH
END
		
GO 
GRANT EXECUTE ON [dbo].[Admin_AutoSettlement_ClearFailAction] TO [aplweb]	