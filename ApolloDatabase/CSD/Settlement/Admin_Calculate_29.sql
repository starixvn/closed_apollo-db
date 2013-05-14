ALTER PROCEDURE [dbo].[Admin_Calculate_29]
	@matchids	VARCHAR(2000),
	@matchdate	SMALLDATETIME
WITH RECOMPILE  
AS  
/*
	Created by: Dan
	Date: 2013-03-28
	Task : Settle bettrans based on bettransm (for mix parlay)
	DB: SVRTXN/TransDB
	Original: 

	Revisions:
		
	Param's Explanation:
		+ @matchid: matchid of match to be settled
		+ @matchdate match date
*/

IF @@SERVERNAME IN ('DB042', 'DB043', 'DB044') RETURN


	SET NOCOUNT ON
	Declare @commWinRate smallmoney, @commLostRate smallmoney

	-- GET list of concern Ticket  
	--DECLARE #temp_bettrans TABLE (
	CREATE TABLE  #temp_bettrans (
		transid BIGINT, 
		custid INT, 
		refno BIGINT PRIMARY KEY CLUSTERED,		
		playerdiscount DECIMAL(9,8),		
		[DoubleCommLosing] BIT NULL,
		UNIQUE (transid)
	)	

	;WITH refnos AS 
	(
		SELECT DISTINCT refno
		FROM dbo.BetParlayDetail pd WITH(rowlock)
		WHERE matchid IN (SELECT val FROM dbo.strSplit(@matchids, ','))
	)
	INSERT INTO #temp_bettrans (
		transid, custid, refno, playerdiscount,  [DoubleCommLosing]
	)
	SELECT
		transid, custid, b.refno, playerdiscount,  [DoubleCommLosing]
	FROM dbo.bettrans b WITH(ROWLOCK)  
		inner join refnos t ON b.refno = t.refno
	WHERE 
		b.matchid = 29 
		AND statusID NOT IN (101,102) -- exclude void/reject
		AND betid = 0 -- main ticket of combination

	IF (@@ROWCOUNT = 0)
		RETURN;
	
	-- Get list of ParlayResult
	--DECLARE #temp_parlayResult TABLE (
	create TABLE #temp_parlayResult  (
		refno BIGINT, serial INT, transid BIGINT, odds MONEY, modds MONEY,
		winlostdate SMALLDATETIME, stake MONEY, statusID TINYINT,
		winlost MONEY, playercomm MONEY, 
		--NoRefund TINYINT, runningCnt TINYINT,
		IsUpdated BIT, -- to stored value indicate if this row been change
		UNIQUE (refno, serial)
	)

	INSERT INTO #temp_parlayResult (
		refno, serial, transid, winlostdate, stake, statusID, odds, modds, winlost, playercomm)
	SELECT
		pr.refno, pr.serial, pr.transid, winlostdate, stake, statusID, 0,0,	pr.winlost,0
	FROM dbo.BetParlayResult pr WITH(ROWLOCK)
		INNER JOIN #temp_bettrans t ON pr.refno = t.refno

	-- get list of max(eventdate) - using for set winlostdate of running ticket
	DECLARE @refno_maxeventdate TABLE (refno BIGINT PRIMARY KEY CLUSTERED, eventdate SMALLDATETIME)
	INSERT INTO @refno_maxeventdate
	SELECT pd.refno, MAX(ISNULL(pd.winlostdate , '01 JAN 2000'))
	FROM dbo.BetParlayDetail pd WITH(ROWLOCK)
		INNER JOIN #temp_bettrans t ON pd.refno = t.refno
	GROUP BY pd.refno

	------------------------------------------------------------  
	DECLARE @statusID TINYINT, @odds MONEY, @DownlinePT smallmoney
	DECLARE @oldstatusID TINYINT, @oldwinlost MONEY, @winlost MONEY

	-- CALCULATE effective odds value
	Declare @EffectiveOdds TABLE 
		(refno bigint, serial int, eventdate SMALLDATETIME,
		odds money, modds money, NoRefund tinyint, loseCnt tinyint, runningCnt tinyint)

	INSERT INTO @EffectiveOdds (refno, serial, eventdate, odds, modds, NoRefund, loseCnt, runningCnt)
	SELECT pd.refno, pd.serial, rm.eventdate,
			EXP(SUM(LOG(odds))) AS Odds,
			EXP(SUM(LOG(
			CASE statuswinlost
				WHEN 0 THEN 1 -- draw
				WHEN 1 THEN 1+((odds-1)/2) -- half won
				WHEN 2 THEN odds -- won
				WHEN 3 THEN 0.5 -- half lose
				WHEN 4 THEN 0.000000000001 -- lose
				ELSE 1 -- void/reject
			END
			))) AS mOdds,
			--SUM(case when pd.statusID = 101			THEN 0 ELSE 1 END) as NoReject, 
			SUM(CASE WHEN pd.statusID IN (121, 103) THEN 0 ELSE 1 END) AS NoRefund,-- DONE, Refund
			SUM(CASE WHEN statuswinlost = 4			THEN 1 ELSE 0 END) AS loseCnt,
			SUM(CASE WHEN pd.statusID IN (0,1)		THEN 1 ELSE 0 END) AS runningCnt
			--MAX(pd.winlostdate) AS matchdate_max
	FROM dbo.BetParlayDetail pd WITH(ROWLOCK)
		INNER JOIN #temp_bettrans tb ON pd.refno = tb.refno
		INNER JOIN @refno_maxeventdate rm ON pd.refno = rm.refno
	GROUP BY pd.refno, pd.serial, rm.eventdate
			
	--get agent PT and comm setting for tickets
	SELECT ba.transid, ba.[AgentId], [AgentLevel], b.[DoubleCommLosing], 		
		APositionTaking, ADiscount, cast(0 as smallmoney) as DownlinePT, b.refno		
	INTO #temp_bettrans_Agent 
	FROM #temp_bettrans B WITH (NOLOCK) INNER JOIN BetTrans_Agent ba WITH (ROWLOCK) ON b.TransId=ba.TransId 
		INNER JOIN AgentInfo a WITH (NOLOCK) ON a.AgentID=ba.AgentID
	
	--create index		
	CREATE CLUSTERED INDEX IX_tmp on #temp_bettrans_Agent (transid,AgentLevel desc)		

	DECLARE @prevtransid BIGINT =0 
	
	-- calculate downline PT for each agent (so we can calculate commission later)
	UPDATE #temp_bettrans_Agent 
	SET 
		@DownlinePT=DownlinePT = case when @prevtransid <> transid 
						then APositionTaking
						else APositionTaking + @DownlinePT -- accumulated PT for upper agent --> for calculating agent commision
						end,
		@prevtransid = transid					
	OPTION (MAXDOP 1) --should use this for quirky update to avoid parallelism problem	

	-- get BetParlayResult_Agent
	SELECT ba.transid, ba.[AgentId], [AgentLevel], ba.[DoubleCommLosing], 
		APositionTaking, ADiscount, DownlinePT, 
		pra.[Stake], pra.AWinLost, cast(0 as money) as AComm ,		
		pra.StatusId, pra.RefNo,Serial,  pra.WinLostDate, cast(0 as bit) as IsUpdated 
	INTO #temp_parlayResult_Agent 
	FROM #temp_bettrans_Agent ba 
		INNER JOIN dbo.BetParlayResult_Agent pra WITH(ROWLOCK) ON pra.refno = ba.refno and pra.AgentId=ba.AgentId

	-- calculate result for agent in sub-tickets
	UPDATE PRA 
	SET		
		@oldstatusID = statusID,
		@oldwinlost = awinlost,

		@statusID = statusID = CASE
			WHEN loseCnt > 0 THEN 113 -- Lose
			WHEN m.runningCnt > 0 THEN 0 -- running
			WHEN m.NoRefund = 0 THEN 103 -- Refund
			WHEN m.modds < 1 THEN 113 -- Lose
			WHEN m.modds = 1 THEN 111 -- Draw
			WHEN m.modds > 1 THEN 112 -- Won
			ELSE -1 -- error ??
			END,
		winlostdate = CASE @statusID
			WHEN 0 THEN m.eventdate -- running : set winlostdate = maxeventdate
			ELSE @matchdate -- settled : set winlostdate = input @matchdate
			END,
		
		@odds = CASE
			WHEN loseCnt > 0 THEN 0
			WHEN @statusID = 0 THEN 0
			ELSE m.modds
			END,
				
		@commWinRate = CASE [DoubleCommLosing]  -- 0 : pay normal, both win/lost -- 1 : pay 'double' ONLY on lost
			WHEN 0 THEN 1
			WHEN 1 THEN 0 
			ELSE 1 END,   
		@commLostRate = CASE [DoubleCommLosing]
			WHEN 0 THEN 1
			WHEN 1 THEN 2 
			ELSE 1 END,--'s','m'		
		
		@winlost= awinlost = CASE 
			WHEN @statusID = 113 and loseCnt > 0  THEN  PRA.stake * apositiontaking
			WHEN @statusID IN (112, 113) THEN -PRA.stake * apositiontaking*(@odds-1)
			ELSE 0
			END,
				
		acomm = CASE @statusID
					WHEN 112 THEN @commWinRate  * PRA.stake * adiscount*(1-DownlinePT)
					WHEN 113 THEN @commLostRate * PRA.stake * adiscount*(1-DownlinePT)
					ELSE 0 END,							
		--NoRefund = m.NoRefund,
		--runningCnt = m.runningCnt,
		IsUpdated = CASE
			WHEN (@oldstatusID <> @statusID) OR (@oldwinlost <> @winlost) THEN 1
			ELSE 0 END
			
	FROM #temp_parlayResult_Agent PRA 
		INNER JOIN @EffectiveOdds m ON PRA.refno = m.refno AND PRA.serial = m.serial
		--INNER JOIN #temp_bettrans TB ON PRA.refno = TB.refno	

	-- calculate result for each sub-ticket
	UPDATE PR
	SET
		@oldstatusID = statusID,
		@oldwinlost = winlost,

		@statusID = statusID = CASE
			WHEN loseCnt > 0 THEN 113 -- Lose
			WHEN m.runningCnt > 0 THEN 0 -- running
			WHEN m.NoRefund = 0 THEN 103 -- Refund
			WHEN m.modds < 1 THEN 113 -- Lose
			WHEN m.modds = 1 THEN 111 -- Draw
			WHEN m.modds > 1 THEN 112 -- Won
			ELSE -1 -- error ??
			END,
		winlostdate = CASE @statusID
			WHEN 0 THEN m.eventdate -- running : set winlostdate = maxeventdate
			ELSE @matchdate -- settled : set winlostdate = input @matchdate
			END,
		Odds = m.Odds,
		@odds = PR.mOdds = CASE
			WHEN loseCnt > 0 THEN 0
			WHEN @statusID = 0 THEN 0
			ELSE m.modds
			END,
				
		@commWinRate = CASE [DoubleCommLosing]  -- 0 : pay normal, both win/lost -- 1 : pay 'double' ONLY on lost
			WHEN 0 THEN 1
			WHEN 1 THEN 0 
			ELSE 1 END,   
		@commLostRate = CASE [DoubleCommLosing]
			WHEN 0 THEN 1
			WHEN 1 THEN 2 
			ELSE 1 END,--'s','m'
		
		@winlost = winlost = CASE
			WHEN loseCnt > 0 THEN 0
			WHEN @statusID = 0 THEN 0
			ELSE PR.stake*@odds
			END,		

		playercomm	= CASE @statusID 
					WHEN 112 THEN @commWinRate  * PR.stake * playerdiscount
					WHEN 113 THEN @commLostRate * PR.stake * playerdiscount
					ELSE 0 END,							
		--NoRefund = m.NoRefund,
		--runningCnt = m.runningCnt,
		IsUpdated = CASE
			WHEN (@oldstatusID <> @statusID) OR (@oldwinlost <> @winlost) THEN 1
			ELSE 0 END

	FROM #temp_parlayResult PR
		INNER JOIN @EffectiveOdds m ON PR.refno = m.refno AND PR.serial = m.serial
		INNER JOIN #temp_bettrans TB ON PR.refno = TB.refno

	-- update temp_ParlayResult back to betParlayResult
	UPDATE PR
	SET winlostdate = t.winlostdate,
		statusid = t.statusid,
		Odds = t.Odds,
		mOdds = t.mOdds,
		winlost = t.winlost, 
		playercomm = t.playercomm 
	FROM dbo.BetParlayResult PR
		INNER JOIN #temp_parlayResult T ON PR.refno = T.refno AND PR.serial = T.serial
	WHERE IsUpdated = 1

	UPDATE PRA
	SET winlostdate = t.winlostdate,
		statusid = t.statusid,		
		awinlost = t.awinlost,
		acomm = t.acomm
	FROM dbo.BetParlayResult_Agent PRA
		INNER JOIN #temp_parlayResult_Agent T ON PRA.refno = T.refno AND PRA.serial = T.serial and PRA.AgentId = T.AgentId
	WHERE IsUpdated = 1

	--IF @@SERVERNAME <> N'DBTRANS' RETURN
	--IF @@SERVERNAME <> N'DB215\SQL2012' or db_name() <> N'TransDB' RETURN
	
	--	 below code is just for DBTRANS to process
	
	-- update ticket in bettrans
	;WITH PRS AS (
		SELECT
			t.transid, t.refno, MAX(winlostdate) winlostdate, SUM(stake) totalStake,
			SUM(odds) odds, SUM(modds) modds, SUM(CASE statusID WHEN 0 THEN stake ELSE 0 END) RunningStake, COUNT(*) TicketCount,
			SUM(winlost) winlost, --SUM(awinlost) awinlost, SUM(mwinlost) mwinlost, SUM(swinlost) swinlost,
			SUM(playercomm) playercomm, MAX(ag.TWinlost) TWinlost, MAX(ag.TComm) TComm
		FROM  			
			dbo.BetParlayResult pr WITH(NOLOCK)
				INNER JOIN #temp_bettrans t ON pr.refno = t.refno
				INNER JOIN (SELECT RefNo, sum(AWinLost) TWinlost, sum(case when AgentLevel=1 then AComm else 0 end) TComm
					FROM #temp_parlayResult_Agent 
					GROUP BY RefNo) as Ag ON AG.RefNo = t.refno
		GROUP BY
			t.transid, t.refno
	)	

	UPDATE B WITH(ROWLOCK,UPDLOCK)
	SET 
		winlostdate = prs.winlostdate,
		modds = prs.modds,
		actual_stake = prs.totalStake,		
		@statusID = statusID = CASE
			WHEN prs.runningStake > 0 THEN 0
			WHEN prs.winlost = prs.totalStake THEN 111
			WHEN prs.winlost > prs.totalStake THEN 112
			WHEN prs.winlost < prs.totalStake THEN 113
			END,
		[status] = CASE @statusID
			WHEN 0 THEN 'running'
			WHEN 111 THEN 'DRAW'
			WHEN 112 THEN 'WON'
			WHEN 113 THEN 'LOSE'
			END,
		ruben    = CASE @statusID WHEN 0 THEN 0 ELSE 1 END,
		winlost  = CASE @statusID WHEN 0 THEN 0 ELSE prs.winlost END,		
		playercomm = CASE @statusID WHEN 0 THEN 0 ELSE prs.playercomm END,
		[TWinLost] = CASE @statusID WHEN 0 THEN 0 ELSE PRS.TWinlost END,	
		[TComm] = CASE @statusID WHEN 0 THEN 0 ELSE PRS.TComm END		
				
	FROM dbo.bettrans B with (rowlock)
		INNER JOIN PRS with (nolock) ON B.transid = PRS.transid
	WHERE
		   (prs.runningStake > 0 AND B.statusID > 0) -- set back to running
		OR (prs.runningStake = 0 AND B.statusID = 0) -- setting it
		OR -- update result
		(
		(prs.runningStake = 0 AND B.statusID > 0) AND
			(  B.winlostdate <> prs.winlostdate
			OR B.winlost <> prs.winlost 
			OR B.playercomm <> prs.playercomm
			)
		)

	-- update ticket for agents in bettrans_agent	
	;WITH PRS_Agent AS (
		SELECT
			t.transid, t.refno, pr.AgentId, SUM(CASE statusID WHEN 0 THEN stake ELSE 0 END) RunningStake,			
			SUM(awinlost) awinlost, 
			SUM(acomm) acomm
		FROM  			
			dbo.BetParlayResult_Agent pr WITH(NOLOCK)
				INNER JOIN #temp_bettrans t ON pr.refno = t.refno
		GROUP BY
			t.transid, t.refno, pr.AgentId
	)	
	
	UPDATE ba WITH(ROWLOCK,UPDLOCK)
	SET 
		winlostdate = b.winlostdate,		
		actual_stake = b.actual_stake,		
		@statusID= ba.statusID = b.StatusId,
		[status] = b.Status,		
		awinlost  = CASE @statusID WHEN 0 THEN 0 ELSE prs.awinlost END,		
		AComm = CASE @statusID WHEN 0 THEN 0 ELSE prs.acomm END		
	FROM dbo.BetTrans_Agent ba with (rowlock)
		INNER JOIN PRS_Agent prs with (nolock) ON ba.transid = PRS.transid and ba.AgentId = PRS.AgentId
		INNER JOIN BetTrans b with (nolock) ON B.transid = ba.transid
	WHERE
		   (prs.runningStake > 0 AND ba.statusID > 0) -- set back to running
		OR (prs.runningStake = 0 AND ba.statusID = 0) -- setting it
		OR -- update result
		(
		(prs.runningStake = 0 AND ba.statusID > 0) AND
			(  ba.winlostdate <> b.winlostdate
			OR ba.actual_stake <> b.actual_stake
			OR ba.StatusId <> b.StatusId
			OR ba.awinlost <> prs.awinlost 
			OR ba.acomm <> prs.acomm			
			)
		)
	
	DROP TABLE #temp_parlayResult
	DROP TABLE #temp_bettrans
	DROP TABLE  #temp_bettrans_Agent
	DROP TABLE  #temp_parlayResult_Agent
GO
GRANT EXECUTE ON [dbo].[Admin_Calculate_29] TO [aplweb] AS [dbo]
