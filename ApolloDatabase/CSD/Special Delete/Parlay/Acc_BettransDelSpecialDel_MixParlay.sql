ALTER PROCEDURE [dbo].[Acc_BettransDelSpecialDel_MixParlay]
	@MatchID int,
	@Type smallint = 0, 	
    @livehomescore smallint = NULL,
    @liveawayscore smallint = NULL, 	
    @FromTransdate Datetime = NULL,
	@ToTransdate Datetime = NULL,
	@hdp smallmoney = 9999,	
	@bettypes varchar(128) = '',	
	@betteam1378 varchar(10) = 'ALL',
	@betteam515 varchar(10) = 'ALL',
	@betteam430 varchar(120) = '',
	@betteam6 varchar(120) = '',
	@betteam14 varchar(120) = '',
	@betteam16 varchar(120) = '',
	@Language NVARCHAR(2) = 'E',
	@transids varchar(4000)='',
    @UserID INT,
    @UserName NVARCHAR(50),
    @UserPwd NVARCHAR(50),
    @IP VARCHAR(15) = '',
    @ErrMsg NVARCHAR(200) = '' OUTPUT,
    @ErrCode INT = 0 OUTPUT	
AS
/*
	Created by: Sophia	
	Date: 20130307
	Task: Delete transaction of mix parlay bet in bettransm
	DB: SVRTXN.TransDB
	Original: 
	
	Revisions:
	 - 20130729@Sophia: Get Username of Agent from AgentInfo table to put Message

	Param's Explanation: 
	
	
*/
BEGIN	
	SET NOCOUNT ON
	DECLARE @LogData NVARCHAR(500)
	SELECT @ErrCode = 0

	
	IF NOT EXISTS (SELECT 1
					FROM	SVRCUST.CustDB.dbo.AdminInfo WITH (NOLOCK)
					WHERE   UserPwd = @UserPwd
							and AdminId = @UserID)
	BEGIN
		SELECT @LogData ='Fail to delete bet for matchid ' + CONVERT(VARCHAR(20), @matchid) + ' for Mix Parlay Special Delete'
		EXEC WriteLog_UserLog_T @UserID = @UserID, @Doing = @LogData

		SELECT @ErrMsg = 'Sorry. You can not process delete bet due to either wrong password or insufficient permission!', @ErrCode = 101   
		RETURN
	END
			
	IF EXISTS(	SELECT 1 FROM dbo.match m WITH(NOLOCK)
				WHERE m.matchid=@matchid AND m.eventstatus='completed')
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'You can not delete completed match.'
		RETURN
	END
	
		
---- Check for concurrent running
	IF EXISTS(SELECT 1 FROM SystemSettings WITH (NOLOCK) WHERE VValue = 1 AND VName = 'isCalculatingParlay')
	BEGIN
		SELECT @ErrCode = 102
		SELECT @ErrMsg = 'Another parlay settlement is in progress or some parlay tickets are being deleted, please wait a few seconds until the on-going process has finished and try again.'
		RETURN
	END
	ELSE 
	BEGIN
		UPDATE	systemSettings WITH (ROWLOCK, UPDLOCK)
		SET		VValue = '1'
		WHERE	VName = 'isCalculatingParlay'
	END

-----------	
									
	CREATE TABLE #Ref (--id int identity(1,1) primary key clustered 
						refno bigint 
						,transid int	
						,CustId int	
						,betfrom nvarchar(1)
						,bettype smallint						
						,hdp1 smallmoney
						,hdp2 smallmoney
						,odds smallmoney
						,betteam nvarchar(20)
						,livehomescore smallint
						,liveawayscore smallint
						,liveindicator bit						
						,org_betteam nvarchar(10)	
						,statusID int						
					)
	--CREATE TABLE #Currency (Refno bigint, CurrencyID tinyint,oddstype tinyint)
 

------------------***** Insert all data into #Ref *****------------------

	INSERT INTO #Ref (
						refno
						,transid
						,CustId							
						,betfrom
						,bettype
						,hdp1
						,hdp2
						,odds
						,betteam
						,livehomescore
						,liveawayscore
						,liveindicator
						,org_betteam
						,statusID
				)
	SELECT b.refno
		,b.transid
		,b.CustId
		,b.betfrom
		,b.bettype
		,b.hdp1
		,b.hdp2
		,b.odds
		,b.betteam		
		,b.livehomescore
		,b.liveawayscore
		,b.liveindicator
		,b.betteam		
		,b.statusID
	FROM dbo.bettransm AS b WITH(NOLOCK)	
	WHERE b.matchid=@MatchID	
		AND CASE WHEN @Type = 2 THEN @Type ELSE b.liveindicator END = @Type
		AND b.livehomescore = CASE WHEN @livehomescore IS NOT NULL AND @Type = 1 THEN @livehomescore ELSE b.livehomescore END
		AND b.liveawayscore = CASE WHEN @liveawayscore IS NOT NULL AND @Type = 1 THEN @liveawayscore ELSE b.liveawayscore END	
		AND b.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @Type = 1 THEN @FromTransdate ELSE b.transdate END 
						AND		CASE WHEN @ToTransdate IS NOT NULL AND @Type = 1 THEN @ToTransdate ELSE b.transdate END 


	CREATE CLUSTERED INDEX cl_Ref_refno ON #Ref(refno)
	CREATE NONCLUSTERED INDEX nl_Ref_StatusID ON #Ref(StatusID)
	CREATE NONCLUSTERED INDEX nl_Ref_bettype_org_betteam ON #Ref(bettype,org_betteam)
	
	
	--REMOVE REDUNDANT item
	DELETE #Ref
	WHERE statusID NOT IN (0,1,103)
	
	DELETE r
	FROM #Ref AS r 
		LEFT JOIN dbo.strSplit(@bettypes,'^') AS bt ON bt.val=r.bettype
	WHERE bt.val IS NULL -- remove unselected bettypes
		
	IF @betteam1378<>'All'
		DELETE r
		FROM #Ref AS r 
			INNER JOIN dbo.strSplit(@bettypes,'^') AS bt ON bt.val=r.bettype
		WHERE r.bettype IN (1,3,7,8,2,12) AND (r.org_betteam<>@betteam1378)
	
	IF @betteam515<>'All'
		DELETE r
		FROM #Ref AS r 
			INNER JOIN dbo.strSplit(@bettypes,'^') AS bt ON bt.val=r.bettype
		WHERE r.bettype in (5,15) AND (r.org_betteam<>@betteam515)
	
	IF @hdp <> 9999
		DELETE r
		FROM #Ref AS r 
			INNER JOIN dbo.strSplit(@bettypes,'^') AS bt ON bt.val=r.bettype
		WHERE r.bettype IN (1,3,7,8) AND (hdp1<>@hdp-hdp2)			
		
	IF @betteam430=''	
		DELETE #Ref
		WHERE bettype IN (4,30) 
	ELSE IF @betteam430<> 'All'
		DELETE r
		FROM #Ref AS r
			LEFT JOIN dbo.strSplit(@betteam430,'^') AS b4 ON b4.val=r.org_betteam		
		WHERE (r.bettype IN (4,30) AND (b4.val IS NULL))			
	
	IF @betteam6=''
		DELETE #Ref
		WHERE bettype=6
	ELSE IF @betteam6<>'All'	
		DELETE r
		FROM #Ref AS r 	
			LEFT JOIN dbo.strSplit(@betteam6,'^') AS b6 ON b6.val=r.org_betteam		
		WHERE r.bettype=6 AND (b6.val IS NULL)
	
	IF @betteam14=''
		DELETE #Ref
		WHERE bettype=14
	ELSE IF @betteam14<>'All'	
		DELETE r
		FROM #Ref AS r 	
			LEFT JOIN dbo.strSplit(@betteam14,'^') AS b14 ON b14.val=r.org_betteam		
		WHERE r.bettype=14 AND (b14.val IS NULL)
	
	IF @betteam16=''
		DELETE #Ref
		WHERE bettype=16
	ELSE IF @betteam16<>'All'	
		DELETE r
		FROM #Ref AS r 	
			LEFT JOIN dbo.strSplit(@betteam16,'^') AS b16 ON b16.val=r.org_betteam		
		WHERE r.bettype=16 AND (b16.val IS NULL)
	
	CREATE NONCLUSTERED INDEX nl_Ref_custid_transid ON #Ref(CustId,transid)
--FOR DELETE SECTION
	
	
	
----------------------------------------------------------------------------------------------
------------------***** Insert Custid of each type into its temp table *****------------------	

	 

	----INSERT UUS  CUSTOMER
	--Insert into @UUSCust(custid,username)
	--SELECT		C.custid, C.username 
	--FROM		custinfo C WITH (nolock) 
	--INNER JOIN	#REF R 
	--		ON	C.custid = R.custid
	--WHERE C.srecommend in (
	--	SELECT custid FROM customer (nolock) Where CURRENCY = 20 and roleid = 4
	--) and C.roleid = 1
	
	
	----INSERT CUSTOMER HAVE REAL CURRENCIES AND CREATE USERNAME LIKE 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'		
	--INSERT INTO @RealCurrCust (CustID, username)
	--SELECT		INF.custid, INF.username 
	--FROM		custinfo INF WITH (NOLOCK) 
	--INNER JOIN	#REF BD ON INF.Custid = BD.Custid 
	--WHERE		INF.srecommend IN( SELECT custid FROM customer WITH(NOLOCK) Where CURRENCY <> 20 AND roleid = 4)	
	--			AND INF.roleid = 1 
	--			AND ( @Username LIKE 'dba%' OR @Username LIKE 'pgm%' OR @Username ='vndbateam' OR @Username = 'vnQaTeam')			
			
			 

------------------***** End of insert Custid of each type into its temp table  *****------------------		

------------------***** Remove data no need to special delete out of #Ref *****------------------	
	
	--DELETE NORMAL TICKETS
	 IF @transids<>''
		DELETE FROM r
		FROM #Ref AS r WITH(NOLOCK)		
			LEFT JOIN dbo.strSplit(@transids, ',') AS t ON t.val=r.transid
		WHERE  t.val IS NULL--not in
			
	 
------------------***** End of Remove data no need to special delete out of #BetDelete  *****------------------

------------------***** Begin Special Delete *****------------------
	
	-- BackUp bettransm tickets into zzzbettrans

	INSERT INTO	zzzbettrans
		(transid, CustId, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
	SELECT
		b.transid, b.CustId, CURRENT_TIMESTAMP, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, b.status, b.winlost, b.livehomescore, b.liveawayscore, b.liveindicator, b.betteam, b.creator , b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.matchid, b.bettype
	FROM dbo.bettransm AS b WITH (nolock)
		INNER JOIN #Ref AS r WITH(NOLOCK) ON r.transid=b.transid --AND r.refno=b.refno AND b.matchid = @matchid			

	--BackUp tickets of bettransm
	INSERT INTO	zzzbettransm
		(transid, custid, transdate, oddsid, hdp1, hdp2, odds, stake, status, winlost, livehomescore, liveawayscore, liveindicator, betteam, creator , refno, winlostdate, betfrom, betcheck, checktime, matchid, bettype)
	SELECT
		b.transid, b.custid, CURRENT_TIMESTAMP, b.oddsid, b.hdp1, b.hdp2, b.odds, b.stake, b.status, b.winlost, b.livehomescore, b.liveawayscore, b.liveindicator, b.betteam, b.creator , b.refno, b.winlostdate, b.betfrom, b.betcheck, b.checktime, b.matchid, b.bettype
	FROM dbo.bettransm AS b WITH (nolock)
		INNER JOIN #Ref AS r WITH(NOLOCK) ON r.transid=b.transid --AND r.refno=b.refno AND b.matchid = @matchid			

	declare @matchdate datetime, @match_tmp varchar(20), @rowcount INT, @step INT, @transid_tmp VARCHAR(2000)

	select	@matchdate = eventdate,
			@match_tmp = CONVERT(VARCHAR(20),matchid),
			@step = 0
	from match with(nolock) where matchid = @matchid
		
		
	--- void selection
	DECLARE @transtbl TABLE (id INT IDENTITY, transid BIGINT)
	INSERT INTO @transtbl (transid)
				SELECT transid
				FROM #Ref
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


	---********* Calculate balance at bettrans table********---
	CREATE TABLE #BeforeUpd (
				custid		 INT,
				balance		 MONEY)
					
	CREATE TABLE #AfterUpd(
					custid		 INT,
					balance		 MONEY)


	IF EXISTS (	SELECT TOP 1 1
				FROM bettrans b WITH(NOLOCK) 
					INNER JOIN #Ref r ON b.refno = r.refno
				WHERE b.matchid = 29 AND b.bettype = 29
			   ) 
	BEGIN
		EXEC dbo.Admin_Calculate_29_PreCal @matchids = @match_tmp
								
		--Get data before update
		INSERT INTO #BeforeUpd (custid, balance)
		SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
		FROM	bettrans b WITH (NOLOCK)
			INNER JOIN #Ref r ON b.refno = r.refno
		WHERE b.matchid = 29 AND b.bettype = 29
		GROUP BY b.CustID		

		EXEC dbo.Admin_Calculate_29 @matchids = @match_tmp, @matchdate = @matchdate		
		 

	--Get data after update
		INSERT INTO #AfterUpd (custid, balance)
		SELECT	b.custid, SUM (b.winlost - b.actual_stake + b.playercomm) balance
		FROM	bettrans b WITH (NOLOCK)
			INNER JOIN #Ref r ON b.refno = r.refno
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
			
		DELETE #BeforeUpd
		DELETE #AfterUpd
	---********* End of calculate balance at bettrans table********---

	END


	SELECT @LogData ='delete bet for matchid ' + CONVERT(VARCHAR(20), @matchid) + ' for Mix Parlay Special Delete' + ' IP=' + COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))
	EXEC WriteLog_UserLog_T @UserID = @UserID, @Doing = @LogData
	
	

	
	----after delete, return all deleted tickets with additional information for mailing
	--IF EXISTS (SELECT 1 FROM #Ref WITH(NOLOCK))
	--BEGIN		
	--	IF EXISTS(SELECT 1 FROM dbo.strSplit(@bettypes,'^') WHERE CONVERT(INT, val) = 10)  --@bettype = 10
	--	BEGIN
	--		SELECT
	--			MATCH.teamid AS homeid,
	--			0 AS awayid,
	--			MATCH.matchcode,
	--			MATCH.eventdate,
	--			MATCH.leagueid,
	--			GETDATE() AS DATETIME,
	--			CONVERT(BIT,0) AS IsNeutral
	--		FROM
	--			Outright AS MATCH WITH (NOLOCK)
	--		WHERE 
	--			MATCH.orid = @matchID
	--	END   
	--	ELSE
	--	BEGIN
	--		SELECT
	--			MATCH.homeid,
	--			MATCH.awayid,
	--			MATCH.matchcode,
	--			MATCH.eventdate,
	--			MATCH.leagueid,
	--			GETDATE() AS DATETIME,
	--			isnull(MATCH.isNeutral, CONVERT(BIT,0)) AS IsNeutral
	--		FROM
	--			MATCH WITH (NOLOCK)
	--		WHERE 
	--			MATCH.matchid = @matchID
	--	END
		
	--	SELECT
	--		b.transid,
	--		r.transid AS SubTransID,
	--		r.refno,
	--		b.username,
	--		b.custid,
	--		b.transdate,			
	--		cr.username as creator,	
	--		b.stake as StakePositiontaking,
	--		b.winlost-b.actual_stake AS winlost,
	--		b.odds,   
	--		b.OddsType, 	
	--		b.bettype,
	--		b.status,
	--		b.spositiontaking,
	--		b.mpositiontaking,
	--		b.apositiontaking,				
	--		b.currency,			
	--		b.mrecommend,			
	--		--case when betfrom IN ('D', 'M', 'E') then 1 else 0 end as IsDeposit
	--		r.bettype AS choice_bettype
	--		,m.homeid
	--		,m.awayid
	--		,r.hdp1 AS choice_hdp1
	--		,r.hdp2 AS choice_hdp2
	--		,r.odds AS choice_odds
	--		,r.betteam
	--		,r.livehomescore
	--		,r.liveawayscore
	--		,r.liveindicator
	--		,m.leagueid
	--		,m.sporttype
	--		,m.isNeutral
	--		,m.matchID
	--		,m.matchCode
	--		,ag.site
	--FROM dbo.bettrans AS b with (NOLOCK)
	--	INNER JOIN #Ref AS r WITH(NOLOCK) ON b.refno=r.refno AND b.matchid IN (9,29) AND b.bettype IN (9,29)
	--	INNER JOIN dbo.match AS m WITH(NOLOCK) ON m.matchid=@MatchID
	--	--INNER JOIN dbo.customer AS ag with (NOLOCK) ON b.recommend = ag.custid
	--	INNER JOIN dbo.customer AS cr with (NOLOCK) ON cr.custid = b.creator
	--	INNER JOIN dbo.customer ag WITH (NOLOCK) ON ag.custid=b.recommend	
	--WHERE	(b.betid = 0 OR b.betid IS NULL)			
	--ORDER BY b.transid
	
	--END	
	
	

	
-------BEGIN : Send mail when delete real currencies and creator username like 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam' / OR Currency is UUS
--		SELECT
--			b.transid,
--			r.transid AS SubTransID,
--			r.refno,
--			b.username,
--			b.custid,
--			b.transdate,			
--			cr.username as creator,	
--			b.stake as StakePositiontaking,
--			b.winlost-b.actual_stake AS winlost,
--			b.odds,   
--			b.OddsType, 
--			b.bettype,			
--			b.status,
--			b.spositiontaking,
--			b.mpositiontaking,
--			b.apositiontaking,				
--			b.currency,			
--			b.mrecommend,			
--			--case when betfrom IN ('D', 'M', 'E') then 1 else 0 end as IsDeposit
--			r.bettype AS choice_bettype
--			,m.homeid
--			,m.awayid
--			,r.hdp1 AS choice_hdp1
--			,r.hdp2 AS choice_hdp2
--			,r.odds AS choice_odds
--			,r.betteam
--			,r.livehomescore
--			,r.liveawayscore
--			,r.liveindicator
--			,m.leagueid
--			,m.sporttype
--			,m.isNeutral
--			,m.matchID
--			,m.matchCode
--			,ag.site 
--			,1 as isInternalMail 
--	FROM dbo.bettrans AS b with (NOLOCK)
--		INNER JOIN #Ref AS r WITH(NOLOCK) ON b.refno=r.refno AND b.matchid IN (9,29) AND b.bettype IN (9,29)
--		INNER JOIN dbo.match AS m WITH(NOLOCK) ON m.matchid=@MatchID
--		INNER JOIN dbo.customer AS cr with (NOLOCK) ON cr.custid = b.creator
--		INNER JOIN dbo.customer ag WITH (NOLOCK) ON ag.custid=b.recommend	
--	WHERE	(b.betid = 0 OR b.betid IS NULL)
--			AND 
--				( b.custid IN (SELECT custid FROM @RealCurrCust)	
--				  OR b.custid IN (SELECT custid FROM @UUSCust)
--				 )	
--	ORDER BY b.transid
	
-------END : Send mail when delete real currencies and creator username like 'dba%' or 'pgm%' or 'vndbateam',  'VnQaTeam'/ OR Currency is UUS
	

		 
	---- List data to put Message
	SELECT  B.TransId, A.AgentID as TargetID, I.Username as TargetName, 1 as IsAgent
	FROM	#Ref B
	INNER JOIN Bettrans_Agent A WITH (NOLOCK)
			ON A.RefNo = B.RefNo
	INNER JOIN AgentInfo I WITH (NOLOCK)
			ON I.AgentId = A.AgentId
	UNION ALL
	SELECT  B.TransId, B.CustId as TargetID, C.Username as TargetName, 0 as IsAgent
	FROM	#Ref B
	INNER JOIN Bettrans C WITH (NOLOCK)
			ON C.RefNo = B.RefNo




	DROP TABLE #Ref	
	
	-----
	UPDATE	systemSettings WITH (ROWLOCK, UPDLOCK)
	SET		VValue = '0'
    WHERE	VName = 'isCalculatingParlay'	
			
	SET NOCOUNT OFF
END

GO
GRANT EXECUTE ON [dbo].[Acc_BettransDelSpecialDel_MixParlay] TO aplweb
GO
--GRANT VIEW DEFINITION ON [dbo].[Acc_BettransDelSpecialDel_MixParlay] TO [vnteam]
go
