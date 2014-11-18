ALTER PROCEDURE [dbo].[Age_Transfer_AgentToAgent]
(
	@LoggedId	INT,
	@AgentId	INT,
	@Amount		INT,
	@TransType	TINYINT = 1,
	@IP			VARCHAR(40) = '',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(1000) = '' OUTPUT

)
 /*
    Created	: Sophia
	Date	: 20141112
    Task	: Transfer credit from Agent To Agent
    DB		: SVRTXN/TransDB
    Revisions: 

	Parameters:
		@TransType  = 1: Deposit
					= 2: Draw		
	Test string: 
		EXEC [Age_Transfer_AgentToAgent]	
				 

 */
AS
BEGIN 
SET NOCOUNT ON

DECLARE @LoggedHId	HIERARCHYID, 
		@rowcnt INT, @Bettype SMALLINT,
		@ParentId INT, @ParentName  NVARCHAR(50), @ParentBalanceBefore MONEY, 
		@Username NVARCHAR(50), @BalanceBefore MONEY 			

DECLARE @RefNo BIGINT, @grefno INT, @TransDate DATETIME	

--- for write log
DECLARE 
		@startRun		DATETIME,
		@endRun			DATETIME,
		@duration		INT,
		@logSPData		VARCHAR(5000),
		@xml			XML


IF @TransType = 1 
	SET @Bettype = 22001  ---Deposit
ELSE 
	SET @Bettype = 22002  ---Draw					

----- Get Agent Info
	SELECT @LoggedHId = AgentHId 
	FROM  dbo.AgentInfo WITH (NOLOCK) 
	WHERE AgentId = @LoggedId
			

	SELECT	@Username = A.Username,	
			@ParentId = A.ParentId,
			@ParentName = (SELECT Username FROM dbo.AgentInfo WITH (NOLOCK) WHERE AgentID = A.ParentId) 
	FROM	dbo.AgentInfo A WITH (NOLOCK)			
	WHERE	A.AgentHId.IsDescendantOf(@LoggedHId) = 1
			AND A.AgentID = @AgentID 
			AND A.AgentID <> @LoggedID 

 --- Check exists
 IF ISNULL(@Username ,'') = '' AND ISNULL(@ParentId, 0) = 0
 BEGIN 
	SELECT	@ErrCode = 5106,			
			@ErrMsg = 'Invalid agent ID'
	RETURN
 END
 
 	-----------------------------------
	--- Get RefNo
	BEGIN TRANSACTION
		UPDATE	ref WITH (ROWLOCK, UPDLOCK)  
		SET		@grefno = transcode=transcode+1
		WHERE	refid='acc'

		IF @@Error <> 0
		BEGIN
			ROLLBACK TRANSACTION
			RETURN
		END		

		SELECT @RefNo=200000000000+@grefno
	COMMIT TRANSACTION

	IF ISNULL(@RefNo,0) = 0 
	BEGIN 	
		SELECT	@ErrCode = 8000,			
				@ErrMsg = 'Invalid RefNo.'
		RETURN

	END

	
	SELECT @TransDate = GETDATE()

	----###########################################
	--- Insert Transfer Transaction 
	
	IF @Bettype = 22001   --- DEPOSIT
	BEGIN 
		
			SELECT @ParentBalanceBefore = SUM(ISNULL(Amount,0)) FROM dbo.CreditTrans WITH (NOLOCK) WHERE AgentId = @ParentId
		
			--- Check valid
			IF @ParentBalanceBefore < 0
			BEGIN 
				SELECT	@ErrCode = 8001,			
						@ErrMsg = 'Sport Credit of '+ @ParentName +' is not enough to deposit.'
				RETURN
			END

			-----Deposit amount = [0; parent's credit]
			IF @Amount NOT BETWEEN 0 AND @ParentBalanceBefore 
			BEGIN 
				SELECT	@ErrCode = 8003,			
						@ErrMsg = 'Invalid Amount.'
				RETURN
			END

		---- 1.a. Upline Transfer Transaction
		INSERT INTO CreditTrans (				
					AgentId
					,CustId
					,TransDate
					,BalanceBefore
					,Amount
					,BetType
					,WinlostDate
					,TransDesc
					,Username
					,RefNo
					,Creator
					,IP )

		VALUES (	@ParentId
					,0
					,@TransDate
					,@ParentBalanceBefore
					,(- @Amount)
					,@BetType
					,@TransDate
					,'Deposit to downline '+ @Username
					,@ParentName
					,@RefNo
					,@LoggedId
					,@IP)

				
		----Rollback 1.a
			IF @@ERROR > 0
				BEGIN
					SELECT 
						@ErrCode = 8006, 
						@ErrMsg = 'Failed to deposit to downline '+ CONVERT(VARCHAR(10),@AgentId)
					RETURN
				END	
	

		-----1.b. Update CreditBalance_Agent

		IF NOT EXISTS (SELECT 1 FROM dbo.CreditBalance_Agent WITH (NOLOCK) WHERE AgentID = @ParentId )
		BEGIN 
			INSERT INTO CreditBalance_Agent (AgentId, Balance)
			SELECT @ParentId, @ParentBalanceBefore + (- @Amount)

			----Rollback 1.b
			IF @@ERROR > 0
				BEGIN
					SELECT 
						@ErrCode = 8004, 
						@ErrMsg = 'Failed to insert Credit Balance of Agent '+ CONVERT(VARCHAR(10),@ParentId)
					
					DELETE CreditTrans WHERE RefNo = @RefNo

					RETURN
				END	

		END
		ELSE
		BEGIN 
			UPDATE	CreditBalance_Agent WITH (ROWLOCK, UPDLOCK)  
			SET		Balance = @ParentBalanceBefore + (- @Amount)
			WHERE	AgentID = @ParentId		
					
			----Rollback 1.b
			IF @@ERROR > 0
				BEGIN
					SELECT 
						@ErrCode = 8005, 
						@ErrMsg = 'Failed to update Credit Balance of Agent '+ CONVERT(VARCHAR(10),@ParentId)
					
					DELETE CreditTrans WHERE RefNo = @RefNo

					RETURN
				END	
		END
					
		----2.a. Downline Transfer Transaction
		SELECT @BalanceBefore = SUM(ISNULL(Amount,0)) FROM dbo.CreditTrans WITH (NOLOCK) WHERE AgentId = @AgentId

		INSERT INTO CreditTrans (				
					AgentId
					,CustId
					,TransDate
					,BalanceBefore
					,Amount
					,BetType
					,WinlostDate
					,TransDesc
					,Username
					,RefNo
					,Creator
					,IP )

		VALUES (	@AgentId
					,0
					,@TransDate
					,@BalanceBefore
					,@Amount
					,@BetType
					,@TransDate
					,'Deposit from Upline'
					,@Username
					,@RefNo
					,@LoggedId
					,@IP)

						
		--Rollback 2.a
			IF @@ERROR > 0
				BEGIN
					SELECT 
						@ErrCode = 8007, 
						@ErrMsg =  'Failed to deposit from Upline.'
					
					DELETE CreditTrans WHERE RefNo = @RefNo
					
					UPDATE	CreditBalance_Agent WITH (ROWLOCK, UPDLOCK)  
					SET		Balance = @ParentBalanceBefore
					WHERE	AgentID = @ParentId		

					RETURN
				END	
	
					
		-----2.b. Update CreditBalance_Agent

		IF NOT EXISTS (SELECT 1 FROM dbo.CreditBalance_Agent WITH (NOLOCK) WHERE AgentID = @AgentId )
		BEGIN 
			INSERT INTO CreditBalance_Agent (AgentId, Balance)
			SELECT @AgentId, @BalanceBefore + @Amount

			---Rollback 2.b
			IF @@ERROR > 0
				BEGIN
					SELECT 
						@ErrCode = 8004, 
						@ErrMsg = 'Failed to insert Credit Balance of Agent '+ CONVERT(VARCHAR(10),@AgentId)
					
					DELETE CreditTrans WHERE RefNo = @RefNo
					
					UPDATE	CreditBalance_Agent WITH (ROWLOCK, UPDLOCK)  
					SET		Balance = @ParentBalanceBefore
					WHERE	AgentID = @ParentId		

					RETURN
				END	

		END
		ELSE
		BEGIN 
			UPDATE	CreditBalance_Agent WITH (ROWLOCK, UPDLOCK)  
			SET		Balance = @BalanceBefore + @Amount
			WHERE	AgentID = @AgentId

			---Rollback 2.b
			IF @@ERROR > 0
				BEGIN
					SELECT 
						@ErrCode = 8005, 
						@ErrMsg = 'Failed to insert Credit Balance of Agent '+ CONVERT(VARCHAR(10),@AgentId)
					
					DELETE CreditTrans WHERE RefNo = @RefNo
					
					UPDATE	CreditBalance_Agent WITH (ROWLOCK, UPDLOCK)  
					SET		Balance = @ParentBalanceBefore
					WHERE	AgentID = @ParentId		

					RETURN
				END	

		END
		
		--------------------------------
	 	------ 3. Write log				
			SET @startRun = @TransDate

			SET @xml = (
				SELECT	@ParentId AS '@p',
						@ParentName AS '@pn',
						@ParentBalanceBefore AS '@pb',

						'Deposit' AS '@tp',
						@Amount AS '@m',

						@AgentId AS '@a',
						@Username AS '@an',
						@BalanceBefore AS '@ab'						
				FOR XML PATH('z'), ROOT('r')
			)
			 
			SET @logSPData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

			SET @endRun	= GETDATE()
			SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun) 
	
		
			IF @@Error = 0
				BEGIN TRY
					EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpAgent
					@UserId			= @LoggedID,
					@SPName			= 'Age_Transfer_AgentToAgent',
					@LogDate		= @startRun,
					@AgentId		= @AgentId,
					@Duration		= @Duration,
					@Data			= @logSPData,
					@OldData		= ''
				END	TRY
				BEGIN CATCH
					EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpAgent
					@UserId			= @LoggedID,
					@SPName			= 'Age_Transfer_AgentToAgent',
					@LogDate		= @startRun,
					@AgentId		= @AgentId,
					@Duration		= @Duration,
					@Data			= @logSPData,
					@OldData		= ''
				END CATCH
		
		 
	END 
	ELSE
	--###############################################################################
	IF @Bettype = 22002   --- DRAW
	BEGIN 
		
		SELECT @BalanceBefore = SUM(ISNULL(Amount,0)) FROM dbo.CreditTrans WITH (NOLOCK) WHERE AgentId = @AgentId
				
		--- Check valid
			IF @BalanceBefore < 0
			BEGIN 
				SELECT	@ErrCode = 8002,			
						@ErrMsg = 'Sport Credit of downline '+ @Username +' is not enough to draw.'
				RETURN
			END 

		-----Draw amount = [0; his credit]
			IF @Amount NOT BETWEEN 0 AND @BalanceBefore 
			BEGIN 
				SELECT	@ErrCode = 8003,			
						@ErrMsg = 'Invalid amount.'
				RETURN
			END

		----1.a. Downline Transfer Transaction	
		INSERT INTO CreditTrans (				
					AgentId
					,CustId
					,TransDate
					,BalanceBefore
					,Amount
					,BetType
					,WinlostDate
					,TransDesc
					,Username
					,RefNo
					,Creator
					,IP )

		VALUES (	@AgentId
					,0
					,@TransDate
					,@BalanceBefore
					,(- @Amount)
					,@BetType
					,@TransDate
					,'Draw to Upline'
					,@Username
					,@RefNo
					,@LoggedId
					,@IP)

			----Rollback 1.a
			IF @@ERROR > 0
				BEGIN
					SELECT 
						@ErrCode = 8008, 
						@ErrMsg = 'Failed to draw to Upline.'
					RETURN
				END	
	

		-----1.b. Update CreditBalance_Agent

		IF NOT EXISTS (SELECT 1 FROM dbo.CreditBalance_Agent WITH (NOLOCK) WHERE AgentID = @AgentId )
		BEGIN 
			INSERT INTO CreditBalance_Agent (AgentId, Balance)
			SELECT @AgentId, @BalanceBefore + (- @Amount)

			----Rollback 1.b
			IF @@ERROR > 0
				BEGIN
					SELECT 
						@ErrCode = 8004, 
						@ErrMsg = 'Failed to insert Credit Balance of Agent '+ CONVERT(VARCHAR(10),@AgentId)
					
					DELETE CreditTrans WHERE RefNo = @RefNo

					RETURN
				END	
		END
		ELSE
		BEGIN 
			UPDATE	CreditBalance_Agent WITH (ROWLOCK, UPDLOCK)  
			SET		Balance = @BalanceBefore + (- @Amount)
			WHERE	AgentID = @AgentId

			----Rollback 1.b
			IF @@ERROR > 0
				BEGIN
					SELECT 
						@ErrCode = 8005, 
						@ErrMsg = 'Failed to update Credit Balance of Agent '+ CONVERT(VARCHAR(10),@AgentId)
					
					DELETE CreditTrans WHERE RefNo = @RefNo

					RETURN
				END	
		END
		

		----2.a. Upline Transfer Transaction
		SELECT @ParentBalanceBefore = SUM(ISNULL(Amount,0)) FROM dbo.CreditTrans WITH (NOLOCK) WHERE AgentId = @ParentId
		
		INSERT INTO CreditTrans (				
					AgentId
					,CustId
					,TransDate
					,BalanceBefore
					,Amount
					,BetType
					,WinlostDate
					,TransDesc
					,Username
					,RefNo
					,Creator
					,IP )

		VALUES (	@ParentId
					,0
					,@TransDate
					,@ParentBalanceBefore
					,@Amount
					,@BetType
					,@TransDate
					,'Draw from downline '+ @Username
					,@ParentName
					,@RefNo
					,@LoggedId
					,@IP)
		
			---Rollback 2.a
			IF @@ERROR > 0
				BEGIN
					SELECT 
						@ErrCode = 8009, 
						@ErrMsg =  'Failed to draw from downline '+ + CONVERT(VARCHAR(10),@AgentId)
					
					DELETE CreditTrans WHERE RefNo = @RefNo
					
					UPDATE	CreditBalance_Agent WITH (ROWLOCK, UPDLOCK)  
					SET		Balance = @BalanceBefore
					WHERE	AgentID = @AgentId		

					RETURN
				END	
					

		-----2.b. Update CreditBalance_Agent

		IF NOT EXISTS (SELECT 1 FROM dbo.CreditBalance_Agent WITH (NOLOCK) WHERE AgentID = @ParentId )
		BEGIN 
			INSERT INTO CreditBalance_Agent (AgentId, Balance)
			SELECT @ParentId, @ParentBalanceBefore + @Amount

			---Rollback 2.b
			IF @@ERROR > 0
				BEGIN
					SELECT 
						@ErrCode = 8004, 
						@ErrMsg = 'Failed to insert Credit Balance of Agent '+ CONVERT(VARCHAR(10),@ParentId)
					
					DELETE CreditTrans WHERE RefNo = @RefNo
					
					UPDATE	CreditBalance_Agent WITH (ROWLOCK, UPDLOCK)  
					SET		Balance = @BalanceBefore
					WHERE	AgentID = @AgentId		

					RETURN
				END	
		END
		ELSE
		BEGIN 
			UPDATE	CreditBalance_Agent WITH (ROWLOCK, UPDLOCK)  
			SET		Balance = @ParentBalanceBefore + @Amount
			WHERE	AgentID = @ParentId

			---Rollback 2.b
			IF @@ERROR > 0
				BEGIN
					SELECT 
						@ErrCode = 8005, 
						@ErrMsg = 'Failed to update Credit Balance of Agent '+ CONVERT(VARCHAR(10),@ParentId)
					
					DELETE CreditTrans WHERE RefNo = @RefNo
					
					UPDATE	CreditBalance_Agent WITH (ROWLOCK, UPDLOCK)  
					SET		Balance = @BalanceBefore
					WHERE	AgentID = @AgentId		

					RETURN
				END	
		END
		

		--------------------------------
	 	------ 3. Write log				
			SET @startRun = @TransDate

			SET @xml = (
				SELECT	@ParentId AS '@p',
						@ParentName AS '@pn',
						@ParentBalanceBefore AS '@pb',

						'Draw' AS '@tp',
						@Amount AS '@m',

						@AgentId AS '@a',
						@Username AS '@an',
						@BalanceBefore AS '@ab'						
				FOR XML PATH('z'), ROOT('r')
			)
			 
			SET @logSPData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

			SET @endRun	= GETDATE()
			SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun) 
	
		
			IF @@Error = 0
				BEGIN TRY
					EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpAgent
					@UserId			= @LoggedID,
					@SPName			= 'Age_Transfer_AgentToAgent',
					@LogDate		= @startRun,
					@AgentId		= @AgentId,
					@Duration		= @Duration,
					@Data			= @logSPData,
					@OldData		= ''
				END	TRY
				BEGIN CATCH
					EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpAgent
					@UserId			= @LoggedID,
					@SPName			= 'Age_Transfer_AgentToAgent',
					@LogDate		= @startRun,
					@AgentId		= @AgentId,
					@Duration		= @Duration,
					@Data			= @logSPData,
					@OldData		= ''
				END CATCH

	 
END

END 
GO 
GRANT EXECUTE ON [dbo].[Age_Transfer_AgentToAgent] TO [aplweb]


 
 