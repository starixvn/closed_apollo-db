ALTER PROCEDURE  [dbo].[Admin_AutoSettlement_ClearFailAction]		
	@AdminId int,
	@matchid int,	
	@matchids	VARCHAR(2000) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created by:Dan
	Date:20130702
	Task: clear failed auto settlement action for a match
	DB: SVRPROD/ProdDB	
	Revisions:		
		- 20140819@Sophia: Change @creator to @AdminId
	Param explanation:										
			
*/
BEGIN
SET NOCOUNT ON
	IF @matchid>0
	BEGIN
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
	ELSE
	BEGIN		
		BEGIN TRY
			UPDATE dbo.match_remark_ex WITH (ROWLOCK, UPDLOCK)
			SET	FailedActionID = NULL
			WHERE matchid IN (SELECT val FROM dbo.strSplit(@matchids,','))
		END TRY
		BEGIN CATCH
			Select @ErrMsg = 'Data updating process failed!!'
				,@ErrCode = 102	
		END CATCH
	END
END
		
GO 
GRANT EXECUTE ON [dbo].[Admin_AutoSettlement_ClearFailAction] TO [aplweb]	