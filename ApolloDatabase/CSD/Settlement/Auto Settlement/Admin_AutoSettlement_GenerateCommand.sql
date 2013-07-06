ALTER PROCEDURE  [dbo].[Admin_AutoSettlement_GenerateCommand]		
	@matchids	VARCHAR(2000),
	@matchid INT,
	@actionID smallint,
	@fth smallint = NULL,
	@fta smallint = NULL,
	@hth smallint = NULL,
	@hta smallint = NULL,
	@goalrecord nvarchar(50)= NULL,
	@betstatus nvarchar(50) = NULL
AS	
/*	Creator: Dan
	Date: 2013-06-29
	Task: create command for 
	DB: SVRTXN/TransDB
	Original SP: Admin_Settlement_1
	History:
		
	Param's Explanation:					
*/

DECLARE @SQLCommand nvarchar(MAX), @action varchar(10), @SPName varchar(2000), 
	@Status varchar(50), @StatusID tinyint

DECLARE @match table(matchid int)

SELECT @Status='pending', @StatusID=0

--if no auto settlement for all, then return
IF NOT EXISTS(SELECT 1 FROM SystemSettings WHERE VName = 'isUsingAutoSettlement' AND VValue='1')
	RETURN

IF @actionid IN (5)
BEGIN
	INSERT INTO @match(matchid)
	SELECT	m.matchid
	FROM match m WITH (NOLOCK) left join dbo.match_remark_ex mr WITH (NOLOCK)
		ON m.matchid=mr.matchid
	WHERE m.matchid IN (SELECT val FROM dbo.strSplit(@matchids,','))
		AND ISNULL(DisabledAutoSettle,0)=0
	
	if @@ROWCOUNT=0
		RETURN
END
ELSE
BEGIN
	--if no auto settlement for this match, then return
	IF EXISTS(SELECT 1 FROM match_remark_ex WITH (NOLOCK) 
			WHERE MATCHID= @matchid and DisabledAutoSettle=1)
		RETURN
END


IF @actionID IN (0, 2, 3 , 4, 6) -- 'UNDO',  'CAL-HT', 'CAL-FT', 'CAL',Re-Calc
BEGIN
	SELECT @action = CASE @actionID 
			WHEN 0 THEN 'UNDO'
			WHEN 2 THEN 'CAL-HT'
			WHEN 3 THEN 'CAL-FT'
			WHEN 4 THEN 'CAL'
			WHEN 6 THEN 'CAL'
			END
			, @SPName='Admin_Settlement_1'

	SELECT @SQLCommand = 'EXEC [dbo].[Admin_Settlement_1] ' +
		' @creator = 0 ' + ' ,' +
		' @matchid = ' + CAST(@matchid AS varchar(50)) + ' ,' +
		' @fth = ' + CASE WHEN @fth IS NULL THEN 'NULL' ELSE CAST(@fth AS varchar(50))  END + ' ,' +
		' @fta = ' + CASE WHEN @fta IS NULL THEN 'NULL' ELSE CAST(@fta AS varchar(50)) END + ' ,' + 
		' @hth = ' + CASE WHEN @hth IS NULL THEN 'NULL' ELSE CAST(@hth AS varchar(50)) END + ' ,' + 
		' @hta = '  + CASE WHEN @hta IS NULL THEN 'NULL' ELSE CAST(@hta AS varchar(50)) END + ' ,' + 
		' @goalrecord = ' + CASE WHEN @goalrecord IS NULL THEN 'NULL' ELSE '''' + CAST(@goalrecord AS varchar(50)) + '''' END + ',' + 
		' @betstatus = ' + + CASE WHEN @betstatus IS NULL THEN 'NULL' ELSE '''' + CAST(@betstatus AS nvarchar(50)) + '''' END + ',' + 
		' @action = ''' + @action + ''' ,' + 
		' @ErrCode = @ErrCode OUTPUT , ' +
		' @ErrMsg = @ErrMsg OUTPUT '
END		
ELSE IF @actionID IN (14, 15 , 16)  -- Refund Parlay HT, Refund Parlay FT, Refund Parlay All
BEGIN
	SELECT @action = CASE @actionID 			
			WHEN 14 THEN 'REFUND-HT'
			WHEN 15 THEN 'REFUND-FT'		
			WHEN 16 THEN 'REFUND'
			END
			, @SPName='Admin_Settlement_Parlay'
	SELECT @SQLCommand = 'EXEC [dbo].[Admin_Settlement_Parlay] ' +
		' @creator = 0 ' + ' ,' +
		' @matchids = ''' + CAST(@matchid AS varchar(50)) + ''' ,' +		
		' @action = ''' + @action + ''' ,' + 
		' @ErrCode = @ErrCode OUTPUT , ' +
		' @ErrMsg = @ErrMsg OUTPUT '

END
ELSE IF @actionID IN (1) -- Calculate FG/NG
BEGIN	
	SELECT @SQLCommand = 'EXEC [dbo].[Admin_Settlement_FGLG] ' +
		' @creator = 0 ' + ' ,' +
		' @matchid = ' + CAST(@matchid AS varchar(50)) + ' ,' +		
		' @goalrecord = ' + CASE WHEN @goalrecord IS NULL THEN 'NULL' ELSE '''' + CAST(@goalrecord AS varchar(50)) + '''' END + ',' + 
		' @betstatus = ' + + CASE WHEN @betstatus IS NULL THEN 'NULL' ELSE '''' + CAST(@betstatus AS nvarchar(50)) + '''' END + ',' + 		
		' @IncludeLG = 0,' + 
		' @ErrCode = @ErrCode OUTPUT , ' +
		' @ErrMsg = @ErrMsg OUTPUT '
		, @SPName='Admin_Settlement_FGLG'
END
ELSE IF @actionID IN (11) -- Refund HT
BEGIN	
	SELECT @SQLCommand = 'EXEC [dbo].[Admin_Settlement_RefundHT] ' +
		' @adminid = 0 ' + ' ,' +
		' @matchid = ' + CAST(@matchid AS varchar(50)) + ' ,' +				
		' @ErrCode = @ErrCode OUTPUT , ' +
		' @ErrMsg = @ErrMsg OUTPUT '
		, @SPName='Admin_Settlement_RefundHT'
END
ELSE IF @actionID IN (12) -- Refund FT
BEGIN	
	SELECT @SQLCommand = 'EXEC [dbo].[Admin_Settlement_RefundFT] ' +
		' @adminid = 0 ' + ' ,' +
		' @matchid = ' + CAST(@matchid AS varchar(50)) + ' ,' +				
		' @betstatus = ' + + CASE WHEN @betstatus IS NULL THEN 'NULL' ELSE '''' + CAST(@betstatus AS nvarchar(50)) + '''' END + ',' + 
		' @ErrCode = @ErrCode OUTPUT , ' +
		' @ErrMsg = @ErrMsg OUTPUT '
		, @SPName='Admin_Settlement_RefundFT'
END
ELSE IF @actionID IN (13) -- Refund All
BEGIN	
	SELECT @SQLCommand = 'EXEC [dbo].[Admin_Settlement_Refund_All] ' +
		' @creator = 0 ' + ' ,' +
		' @matchid = ' + CAST(@matchid AS varchar(50)) + ' ,' +				
		' @betstatus = ' + + CASE WHEN @betstatus IS NULL THEN 'NULL' ELSE '''' + CAST(@betstatus AS nvarchar(50)) + '''' END + ',' + 
		' @ErrCode = @ErrCode OUTPUT , ' +
		' @ErrMsg = @ErrMsg OUTPUT '
		, @SPName='Admin_Settlement_Refund_All'
END
ELSE IF @actionID IN (17) -- Refund All FGLG
BEGIN	
	SELECT @SQLCommand = 'EXEC [dbo].[Admin_Settlement_Refund_FGLG] ' +
		' @adminid = 0 ' + ' ,' +
		' @matchid = ' + CAST(@matchid AS varchar(50)) + ' ,' +				
		' @LGOnly = 0,' + 
		' @ErrCode = @ErrCode OUTPUT , ' +
		' @ErrMsg = @ErrMsg OUTPUT '
		, @SPName='Admin_Settlement_Refund_FGLG'
END
---confirm action 18
ELSE IF @actionID IN (18) -- Refund Last Goal Only
BEGIN	
	SELECT @SQLCommand = 'EXEC [dbo].[Admin_Settlement_Refund_FGLG] ' +
		' @adminid = 0 ' + ' ,' +
		' @matchid = ' + CAST(@matchid AS varchar(50)) + ' ,' +				
		' @LGOnly = 1,' + 
		' @ErrCode = @ErrCode OUTPUT , ' +
		' @ErrMsg = @ErrMsg OUTPUT '
		, @SPName='Admin_Settlement_Refund_FGLG'
END

--insert command
IF @actionid IN (5)
BEGIN
	SELECT @action = 'CAL', @SPName='Admin_Settlement_Parlay'    
	
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
			,'EXEC [dbo].[Admin_Settlement_Parlay] ' +
				' @creator = 0 ' + ' ,' +
				' @matchids = ''' + CAST(matchid AS varchar(50)) + ''' ,' +		
				' @action = ''' + @action + ''' ,' + 
				' @ErrCode = @ErrCode OUTPUT , ' +
				' @ErrMsg = @ErrMsg OUTPUT ' [SQLCommand]
			,@actionID [ActionId]
			,getdate() [CreatedDate]
			,NULL [ExecutedDate]
			,@StatusID [StatusID]
			,0 [RetryCount]
			,matchid [MatchID]
			,@Status [Status]
			,NULL [Duration]
			,NULL [Note]    
	FROM @match	           
END
ELSE
BEGIN
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
			,@StatusID [StatusID]
			,0 [RetryCount]
			,@matchid [MatchID]
			,@Status [Status]
			,NULL [Duration]
			,NULL [Note]           
END