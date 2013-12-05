SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Task_DailySummary_Verify]
	@WinLostDate date,
	@TestMode tinyint = 1
AS

/*
Created by: Sophia
Date: 20130505
Task:	- Daily Summary
		- Update outright on ProdDB via linked server call: Task_DailySummary_DB02_Copy/Delete 
DB: SVRAGE/RepDB
Revisions:	
	-20131129@Dan: update more check condition

 */

SET NOCOUNT ON
-- ====================
-- DATA VERIFICATION
-- ====================


IF EXISTS (
	SELECT	TransId FROM bettrans WITH (NOLOCK)
	WHERE	statusID in (0,1)
			AND custid <> 0
			AND bettype <=19000 AND bettype <> 10 AND winlostdate <= @winlostdate
			AND currency <> 20			
			AND transid NOT IN (
					SELECT	TransID 
					FROM	dbo.Bettrans_Agent WITH (NOLOCK)
					WHERE	winlostdate <= @winlostdate	 
							AND statusID in (0,1)  
							AND bettype <=19000
							AND AgentID = 53288 -----line test Suntest
					)
)
BEGIN
	SELECT DISTINCT matchid, bettype, 'EXEC DBA_MatchName ' + CAST(matchid as nvarchar(20)) cmd FROM bettrans WITH (NOLOCK)
	WHERE	winlostdate <= @winlostdate 		
			AND statusID = 0 
			AND bettype <=19000 and bettype NOT IN (9, 10, 29)
			AND currency <> 20

	SELECT DISTINCT 'EXEC DBA_MatchName ' + CAST(bm.matchid as varchar(10)) matchid, m.eventdate, bm.matchid, ',' [Comma]
	FROM dbo.bettrans b WITH (NOLOCK)
		INNER JOIN dbo.bettransm bm WITH (NOLOCK) ON b.refno = bm.refno
		INNER JOIN dbo.match m WITH (NOLOCK) ON bm.matchid = m.matchid
	WHERE	b.winlostdate <= @winlostdate 
			AND b.statusID in (0,1) AND bm.statusID in (0,1)
			AND b.bettype in (9,29)
			AND b.matchID in (9,29)
			AND b.currency <> 20
			AND b.transid NOT IN (
					SELECT	TransID 
					FROM	dbo.Bettrans_Agent WITH (NOLOCK)
					WHERE	winlostdate <= @winlostdate	 
							AND statusID in (0,1)  
							AND bettype <=19000
							AND AgentID = 53288 -----line test Suntest
					)
	ORDER BY m.eventdate

	IF @@ROWCOUNT > 0
	BEGIN
		PRINT '--'
		PRINT '--SELECT CONVERT(VARCHAR(20),transID) + '','', * FROM bettrans WITH (NOLOCK) WHERE statusid = 0 AND matchid IN (9,29) AND bettype IN (9,29) AND winlostdate <= ''' + CONVERT(varchar(10), @winlostdate, 120) + ''''
		PRINT '--UPDATE dbo.bettrans SET winlostdate = ''' + CONVERT(varchar(10), DATEADD(day,1,@winlostdate), 120) + ''' WHERE transid IN ( xxxxx )'
		PRINT '--UPDATE dbo.bettrans_Agent SET winlostdate = ''' + CONVERT(varchar(10), DATEADD(day,1,@winlostdate), 120) + ''' WHERE transid IN ( xxxxx )'
		PRINT '--'
	END

	RAISERROR ('FAILED: Have running tickets', 16, 1)
	RETURN
END
-- ====================
---No need
--IF EXISTS (
--	SELECT transid FROM bettrans WITH (NOLOCK)
--	WHERE srecommend <= 100 AND (scomm <> acomm OR swinlost <> 0)
--	AND bettype <=19000 AND winlostdate = @winlostdate
--)
--BEGIN
--	RAISERROR ('FAILED: Incorrect Company SuperAgent setting', 16, 1)
--	RETURN
--END

-- ====================

IF EXISTS (
	SELECT transid FROM BetTrans WITH (NOLOCK)
	WHERE (PlayerComm IS NULL OR WinLost IS NULL)
		  AND bettype <=19000 AND winlostdate = @winlostdate
)
BEGIN
	RAISERROR ('FAILED: Null Commission/WinLost of Member', 16, 1)
	RETURN
END
-- ====================
IF EXISTS (
	SELECT transid FROM BetTrans_Agent WITH (NOLOCK)
	WHERE (AComm IS NULL OR AWinLost IS NULL)
		  AND bettype <=19000 AND winlostdate = @winlostdate
)
BEGIN
	RAISERROR ('FAILED: Null Commission/WinLost of Agent', 16, 1)
	RETURN
END
-- ====================
IF EXISTS (
	SELECT currency
	FROM bettrans WITH (NOLOCK)
	WHERE bettype <=19000 AND winlostdate = @winlostdate
	AND NOT (bettype = 10 and statusID = 0) -- exclude running outright
	GROUP BY currency
	HAVING COUNT(DISTINCT actualrate) > 1
)
BEGIN
	RAISERROR ('FAILED: Multiple Exchange Rate', 16, 1)
	RETURN
END

-- ====================
IF EXISTS(
	SELECT 1
	FROM bettrans b (nolock)
		join BetTrans_Agent ba (nolock) on b.TransId=ba.TransId
	where b.StatusId <> ba.StatusId
		AND b.bettype <=19000 AND b.winlostdate = @winlostdate
	)
BEGIN
	RAISERROR ('FAILED: Status in bettrans is difference from bettrans_agent ', 16, 1)
	RETURN
END

-- ====================
 
IF @TestMode = 1
BEGIN
	PRINT 'DATA OK'

	IF EXISTS (SELECT 1 FROM bettrans WITH (NOLOCK)
		WHERE bettype = 10 
			AND statusID = 0 
			AND winlostdate = @winlostdate)
		PRINT 'Some Outright need to moved : Run with parameter = 2'

	IF EXISTS (SELECT 1 FROM bettrans WITH (NOLOCK)
		WHERE currency = 20
			AND winlostdate = @winlostdate
			AND bettype <=19000
			AND statusID = 0)
		PRINT 'Some TEST Ticket need to Refund : Run with parameter = 2'

	RETURN
END
