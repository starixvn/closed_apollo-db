ALTER PROCEDURE [dbo].[Age_Transfer_AgentToCust]
(
	@LoggedId	INT,
	@CustId		INT,
	@Amount		INT,
	@TransType	TINYINT = 1,
	@IP			VARCHAR(40) = '',
	@AdminId	INT = NULL,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(1000) = '' OUTPUT

)
 /*
    Created	: Sophia
	Date	: 20141114
    Task	: Transfer credit from Agent To Member
    DB		: SVRTXN/TransDB
    Revisions: 

	Parameters:
		@TransType  = 1: Deposit
					= 2: Draw		
	Test string:
	 
	  DECLARE   @ErrCode	INT ,
				@ErrMsg		NVARCHAR(1000) 


	  EXEC [Age_Transfer_AgentToCust] 
			@LoggedId	= 1,
			@CustId		= 68,
			@Amount		= 100,
			@TransType	= 1,
			@IP			= '123456',
			@AdminID	= NULL,
			@ErrCode	= @ErrCode OUTPUT,
			@ErrMsg		= @ErrMsg OUTPUT
		
		SELECT @ErrCode, @ErrMsg
				 

 */
AS
BEGIN 
SET NOCOUNT ON

DECLARE @LoggedHId	HIERARCHYID, 
		@rowcnt INT, @Bettype SMALLINT,
		@AgentId INT, @AgentName  NVARCHAR(50), @AgentBalanceBefore MONEY, 
		@Username NVARCHAR(50), @BalanceBefore MONEY 			

DECLARE @RefNo BIGINT, @grefno INT, @TransDate DATETIME	

--- for write log
DECLARE 
		@startRun		DATETIME,
		@endRun			DATETIME,
		@duration		INT,
		@logSPData		VARCHAR(5000),
		@xml			XML



IF ISNULL(@TransType,0) not in (1,2)
BEGIN
	SELECT	@ErrMsg = 'Trans Type is invalid.', 
			@ErrCode = 8010	
	RETURN		
END


SELECT @Bettype = 
	CASE @TransType 
		WHEN 1 THEN 22001 --- DEPOSIT
		WHEN 2 THEN 22002 --- DRAW		
	END
	 
----- Get Agent Info
	SELECT @AgentID = AgentID , @Username = Username FROM dbo.CustInfo WITH (NOLOCK) WHERE CustID = @CustId

	--- Check exists
	 IF ISNULL(@AgentID ,0) = 0
	 BEGIN 
		SELECT	@ErrCode = 5220,			
				@ErrMsg = 'Invalid customer ID'
		RETURN
	 END


	SELECT	@Agentname = A.Username	
	FROM	dbo.AgentInfo A WITH (NOLOCK)			
	WHERE	A.AgentID = @AgentID 			
 
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
		
			SELECT @AgentBalanceBefore = SUM(ISNULL(Amount,0)) FROM dbo.CreditTrans WITH (NOLOCK) WHERE AgentId = @AgentId
			SELECT @AgentBalanceBefore = ISNULL(@AgentBalanceBefore, 0)

			--- Check valid		
			IF @Amount < 0
			BEGIN 
				SELECT	@ErrCode = 8003,			
						@ErrMsg = 'Invalid Amount.'
				RETURN
			END


			IF @AgentBalanceBefore < @Amount
			BEGIN 
				SELECT	@ErrCode = 8001,			
						@ErrMsg = 'Sport Credit of '+ @AgentName +' is not enough to deposit.'
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

		VALUES (	@AgentId
					,0
					,@TransDate
					,@AgentBalanceBefore
					,(- @Amount)
					,@BetType
					,@TransDate
					,'Deposit to downline '+ @Username
					,@AgentName
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

		IF NOT EXISTS (SELECT 1 FROM dbo.CreditBalance_Agent WITH (NOLOCK) WHERE AgentID = @AgentId )
		BEGIN 
			INSERT INTO  dbo.CreditBalance_Agent (AgentId, Balance)
			SELECT @AgentId, @AgentBalanceBefore + (- @Amount)

			----Rollback 1.b
			IF @@ERROR > 0
				BEGIN
					SELECT 
						@ErrCode = 8004, 
						@ErrMsg = 'Failed to insert Credit Balance of Agent '+ CONVERT(VARCHAR(10),@AgentId)
					
					DELETE  dbo.CreditTrans WHERE RefNo = @RefNo

					RETURN
				END	

		END
		ELSE
		BEGIN 
			UPDATE	dbo.CreditBalance_Agent WITH (ROWLOCK, UPDLOCK)  
			SET		Balance = @AgentBalanceBefore + (- @Amount)
			WHERE	AgentID = @AgentId		
					
			----Rollback 1.b
			IF @@ERROR > 0
				BEGIN
					SELECT 
						@ErrCode = 8005, 
						@ErrMsg = 'Failed to update Credit Balance of Agent '+ CONVERT(VARCHAR(10),@AgentId)
					
					DELETE dbo.CreditTrans WHERE RefNo = @RefNo

					RETURN
				END	
		END
					
		----2.a. Downline Transfer Transaction
		SELECT @BalanceBefore = SUM(ISNULL(WinLost,0) - ISNULL(Actual_Stake,0) + ISNULL(PlayerComm,0)) FROM dbo.Bettrans WITH (NOLOCK) WHERE CustId = @CustId
		SELECT @BalanceBefore = ISNULL (@BalanceBefore, 0)

		INSERT INTO dbo.CreditTrans (				
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

		VALUES (	0
					,@CustId
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
					
					DELETE dbo.CreditTrans WHERE RefNo = @RefNo
					
					UPDATE	dbo.CreditBalance_Agent WITH (ROWLOCK, UPDLOCK)  
					SET		Balance = @AgentBalanceBefore
					WHERE	AgentID = @AgentId		

					RETURN
				END	
	
		
		----- 2.b. Insert transaction into Bettrans
		EXEC	dbo.Age_Transfer_CustInsBettrans
				@LoggedId	= @LoggedId ,
				@Custid		= @Custid,	
				@Bettype	= @Bettype,
				@RefNo		= @RefNo,
				@Amount		= @Amount,	
				@IP			= @IP,
				@ErrCode	= @ErrCode OUTPUT,
				@ErrMsg		= @ErrMsg OUTPUT
		

		-------Rollback 2.b
		IF @ErrCode <> 0 
		BEGIN 
			SELECT 	@ErrCode = @ErrCode, 
					@ErrMsg =  @ErrMsg		

			DELETE  dbo.CreditTrans WHERE RefNo = @RefNo
					
			UPDATE	dbo.CreditBalance_Agent WITH (ROWLOCK, UPDLOCK)  
			SET		Balance = @AgentBalanceBefore
			WHERE	AgentID = @AgentId	


			RETURN
		END
		

		--------------------------------
	 	------ 3. Write log				
			SET @startRun = @TransDate

			SET @xml = (
				SELECT	@AgentId AS '@a',
						@AgentName AS '@an',
						@AgentBalanceBefore AS '@ab',

						'Deposit' AS '@tp',
						@Amount AS '@m',

						@CustId AS '@c',
						@Username AS '@cn',
						@BalanceBefore AS '@cb'						
				FOR XML PATH('z'), ROOT('r')
			)
			 
			SET @logSPData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

			SET @endRun	= GETDATE()
			SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun) 
	
		
			IF @@Error = 0
				BEGIN TRY
					EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpAgent
					@UserId			= @LoggedID,
					@AdminID		= @AdminId,
					@SPName			= 'Age_Transfer_AgentToCust',
					@LogDate		= @startRun,
					@AgentId		= @AgentId,
					@Duration		= @Duration,
					@Data			= @logSPData,
					@OldData		= ''
				END	TRY
				BEGIN CATCH
					EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpAgent
					@UserId			= @LoggedID,
					@AdminID		= @AdminId,
					@SPName			= 'Age_Transfer_AgentToCust',
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
		
		SELECT @BalanceBefore = SUM(ISNULL(WinLost,0) - ISNULL(Actual_Stake,0) + ISNULL(PlayerComm,0)) FROM dbo.Bettrans WITH (NOLOCK) WHERE CustId = @CustId
		SELECT @BalanceBefore = ISNULL (@BalanceBefore, 0)
				

			--- Check valid
			IF @Amount < 0
			BEGIN 
				SELECT	@ErrCode = 8003,			
						@ErrMsg = 'Invalid amount.'
				RETURN
			END

			IF @BalanceBefore < @Amount
			BEGIN 
				SELECT	@ErrCode = 8002,			
						@ErrMsg = 'Sport Credit of downline '+ @Username +' is not enough to draw.'

				RETURN
			END 
			
		----1.a. Downline Transfer Transaction	
		INSERT INTO dbo.CreditTrans (				
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

		VALUES (	0
					,@CustId
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
	

		-----1.b. Insert transaction into Bettrans
		EXEC	dbo.Age_Transfer_CustInsBettrans
				@LoggedId	= @LoggedId ,
				@Custid		= @Custid,	
				@Bettype	= @Bettype,
				@RefNo		= @RefNo,
				@Amount		= @Amount,	
				@IP			= @IP,
				@ErrCode	= @ErrCode OUTPUT,
				@ErrMsg		= @ErrMsg OUTPUT
		

		-------Rollback 1.b
		IF @ErrCode <> 0 
		BEGIN 
			SELECT 	@ErrCode = @ErrCode, 
					@ErrMsg =  @ErrMsg		

			DELETE  dbo.CreditTrans WHERE RefNo = @RefNo

			RETURN
		END

		----2.a. Upline Transfer Transaction
		SELECT @AgentBalanceBefore = SUM(ISNULL(Amount,0)) FROM dbo.CreditTrans WITH (NOLOCK) WHERE AgentId = @AgentId
		SELECT @AgentBalanceBefore = ISNULL (@AgentBalanceBefore, 0)

		INSERT INTO dbo.CreditTrans (				
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
					,@AgentBalanceBefore
					,@Amount
					,@BetType
					,@TransDate
					,'Draw from downline '+ @Username
					,@AgentName
					,@RefNo
					,@LoggedId
					,@IP)
		
			---Rollback 2.a
			IF @@ERROR > 0
				BEGIN
					SELECT 
						@ErrCode = 8009, 
						@ErrMsg =  'Failed to draw from downline '+ + CONVERT(VARCHAR(10),@AgentId)
					
					DELETE dbo.CreditTrans WHERE RefNo = @RefNo
					DELETE dbo.Bettrans	 WHERE	Custid = @custid 
												and Refno = @RefNo 
												and Matchid = 0
												and Bettype = @bettype
												
					RETURN
				END	
					

		-----2.b. Update CreditBalance_Agent

		IF NOT EXISTS (SELECT 1 FROM dbo.CreditBalance_Agent WITH (NOLOCK) WHERE AgentID = @AgentId )
		BEGIN 
			INSERT INTO dbo.CreditBalance_Agent (AgentId, Balance)
			SELECT @AgentId, @AgentBalanceBefore + @Amount

			---Rollback 2.b
			IF @@ERROR > 0
				BEGIN
					SELECT 
						@ErrCode = 8004, 
						@ErrMsg = 'Failed to insert Credit Balance of Agent '+ CONVERT(VARCHAR(10),@AgentId)
					
					DELETE dbo.CreditTrans WHERE RefNo = @RefNo
					DELETE dbo.Bettrans	 WHERE	Custid = @custid 
												and Refno = @RefNo 
												and Matchid = 0
												and Bettype = @bettype

					RETURN
				END	
		END
		ELSE
		BEGIN 
			UPDATE	dbo.CreditBalance_Agent WITH (ROWLOCK, UPDLOCK)  
			SET		Balance = @AgentBalanceBefore + @Amount
			WHERE	AgentID = @AgentId

			---Rollback 2.b
			IF @@ERROR > 0
				BEGIN
					SELECT 
						@ErrCode = 8005, 
						@ErrMsg = 'Failed to update Credit Balance of Agent '+ CONVERT(VARCHAR(10),@AgentId)
					
					DELETE dbo.CreditTrans WHERE RefNo = @RefNo					
					DELETE dbo.Bettrans	 WHERE	Custid = @custid 
												and Refno = @RefNo 
												and Matchid = 0
												and Bettype = @bettype	

					RETURN
				END	
		END
		

		--------------------------------
	 	------ 3. Write log				
			SET @startRun = @TransDate

			SET @xml = (
				SELECT	@AgentId AS '@a',
						@AgentName AS '@an',
						@AgentBalanceBefore AS '@ab',

						'Draw' AS '@tp',
						@Amount AS '@m',

						@CustId AS '@c',
						@Username AS '@cn',
						@BalanceBefore AS '@cb'						
				FOR XML PATH('z'), ROOT('r')
			)
			 
			SET @logSPData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

			SET @endRun	= GETDATE()
			SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun) 
	
		
			IF @@Error = 0
				BEGIN TRY
					EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpAgent
					@UserId			= @LoggedID,
					@AdminID		= @AdminId,
					@SPName			= 'Age_Transfer_AgentToCust',
					@LogDate		= @startRun,
					@AgentId		= @AgentId,
					@Duration		= @Duration,
					@Data			= @logSPData,
					@OldData		= ''
				END	TRY
				BEGIN CATCH
					EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpAgent
					@UserId			= @LoggedID,
					@AdminID		= @AdminId,
					@SPName			= 'Age_Transfer_AgentToCust',
					@LogDate		= @startRun,
					@AgentId		= @AgentId,
					@Duration		= @Duration,
					@Data			= @logSPData,
					@OldData		= ''
				END CATCH
			
END


END 
GO 
GRANT EXECUTE ON [dbo].[Age_Transfer_AgentToCust] TO [aplweb]
GO

 
 