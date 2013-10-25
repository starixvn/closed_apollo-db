ALTER PROCEDURE [dbo].[Acc_BettransDelBet]
    @transids VARCHAR(4000) = '',
	@IsDeleteAll BIT = 0,	
    @UserPwd NVARCHAR(50),
    @UserID INT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT,
    @ErrCode INT = 0 OUTPUT
AS

/*
Created by: Sophia
Date: 20130926
Task : delete single bet by TransID (from Betlist)
DB: SVRTXN.TransDB
Original: 

Revisions:     

		    
Param's Explanation: Special bet delete option   

	- @IsDeleteAll:
	 + 0: can only delete the unsettled or refunded tickets
	 + 1: can delete all type of status 
*/

SET NOCOUNT ON	
	
	DECLARE @LogData NVARCHAR(MAX)
	DECLARE @Remark NVARCHAR(MAX)
	SELECT @ErrCode = 0

----------Check permission for Delete all 
	DECLARE @FunctionId smallint, @FunctionKey NVARCHAR(50)

	IF @IsDeleteAll = 1
		SET @FunctionKey = 'VoidByBetIdAll'
	ELSE	
		SET @FunctionKey = 'VoidByBetId'
		
	SELECT	@FunctionId = FunctionId
	FROM	SVRNAP.bodb_NAP.dbo.Functions WITH (NOLOCK)
	WHERE	FunctionKey = @FunctionKey

	EXEC SVRNAP.bodb_NAP.dbo.NAP_User_CheckPermission @UserId=@UserID,@FunctionId=@FunctionId,@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
 
---------end check permission for Delete all 

	IF NOT EXISTS ( SELECT 1
					FROM	SVRCUST.CustDB.dbo.AdminInfo WITH (NOLOCK)
					WHERE   UserPwd = @UserPwd
							and AdminId = @UserID)
	BEGIN
		SELECT @LogData ='Fail to delete bet by IDs: '+ @transids
		EXEC WriteLog_UserLog_T @UserID = @UserID, @Doing = @LogData

		SELECT @ErrMsg = 'Sorry. You can not process delete bet due to either wrong password or insufficient permission!',
			   @ErrCode = 101   
		RETURN
	END
	
------------------***** Insert all data into #BetDelete *****------------------
	CREATE TABLE #BetDelete (transid BIGINT, CustId INT, PlayerName nvarchar(50), Status Varchar(10), winlost MONEY, KeyValue INT, KeyID INT )
	    	 
	INSERT INTO #BetDelete (transid, CustId, PlayerName, Status, winlost , KeyValue, KeyID)   
	SELECT	transid, CustId, Username, Status, winlost, MatchID as KeyValue, CASE WHEN Bettype = 10 THEN 2 ELSE 1 END AS KeyID
	FROM	bettrans b WITH (NOLOCK)		
	WHERE   TransID IN (SELECT CONVERT(BIGINT, val) FROM dbo.strSplit(@transids, ','))    	 

------------------***** End of insert all data into #BetDelete *****------------------		


---- check and not allow attempt to delete same game while it's still not finish
	 
		IF EXISTS (	SELECT 1	FROM TempVariableNumber T WITH (NOLOCK)
					INNER JOIN	#BetDelete B 
							ON	B.KeyValue = T.KeyValue AND B.KeyID = T.KeyID 
					)
		BEGIN
			SELECT  @ErrCode = 101,
					@ErrMsg = 'Some matches are being calculated or some tickets of these matches are being deleted, please wait a few seconds until the on-going process is completed and try again.'
			RETURN
		END

		INSERT	INTO TempVariableNumber (KeyID, KeyValue) 
		SELECT	DISTINCT KeyID, KeyValue
		FROM	#BetDelete

		IF (@@Error = 0)
		BEGIN TRY	
			SELECT @Remark = 'ADD SUCCESS SPName=Acc_BettransDelBet'		
			INSERT INTO SVRLOG.LogDB.dbo.Settlement_Checking
				(	UserID,
					MatchID,
					KeyID,
					ActionID,	
					Remark
				) 
			SELECT	DISTINCT 
					@UserID, 
					KeyValue, 
					KeyID, 
					0, 
					@Remark
			FROM	#BetDelete 
		END TRY
		BEGIN CATCH
			SELECT @Remark = 'ADD SUCCESS SPName=Acc_BettransDelBet ErrMsg=' + left(error_message(), 400)
				
			INSERT INTO LogDB.dbo.Settlement_Checking
				(	UserID,
					MatchID,
					KeyID,
					ActionID,	
					Remark
				) 
			SELECT	DISTINCT 
					@UserID, 
					KeyValue, 
					KeyID, 
					0, 
					@Remark
			FROM	#BetDelete 

		END CATCH
		ELSE 
		BEGIN
			SELECT @ErrCode = 100, @ErrMsg = 'Some matches are being calculated or some tickets of these matches are being deleted, please wait a few seconds until the on-going process is completed and try again.'
			RETURN
		END 
		-------

		

------------------***** Begin Delete *****------------------
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

------------------***** End of Delete *****------------------

	SELECT @LogData ='Delete bet by IDs: '+ @TransIDs
	EXEC WriteLog_UserLog_T @UserID = @UserID, @Doing = @LogData


	------after delete, return all deleted with additional information for mailing 
	  
		SELECT
			b.transid,
			b.CustId,
			b.username,
			b.Creator,
			b.odds,   
			b.OddsType,  
			b.transdate,
			b.bettype,
			betteam,
			hdp1,
			hdp2,
			b.Liveindicator,
			b.livehomescore,
			b.liveawayscore,
			stake as Stake,
			b.CurrencyName, 
			D.status,
			ISNULL(SecAcceptFlag,0) SecAcceptFlag,
			m.HomeId, 
			m.AwayId, 			
			m.SportType,
			m.LeagueId,
			d.Winlost
		FROM bettrans b WITH (NOLOCK)	
		INNER JOIN #BetDelete D
				ON 	D.transid = b.TransID
		INNER JOIN match m WITH (NOLOCK)
				ON M.MatchID = B.MatchID
		 
		UNION ALL
		SELECT
			b.transid,
			b.CustId,
			b.username,
			b.Creator,
			b.odds,   
			b.OddsType,  
			b.transdate,
			b.bettype,
			betteam,
			hdp1,
			hdp2,
			b.Liveindicator,
			b.livehomescore,
			b.liveawayscore,
			stake as Stake,
			b.CurrencyName, 
			D.status,
			ISNULL(SecAcceptFlag,0) SecAcceptFlag,
			m.TeamId as HomeId, 
			0 as AwayId, 			
			l.SportType,
			m.LeagueId,
			d.Winlost
		FROM bettrans b WITH (NOLOCK)		
		INNER JOIN #BetDelete D	ON 	D.transid = b.TransID	
		INNER JOIN outright m WITH(NOLOCK) ON b.matchid = m.orid
		INNER JOIN league l WITH (NOLOCK) On l.leagueId = m.leagueid


		 	

		-----Get username having negative balance
		SELECT	SUM(b.Winlost - B.actual_stake + B.PlayerComm) as Balance, B.Username
		FROM	Bettrans B 
		INNER JOIN #BetDelete D ON B.TransID = D.TransID
		GROUP BY  B.Username
		HAVING SUM(b.Winlost - B.actual_stake + B.PlayerComm) < 0
		 
	-----End : Send mail when delete tickets 

	 
	---- List data to put Message
	SELECT  B.TransId, B.KeyValue as MatchId, CASE WHEN B.KeyID = 2 THEN 1 ELSE 0 END IsOutright, A.AgentID as TargetID, I.Username as TargetName, 1 as IsAgent
	FROM	#BetDelete B
	INNER JOIN Bettrans_Agent A WITH (NOLOCK)
			ON A.TransID = B.TransID
	INNER JOIN AgentInfo I WITH (NOLOCK)
			ON I.AgentId = A.AgentId
	UNION ALL
	SELECT  B.TransId, B.KeyValue as MatchId, CASE WHEN B.KeyID = 2 THEN 1 ELSE 0 END IsOutright, B.CustId as TargetID,B.PlayerName as TargetName, 0 as IsAgent
	FROM	#BetDelete B

	 
	--------------
	DELETE	T WITH (ROWLOCK,UPDLOCK)
	FROM	TempVariableNumber T
	INNER JOIN #BetDelete B 
			ON T.KeyID = B.KeyID AND T.KeyValue = B.KeyValue
				
			
	IF (@@Error = 0)
		BEGIN TRY
			SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransDelBet'
			INSERT INTO SVRLOG.LogDB.dbo.Settlement_Checking
				(	UserID,
					MatchID,
					KeyID,
					ActionID,	
					Remark
				) 
			SELECT	DISTINCT 
					@UserID, 
					KeyValue, 
					KeyID, 
					0, 
					@Remark
			FROM	#BetDelete 

		END TRY
		BEGIN CATCH
			SELECT @Remark = 'DEL SUCCESS SPName=Acc_BettransDelBet ErrMsg=' + left(error_message(), 400)
			INSERT INTO LogDB.dbo.Settlement_Checking
				(	UserID,
					MatchID,
					KeyID,
					ActionID,	
					Remark
				) 
			SELECT	DISTINCT 
					@UserID, 
					KeyValue, 
					KeyID, 
					0, 
					@Remark
			FROM	#BetDelete 
		END CATCH
		ELSE
		BEGIN
			BEGIN TRY				
				SELECT  @Remark = 'DEL FAILED SPName=Acc_BettransDelBet'
				INSERT INTO SVRLOG.LogDB.dbo.Settlement_Checking
					(	UserID,
						MatchID,
						KeyID,
						ActionID,	
						Remark
					) 
				SELECT	DISTINCT 
						@UserID, 
						KeyValue, 
						KeyID, 
						0, 
						@Remark
				FROM	#BetDelete 
			END TRY
			BEGIN CATCH
				SELECT @Remark = 'DEL FAILED SPName=Acc_BettransDelBet ErrMsg=' + left(error_message(), 400)
					INSERT INTO LogDB.dbo.Settlement_Checking
						(	UserID,
							MatchID,
							KeyID,
							ActionID,	
							Remark
						) 
					SELECT	DISTINCT 
							@UserID, 
							KeyValue, 
							KeyID, 
							0, 
							@Remark
					FROM	#BetDelete 
			END CATCH
		END

	DROP TABLE #BetDelete
	
	DROP TABLE #BeforeUpd
	DROP TABLE #AfterUpd
	 
	 
GO
GRANT EXECUTE ON [dbo].[Acc_BettransDelBet] TO [aplweb] 
