ALTER PROCEDURE  [dbo].[Admin_AutoSettlement_GenerateCommandOutright]		
	@matchid int,
	@actionid tinyint,
	@status nvarchar(10),
	@deadheat float
AS	
/*	Creator: Dan
	Date: 2013-06-29
	Task: create command for outright settlement
	DB: SVRTXN/TransDB
	Original SP: 
	History:
		
	Param's Explanation:					
*/

DECLARE @SQLCommand nvarchar(MAX), @action varchar(10), @SPName varchar(2000), 
	@cmdStatus varchar(50), @cmdStatusID tinyint

DECLARE @match table(matchid int)

SELECT @cmdStatus='pending', @cmdStatusID=0

--if no auto settlement for all, then return
IF NOT EXISTS(SELECT 1 FROM SystemSettings WHERE VName = 'isUsingAutoSettlement' AND VValue='1')
	RETURN

--if no auto settlement for this outright, then return
IF EXISTS(SELECT 1 FROM SVRPRO.ProdDB.dbo.outright_ex WITH (NOLOCK) 
	WHERE orid_ex= @matchid and DisabledAutoSettle=1)
	RETURN

IF @actionID IN (30) -- settle outright event
BEGIN
	declare @isDeadheat bit
	set @isDeadheat= CAST(@deadheat as BIT)

	SELECT @SQLCommand = 'EXEC SVRPRO.ProdDB.[dbo].[Dot_Admin_SettleOutright_Event] ' +		
		' @matchid = ' + CAST(@matchid AS varchar(50)) + ' ,' +
		' @status = ''' + @status  + ''' ,' +		 
		' @isDeadheat = ' + CAST(@isDeadheat AS varchar(50)) + ' ,' + 
		' @ErrCode = @ErrCode OUTPUT , ' +
		' @ErrMsg = @ErrMsg OUTPUT ',
		@SPName = 'Dot_Admin_SettleOutright_Event'
END		
ELSE IF @actionID IN (31)  -- settle outright ticket
BEGIN	
	SELECT @SQLCommand = 'EXEC [dbo].[Dot_Admin_SettleOutright_Trans] ' +
		' @matchid = ' + CAST(@matchid AS varchar(50)) + ' ,' +
		' @status = ''' + @status  + ''' ,' +		 
		' @deadheat = ' + CAST(@deadheat AS varchar(50)) + ' ,' + 
		' @ErrCode = @ErrCode OUTPUT , ' +
		' @ErrMsg = @ErrMsg OUTPUT ',
		@SPName = 'Dot_Admin_SettleOutright_Trans'

END

	INSERT INTO [dbo].[AutoSettlementCommand]
			([SPName]
			,[SQLCommand]
			,[ActionId]
			,[CreatedDate]
			,[ExecutedDate]
			,[StatusID]
			,[RetryCount]
			,[MatchID]
			,[Status]
			,[Duration]
			,[Note])
	SELECT
			@SPName [SPName]
			,@SQLCommand [SQLCommand]
			,@actionID [ActionId]
			,getdate() [CreatedDate]
			,NULL [ExecutedDate]
			,@cmdStatusID [StatusID]
			,0 [RetryCount]
			,@matchid [MatchID]
			,@cmdStatus [Status]
			,NULL [Duration]
			,NULL [Note]           
