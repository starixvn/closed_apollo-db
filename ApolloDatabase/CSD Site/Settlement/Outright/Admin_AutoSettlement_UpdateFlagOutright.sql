ALTER PROCEDURE  [dbo].[Admin_AutoSettlement_UpdateFlagOutright]
	@AdminId int,
	@leagueid int,
	@isTurnOn bit,
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created by:Dan
	Date:20130702
	Task: turn on/off settlement for outright
	DB: SVRTRANS/TRANSDB	
	Revisions:		
		- 20140819@Sophia: Change @creator to @AdminId
	Param explanation:						
		@isTurnOn: 0-off; 1-on
		@leagueid: outright league
			
*/
BEGIN
SET NOCOUNT ON

DECLARE @LogData nvarchar(200), @previousStatus bit, @totalOutright int
DECLARE @outright table(orid INT, DisabledAutoSettle BIT NULL, orid_ex INT)

INSERT @outright(orid, DisabledAutoSettle, orid_ex)
SELECT o.orid, orex.DisabledAutoSettle, orex.orid_ex
FROM SVRPRO.ProdDB.dbo.outright o WITH(NOLOCK) 
	LEFT JOIN SVRPRO.ProdDB.dbo.outright_ex orex WITH(NOLOCK) ON o.orid= orex.orid_ex	
WHERE o.leagueID = @LeagueID

SELECT @totalOutright = @@ROWCOUNT

--same status
IF (NOT EXISTS (SELECT 1 FROM @outright 
				WHERE ISNULL(DisabledAutoSettle,0) <> case when @isTurnOn = 0 then 1 else 0 end))
		RETURN

--validate
-- turn off and there is pending/running command
IF @isTurnOn=0 AND 
	EXISTS(SELECT 1 FROM [dbo].[AutoSettlementCommand]				
			WHERE matchid in (SELECT orid FROM @outright)
				and actionid in (30,31)
				and	StatusID in (0,1,2)
			) 
BEGIN
	Select @ErrMsg = 'There are running auto settlement commands! Please try again later.'
			,@ErrCode = 101		
	RETURN
END

-- turn on and there is action settlement already
IF @isTurnOn=1 AND 
	EXISTS(SELECT 1 FROM [dbo].outright_log WITH (NOLOCK)
			WHERE orid in (SELECT orid FROM @outright)
			) 
BEGIN
	Select @ErrMsg = 'There was action settlement already so it cannot turn on to ensure consistency'
		,@ErrCode = 102		
	RETURN
END

BEGIN TRY
	UPDATE SVRPRO.ProdDB.dbo.outright_ex WITH (ROWLOCK, UPDLOCK)
	SET	DisabledAutoSettle = case when @isTurnOn = 0 then 1 else 0 end
	WHERE orid_ex in (SELECT orid FROM @outright)

	IF @@ROWCOUNT< @totalOutright AND @isTurnOn=0 --OFF
		INSERT SVRPRO.ProdDB.dbo.outright_ex (orid_ex, DisabledAutoSettle)		
		SELECT orid, 1 
		FROM @outright
		WHERE DisabledAutoSettle is null and orid_ex IS NULL
END TRY
BEGIN CATCH
	Select @ErrMsg = 'Data updating process failed!!'
		,@ErrCode = 103		
	RETURN
END CATCH

SELECT @LogData = 'Turn ' + CASE WHEN @isTurnOn =1 THEN 'on' ELSE 'off' END + ' auto outright settlement for leagueid=' +  CAST(@LeagueID as varchar(50)) 
		
EXEC dbo.WriteLog_UserLog_T  @AdminId, @LogData

BEGIN TRY
	EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_SettleOutright
		@UserID = @AdminId,
		@OrId = 0,
		@LeagueId = @leagueid,
		@ActionID = 126,
		@status = null,
		@deadheat = null, 
		@Remark = @LogData,
		@IP = @IP
END TRY  
BEGIN CATCH	
	SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 250)	
	EXEC LogDB.dbo.WriteLog_Settlement_SettleOutright
		@UserID = @AdminId,
		@OrId = 0,
		@LeagueId = @leagueid,
		@ActionID = 126,
		@status = null,
		@deadheat = null, 
		@Remark = @LogData,
		@IP = @IP
END CATCH
END

GO 
GRANT EXECUTE ON [dbo].[Admin_AutoSettlement_UpdateFlagOutright] TO [aplweb]	