ALTER PROCEDURE [dbo].[Acc_BettransDelSpecial_NumberGame]
    @matchid		INT,
    @f_transid		BIGINT,
    @t_transid		BIGINT,
    @Dead			VARCHAR(100)	= '', -- bettype for dead-ball
	@Live			VARCHAR(100)	= '', -- bettype for live-ball	
    @transids		VARCHAR(4000)	= '',-- Normal bets    	
    @UserName		NVARCHAR(50),
    @UserPwd		NVARCHAR(50),
    @UserID			INT,
    @IP				VARCHAR(15)		= '',   
    @ErrMsg			NVARCHAR(200)	= '' OUTPUT,
    @ErrCode		INT				= 0 OUTPUT      
AS
/*
Created by: Sophia
DAte 20130306
Task : SP deletebet (Number Game)
DB:  SVRTXN.TransDB
Original: 

Revisions:
   - 20130725@Sophia: Change username nvarchar(50)
   - 20130729@Sophia: Get Username of Agent from AgentInfo table to put Message
						   
Param's Explanation: 

*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @LogData NVARCHAR(500)
	DECLARE @Remark VARCHAR(500)
	SELECT	@ErrCode = 0

	IF NOT EXISTS (	SELECT 1
					FROM	SVRCUST.CustDB.dbo.AdminInfo WITH (NOLOCK)
					WHERE   UserPwd = @UserPwd
							and AdminId = @UserID)
	BEGIN
		SELECT @LogData ='Fail to delete bet for matchid ' + CONVERT(VARCHAR(20), @matchid) + ' from ' + CONVERT(VARCHAR(20), @f_transid) + ' to ' + CONVERT(VARCHAR(20), @t_transid)
		EXEC WriteLog_UserLog_T @UserID = @UserID, @Doing = @LogData

		SELECT @ErrMsg = 'Sorry. You can not process delete bet due to either wrong password or insufficient permission!', @ErrCode = 101   
		RETURN
	END

	DECLARE @Status TABLE (statusID TINYINT)

		/*
		INSERT INTO @Status
		SELECT 'Void' UNION ALL
		SELECT 'Reject' UNION ALL
		SELECT 'WON' UNION ALL
		SELECT 'LOSE' UNION ALL
		SELECT 'DRAW'
		*/
		INSERT INTO @Status
		SELECT 102 UNION ALL
		SELECT 101 UNION ALL
		SELECT 112 UNION ALL
		SELECT 113 UNION ALL
		SELECT 111


	----################ check concurrent running #####################----
	---- check by TempVariableNumber
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
			@UserID = @UserID, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = 0, 
			@Remark = 'ADD SUCCESS SPName=Acc_BettransDelSpecial_NumberGame'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'ADD SUCCESS SPName=Acc_BettransDelSpecial_NumberGame ErrMsg=' + left(error_message(), 400)
		EXEC LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @UserID, 
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
	
	----Check by SystemSettings
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
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 0, 
				@Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecial_NumberGame'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecial_NumberGame ErrMsg=' + left(error_message(), 400)
			EXEC LogDB.dbo.WriteLog_Settlement_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 0, 
				@Remark = @Remark
		END CATCH
		ELSE
		BEGIN
			BEGIN TRY
				EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
					@UserID = @UserID, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0, 
					@Remark = 'DEL FAILED SPName=Acc_BettransDelSpecial_NumberGame'
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'DEL FAILED SPName=Acc_BettransDelSpecial_NumberGame ErrMsg=' + left(error_message(), 400)
				EXEC LogDB.dbo.WriteLog_Settlement_Checking 
					@UserID = @UserID, 
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
	
	----################ End of check concurrent running #####################----
	
	CREATE TABLE #BetDelete (transid BIGINT, CustId INT, PlayerName nvarchar(50), betfrom NVARCHAR(1),statusID INT)
		

	INSERT INTO #BetDelete (transid, CustId, PlayerName, betfrom, statusID)			
			SELECT DISTINCT transid, CustId, Username, betfrom, statusID
			FROM bettrans b WITH (nolock)
			WHERE
				b.matchid = @matchid 						
				AND b.transid BETWEEN @f_transid AND @t_transid			
				and bettype BETWEEN 81 and 120		
				AND statusID NOT IN (101, 102)											
				AND
				(   
					(b.bettype IN (SELECT CONVERT(INT,val) FROM dbo.strSplit(@Dead,'^')) AND b.liveindicator = 0)
					 OR
					(b.bettype IN (SELECT CONVERT(INT,val) FROM dbo.strSplit(@Live,'^')) AND b.liveindicator = 1)
				) 		
				and  b.transid in (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids, ','))
				
	----------------------------------------------------------------------------
			
	IF EXISTS (SELECT 1 FROM #BetDelete WHERE statusID IN (111,112,113))
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'You can only delete the unsettled or refunded tickets.'
		
		----release data of TempVariableNumber table
		DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
		WHERE KeyID = 1 AND KeyValue = @matchid
		IF (@@Error = 0)
		BEGIN TRY
			EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 0, 
				@Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecial_NumberGame'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecial_NumberGame ErrMsg=' + left(error_message(), 400)
			EXEC LogDB.dbo.WriteLog_Settlement_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 0, 
				@Remark = @Remark
		END CATCH
		ELSE
		BEGIN
			BEGIN TRY
				EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
					@UserID = @UserID, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0, 
					@Remark = 'DEL FAILED SPName=Acc_BettransDelSpecial_NumberGame'
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'DEL FAILED SPName=Acc_BettransDelSpecial_NumberGame ErrMsg=' + left(error_message(), 400)
				EXEC LogDB.dbo.WriteLog_Settlement_Checking 
					@UserID = @UserID, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0, 
					@Remark = @Remark
			END CATCH
		END

		----release data of systemSettings table
		UPDATE	systemSettings WITH (ROWLOCK, UPDLOCK)
		SET		VValue = '0'
		WHERE	VName = 'isCalculatingNGManual'	

		RETURN
	END
	ELSE
	BEGIN
		DELETE FROM #BetDelete WHERE statusID IN (SELECT * FROM @Status)
	END
										
	--------------------------------------------------------------------------
	
	-- STEP 1 : BackUp
	INSERT INTO zzzbettrans
		(transid, CustId, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
	SELECT
		 transid, CustId, CURRENT_TIMESTAMP, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype
	FROM
		bettrans b WITH (nolock)
	WHERE
		b.transid IN (SELECT transid FROM #BetDelete)		
	
	CREATE TABLE #BeforeUpd (
			CustId		 INT,
			balance		 MONEY)
		
	CREATE TABLE #AfterUpd(
				CustId		 INT,
				balance		 MONEY)
				
	--Get data before update
	INSERT INTO #BeforeUpd (CustId, balance)
	SELECT	b.CustId, SUM (b.winlost - b.actual_stake + b.playercomm) balance
	FROM	bettrans b WITH (NOLOCK)
	WHERE	b.transid in (SELECT transid FROM #BetDelete)
	GROUP BY b.CustId
	
	
		
	-- STEP 2 : Update
		UPDATE 
			bettrans WITH (ROWLOCK, UPDLOCK)
		SET winlost=actual_stake,
			playercomm = 0, 
			Twinlost = 0, 
			Tcomm = 0, 
			ruben=1,
			statuswinlost=6, 
			status = 'Void',
			statusID = 102,
			creator = @UserID		      
		WHERE
			transid in (SELECT transid FROM #BetDelete)

	--  update Bettrans_Agent
			UPDATE	A 			
			SET		awinlost=0, 
					acomm = 0,
					status = 'Void', 
					statusID = 102        
			FROM	Bettrans_Agent A  WITH (ROWLOCK, UPDLOCK)
				INNER JOIN Bettrans B  WITH (NOLOCK)
					ON A.TransID = B.TransID
			WHERE	A.transid in (SELECT transid FROM #BetDelete)


	--Get data after update
	INSERT INTO #AfterUpd (CustId, balance)
	SELECT	b.CustId, SUM (b.winlost - b.actual_stake + b.playercomm) balance
	FROM	bettrans b WITH (NOLOCK)
	WHERE	b.transid in (SELECT transid FROM #BetDelete)
	GROUP BY b.CustId

	---insert data into pending balance table 
	INSERT INTO BalancePendingCredit (CustId,Balance)
	SELECT		a.CustId, (a.balance - b.balance) as Balance
	FROM		#BeforeUpd b
	INNER JOIN	#AfterUpd a 	
			ON	a.CustId = b.CustId
	WHERE	    (a.balance - b.balance) > 0

	INSERT INTO BalancePendingDebit (CustId,Balance)
	SELECT		a.CustId, ABS(a.balance - b.balance) as Balance
	FROM		#BeforeUpd b
	INNER JOIN	#AfterUpd a 	
			ON	a.CustId = b.CustId
	WHERE	    (a.balance - b.balance) < 0


	SELECT @LogData ='delete bet for matchid ' + CONVERT(VARCHAR(20), @matchid) + ' from ' + CONVERT(VARCHAR(20), @f_transid) + ' to ' + CONVERT(VARCHAR(20), @t_transid) + ' IP=' + COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))
	EXEC WriteLog_UserLog_T @UserID = @UserID, @Doing = @LogData

	--after delete, return all deleted deposit bets with additional information for mailing	
	--SELECT
	--	MATCH.homeid,
	--	MATCH.awayid,
	--	MATCH.matchcode,
	--	MATCH.eventdate,
	--	MATCH.leagueid,
	--	GETDATE() AS DATETIME,
	--	isnull(MATCH.isNeutral, CONVERT(BIT,0)) AS IsNeutral
	--FROM
	--	MATCH WITH (NOLOCK)
	--WHERE 
	--	MATCH.matchid = @matchID	
	   
	--SELECT
	--	b.username,
	--	b.odds,  
	--	b.OddsType, 
	--	b.transdate,
	--	b.bettype,
	--	b.transid AS refno,
	--	b.betteam,
	--	b.hdp1,
	--	b.hdp2,
	--	b.stake,
	--	b.winlost,
	--	b.comm, 
	--	b.status,
	--	b.currency,
	--	b.liveindicator				
	--FROM	#TicketInfo b WITH (NOLOCK)	
	--ORDER BY transid  	

-----Begin : Send mail when delete real currencies and creator username like 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'/ OR Currency is UUS	
	--SELECT
	--	customer.username,
	--	b.odds,  
	--	b.OddsType, 
	--	b.transdate,
	--	b.bettype,
	--	b.transid AS refno,
	--	b.betteam,
	--	b.hdp1,
	--	b.hdp2,
	--	cr.username creator,
	--	b.stake,
	--	b.winlost,
	--	b.comm, 
	--	b.status,
	--	b.currency,
	--	ag.site,
	--	b.liveindicator,			
	--	IsNegative	
	--FROM
	--	#TicketInfo b WITH (NOLOCK)
	--	INNER JOIN customer  WITH (NOLOCK) ON customer.custid=b.custid
	--	INNER JOIN customer cr WITH (NOLOCK) ON cr.custid = b.creator
	--	INNER JOIN customer ag WITH (NOLOCK) ON customer.recommend = ag.custid
	--	inner JOIN @NegativeBalanceCust nc on b.custid = nc.custid
	--WHERE customer.custid IN (SELECT custid FROM @UUSCust)
	--		or customer.custid IN (SELECT custid FROM @RealCurrCust) 				     
	--ORDER BY transid  	   	
	-----End : Send mail when delete real currencies and creator username like 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'/ OR Currency is UUS

		 
	---- List data to put Message
	SELECT  B.TransId, A.AgentID as TargetID, I.Username as TargetName, 1 as IsAgent
	FROM	#BetDelete B
	INNER JOIN Bettrans_Agent A WITH (NOLOCK)
			ON A.TransID = B.TransID
	INNER JOIN AgentInfo I WITh (NOLOCK)
			ON I.AgentID = A.AgentID
	UNION ALL
	SELECT  B.TransId, B.CustId as TargetID, B.PlayerName as TargetName, 0 as IsAgent
	FROM	#BetDelete B


	DROP TABLE #BetDelete
	DROP TABLE #BeforeUpd
	DROP TABLE #AfterUpd
	
	----release data of TempVariableNumber table
	DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
	WHERE KeyID = 1 AND KeyValue = @matchid	
	IF (@@Error = 0)
	BEGIN TRY
		EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @UserID, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = 0, 
			@Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecial_NumberGame'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecial_NumberGame ErrMsg=' + left(error_message(), 400)
		EXEC LogDB.dbo.WriteLog_Settlement_Checking 
			@UserID = @UserID, 
			@Matchid = @matchid, 
			@KeyID = 1,
			@ActionID = 0, 
			@Remark = @Remark
	END CATCH
	ELSE
	BEGIN
		BEGIN TRY
			EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 0, 
				@Remark = 'DEL FAILED SPName=Acc_BettransDelSpecial_NumberGame'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL FAILED SPName=Acc_BettransDelSpecial_NumberGame ErrMsg=' + left(error_message(), 400)
			EXEC LogDB.dbo.WriteLog_Settlement_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = 1,
				@ActionID = 0, 
				@Remark = @Remark
		END CATCH
	END
			
	----release data of systemSettings table
	UPDATE	systemSettings WITH (ROWLOCK, UPDLOCK)
	SET		VValue = '0'
	WHERE	VName = 'isCalculatingNGManual'	
END

GO
GRANT EXECUTE ON [dbo].[Acc_BettransDelSpecial_NumberGame] TO [aplweb] AS [dbo]
GO
--GRANT VIEW DEFINITION ON [dbo].[Acc_BettransDelSpecial_NumberGame] TO [vnteam] AS [dbo]