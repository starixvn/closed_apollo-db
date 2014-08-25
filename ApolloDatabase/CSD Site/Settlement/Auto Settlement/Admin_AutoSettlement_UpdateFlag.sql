ALTER PROCEDURE  [dbo].[Admin_AutoSettlement_UpdateFlag]		
	@AdminId int,
	@matchid int,
	@isTurnOn bit,
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created by:Dan
	Date:20130702
	Task: turn on/off settlement for a match/all match
	DB: SVRTRANS/TRANSDB	
	Revisions:		
		- 20140819@Sophia: Change @creator to @AdminId

	Param explanation:						
		@isTurnOn: 0-off; 1-on
		@matchid: 0-all; >0: a specific match
			
*/
BEGIN
SET NOCOUNT ON

DECLARE @LogData nvarchar(200), @previousStatus bit

IF (@matchid = 0) --all matches
BEGIN	
	/*
	SELECT @previousStatus= CAST([VValue] as BIT)	
	FROM SystemSettings	
	WHERE VName='isUsingAutoSettlement'

	IF (@previousStatus=@isTurnOn)
		RETURN
	*/

	UPDATE SystemSettings
	SET	[VValue] = CAST(@isTurnOn as varchar(1))
	WHERE VName='isUsingAutoSettlement'

	IF (@@ERROR <> 0)
	BEGIN
		Select @ErrMsg = 'Data updating process failed!!'
				,@ErrCode = 100		
		RETURN
	END
	
	--OFF
	IF @isTurnOn = 0
	BEGIN
		--mark all pending and waiting command be skipped
		UPDATE AutoSettlementCommand WITH(ROWLOCK,UPDLOCK)
		SET StatusID		= 5,
			ExecutedDate	= GETDATE(),
			Status			= 'skipped',
			Note			= 'auto settlement (global) is turned off'				
		FROM	AutoSettlementCommand 
		WHERE	StatusID in (0,2) -- get pending commands, failed and retry commands
		
		IF (@@ERROR <> 0)
		BEGIN
			Select @ErrMsg = 'Data updating process failed!!'
					,@ErrCode = 101		
			RETURN
		END
	END
	
	SELECT @LogData = 'Turn ' + CASE WHEN @isTurnOn =1 THEN 'on' ELSE 'off' END + ' auto settlement for all matches'
END
ELSE
BEGIN
	--validate
	--DECLARE @odd
	-- turn off and there is pending/running command

	DECLARE @prevDisabledAutoSettle BIT
	
	SELECT @prevDisabledAutoSettle=DisabledAutoSettle
	from SVRPRO.ProdDB.dbo.match_remark_ex WITH (NOLOCK)
	WHERE matchid=@matchid

	SET @prevDisabledAutoSettle=ISNULL(@prevDisabledAutoSettle,0)

	--same status
	IF (@prevDisabledAutoSettle = case when @isTurnOn = 0 then 1 else 0 end)
		RETURN

	IF @isTurnOn=0 AND 
		EXISTS(SELECT 1 FROM [dbo].[AutoSettlementCommand]				
				WHERE matchid=@matchid
					and	StatusID in (0,1,2)
				) 
	BEGIN
		Select @ErrMsg = 'There are running auto settlement commands! Please try again later.'
				,@ErrCode = 103		
		RETURN
	END

	-- turn on and there is action settlement already
	IF @isTurnOn=1 AND 
		EXISTS(SELECT 1 FROM [dbo].match_log WITH (NOLOCK)
				WHERE matchid=@matchid					
				) 
	BEGIN
		Select @ErrMsg = 'There was action settlement already so it cannot turn on to ensure consistency'
			,@ErrCode = 104		
		RETURN
	END

	BEGIN TRY
		UPDATE SVRPRO.ProdDB.dbo.match_remark_ex WITH (ROWLOCK, UPDLOCK)
		SET	DisabledAutoSettle = case when @isTurnOn = 0 then 1 else 0 end
		WHERE matchid=@matchid

		IF @@ROWCOUNT=0 AND @isTurnOn=0 --OFF
			INSERT SVRPRO.ProdDB.dbo.match_remark_ex (matchid, DisabledAutoSettle)
			SELECT @matchid, 1
	END TRY
	BEGIN CATCH
		Select @ErrMsg = 'Data updating process failed!!'
			,@ErrCode = 105		
		RETURN
	END CATCH

	SELECT @LogData = 'Turn ' + CASE WHEN @isTurnOn =1 THEN 'on' ELSE 'off' END + ' auto settlement for matchid=' +  CAST(@matchid as varchar(50)) 
END
		
EXEC dbo.WriteLog_UserLog_T  @AdminId, @LogData

BEGIN TRY
	EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Settle
		@UserID = @AdminId,
		@Matchid = @matchid,
		@ActionID = 125,
		@finalhomescore = null,
		@finalawayscore = null,  
		@hthomescore = null,
		@htawayscore = null,
		@GoalRecord = null,
		@betstatus = null,
		@Remark = @LogData,
		@IP = @IP
END TRY  
BEGIN CATCH	
	SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 250)	
	EXEC LogDB.dbo.WriteLog_Settlement_Settle
		@UserID = @AdminId,
		@Matchid = @matchid,
		@ActionID = 125,
		@finalhomescore = null,
		@finalawayscore = null,  
		@hthomescore = null,
		@htawayscore = null,
		@GoalRecord = null,
		@betstatus = null,
		@Remark = @LogData,
		@IP = @IP
END CATCH
END

GO 
GRANT EXECUTE ON [dbo].[Admin_AutoSettlement_UpdateFlag] TO [aplweb]	