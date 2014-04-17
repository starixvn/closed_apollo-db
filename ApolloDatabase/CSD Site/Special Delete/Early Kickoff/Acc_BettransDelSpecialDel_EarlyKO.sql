ALTER PROCEDURE [dbo].[Acc_BettransDelSpecialDel_EarlyKO]
    @matchid INT,
    @KickOffDate datetime,
    @transids VARCHAR(4000) = 'All',
    @bettypes VARCHAR(128) = 'All',
    @betteam1378 NVARCHAR(10) = '',
    @betteam515 NVARCHAR(10) = '',    
    @betteam430 varchar(120) = '',
	@betteam6 varchar(120) = '',
	@betteam14 varchar(120) = '',
	@betteam16 varchar(120) = '',
    @hdp SMALLMONEY,
    @UserName NVARCHAR(50),
    @UserPwd NVARCHAR(50),
    @UserID INT,
    @ErrMsg NVARCHAR(200) = '' OUTPUT,
    @ErrCode INT = 0 OUTPUT,       
    @IP VARCHAR(15) = '',    
    @SAFilter tinyint = 0 	

AS
/*  
   Created by: Sophia
	Date: 20130718
	Original:  
	Task: Delete bet tickets early kickoff need to delete
	DB: SVRTXN/TRANSDB

	Revisions:		
		- 20130725@Sophia: Change username nvarchar(50)
		- 20130729@Sophia: Get Username of Agent from AgentInfo table to put Message
		- 20140414@Sophia: Get EventStatus at match_remark_ex table

	Explanation's Param:
	    - @SAFilter: 
	      + 0: All tickets
          + 1: Normal tickets only
	      + 2: SA tickets only
     		
*/
BEGIN
SET NOCOUNT ON


	----Check permission for account site: @phuc20080213
	--EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[SpecialDeleteEarlyKickOff]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	--IF @ErrCode <> 0
	--RETURN
	 

	DECLARE @LogData NVARCHAR(500)
	SELECT @ErrCode = 0

	IF NOT EXISTS ( SELECT 1
					FROM	SVRCUST.CustDB.dbo.AdminInfo WITH (NOLOCK)
					WHERE   UserPwd = @UserPwd
							and AdminId = @UserID)
	BEGIN
		SELECT @LogData ='fail to delete bet for matchid ' + CONVERT(VARCHAR(20), @matchid) + ' because of early kick off at '+CAST(@KickOffDate as varchar(30))
		EXEC WriteLog_UserLog_T @UserID = @UserID, @Doing = @LogData

		SELECT @ErrMsg = 'Sorry. You can not process delete bet due to either wrong password or insufficient permission!', @ErrCode = 101   
		RETURN
	END
			
	IF EXISTS(SELECT 1 FROM dbo.Match_Remark_Ex WITH(NOLOCK) WHERE matchid=@matchid AND eventstatus='completed')
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'You can not delete completed match.'
		RETURN
	END
	
	----################### Check for concurrent running ###################----
	DECLARE @isParlay TINYINT 
	
	IF EXISTS (SELECT 1 FROM dbo.strSplit(@bettypes,'^') WHERE val IN (9,29))	
		AND EXISTS (SELECT 1 FROM dbo.bettransm AS b WITH(NOLOCK) WHERE b.matchid=@matchid  AND b.transdate>=@KickOffDate AND b.statusID NOT IN (101,102) AND b.liveindicator=0 AND betfrom <>'P')
	BEGIN 	
		IF @bettypes IN ('9','29','9^29','29^9')
			SET @isParlay = 1  --- Only Parlay
		ELSE
			SET @isParlay = 2  --- Parlay and other bettype
	END	
	ELSE 
		SET @isParlay = 0 ---Not have Parlay
	
	DECLARE @Remark VARCHAR(500)
	------ Check for concurrent running of match
	IF @isParlay IN (0,2)
	BEGIN 
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
				@Remark = 'ADD SUCCESS SPName=Acc_BettransDelSpecialDel_EarlyKO'
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'ADD SUCCESS SPName=Acc_BettransDelSpecialDel_EarlyKO ErrMsg=' + left(error_message(), 400)
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
	END
	------ Check for concurrent running for Parlay 
	IF @isParlay IN (1,2)
	BEGIN 	
		IF EXISTS(SELECT 1 FROM SystemSettings WITH (NOLOCK) WHERE VValue = 1 AND VName = 'isCalculatingParlay')
		BEGIN
			SELECT @ErrCode = 102
			SELECT @ErrMsg = 'Another parlay settlement is in progress or some parlay tickets are being deleted, please wait a few seconds until the on-going process has finished and try again.'
			
			---- release data of TempVariableNumber before return
			DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
			WHERE KeyID = 1 AND KeyValue = @matchid	
			IF (@@Error = 0)
			BEGIN TRY
				EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking
					@UserID = @UserID, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0, 
					@Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecialDel_EarlyKO'
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecialDel_EarlyKO ErrMsg=' + left(error_message(), 400)
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
						@Remark = 'DEL FAILED SPName=Acc_BettransDelSpecialDel_EarlyKO'
				END TRY
				BEGIN CATCH
					SELECT @Remark = 'DEL FAILED SPName=Acc_BettransDelSpecialDel_EarlyKO ErrMsg=' + left(error_message(), 400)
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
			WHERE	VName = 'isCalculatingParlay'
		END
	
	END 	
	----################### End of check for concurrent running ###################----
	
	CREATE TABLE #BetDelete (transid BIGINT,refno bigint,custid INT, Username nvarchar(50), betfrom NVARCHAR(1),statusID INT, Status Varchar(10))
	CREATE TABLE #BetmDelete (transid BIGINT,refno bigint,custid INT, Username nvarchar(50), betfrom NVARCHAR(1),statusID INT, Status Varchar(10))
		
 
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
	

------------------***** Insert all data into #BetDelete,#BetmDelete *****------------------	
	
	--bettype <> 4
	INSERT INTO #BetDelete (transid,refno,custid, Username, betfrom, statusID,Status)   
	SELECT DISTINCT transid,refno,custid, Username, betfrom, statusID, Status
	FROM bettrans b WITH (nolock)
		INNER JOIN dbo.strSplit(@bettypes,'^') AS fb ON b.bettype=fb.val
	WHERE
			b.matchid=@matchid	
			AND b.transdate>=@KickOffDate	
			AND b.liveindicator=0		
			AND CASE
				WHEN b.bettype in (1,3,7,8,2,12) THEN CASE WHEN @betteam1378 = 'ALL' THEN betteam ELSE @betteam1378 END
				WHEN b.bettype in (5,15) THEN CASE WHEN @betteam515 = 'ALL' THEN betteam ELSE @betteam515 END               
				ELSE betteam 
			END = betteam
			AND CASE WHEN b.bettype in (1,3,7,8) THEN CASE
												WHEN @hdp = 9999 THEN 1
												WHEN @hdp = (hdp1 + hdp2) THEN 1
												ELSE 0
											  END
				ELSE 1 END = 1
			AND b.bettype NOT IN(4,6,14,16,30)
			AND b.betfrom <>'P'
			AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
	

	--bettype = 4
	INSERT INTO #BetDelete (transid,refno,custid,Username,betfrom, statusID,Status)   
	SELECT DISTINCT transid,refno,custid, Username, betfrom, statusID,Status
	FROM bettrans b WITH (nolock)
	WHERE
			b.matchid=@matchid	
			AND b.transdate>=@KickOffDate	
			AND b.liveindicator=0		
			AND betteam  in (SELECT CONVERT(VARCHAR,val) FROM dbo.strSplit(CASE WHEN @betteam430 = 'All' THEN betteam ELSE @betteam430 END,'^'))
			AND b.bettype in (4,30)
			AND b.betfrom <>'P'
			AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
		
	
	INSERT INTO #BetDelete (transid,refno,custid,Username, betfrom, statusID,Status)   
	SELECT DISTINCT transid,refno,custid, Username,betfrom, statusID,Status
	FROM bettrans b WITH (nolock)
	WHERE
			b.matchid=@matchid	
			AND b.transdate>=@KickOffDate	
			AND b.liveindicator=0		
			AND betteam  in (SELECT CONVERT(VARCHAR,val) FROM dbo.strSplit(CASE WHEN @betteam6 = 'All' THEN betteam ELSE @betteam6 END,'^'))
			AND b.bettype = 6
			AND b.betfrom <>'P'
			AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
		
	
	INSERT INTO #BetDelete (transid,refno,custid,Username,betfrom, statusID,Status)   
	SELECT DISTINCT transid,refno,custid,Username,betfrom, statusID, Status
	FROM bettrans b WITH (nolock)
		LEFT JOIN dbo.strSplit(@betteam14,'^') AS goal ON goal.val=b.betteam 
	WHERE
			b.matchid=@matchid	
			AND b.transdate>=@KickOffDate	
			AND b.liveindicator=0		
			AND b.bettype = 14
			AND b.betfrom <>'P'
			AND (@betteam14 = 'All' OR goal.val IS NOT NULL)
			AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
		
	
	INSERT INTO #BetDelete (transid,refno,custid,Username,betfrom, statusID,Status)   
	SELECT DISTINCT transid,refno,custid,Username,betfrom, statusID, Status
	FROM bettrans b WITH (nolock)
	WHERE
			b.matchid=@matchid	
			AND b.transdate>=@KickOffDate	
			AND b.liveindicator=0		
			AND betteam  in (SELECT CONVERT(VARCHAR,val) FROM dbo.strSplit(CASE WHEN @betteam16 = 'All' THEN betteam ELSE @betteam16 END,'^'))
			AND b.bettype = 16
			AND b.betfrom <>'P'
			AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
		
				
	--GET sub ticket of the matchid for mix parlay
	IF EXISTS (SELECT 1 FROM dbo.strSplit(@bettypes,'^') WHERE val IN (9,29))	
		AND EXISTS (SELECT 1 FROM dbo.bettransm AS b WITH(NOLOCK) WHERE b.matchid=@matchid AND b.transdate>=@KickOffDate AND b.statusID NOT IN (101,102) AND b.liveindicator=0 AND betfrom <>'P')
	BEGIN	
		INSERT INTO #BetmDelete (transid,refno,custid,Username, betfrom, statusID, Status)   
		SELECT DISTINCT b.transid,b.refno,b.custid,bt.Username, b.betfrom, b.statusID , b.Status
		FROM bettransm AS b with (NOLOCK)			
			INNER JOIN bettrans bt WITH(NOLOCK) ON b.refno = bt.refno 
			INNER JOIN (SELECT CONVERT(SMALLINT,val) AS bettype FROM dbo.strSplit(@bettypes,'^') WHERE val IN (9,29)) t ON t.bettype = bt.bettype	
		WHERE	b.matchid=@matchid   
			AND b.transdate>=@KickOffDate		
			AND b.liveindicator=0			
			AND b.betfrom <>'P'
			AND bt.matchid IN (9,29) AND bt.bettype IN (9,29)
			AND CASE when @SAFilter = 2 then 0 else 1 END = 1
			---AND (bt.betid = 0 OR bt.betid IS NULL)			
	END

------------------***** End of insert all data into #BetDelete,#BetmDelete *****------------------	

------------------***** Remove data no need to special delete out of #BetDelete *****------------------	
	
	IF @transids <> ''
	BEGIN
		DELETE FROM #BetDelete
		WHERE transid NOT IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids, ','))
			
		
		DELETE FROM #BetmDelete
		WHERE transid NOT IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids, ','))			
	END

------------------***** End of Remove data no need to special delete out of #BetDelete  *****------------------

-------------------Checking 
		
	IF EXISTS (SELECT 1 FROM #BetDelete WHERE statusID IN (111,112,113)
			UNION ALL 
			SELECT 1 FROM #BetmDelete WHERE statusID IN (111,112,113))
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'You can only delete the unsettled or refunded tickets.'
		
		-----Release data of TempVariableNumber table before
		IF @isParlay IN (0,2)
		BEGIN 
			DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
			WHERE KeyID = 1 AND KeyValue = @matchid	
			IF (@@Error = 0)
			BEGIN TRY
				EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking
					@UserID = @UserID, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0, 
					@Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecialDel_EarlyKO'
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecialDel_EarlyKO ErrMsg=' + left(error_message(), 400)
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
						@Remark = 'DEL FAILED SPName=Acc_BettransDelSpecialDel_EarlyKO'
				END TRY
				BEGIN CATCH
					SELECT @Remark = 'DEL FAILED SPName=Acc_BettransDelSpecialDel_EarlyKO ErrMsg=' + left(error_message(), 400)
					EXEC LogDB.dbo.WriteLog_Settlement_Checking
						@UserID = @UserID, 
						@Matchid = @matchid, 
						@KeyID = 1,
						@ActionID = 0, 
						@Remark = @Remark
				END CATCH
			END
		END 
		
		-----Release data of SystemSettings table before
		IF @isParlay IN (1,2)
		BEGIN 	
			UPDATE	SystemSettings WITH (ROWLOCK, UPDLOCK)
			SET		VValue = '0'
			WHERE	VName = 'isCalculatingParlay'
		END

		RETURN
	END
	ELSE
	BEGIN
		DELETE FROM #BetDelete WHERE statusID IN (SELECT * FROM @Status)
		DELETE FROM #BetmDelete WHERE statusID IN (SELECT * FROM @Status)
	END

	 
------------------***** Begin special delete early kickoff *****------------------

	-- STEP 1 : BackUp of bettrans and bettransm
	INSERT INTO	zzzbettrans
		(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
	SELECT
		b.transid, b.custid, CURRENT_TIMESTAMP, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, b.status, b.winlost, b.livehomescore, b.liveawayscore, b.liveindicator, b.betteam, b.creator , b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.matchid, b.bettype
	FROM	dbo.bettrans AS b WITH (nolock)
		INNER JOIN #BetDelete AS d WITH(NOLOCK) ON d.transid=b.transid AND d.refno=b.refno
	WHERE		
		b.bettype in (SELECT CONVERT(INT,val) FROM dbo.strSplit(@bettypes,'^'))
		AND b.matchid = @matchid
		AND b.liveindicator = 0
		AND b.transdate>=@KickOffDate
		AND CASE
		WHEN b.bettype in (1,3,7,8) THEN CASE WHEN @betteam1378 = 'ALL' THEN betteam ELSE @betteam1378 END
		WHEN b.bettype in (5,15) THEN CASE WHEN @betteam515 = 'ALL' THEN betteam ELSE @betteam515 END
		ELSE betteam
		END = betteam

	-- BackUp bettransm tickets into zzzbettrans
	/***
		ADD MORE LOG IN ZZZBETTRANS FOR VIEWING LOG TW SITE
	***/
	INSERT INTO	zzzbettrans
		(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
	SELECT
		b.transid, b.custid, CURRENT_TIMESTAMP, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, b.status, b.winlost, b.livehomescore, b.liveawayscore, b.liveindicator, b.betteam, b.creator , b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.matchid, b.bettype
	FROM	bettransm AS b WITH (nolock)
		INNER JOIN #BetmDelete AS d WITH(NOLOCK) ON d.transid=b.transid AND d.refno=b.refno
	WHERE
		b.matchid = @matchid
		AND b.liveindicator = 0
		AND b.transdate>=@KickOffDate	
	/*
		END - ADD MORE LOG IN ZZZBETTRANS FOR VIEWING LOG TW SITE
	*/

	INSERT INTO	zzzbettransm
		(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
	SELECT
		b.transid, b.custid, CURRENT_TIMESTAMP, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, b.status, b.winlost, b.livehomescore, b.liveawayscore, b.liveindicator, b.betteam, b.creator , b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.matchid, b.bettype
	FROM	bettransm AS b WITH (nolock)
		INNER JOIN #BetmDelete AS d WITH(NOLOCK) ON d.transid=b.transid AND d.refno=b.refno
	WHERE
		b.matchid = @matchid
		AND b.liveindicator = 0
		AND b.transdate>=@KickOffDate		
		
	declare @matchdate datetime
	select @matchdate = eventdate from match with(nolock) where matchid = @matchid

	-- Create temp table to calculate balance
	CREATE TABLE #BeforeUpd (
			custid		 INT,
			balance		 MONEY)
		
	CREATE TABLE #AfterUpd(
				custid		 INT,
				balance		 MONEY)
				
	--Get data before update
	INSERT INTO #BeforeUpd (custid, balance)
	SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
	FROM	bettrans b WITH (NOLOCK)
	INNER JOIN #BetDelete d WITH(NOLOCK) ON d.transid=b.transid AND d.refno=b.refno
	GROUP BY b.CustID
	
	-- STEP 2 : Update 
		--  update bettrans
			UPDATE	B
			SET		winlost=actual_stake,
					playercomm = 0,
					Twinlost = 0,
					Tcomm = 0,    
					ruben=1,
					statuswinlost=6,
					status = 'Void', 
					statusID = 102, 
					creator = @UserID	
			FROM Bettrans B	WITH (ROWLOCK, UPDLOCK)		
			INNER JOIN #BetDelete AS D WITH(NOLOCK) ON D.transid=B.transid AND D.refno=B.refno
	

		--  update Bettrans_Agent
			UPDATE	A WITH(ROWLOCK,UPDLOCK)		
			SET		awinlost=0, 
					acomm = 0,
					status = 'Void', 
					statusID = 102       
			FROM	Bettrans_Agent A  WITH (ROWLOCK, UPDLOCK)
			INNER JOIN #BetDelete D WITH(NOLOCK) ON D.transid=A.transid AND D.refno=A.refno
				 
	
	--Get data after update
	INSERT INTO #AfterUpd (custid, balance)
	SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
	FROM	bettrans b WITH (NOLOCK)
	INNER JOIN #BetDelete AS d WITH(NOLOCK) ON d.transid=b.transid AND d.refno=b.refno
	GROUP BY b.CustID

	---insert data into pending balance table 
		INSERT INTO BalancePendingCredit (custid,Balance)
		SELECT		a.custid, (a.balance - b.balance) as Balance
		FROM		#BeforeUpd b
		INNER JOIN	#AfterUpd a 	
				ON	a.custid = b.custid
		WHERE	    (a.balance - b.balance) > 0

		INSERT INTO BalancePendingDebit (custid,Balance)
		SELECT		a.custid, ABS(a.balance - b.balance) as Balance
		FROM		#BeforeUpd b
		INNER JOIN	#AfterUpd a 	
				ON	a.custid = b.custid
		WHERE	    (a.balance - b.balance) < 0
		 
	
	IF EXISTS (SELECT 1 FROM #BetmDelete)
	BEGIN	
		declare @match_tmp varchar(20), @rowcount INT, @step INT, @transid_tmp VARCHAR(2000)

		select	@match_tmp = CONVERT(VARCHAR(20),@matchid),
				@step = 0
		

		DECLARE @transtbl TABLE (id INT IDENTITY, transid BIGINT)
		INSERT INTO @transtbl (transid)
					SELECT transid
					FROM #BetmDelete
		SELECT @rowcount = @@ROWCOUNT

		WHILE @step < @rowcount
		BEGIN

			SET @transid_tmp = ''

			SELECT @transid_tmp  = @transid_tmp + CONVERT(VARCHAR(20),transid)  + ','	
			FROM @transtbl
			WHERE id > @step AND id <= @step + 100
			
			SET @step = @step + 100

			EXEC Admin_Calculate_9m 
					@matchid	= @MatchID,
					@fth		= 0, 
					@fta		= 0,
					@hth		= 0,  
					@hta		= 0,
					@matchdate	= @matchdate,
					@action		= 'VOID',
					@VoidTransID= @transid_tmp,
					@UserID		= @UserID
		END

	--***********System parlay*********---
		IF EXISTS (	SELECT TOP 1 1
					FROM bettrans b WITH(NOLOCK) 
						INNER JOIN #BetmDelete r ON b.refno = r.refno
					WHERE b.matchid = 29 AND b.bettype = 29
				   ) 
		BEGIN
			EXEC dbo.Admin_Calculate_29_PreCal @matchids = @match_tmp
						
		---********* Calculate balance for system parlay********---
		
				DELETE #BeforeUpd
				DELETE #AfterUpd
								
				--Get data before update
				INSERT INTO #BeforeUpd (custid, balance)
				SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
				FROM	bettrans b WITH (NOLOCK)
					INNER JOIN #BetmDelete r ON b.refno = r.refno
				WHERE b.matchid = 29 AND b.bettype = 29
				GROUP BY b.CustID		

		--Settlement System parlay (changed balance)
			EXEC dbo.Admin_Calculate_29 @matchids = @match_tmp, @matchdate = @matchdate

		--Get data after update
				INSERT INTO #AfterUpd (custid, balance)
				SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
				FROM	bettrans b WITH (NOLOCK)
					INNER JOIN #BetmDelete r ON b.refno = r.refno
				WHERE b.matchid = 29 AND b.bettype = 29
				GROUP BY b.CustID

			---insert data into pending balance table 
				INSERT INTO BalancePendingCredit (custid,Balance)
				SELECT		a.custid, (a.balance - b.balance) as Balance
				FROM		#BeforeUpd b
				INNER JOIN	#AfterUpd a 	
						ON	a.custid = b.custid
				WHERE	    (a.balance - b.balance) > 0

				INSERT INTO BalancePendingDebit (custid,Balance)
				SELECT		a.custid, ABS(a.balance - b.balance) as Balance
				FROM		#BeforeUpd b
				INNER JOIN	#AfterUpd a 	
						ON	a.custid = b.custid
				WHERE	    (a.balance - b.balance) < 0
				
		---********* End of calculate balance for system parlay********---

		END
		 			
	END
	
	SELECT @LogData ='delete bet for matchid ' + CONVERT(VARCHAR(20), @matchid) + ' because of early kick off at '+CONVERT(varchar(23),@KickOffDate,121) + ' IP=' + COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))
	EXEC WriteLog_UserLog_T @UserID = @UserID, @Doing = @LogData

	


---------BEGIN : Send mail  

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
				b.transid AS SubTransID,
				b.refno,
				b.custid,  
				b.username, 
				b.odds,  
				b.modds,       
				b.OddsType,    
				b.transdate,  
				b.bettype,  
				b.betteam,  
				b.hdp1,  
				b.hdp2,  
				b.livehomescore,  
				b.liveawayscore, 	
				b.Actual_stake,
				b.stake,  
				b.CurrencyName,   
				d.status,					 
				m.HomeId, 
				m.AwayId, 
				m.SportType,
				m.LeagueId , 
				b.bettype as parlaytype,
				0 as IsMP
			FROM bettrans b WITH (NOLOCK)
			INNER JOIN #BetDelete d WITH (NOLOCK)
				ON b.transID = d.transID
			INNER JOIN Match m WITH (NOLOCK) 
				ON b.MatchId = m.MatchId
			WHERE  m.matchID = @matchID

			UNION ALL 							
									
			SELECT
				b.transid,
				bm.transid AS SubTransID,			
				bm.refno,
				bm.custid,    
				b.username,
				bm.odds,     
				b.modds,    
				b.OddsType,    
				bm.transdate,  
				bm.bettype,  
				bm.betteam,  
				bm.hdp1,  
				bm.hdp2,  
				bm.livehomescore,  
				bm.liveawayscore,    
				b.Actual_stake,
				b.stake,
				b.currencyName, 		
				d.status,	
				m.HomeId, 
				m.AwayId, 
				m.SportType,
				m.LeagueId,  		
				b.bettype as parlaytype,
				1 as IsMP
			FROM bettrans b WITH (NOLOCK)
			INNER JOIN BettransM bm WITH (NOLOCK)
				ON bm.Refno = b.refno
			INNER JOIN #BetmDelete d WITH (NOLOCK)
				ON b.refno = d.refno
			INNER JOIN Match m WITH (NOLOCK) 
				ON bm.MatchId = m.MatchId
			WHERE  m.matchID = @matchID
			ORDER BY b.transid

		-----Get username having negative balance 
		SELECT	SUM(b.Winlost - B.actual_stake + B.PlayerComm) as Balance, B.Username, B.CurrencyName
		FROM	Bettrans B
		WHERE	B.CustID  IN (SELECT DISTINCT CustID FROM #BetDelete)
		GROUP BY  B.Username, B.CurrencyName
		HAVING SUM(b.Winlost - B.actual_stake + B.PlayerComm) < 0

		UNION ALL
		
		SELECT	SUM(b.Winlost - B.actual_stake + B.PlayerComm) as Balance, B.Username, B.CurrencyName
		FROM	Bettrans B 
		WHERE	B.CustID  IN (SELECT DISTINCT CustID FROM #BetmDelete)
		GROUP BY  B.Username, B.CurrencyName
		HAVING SUM(b.Winlost - B.actual_stake + B.PlayerComm) < 0						

--------END : Send mail  
			
	
	----BEGIN: List data to put Message
	SELECT  B.TransId, A.AgentID as TargetID, I.Username as TargetName, 1 as IsAgent
	FROM	#BetDelete B
	INNER JOIN Bettrans_Agent A WITH (NOLOCK)
			ON A.TransID = B.TransID
	INNER JOIN AgentInfo I WITH (NOLOCK)
			ON I.AgentId = A.AgentId
	UNION ALL
	SELECT  B.TransId, B.CustId as TargetID, B.Username as TargetName, 0 as IsAgent
	FROM	#BetDelete B
	
	-- Parlay
	UNION ALL 
	SELECT  B.TransId, A.AgentID as TargetID, I.Username as TargetName, 1 as IsAgent
	FROM	#BetmDelete B
	INNER JOIN Bettrans_Agent A WITH (NOLOCK)
			ON A.RefNo = B.RefNo
	INNER JOIN AgentInfo I WITH (NOLOCK)
			ON I.AgentId = A.AgentId
	UNION ALL 
	SELECT  B.TransId, B.CustId as TargetID, B.Username as TargetName, 0 as IsAgent
	FROM	#BetmDelete B

	----END : List data to put Message

					
	DROP TABLE #BetDelete	
	DROP TABLE #BetmDelete 
	
	DROP TABLE #BeforeUpd
	DROP TABLE #AfterUpd
		
	-----Release data of TempVariableNumber table
	IF @isParlay IN (0,2)
	BEGIN 
		DELETE FROM dbo.TempVariableNumber WITH (ROWLOCK,UPDLOCK)
		WHERE KeyID = 1 AND KeyValue = @matchid	
		IF (@@Error = 0)
			BEGIN TRY
				EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking
					@UserID = @UserID, 
					@Matchid = @matchid, 
					@KeyID = 1,
					@ActionID = 0, 
					@Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecialDel_EarlyKO'
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransDelSpecialDel_EarlyKO ErrMsg=' + left(error_message(), 400)
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
						@Remark = 'DEL FAILED SPName=Acc_BettransDelSpecialDel_EarlyKO'
				END TRY
				BEGIN CATCH
					SELECT @Remark = 'DEL FAILED SPName=Acc_BettransDelSpecialDel_EarlyKO ErrMsg=' + left(error_message(), 400)
					EXEC LogDB.dbo.WriteLog_Settlement_Checking
						@UserID = @UserID, 
						@Matchid = @matchid, 
						@KeyID = 1,
						@ActionID = 0, 
						@Remark = @Remark
				END CATCH
			END
	END 
	
	-----Release data of SystemSettings table
	IF @isParlay IN (1,2)
	BEGIN 	
		UPDATE	SystemSettings WITH (ROWLOCK, UPDLOCK)
		SET		VValue = '0'
		WHERE	VName = 'isCalculatingParlay'
	END	
	
SET NOCOUNT OFF
END
 
GO
GRANT EXECUTE ON [dbo].[Acc_BettransDelSpecialDel_EarlyKO] TO [aplweb]
GO