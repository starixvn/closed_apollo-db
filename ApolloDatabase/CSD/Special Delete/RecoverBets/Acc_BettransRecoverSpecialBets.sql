ALTER PROCEDURE [dbo].[Acc_BettransRecoverSpecialBets]
    @transid BIGINT,
    @userid int,   
    @IP varchar(50),
    @ErrCode int output,
    @ErrMsg nvarchar(200) output
AS
/*
Created: Sophia
Date: 20130307
DB: SVRTXN.TransDB
Task: Recover Single Bet and Outright
	
Revisions:   
	 
Param's Explanation:

*/

SET NOCOUNT ON
BEGIN

	DECLARE @LogData NVARCHAR(500)
	DECLARE @Remark VARCHAR(500)
    SELECT @errcode = 0, @errmsg = ''

    declare
        @LogSPData varchar(200),
        @startRun datetime,
        @endRun datetime,
        @duration int,
        @matchid int,      
        @bettype int,
		@Status NVARCHAR(10),
        @balance money,
		@CustId int,
		@Username varchar(50)

    SELECT	@matchid = matchid, 
			@bettype = bettype ,
			@CustId = CustId,
			@Status = status,
			@balance = Winlost,
			@Username = Username
	FROM	Bettrans WITH (NOLOCK) 
	WHERE   transid=@transid
      
    
		
	----################ Check concurrent running #####################----
	DECLARE @KeyID TINYINT
		
	IF @bettype = 10	--Outright
		SET @KeyID = 2
	ELSE 
		SET @KeyID = 1

	---Check table TempVariableNumber 		
	IF EXISTS (SELECT 1 FROM dbo.TempVariableNumber WHERE KeyID = @KeyID AND KeyValue = @matchid)
	BEGIN
		SELECT  @ErrCode = 101,
				@ErrMsg = 'This match is being calculated or some tickets of this match are being deleted, please wait a few seconds until the on-going process is completed and try again.'
		RETURN
	END
	INSERT INTO dbo.TempVariableNumber (KeyID, KeyValue) VALUES (@KeyID, @matchid)
	IF (@@Error = 0)
	BEGIN TRY
		EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @UserID, 
			@Matchid = @matchid, 
			@KeyID = @KeyID,
			@ActionID = 0, 
			@Remark = 'ADD SUCCESS SPName=Acc_BettransRecoverSpecialBets'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'ADD SUCCESS SPName=Acc_BettransRecoverSpecialBets ErrMsg=' + left(error_message(), 400)
		EXEC LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @UserID, 
			@Matchid = @matchid, 
			@KeyID = @KeyID,
			@ActionID = 0, 
			@Remark = @Remark
	END CATCH
	ELSE 
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'This match is being calculated or some tickets of this match are being deleted, please wait a few seconds until the on-going process is completed and try again.'
		RETURN
	END
					
	
	-------------------		
		
    --IF @bettype = 10  --@bettype = 10
    --BEGIN
    --    SELECT
    --        MATCH.teamid AS homeid,
    --        0 AS awayid,
    --        MATCH.matchcode,
    --        MATCH.eventdate,
    --        MATCH.leagueid,
    --        GETDATE() AS DATETIME,
    --        CONVERT(BIT,0) AS IsNeutral
    --    FROM
    --        Outright AS MATCH WITH (NOLOCK)
    --    WHERE
    --        MATCH.orid = @matchID
    --END  
    --ELSE
    --BEGIN
    --    SELECT
    --        MATCH.homeid,
    --        MATCH.awayid,
    --        MATCH.matchcode,
    --        MATCH.eventdate,
    --        MATCH.leagueid,
    --        GETDATE() AS DATETIME,
    --        isnull(MATCH.isNeutral, CONVERT(BIT,0)) AS IsNeutral
    --    FROM
    --        MATCH WITH (NOLOCK)
    --    WHERE
    --        MATCH.matchid = @matchID
    --END

   --- exec ApolloArchive.DB06.dbo.Acc_BettransSelRecoverSpecialBets @transid = @transid 


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
				@Remark = 'DEL SUCCESS SPName=Acc_BettransRecoverSpecialBets'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransRecoverSpecialBets ErrMsg=' + left(error_message(), 400)
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
					@Remark = 'DEL FAILED SPName=Acc_BettransRecoverSpecialBets'
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'DEL FAILED SPName=Acc_BettransRecoverSpecialBets ErrMsg=' + left(error_message(), 400)
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



	--update balance debit
	IF @balance > 0
	BEGIN
		EXEC Dot_BalanceUpdDebit @CustId = @CustId, @balance = @balance
	END
	
------ Recover 
	-- update Bettrans 
    UPDATE bettrans WITH(ROWLOCK,UPDLOCK)
    SET winlost = 0, 
		ruben= 0, 
		statuswinlost = 0, 
		STATUS ='running', 
		statusID=0,
        creator = z.creator   
    FROM bettrans b 
    INNER JOIN zzzbettrans z WITH(NOLOCK) ON b.transid =z.transid
    WHERE b.transid = @transid

	-- update Bettrans_Agent
	UPDATE	A  WITH(ROWLOCK,UPDLOCK)			
	SET		status = 'running', 
			statusID = 0       
	FROM	Bettrans_Agent A 
		INNER JOIN Bettrans B  WITH (NOLOCK)
			ON A.TransID = B.TransID
	 WHERE b.transid = @transid


    
    --update balance credit	
	IF @balance < 0
	BEGIN
		SELECT @balance = ABS(@balance)
		EXEC Dot_BalanceUpdCredit @CustId = @CustId, @balance = @balance
	END

	--IF @bettype IN (1,3,7,8)
	--BEGIN
	--	-- update totalbets
	--	DECLARE @Total TABLE (oddsid INT, HomeTotal MONEY, AwayTotal MONEY)

	--	INSERT INTO @Total
	--	SELECT
	--		oddsid,
	--		SUM(CASE WHEN betteam='h' THEN (CASE WHEN ABS(odds) > 1 THEN ABS(odds) ELSE 1 END * b.stake * e.actualrate * (1-b.tpositiontaking)) ELSE 0 END) homeTotal,
	--		SUM(CASE WHEN betteam='a' THEN (CASE WHEN ABS(odds) > 1 THEN ABS(odds) ELSE 1 END * b.stake * e.actualrate * (1-b.tpositiontaking)) ELSE 0 END) awayTotal
	--	FROM bettrans b WITH (nolock)
	--		INNER JOIN exchange e WITH (nolock) ON b.currency = e.exchangeid
	--	WHERE bettype = @bettype AND ruben = 0 AND oddsid <> 0 and matchid = @matchid
	--	GROUP BY oddsid

	--	UPDATE odds WITH (rowlock, updlock)
	--	SET hometotal = t.HomeTotal, awaytotal = t.AwayTotal
	--	FROM @Total t WHERE odds.oddsid = t.oddsid AND odds.matchid = @matchid
	--END

    DELETE FROM zzzbettrans WITH(ROWLOCK,UPDLOCK) WHERE transid = @transid
	IF @@error <> 0
    BEGIN
        SELECT @errcode = 100, @errmsg = 'Recover transaction ' + convert(varchar, @transid) + ' unsuccessful. Please try again.'
    END
    --print('write log')-- Write Log Here
	SELECT @LogData = 'Recover bet has transid: ' + cast(@transid as varchar(20))+ ' IP: ' + cast(@IP as varchar(15))
	EXEC WriteLog_UserLog_T @UserID = @UserID, @Doing = @LogData
	

	
	---- List data to put Message
	SELECT  @TransId as TransId, A.AgentID as TargetID, A.Username as TargetName, 1 as IsAgent
	FROM	Bettrans B WITH (NOLOCK)
	INNER JOIN Bettrans_Agent A WITH (NOLOCK)
			ON A.TransID = B.TransID
	WHERE B.TransId = @TransId
	UNION ALL
	SELECT  @TransId as TransId, @CustId as TargetId, @Username as TargetName, 0 as IsAgent
	



	-----release data of TempVariableNumber table 
	DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
	WHERE KeyID = @KeyID AND KeyValue = @matchid
	IF (@@Error = 0)
	BEGIN TRY
		EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @UserID, 
			@Matchid = @matchid, 
			@KeyID = @KeyID,
			@ActionID = 0, 
			@Remark = 'DEL SUCCESS SPName=Acc_BettransRecoverSpecialBets'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransRecoverSpecialBets ErrMsg=' + left(error_message(), 400)
		EXEC LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @UserID, 
			@Matchid = @matchid, 
			@KeyID = @KeyID,
			@ActionID = 0, 
			@Remark = @Remark
	END CATCH			
	ELSE
	BEGIN
		BEGIN TRY
			EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = @KeyID,
				@ActionID = 0,
				@Remark = 'DEL FAILED SPName=Acc_BettransRecoverSpecialBets'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL FAILED SPName=Acc_BettransRecoverSpecialBets ErrMsg=' + left(error_message(), 400)
			EXEC LogDB.dbo.WriteLog_Settlement_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = @KeyID,
				@ActionID = 0,
				@Remark = @Remark
		END CATCH
	END
	

END

GO
GRANT EXECUTE ON [dbo].[Acc_BettransRecoverSpecialBets] TO [aplweb]
GO
--GRANT VIEW DEFINITION ON [dbo].[Acc_BettransRecoverSpecialBets] TO [vnteam]
