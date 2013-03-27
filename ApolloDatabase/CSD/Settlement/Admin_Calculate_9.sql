ALTER  PROCEDURE [dbo].[Admin_Calculate_9]	
	@matchids varchar(2000),  
	@matchdate smalldatetime,
	@targetserver varchar(20),
	@strXML varchar(MAX) ='' OUTPUT,
	@selTime int = 0 OUTPUT,
	@updTime int = 0 OUTPUT
WITH RECOMPILE  
AS  
/*
Creator: Dan
Date: 2013-03-27
Task : Settle bettrans based on bettransm (for mix parlay)
DB: SVRTXN/TransDB
Original: 

Revisions:
	
Param's Explanation:
	- @matchid: matchid of match to be settled
	- @matchdate match date
*/

SET NOCOUNT ON

IF @@SERVERNAME IN ('DB042', 'DB043', 'DB044') RETURN

------- 20121105@Viet : bring modds value from DBTrans to replicated servers.----
-- 1st call: RUN at DBTRANS only
--IF @targetserver = 'DBTRANS' AND @@SERVERNAME <> 'DBTRANS' RETURN
IF @targetserver = 'DBTRANS' AND @@SERVERNAME <> 'DB215\SQL2012' RETURN

-- 2nd call: RUN all servers except DBTRANS
--IF @targetserver = '' AND @@SERVERNAME = 'DBTRANS' RETURN
IF @targetserver = '' AND @@SERVERNAME = 'DB215\SQL2012' RETURN

--------/ 20121105@Viet : bring modds value from DBTrans to replicated servers.---

Declare @subStart datetime
Declare @commWinRate smallmoney, @commLostRate smallmoney

-- GET list of matchid(s)
Declare @match TABLE (matchid int PRIMARY KEY)
INSERT INTO @match SELECT val FROM dbo.strSplit(@matchids,',')
-- GET List of refno concern for input match(es)

DECLARE @tmp_mrefno TABLE (refno bigint)

INSERT INTO @tmp_mrefno (refno)
	SELECT distinct refno
	FROM dbo.bettransm bm WITH (ROWLOCK)
		INNER JOIN @match m ON bm.matchid = m.matchid   

CREATE TABLE #temp_bettrans  (
	[transid] [bigint] NOT NULL ,  
	[refno] [bigint] unique clustered NOT NULL ,  
	[stake] [money] NOT NULL ,  
	[status] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,  
	[winlost] [money] NULL ,  	
	[winlostdate] [smalldatetime] NULL ,  	
	[playerdiscount] [float] NULL ,  	
	[playercomm] [money] NULL ,  	
	[TPositionTaking] [smallmoney] NOT NULL ,
	Tdiscount [float] NULL,  
	[TWinLost] [money] NULL ,  
	TComm [money] NULL,  
	[ruben] [tinyint] NULL ,  
	[modds] [money] null,
	[statusID] [tinyint] NULL,
	[DoubleCommLosing] BIT NULL,
	IsUpdated [bit] NULL -- this field to stored value indicate if this row been change
)   
--create index temp_index on #temp_bettrans (TransID)  
-- GET list of concern Ticket
SET @subStart = CURRENT_TIMESTAMP
	INSERT INTO #temp_bettrans ([transid], [refno], [stake], [status],
			[winlost], 	[winlostdate], 	[playerdiscount], [playercomm],  
			[TPositionTaking], Tdiscount, [TWinLost], TComm,
			[ruben], [modds],[statusID], [DoubleCommLosing])
	SELECT
		[transid], b.[refno], [stake], [status],
		[winlost], 	[winlostdate], 	[playerdiscount], [playercomm], 
		[TPositionTaking], Tdiscount, [TWinLost], TComm,
		[ruben], [modds],[statusID], [DoubleCommLosing]
	FROM dbo.bettrans b WITH (ROWLOCK)
		inner join @tmp_mrefno t on b.refno = t.refno
	WHERE 
		b.matchid = 9 
		AND bettype=9    
		AND statusID NOT IN (101,102) --('VOID','REJECT')

SET @selTime = @selTime + DATEDIFF(millisecond, @subStart, CURRENT_TIMESTAMP)

-- Results list from both bettransm & bettransm14
--Declare #parlay
CREATE TABLE #parlay (refno bigint, matchid int, statuswinlost tinyint, statusID int, odds smallmoney, matchdate smalldatetime)

INSERT INTO #parlay
	SELECT bm.refno, bm.matchid, bm.statuswinlost, statusID, odds, matchdate
	FROM dbo.bettransm bm with (rowlock) INNER JOIN @tmp_mrefno tm ON bm.refno = tm.refno

INSERT INTO #parlay
	SELECT bm.refno, bm.matchid, bm.statuswinlost, statusID, odds, matchdate
	FROM dbo.bettransm14 bm with (rowlock) INNER JOIN @tmp_mrefno tm ON bm.refno = tm.refno

-- CALCULATE effective odds value  
Declare @modds
	TABLE (m_refno bigint PRIMARY KEY, modds money, NoRefund tinyint, loseCnt tinyint, runningCnt tinyint, matchdate_max smalldatetime)
INSERT INTO @modds (m_refno, modds, NoRefund, loseCnt, runningCnt, matchdate_max)
	SELECT refno,
		EXP(SUM(LOG(
		case bm.statuswinlost
			when 0 then 1 -- draw
			when 1 then 1+((bm.odds-1)/2) -- half won
			when 2 then bm.odds -- won
			when 3 then 0.5 -- half lose
			when 4 then 0.000000000001 -- lose
			else 1 -- void/reject
		end
		))) as modds,
		SUM(
		case 
			when bm.statusID IN(121, 103) then 0			
			else 1
		end
		) as NoRefund,
		SUM(case
			when bm.statuswinlost = 4 then 1
			else 0
		end) as loseCnt,
		SUM(case
			when bm.statusID IN (0,1) then 1
			else 0
		end) as runningCnt,
		MAX(matchdate) AS matchdate_max
	FROM #parlay bm
	GROUP BY refno  

------- 20121105@Viet : bring modds value from DBTrans to replicated servers.----
IF (@targetserver = 'DBTRANS' AND @@SERVERNAME = 'DBTRANS')
BEGIN 
	-- export modds for replicated servers to use [edited by viet @ 20121213]
	SET @strXML = CONVERT(varchar(max),(
		SELECT m_refno '@k'
			,NULLIF(modds,0) '@v'	
		FROM @modds						
		FOR XML PATH('r'), ROOT('root'), TYPE
	))				
END
ELSE IF (@targetserver = '' AND @@SERVERNAME <> 'DBTRANS')
BEGIN
	-- get modds from XML string [edited by viet @ 20121213]
	declare @xml XML
	SET @xml = convert(xml, @strXML)
 	
	declare @dbtrans_modds as TABLE (m_refno bigint PRIMARY KEY, modds money)
	INSERT INTO @dbtrans_modds(m_refno, modds)
	SELECT T.C.value('./@k', 'bigint'), -- refno
		isnull(T.C.value('./@v', 'money'),0) -- modds
	from @xml.nodes('/root/r') as T(C)	
	
	-- apply modds which was generating from DBTrans
	UPDATE d
	SET modds = s.modds
	FROM @modds d
		INNER JOIN @dbtrans_modds s on d.m_refno = s.m_refno
END
--------/ 20121105@Viet : bring modds value from DBTrans to replicated servers.---

Declare @statusID tinyint, @odds money, @DownlinePT smallmoney
Declare @oldstatusID tinyint, @oldwinlost money, @winlost money


--get the needed data to settle for agent
SELECT ba.transid, ba.[AgentId], [AgentLevel], b.[DoubleCommLosing], b.[Stake],
	AWinLost,ba.AComm,APositionTaking, ADiscount, cast(0 as smallmoney) as DownlinePT, 
	ba.Status, ba.StatusId, b.RefNo, b.WinLostDate, cast(0 as bit) as IsUpdated 
INTO #ba 
FROM #temp_bettrans B WITH (NOLOCK) JOIN BetTrans_Agent ba WITH (ROWLOCK) ON 
	b.TransId=ba.TransId JOIN AgentInfo a WITH (NOLOCK) ON a.AgentID=ba.AgentID	
		
--create index		
CREATE CLUSTERED INDEX IX_tmp on #ba (transid,AgentLevel desc)		
		
DECLARE @prevtransid BIGINT =0 
	
-- settle for agent in temporary table
UPDATE #ba 
SET 
	@DownlinePT=DownlinePT = case when @prevtransid <> transid 
					then APositionTaking
					else APositionTaking + @DownlinePT -- accumulated PT for upper agent --> for calculating agent commision
					end,
	@prevtransid = transid,	
		
	@oldstatusID = statusID,
	@oldwinlost = awinlost,
	@statusID = statusID = CASE
		WHEN loseCnt > 0 THEN 113 -- Lose
		WHEN runningCnt > 0 THEN 0 -- running
		WHEN NoRefund = 0 THEN 103 -- Refund
		WHEN m.modds < 1 THEN 113 -- Lose
		WHEN m.modds = 1 THEN 111 -- Draw
		ELSE 112 -- Won
		END,
	status = CASE @statusID
		WHEN 0 THEN 'running'
		WHEN 103 THEN 'Refund'
		WHEN 111 THEN 'DRAW'
		WHEN 112 THEN 'WON'
		WHEN 113 THEN 'LOSE'
		END,

	winlostdate = CASE @statusID
		WHEN 0 THEN m.matchdate_max
		ELSE @matchdate
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
				
	awinlost = CASE 
		WHEN @statusID = 113 and loseCnt > 0  THEN  stake*apositiontaking
		WHEN @statusID IN (112, 113) THEN -stake*apositiontaking*(@odds-1)
		ELSE 0
		END,

	acomm	= CASE @statusID
			WHEN 112 THEN @commWinRate  * adiscount*stake*(1-@DownlinePT)
			WHEN 113 THEN @commLostRate * adiscount*stake*(1-@DownlinePT)
			ELSE 0 END,
	IsUpdated = CASE
		WHEN (@oldstatusID <> @statusID) OR (@oldwinlost <> @winlost) THEN 1
		ELSE 0 END
			
FROM #ba INNER JOIN @modds m ON #ba.refno = m.m_refno
OPTION (MAXDOP 1) --should use this for quirky update to avoid parallelism problem	
		
UPDATE T
SET
	@oldstatusID = statusID,
	@oldwinlost = winlost,

	@statusID = statusID = CASE
		WHEN loseCnt > 0 THEN 113 -- Lose
		WHEN runningCnt > 0 THEN 0 -- running
		WHEN NoRefund = 0 THEN 103 -- Refund
		WHEN m.modds < 1 THEN 113 -- Lose
		WHEN m.modds = 1 THEN 111 -- Draw
		ELSE 112 -- Won
		END,
	status = CASE @statusID
		WHEN 0 THEN 'running'
		WHEN 103 THEN 'Refund'
		WHEN 111 THEN 'DRAW'
		WHEN 112 THEN 'WON'
		WHEN 113 THEN 'LOSE'
		END,
	ruben = CASE @statusID
		WHEN 0 THEN 0
		ELSE 1
		END,
	winlostdate = CASE @statusID
		WHEN 0 THEN m.matchdate_max
		ELSE @matchdate
		END,
	@odds = T.modds = CASE
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
		ELSE stake*@odds
		END,
	
	playercomm	= CASE @statusID 
				WHEN 112 THEN @commWinRate  * stake*playerdiscount
				WHEN 113 THEN @commLostRate * stake*playerdiscount
				ELSE 0 END,	
				
	IsUpdated = CASE
		WHEN (@oldstatusID <> @statusID) OR (@oldwinlost <> @winlost) THEN 1
		ELSE 0 END,
	[TWinLost] = AgentWinlost.AWinlost,
	[TComm] =  CASE @statusID
			WHEN 112 THEN @commWinRate  * Tdiscount*stake*(1-[TPositionTaking])
			WHEN 113 THEN @commLostRate * Tdiscount*stake*(1-[TPositionTaking])
			ELSE 0 END

FROM #temp_bettrans T 
		INNER JOIN @modds m ON T.refno = m.m_refno
		INNER JOIN (SELECT TransId, sum(AWinLost) aWinlost
					FROM #ba 
					GROUP BY TransId) AgentWinlost ON T.TransID=AgentWinlost.TransId 
-------------------------------------------------------------------------------------  

-- UPDATE BACK TO BETTRANS  
-- ONLY for ticket which result change OR winlost amount change
-- ONLY update winlostdate when
	--+new status is "RUNNING" --> update to max_matchdate
	--+current status is RUNNING (ruben = 0) and new status is NOT RUNNING --> update to @matchdate

Declare @ruben bit
SET @subStart = CURRENT_TIMESTAMP
	UPDATE b WITH(ROWLOCK,UPDLOCK)
	SET status = s.status ,  
		statusID = s.statusID,
		@ruben = b.ruben,
		winlostdate = 	case when s.statusID = 0 then s.winlostdate --max_matchdate
							when @ruben = 0 and s.statusID <> 0 then @matchdate
						else b.winlostdate
						end,					
		ruben = s.ruben,
		modds = s.modds,  
		winlost  = s.winlost,  		
		playercomm = s.playercomm,  
		TWinLost = s.Twinlost,  
		TComm  = s.TComm  		
	FROM dbo.bettrans b 
			INNER JOIN 	#temp_bettrans s  ON b.transid = s.transid
	WHERE s.IsUpdated = 1
		--AND (bettrans.status <> s.status OR bettrans.winlost <> s.winlost)  

	UPDATE BetTrans_Agent with (ROWLOCK, UPDLOCK)
	SET 
		@ruben = CASE WHEN BetTrans_Agent.statusID IN (0)
					THEN 0
					ELSE 1
		END,		
		winlostdate = 	case when #ba.statusID = 0 then #ba.winlostdate --max_matchdate
							when @ruben = 0 and #ba.statusID <> 0 then @matchdate
						else BetTrans_Agent.winlostdate
						end,

		aWinLost = #ba.AWinLost,
		aComm = #ba.aComm,			
		Status = #BA.Status,
		StatusID = #ba.StatusId			
	FROM BetTrans_Agent 
			join #ba ON BetTrans_Agent.TransId = #ba.TransId AND BetTrans_Agent.AgentId = #ba.AgentId
	WHERE #ba.IsUpdated = 1

SET @updTime = @updTime + DATEDIFF(millisecond, @subStart, CURRENT_TIMESTAMP)

---------------------------------------------------------------  
GO
GRANT EXECUTE ON [dbo].[Admin_Calculate_9] TO [aplweb]