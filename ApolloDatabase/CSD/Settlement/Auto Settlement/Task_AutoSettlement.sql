ALTER PROCEDURE [dbo].[Task_AutoSettlement]
AS
/*
	Created by:Dan
	Date:2013-07-02
	Task: execute auto Settlement (job)
	DB: SVRTRANS/TRANSDB	
	Revisions:		

	Param explanation:				
		StatusID & Status
		0: pending; 
		1 : running; 
		2: failed and waiting for retry;  
		3: failed and no retry; 
		4: completed; 
		5: skipped
			
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @sql			NVARCHAR(MAX),
			@execID			INT,		
			@statusID		TINYINT,
			@matchID		INT,					
			@ErrCode		INT = 0 ,
			@ErrMsg			NVARCHAR(200) = '' ,
			@ActionId		TINYINT,
			@action			VARCHAR(10),
			@RetryCount		TINYINT			

	SELECT TOP 1	@sql = SQLCommand, 
					@execID = execID, 
					@statusID = statusID,
					@matchID = MatchID,
					@ActionId=ActionId,
					@RetryCount = RetryCount
				
	FROM	AutoSettlementCommand WITH(NOLOCK)
	WHERE	(	StatusID = 0 -- get pending command
				OR (StatusID = 2 AND AllowedDate < GETDATE()) -- get fail command and retry after a delay time
			)
			--AND StatusID <> 1  -- Running			
	ORDER BY statusID desc, execID
	
	IF @execID IS NULL OR @sql IS NULL --no command in queue
		RETURN

	---waiting for any previous command which is not finish
	IF EXISTS(SELECT 1 FROM [dbo].[AutoSettlementCommand] WITH (NOLOCK)
			WHERE matchid=@matchid and statusid in (0,1,2) and [execID] < @execID)
	BEGIN	
		RETURN
	END

	--has failed command, skip commands
	IF EXISTS(SELECT 1 FROM [dbo].[AutoSettlementCommand] WITH (NOLOCK)
			WHERE matchid=@matchid and statusid in (3,5) and [execID] < @execID)
	BEGIN
		--- UPDATE STATUS
		UPDATE AutoSettlementCommand WITH(ROWLOCK,UPDLOCK)
		SET StatusID		= 5,
			ExecutedDate	= GETDATE(),
			Status			= 'skipped'
		WHERE execID = @execID
		RETURN
	END	
		
	--- UPDATE STATUS
	UPDATE AutoSettlementCommand WITH(ROWLOCK,UPDLOCK)
	SET StatusID		= 1,
		ExecutedDate	= GETDATE(),
		Status			= 'running'
	WHERE execID = @execID

	BEGIN TRY
		-- checking before settle
		IF @actionID IN (2, 3 , 4, 6) 
		BEGIN
			SELECT @action = CASE @actionID 			
				WHEN 2 THEN 'CAL-HT'
				WHEN 3 THEN 'CAL-FT'
				WHEN 4 THEN 'CAL'
				WHEN 6 THEN 'CAL'
			END

			EXEC [dbo].[Admin_Settlement_Checking]
				@matchid = @matchid,
				@action = @action,		
				@ErrCode = @ErrCode OUTPUT,
				@ErrMsg = @ErrMsg OUTPUT
		
			IF ISNULL(@ErrCode,0)<>0
				RAISERROR(@ErrMsg,16,1)
		END
		
		EXEC sp_executesql @sql, N'@ErrCode int = 0 OUTPUT,@ErrMsg nvarchar(200) = '''' OUTPUT', 
					@ErrCode = @ErrCode OUTPUT , @ErrMsg = @ErrMsg OUTPUT

		IF ISNULL(@ErrCode,0)<>0
				RAISERROR(@ErrMsg,16,1)
		
		UPDATE AutoSettlementCommand WITH(ROWLOCK,UPDLOCK)
		SET StatusID	= 4, --- successed	
			Duration	= DATEDIFF(ms,ExecutedDate,GETDATE()),
			Status		= 'Completed',
			AllowedDate = NULL,
			Note = NULL
		WHERE execID = @execID
	
	END TRY

	BEGIN CATCH				
		SELECT @ErrMsg = ERROR_MESSAGE()
		SELECT @RetryCount = case when  @statusID  = 0 then 0
						else @RetryCount + 1 end 

		SELECT @StatusID	= CASE	WHEN @statusID  = 0 THEN 2  -- Failed & retry 
								WHEN @statusID  = 2 and @RetryCount = 3 THEN 3	-- Failed & stop retry 
								ELSE 2 END	

		UPDATE AutoSettlementCommand WITH(ROWLOCK,UPDLOCK)
		SET StatusID = @StatusID,
			Duration = DATEDIFF(ms,ExecutedDate,GETDATE()),
			RetryCount = @RetryCount, 
			Status = CASE	WHEN @StatusID = 0 THEN 'pending'  -- put to retry 1
								WHEN @statusID  = 2 THEN 'Failed'	 -- fail and retry
								WHEN @statusID  = 3 THEN 'Failed'	 -- fail and no retry
								END,
			AllowedDate		= CASE  WHEN @RetryCount = 0  THEN DATEADD(MINUTE,1,GETDATE())		--Delay in 1 minute	
										WHEN @RetryCount = 1 THEN DATEADD(MINUTE,3,GETDATE())
										WHEN @RetryCount = 2 THEN DATEADD(MINUTE,5,GETDATE())										
										ELSE AllowedDate END,
			Note = @ErrMsg
		WHERE execID = @execID
	
		if (@StatusID=3)
		BEGIN
			--notify fail for match
			UPDATE SVRPRO.ProdDB.dbo.match_remark_ex WITH(ROWLOCK,UPDLOCK)
			SET FailedActionID = @ActionId
			WHERE matchid=@matchid

			IF @@ROWCOUNT=0
				INSERT  SVRPRO.ProdDB.dbo.match_remark_ex (matchid, FailedActionID)
				VALUES(@matchid, @ActionId)
		END

	END CATCH
END

