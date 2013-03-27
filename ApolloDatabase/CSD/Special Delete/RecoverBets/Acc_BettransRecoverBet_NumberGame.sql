ALTER PROCEDURE [dbo].[Acc_BettransRecoverBet_NumberGame]
    @transid BIGINT,
    @userid int,  
    @IP varchar(50),
    @ErrCode int output,
    @ErrMsg nvarchar(200) output
AS
/*
	Created:Sophia
	Date: 20120307
	DB: SVRTXN.TransDB
	Task: Recover bet Number Game

	Revisions:   				   
		 
	Param's Explanation:
*/

SET NOCOUNT ON
BEGIN
	
	DECLARE @LogData NVARCHAR(500)
	DECLARE @Remark VARCHAR(500)
    SELECT @errcode = 0, @errmsg = ''

    declare     	
        @matchid int,      
        @bettype int,        		
		@winlostdate datetime,
		@status NVARCHAR(10),
		@Username VARCHAR(50),	
		@custid int,	    
        @balance money,
		@bf_balance MONEY,
		@at_balance MONEY

    SELECT	@matchid = matchid, 
			@bettype = bettype ,
			@winlostdate = winlostdate, 
			@status = status,
			@Username = Username, 
			@CustId = CustId
    FROM	bettrans WITH (NOLOCK) 
	WHERE	transid = @transid   
     
    ---- check and not allow attempt to delete same game while it's still not finish
    IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = 1 AND KeyValue = @matchid)
	BEGIN
		SELECT  @ErrCode = 101,
				@ErrMsg = 'This match is being calculated or some tickets of this match are being deleted, please wait a few seconds until the on-going process is completed and try again.'
		RETURN
	END

	INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (1, @matchid)
	IF (@@Error = 0)
	BEGIN TRY
		EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking
			@UserID = @userid, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = 0, 
			@Remark = 'ADD SUCCESS SPName=Acc_BettransRecoverBet_NumberGame'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'ADD SUCCESS SPName=Acc_BettransRecoverBet_NumberGame ErrMsg=' + left(error_message(), 400)
		EXEC LogDB.dbo.WriteLog_Settlement_Checking
			@UserID = @userid, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = 0, 
			@Remark = @Remark
	END CATCH
	ELSE 
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'This match is being calculated or some tickets of this match are being deleted, please wait a few seconds until the on-going process is completed and try again.'
		RETURN
	END

	---Also check table SystemSettings for Number game 
	IF @bettype BETWEEN 81 AND 120
	BEGIN
		IF EXISTS(SELECT 1 FROM SystemSettings WITH (NOLOCK) WHERE VValue = 1 AND VName = 'isCalculatingNGManual')
		BEGIN
			SELECT @ErrCode = 102
			SELECT @ErrMsg = 'Another number game re-calculation is in progress or some tickets of this match are being deleted, please wait a few seconds until the on-going process has finished and try again.'
			
			----release data of TempVariableNumber table
			DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
			WHERE KeyID = 1 AND KeyValue = @matchid
			IF (@@Error = 0)
			BEGIN TRY
				EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking
					@UserID = @userid, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0, 
					@Remark = 'DEL SUCCESS SPName=Acc_BettransRecoverBet_NumberGame'
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransRecoverBet_NumberGame ErrMsg=' + left(error_message(), 400)
				EXEC LogDB.dbo.WriteLog_Settlement_Checking
					@UserID = @userid, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0, 
					@Remark = @Remark
			END CATCH	
			ELSE
			BEGIN
				BEGIN TRY
					EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking
						@UserID = @userid, 
						@Matchid = @matchid, 
						@KeyID = 1,
						@ActionID = 0, 
						@Remark = 'DEL FAILED SPName=Acc_BettransRecoverBet_NumberGame'
				END TRY
				BEGIN CATCH
					SELECT @Remark = 'DEL FAILED SPName=Acc_BettransRecoverBet_NumberGame ErrMsg=' + left(error_message(), 400)
					EXEC LogDB.dbo.WriteLog_Settlement_Checking
						@UserID = @userid, 
						@Matchid = @matchid, 
						@KeyID = 1,
						@ActionID = 0, 
						@Remark = @Remark
				END CATCH
			END
			RETURN
		END
		ELSE 
		BEGIN
			UPDATE	systemSettings WITH (ROWLOCK, UPDLOCK)
			SET		VValue = '1'
			WHERE	VName = 'isCalculatingNGManual'
		END
	END 
	
	-------    
    --SELECT
    --    MATCH.homeid,
    --    MATCH.awayid,
    --    MATCH.matchcode,
    --    MATCH.eventdate,
    --    MATCH.leagueid,
    --    GETDATE() AS DATETIME,
    --    isnull(MATCH.isNeutral, CONVERT(BIT,0)) AS IsNeutral
    --FROM
    --    MATCH WITH (NOLOCK)
    --WHERE
    --    MATCH.matchid = @matchID

    --EXEC ApolloArchive.DB06.dbo.Acc_BettransSelRecoverBet_NumberGame @transid = @transid

	-- check if the ticket is not in zzzbettrans
	IF NOT EXISTS (	
				SELECT 1 
				FROM bettrans b WITH(NOLOCK)
					 INNER JOIN zzzbettrans z WITH(NOLOCK) ON b.transid = z.transid    
				WHERE b.transid = @transid AND b.custid = z.custid AND b.matchid = z.matchid AND b.bettype = z.bettype ) 
	BEGIN			
		SELECT @errcode = 101, @errmsg = 'Status of this ticket is already ' + @status		
		----
		DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
		WHERE KeyID = 1 AND KeyValue = @matchid	
		IF (@@Error = 0)
		BEGIN TRY
			EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking
				@UserID = @userid, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 0, 
				@Remark = 'DEL SUCCESS SPName=Acc_BettransRecoverBet_NumberGame'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransRecoverBet_NumberGame ErrMsg=' + left(error_message(), 400)
			EXEC LogDB.dbo.WriteLog_Settlement_Checking
				@UserID = @userid, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 0, 
				@Remark = @Remark
		END CATCH	
		ELSE
		BEGIN
			BEGIN TRY
				EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking
					@UserID = @userid, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0, 
					@Remark = 'DEL FAILED SPName=Acc_BettransRecoverBet_NumberGame'
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'DEL FAILED SPName=Acc_BettransRecoverBet_NumberGameb ErrMsg=' + left(error_message(), 400)
				EXEC LogDB.dbo.WriteLog_Settlement_Checking
					@UserID = @userid, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0, 
					@Remark = @Remark
			END CATCH
		END
		
		UPDATE	systemSettings WITH (ROWLOCK, UPDLOCK)
		SET		VValue = '0'
		WHERE	VName = 'isCalculatingNGManual'	
		
		RETURN
	END
		
----Get data before update	
	SELECT	@bf_balance = b.winlost - b.actual_stake + b.playercomm
	FROM	bettrans b WITH (NOLOCK)			
	WHERE   b.transid = @transid	


------ Recover 
    UPDATE bettrans WITH(ROWLOCK,UPDLOCK)
    SET winlost = 0, 
		PlayerComm =0,
		ruben = 0, 
		statuswinlost = 0, 
		status = 'running', 
		statusID = 0,						
        creator = z.creator   
    FROM bettrans b 
		INNER JOIN zzzbettrans z WITH(NOLOCK) 
			ON b.transid =z.transid
    WHERE b.transid = @transid 

	
	-- update Bettrans_Agent
	UPDATE	A  WITH(ROWLOCK,UPDLOCK)			
	SET		status = 'running', 
			statusID = 0,
			AWinlost = 0,
			AComm = 0    
	FROM	Bettrans_Agent A 
		INNER JOIN Bettrans B  WITH (NOLOCK)
			ON A.TransID = B.TransID
	 WHERE b.transid = @transid 


----Get data after update
    SELECT	@at_balance = b.winlost - b.actual_stake + b.playercomm
	FROM	bettrans b WITH (NOLOCK)
	WHERE   b.transid = @transid
	
---update balance	
	SELECT @balance = (@at_balance - @bf_balance )
	IF @balance > 0
	BEGIN
		EXEC Dot_BalanceUpdCredit @custid = @custid, @balance = @balance
	END
	IF @balance < 0
	BEGIN
		SELECT @balance = ABS(@balance)
		EXEC Dot_BalanceUpdDebit @custid = @custid, @balance = @balance
	END

		
--Delete zzzbettrans table        
    DELETE FROM zzzbettrans WITH(ROWLOCK,UPDLOCK) WHERE transid = @transid	
	IF @@error <> 0
    BEGIN
        SELECT @errcode = 102, @errmsg = 'Recover transaction ' + convert(varchar, @transid) + ' unsuccessful. Please try again.'
    END
	--print('write log')-- Write Log Here
	SELECT @LogData = 'Number Game recover bet has transid: ' + cast(@transid as varchar(20))+ ' IP: ' + cast(@IP as varchar(15))
	EXEC WriteLog_UserLog_T @UserID = @UserID, @Doing = @LogData
	

	
	---- List data to put Message
	SELECT  @TransId as TransId, A.AgentID as TargetID, A.Username as TargetName, 1 as IsAgent
	FROM	Bettrans B WITH (NOLOCK)
	INNER JOIN Bettrans_Agent A WITH (NOLOCK)
			ON A.TransID = B.TransID
	WHERE B.TransId = @TransId
	UNION ALL
	SELECT  @TransId as TransId, @CustId as TargetId, @Username as TargetName, 0 as IsAgent
	
	---
	DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
	WHERE KeyID = 1 AND KeyValue = @matchid	
	IF (@@Error = 0)
	BEGIN TRY
		EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking
			@UserID = @userid, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = 0, 
			@Remark = 'DEL SUCCESS SPName=Acc_BettransRecoverBet_NumberGame'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransRecoverBet_NumberGame ErrMsg=' + left(error_message(), 400)
		EXEC LogDB.dbo.WriteLog_Settlement_Checking
			@UserID = @userid, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = 0, 
			@Remark = @Remark
	END CATCH	
	ELSE
	BEGIN
		BEGIN TRY
			EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking
				@UserID = @userid, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 0, 
				@Remark = 'DEL FAILED SPName=Acc_BettransRecoverBet_NumberGame'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL FAILED SPName=Acc_BettransRecoverBet_NumberGame ErrMsg=' + left(error_message(), 400)
			EXEC LogDB.dbo.WriteLog_Settlement_Checking
				@UserID = @userid, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 0, 
				@Remark = @Remark
		END CATCH
	END
	
	UPDATE	systemSettings WITH (ROWLOCK, UPDLOCK)
	SET		VValue = '0'
	WHERE	VName = 'isCalculatingNGManual'	
	
END

GO
GRANT VIEW DEFINITION ON [Acc_BettransRecoverBet_NumberGame] TO aplweb
GO
--GRANT EXECUTE ON [Acc_BettransRecoverBet_NumberGame] TO bodbAdminNet

 