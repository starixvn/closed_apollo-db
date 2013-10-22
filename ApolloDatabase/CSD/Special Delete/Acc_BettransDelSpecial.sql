ALTER PROCEDURE [dbo].[Acc_BettransDelSpecial]
    @matchid INT,
    @FromTransId BIGINT,
    @ToTransId BIGINT,
    @transids VARCHAR(4000) = '', 
    @bettypes VARCHAR(128) = '',
    @betteam1378 NVARCHAR(10) = '',
    @betteam515 NVARCHAR(10) = '',
    @betteam430 VARCHAR(120) = '',
    @betteam6 varchar(120) = '',
	@betteam14 varchar(120) = '',
	@betteam16 varchar(120) = '',
    @hdp SMALLMONEY,
    @UserName NVARCHAR(50),
    @UserPwd NVARCHAR(50),
    @UserID INT,
    @ErrMsg NVARCHAR(200) = '' OUTPUT,
    @ErrCode INT = 0 OUTPUT,
    @liveindicator SMALLINT = 0,
    @livehomescore smallint = NULL,
    @liveawayscore smallint = NULL,
    @FromTransdate Datetime = NULL,
	@ToTransdate Datetime = NULL,
    @IP VARCHAR(15) = '',   
    @SAFilter tinyint = 0 
AS

/*
Created by: Sophia
Date: 20130305
Task : delete single bet and outright
DB: SVRTXN.TransDB
Original: 

Revisions:    
  - 20130725@Sophia: Change username nvarchar(50)
  - 20130729@Sophia: Get Username of Agent from AgentInfo table to put Message
  - 20130829@Sophia: change @f_transID /@t_transid to @FromTransId / @ToTransId
  - 20131017@Sophia: Get data to mail
		    
Param's Explanation: Special bet delete option

    - @SAFilter: 
      + 0: All tickets
      + 1: Normal tickets only
      + 2: SA tickets only
     
    - @liveindicator:
	 + 0: Dead
	 + 1: Live
	 + 2: All

*/

	SET NOCOUNT ON

	---- **************MODIFY LATER*********
	----Check permission for account site:  
	--EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[SpecialDelete]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	--IF @ErrCode <> 0
	--	RETURN
	--end
		
	
	DECLARE @LogData NVARCHAR(500)
	DECLARE @Remark VARCHAR(500)
	SELECT @ErrCode = 0

	IF NOT EXISTS ( SELECT 1
					FROM	SVRCUST.CustDB.dbo.AdminInfo WITH (NOLOCK)
					WHERE   UserPwd = @UserPwd
							and AdminId = @UserID)
	BEGIN
		SELECT @LogData ='Fail to delete bet for matchid ' + CONVERT(VARCHAR(20), @matchid) + ' from ' + CONVERT(VARCHAR(20), @FromTransId) + ' to ' + CONVERT(VARCHAR(20), @ToTransId)
		EXEC WriteLog_UserLog_T @UserID = @UserID, @Doing = @LogData

		SELECT @ErrMsg = 'Sorry. You can not process delete bet due to either wrong password or insufficient permission!',
			   @ErrCode = 101   
		RETURN
	END
	
	---- check and not allow attempt to delete same game while it's still not finish
	DECLARE @KeyID INT

	IF EXISTS(SELECT CONVERT(INT,val) FROM dbo.strSplit(@bettypes,'^') WHERE CONVERT(INT, val) = 10)
	BEGIN 	
		SET @KeyID = 2
	END
	ELSE
	BEGIN 	
		SET @KeyID = 1
	END

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
			@Remark = 'ADD SUCCESS SPName=Acc_BettransDelSpecial'
	END TRY
	BEGIN CATCH
		SELECT @Remark = 'ADD SUCCESS SPName=Acc_BettransDelSpecial ErrMsg=' + left(error_message(), 400)
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
		
	CREATE TABLE #BetDelete (transid BIGINT, CustId INT, PlayerName nvarchar(50), betfrom NVARCHAR(1),statusID INT, status VARCHAR(10))
 
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

	

------------------***** Insert all data into #BetDelete *****------------------
	--bettype <> 4
	INSERT INTO #BetDelete (transid, CustId, PlayerName, betfrom, statusID, status )   
	SELECT DISTINCT transid, CustId, username, betfrom, statusID, status
	FROM bettrans b WITH (nolock)
		INNER JOIN dbo.strSplit(@bettypes,'^') AS bt ON bt.val=b.bettype
	WHERE
		b.matchid=@matchid 
		AND b.transid between @FromTransId and @ToTransId
		AND CASE WHEN @liveindicator = 2 THEN @liveindicator ELSE b.liveindicator END = @liveindicator
		AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @liveindicator = 1 THEN @livehomescore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @liveindicator = 1 THEN @liveawayscore ELSE b.liveawayscore END
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @liveindicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @liveindicator = 1 THEN @ToTransdate ELSE b.transdate END 
		and CASE
			WHEN b.bettype in (1,3,7,8,2,12) THEN CASE WHEN @betteam1378 = 'ALL' THEN betteam ELSE @betteam1378 END
			WHEN b.bettype in (5,15) THEN CASE WHEN @betteam515 = 'ALL' THEN betteam ELSE @betteam515 END               
			ELSE betteam 
		END = betteam    
		AND b.bettype NOT IN(4,6,14,16,30)
		AND CASE WHEN b.bettype in (1,3,7,8) THEN CASE
													WHEN @hdp = 9999 THEN 1
													WHEN @hdp = (hdp1 + hdp2) THEN 1
													ELSE 0
												  END
		ELSE 1 END = 1
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
		AND b.TransID IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids, ','))
        
	--bettype = 4
	INSERT INTO #BetDelete (transid, CustId, PlayerName, betfrom, statusID, status)   
	SELECT DISTINCT transid, CustId, Username, betfrom, statusID, status
	FROM bettrans b WITH (nolock)
		LEFT JOIN dbo.strSplit(@betteam430,'^') AS bt ON b.betteam=CONVERT(varchar(3),bt.val)
	WHERE
		b.matchid=@matchid and           
		b.transid between @FromTransId and @ToTransId
		AND CASE WHEN @liveindicator = 2 THEN @liveindicator ELSE b.liveindicator END = @liveindicator
		AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @liveindicator = 1 THEN @livehomescore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @liveindicator = 1 THEN @liveawayscore ELSE b.liveawayscore END
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @liveindicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @liveindicator = 1 THEN @ToTransdate ELSE b.transdate END 
		and b.bettype in (4,30)
		AND (@betteam430='All' OR bt.val IS NOT NULL)
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
		AND b.TransID IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids, ','))	

 
	INSERT INTO #BetDelete (transid, CustId, PlayerName, betfrom, statusID, status)   
	SELECT DISTINCT transid, CustId, Username, betfrom, statusID, status
	FROM dbo.bettrans AS b WITH (nolock)
		LEFT JOIN dbo.strSplit(@betteam6,'^') AS bt ON bt.val=b.betteam
	WHERE
		b.matchid=@matchid and           
		b.transid between @FromTransId and @ToTransId		
		AND CASE WHEN @liveindicator = 2 THEN @liveindicator ELSE b.liveindicator END = @liveindicator
		AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @liveindicator = 1 THEN @livehomescore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @liveindicator = 1 THEN @liveawayscore ELSE b.liveawayscore END	
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @liveindicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @liveindicator = 1 THEN @ToTransdate ELSE b.transdate END 	
		and b.bettype = 6
		AND (@betteam6='All' OR bt.val IS NOT NULL)
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
		AND b.TransID IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids, ','))
	
	INSERT INTO #BetDelete (transid, CustId, PlayerName, betfrom, statusID,status)   
	SELECT DISTINCT transid, CustId, Username, betfrom, statusID, status
	FROM bettrans b WITH (nolock)
		LEFT JOIN dbo.strSplit(@betteam14,'^') AS bt ON b.betteam=CONVERT(varchar(3),bt.val)
	WHERE
		b.matchid=@matchid and           
		b.transid between @FromTransId and @ToTransId
		AND CASE WHEN @liveindicator = 2 THEN @liveindicator ELSE b.liveindicator END = @liveindicator
		AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @liveindicator = 1 THEN @livehomescore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @liveindicator = 1 THEN @liveawayscore ELSE b.liveawayscore END
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @liveindicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @liveindicator = 1 THEN @ToTransdate ELSE b.transdate END 
		and b.bettype = 14
		AND (@betteam14='All' OR bt.val IS NOT NULL)
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
		AND b.TransID IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids, ','))	
		
	INSERT INTO #BetDelete (transid, CustId, PlayerName, betfrom, statusID, status)   
	SELECT DISTINCT transid, CustId, Username, betfrom, statusID, status
	FROM dbo.bettrans AS b WITH (nolock)
		LEFT JOIN dbo.strSplit(@betteam16,'^') AS bt ON bt.val=b.betteam
	WHERE
		b.matchid=@matchid and           
		b.transid between @FromTransId and @ToTransId		
		AND CASE WHEN @liveindicator = 2 THEN @liveindicator ELSE b.liveindicator END = @liveindicator	
		AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @liveindicator = 1 THEN @livehomescore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @liveindicator = 1 THEN @liveawayscore ELSE b.liveawayscore END	
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @liveindicator = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @liveindicator = 1 THEN @ToTransdate ELSE b.transdate END 
		and b.bettype = 16
		AND (@betteam16='All' OR bt.val IS NOT NULL)
		AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
		AND b.TransID IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids, ','))
	 
------------------***** End of insert all data into #BetDelete *****------------------		
			
	IF EXISTS (SELECT 1 FROM #BetDelete WHERE statusID IN (111,112,113))
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'You can only delete the unsettled or refunded tickets.'
		
		-----
		DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
		WHERE KeyID = @KeyID AND KeyValue = @matchid	
		IF (@@Error = 0)
		BEGIN TRY
			EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = @KeyID,
				@ActionID = 0, 
				@Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecial'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecial ErrMsg=' + left(error_message(), 400)
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
					@Remark = 'DEL FAILED SPName=Acc_BettransDelSpecial'
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'DEL FAILED SPName=Acc_BettransDelSpecial ErrMsg=' + left(error_message(), 400)
				EXEC LogDB.dbo.WriteLog_Settlement_Checking 
					@UserID = @UserID, 
					@Matchid = @matchid, 
					@KeyID = @KeyID,
					@ActionID = 0, 
					@Remark = @Remark
			END CATCH
		END
		RETURN
	END
	ELSE
	BEGIN
		DELETE FROM #BetDelete WHERE statusID IN (SELECT * FROM @Status)
	END
	


------------------***** Begin Special Delete *****------------------

	-- STEP 1 : BackUp
		INSERT INTO
			zzzbettrans
			(transid, CustId, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
		SELECT
			 transid, CustId, CURRENT_TIMESTAMP, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype
		FROM
			bettrans b WITH (nolock)
		WHERE
			b.transid IN (SELECT transid FROM #BetDelete)
			AND b.bettype in (SELECT CONVERT(INT,val) FROM dbo.strSplit(@bettypes,'^'))
			AND b.matchid = @matchid
			AND CASE
				WHEN b.bettype in (1,3,7,8) THEN CASE WHEN @betteam1378 = 'ALL' THEN betteam ELSE @betteam1378 END
				WHEN b.bettype in (5,15) THEN CASE WHEN @betteam515 = 'ALL' THEN betteam ELSE @betteam515 END
				ELSE betteam
			END = betteam   


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
		--  update bettrans
			UPDATE	bettrans WITH (ROWLOCK, UPDLOCK)
			SET		winlost=actual_stake,
					playercomm = 0,
					Twinlost = 0,
					Tcomm = 0,    
					ruben=1,
					statuswinlost=6,
					status = 'Void', 
					statusID = 102, 
					creator = @UserID					
			WHERE	transid in (SELECT transid FROM #BetDelete)

		--  update Bettrans_Agent
			UPDATE	A WITH(ROWLOCK,UPDLOCK)		
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

------------------***** End of Special Delete *****------------------

	SELECT @LogData ='Delete bet for matchid ' + CONVERT(VARCHAR(20), @matchid) + ' from ' + CONVERT(VARCHAR(20), @FromTransId) + ' to ' + CONVERT(VARCHAR(20), @ToTransId) + ' IP=' + COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))
	EXEC WriteLog_UserLog_T @UserID = @UserID, @Doing = @LogData
		 

------after delete, return all deleted with additional information for mailing 
	
	IF EXISTS(SELECT CONVERT(INT,val) FROM dbo.strSplit(@bettypes,'^') WHERE CONVERT(INT, val) = 10)  --@bettype = 10
		BEGIN
			-- Get Outright info
			SELECT
				MATCH.teamid AS homeid,
				0 AS awayid,
				MATCH.matchcode,
				MATCH.eventdate,
				MATCH.leagueid,
				GETDATE() AS DATETIME,
				CONVERT(BIT,0) AS IsNeutral
			FROM
				Outright AS MATCH WITH (NOLOCK)
			WHERE 
				MATCH.orid = @matchID

			-- Get deleted tickets Info	 
			SELECT
				b.transid,
				b.CustId, 
				b.username,
				b.odds,
				b.transdate,	
				b.stake,
				b.currency, 
				d.status 
			FROM bettrans b WITH (NOLOCK)
			INNER JOIN #BetDelete d WITH (NOLOCK)
				ON b.transID = d.transID		
			ORDER BY b.transid

		END   
	ELSE
		BEGIN
			-- Get Match info
			SELECT
				MATCH.homeid,
				MATCH.awayid,
				MATCH.matchcode,
				MATCH.eventdate,
				MATCH.leagueid,
				GETDATE() AS DATETIME,
				isnull(MATCH.isNeutral, CONVERT(BIT,0)) AS IsNeutral
			FROM
				MATCH WITH (NOLOCK)
			WHERE 
				MATCH.matchid = @matchID


			-- Get deleted tickets Info	 
			SELECT
				b.transid,
				b.CustId,
				b.username,
				b.odds,   
				b.OddsType,  
				b.transdate,
				b.bettype,
				b.betteam,
				b.hdp1,
				b.hdp2,
				b.Liveindicator,
				b.livehomescore,
				b.liveawayscore,
				b.stake,
				b.CurrencyName,
				d.status,
				ISNULL(b.SecAcceptFlag,0) SecAcceptFlag,
				m.HomeId, 
				m.AwayId, 
				m.SportType,
				m.LeagueId
			FROM bettrans b WITH (NOLOCK)
			INNER JOIN #BetDelete d WITH (NOLOCK)
				ON b.transID = d.transID
			INNER JOIN Match m WITH (NOLOCK) 
				ON b.MatchId = m.MatchId
			WHERE  m.matchID = @matchID
			ORDER BY b.transid

		END	

		-----Get username having negative balance 
		SELECT  B.PlayerName as username, (C.Balance + PC.Balance) - (D.Balance+ PD.Balance) as Balance
		FROM	#BetDelete B 
		INNER JOIN BalanceCredit C 
				ON B.CustId = C.CustID
		INNER JOIN BalanceDebit D   
				ON B.CustId = D.CustId
		LEFT JOIN BalancePendingCredit PC
				ON C.CustId = PC.CustId
		LEFT JOIN BalancePendingDebit PD
				ON D.CustId = PD.CustId
		WHERE (C.Balance + PC.Balance) - (D.Balance+ PD.Balance) < 0

		 
	-----End : Send mail when delete tickets 

	
	----Begin: List data to put Message
	SELECT  B.TransId, A.AgentID as TargetID, I.Username as TargetName, 1 as IsAgent
	FROM	#BetDelete B
	INNER JOIN Bettrans_Agent A WITH (NOLOCK)
			ON A.TransID = B.TransID
	INNER JOIN AgentInfo I WITH (NOLOCK)
			ON I.AgentId = A.AgentId
	UNION ALL
	SELECT  B.TransId, B.CustId as TargetID, B.PlayerName as TargetName, 0 as IsAgent
	FROM	#BetDelete B	
	
	----END: List data to put Message

	
	------Release	
	DROP TABLE #BetDelete
	
	DROP TABLE #BeforeUpd
	DROP TABLE #AfterUpd

	---------
	DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
	WHERE KeyID = @KeyID AND KeyValue = @matchid	
	IF (@@Error = 0)
		BEGIN TRY
			EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
				@UserID = @UserID, 
				@Matchid = @matchid, 
				@KeyID = @KeyID,
				@ActionID = 0, 
				@Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecial'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecial ErrMsg=' + left(error_message(), 400)
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
					@Remark = 'DEL FAILED SPName=Acc_BettransDelSpecial'
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'DEL FAILED SPName=Acc_BettransDelSpecial ErrMsg=' + left(error_message(), 400)
				EXEC LogDB.dbo.WriteLog_Settlement_Checking 
					@UserID = @UserID, 
					@Matchid = @matchid, 
					@KeyID = @KeyID,
					@ActionID = 0, 
					@Remark = @Remark
			END CATCH
		END
	
	SET NOCOUNT OFF

	 
GO
GRANT EXECUTE ON [dbo].[Acc_BettransDelSpecial] TO [aplweb] AS [dbo]
GO 