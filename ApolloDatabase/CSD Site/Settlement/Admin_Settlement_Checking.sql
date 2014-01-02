ALTER PROCEDURE [dbo].[Admin_Settlement_Checking]
	@matchid int,
	@action varchar(10) = 'CAL',		
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
Created: 2013/05/06
Task : Settlement checking 
DB: SVRTXN/TransDB 

Revisions:    
	
Param's Explanation:
	- @matchid: The ID of match want to settlement
	- @action: indicate action performed
	 + CAL: Calc all
	 + CAL-HT: Calc HT bet only
	 + CAL-FT: Calc FT bet only
    - @ErrCode: if @ErrCode>0 Invalid of GoalRecord and TotalGoal
    - @ErrMsg: The message will be show if @ErrCode>0
*/

if exists(select 1 from bettrans with (nolock) where matchid = @matchid and bettype = 22 and (hdp1>1 or hdp2>1))
BEGIN
	select 
		@ErrCode = 101, 
		@ErrMsg = 'Invalid Handicap value for Next goal tickets! Cannot calculate!'    
		return                    
END	

--check consitency bettrans and BetTrans_Agent
IF (EXISTS(
	select 1 -- b.TransId, ISNULL(MAX(ag.AgentLevel),0), count(ba.TransId)
	from bettrans (nolock) b LEFT JOIN [dbo].[CustInfo] (nolock) c ON c.CustId =b.CustId
		LEFT JOIN AgentInfo (nolock) ag ON ag.AgentId = c.AgentId
		LEFT JOIN [dbo].[BetTrans_Agent] (nolock) ba on ba.TransId = b.TransId	
	where b.matchid = @matchid
	GROUP BY b.TransId
	HAVING ISNULL(MAX(ag.AgentLevel),0) <> count(ba.TransId)
	))
BEGIN
	select 
		@ErrCode = 102, 
		@ErrMsg = 'System is not ready to calculate this match. Please try again after few minutes.'    
		return                    
END	

--Check replication:
declare @tempBettrans as table(db varchar(10), betCNT int, runningCNT int, waitingCNT int)
declare @tempBettransAgent as table(db varchar(10), betCNT int, runningCNT int, waitingCNT int)

declare @min1b int, @min2b int, @max1b int, @max2b int, @maxWaitingb int

IF (@action = 'CAL-HT')
BEGIN
	INSERT INTO @tempBettrans (db, betCNT, runningCNT, waitingCNT)
	select 'DBTrans', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from bettrans with(nolock) 
	where matchid = @matchid and bettype IN(7,8,12,15,21,30,125)
	UNION ALL
	select 'DB052', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from SVRAGE.RepDB.dbo.bettrans with(nolock) 
	where matchid = @matchid and bettype IN(7,8,12,15,21,30,125)	
	UNION ALL
	select 'DB06', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from SVRCSD.RepDB.dbo.bettrans with(nolock) 
	where matchid = @matchid and bettype IN(7,8,12,15,21,30,125)	
END
ELSE IF (@action = 'CAL-FT')
BEGIN
	INSERT INTO @tempBettrans (db, betCNT, runningCNT, waitingCNT)
	select 'DBTrans', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from bettrans with(nolock) 
	where matchid = @matchid and bettype NOT IN(7,8,12,15,21,30,125) 
		and bettype not between 1301 and 1334 -- exclude sporting solution product
	UNION ALL
	select 'DB052', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)	
	from SVRAGE.RepDB.dbo.bettrans with(nolock) 
	where matchid = @matchid and bettype NOT IN(7,8,12,15,21,30,125)
		and bettype not between 1301 and 1334 -- exclude sporting solution product	
	UNION ALL
	select 'DB06', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from SVRCSD.RepDB.dbo.bettrans with(nolock) 
	where matchid = @matchid and bettype NOT IN(7,8,12,15,21,30,125)	
		and bettype not between 1301 and 1334 -- exclude sporting solution product
END
ELSE IF (@action = 'CAL')
BEGIN
	INSERT INTO @tempBettrans (db, betCNT, runningCNT, waitingCNT)
	select 'DBTrans', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from bettrans with(nolock) 
	where matchid = @matchid
		and bettype not between 1301 and 1334 -- exclude sporting solution product
	UNION ALL
	select 'DB052', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from SVRAGE.RepDB.dbo.bettrans with(nolock) 
	where matchid = @matchid
		and bettype not between 1301 and 1334 -- exclude sporting solution product	
	UNION ALL
	select 'DB06', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from SVRCSD.RepDB.dbo.bettrans with(nolock) 
	where matchid = @matchid
		and bettype not between 1301 and 1334 -- exclude sporting solution product
END

select @min1b= min(betCNT), @max1b = max(betCNT), @min2b= min(runningCNT), @max2b=max(runningCNT), @maxWaitingb = max(waitingCNT)
from @tempBettrans
--where db <> 'DB052'

IF @max1b > @min1b OR @max2b > @min2b OR @maxWaitingb > 0
BEGIN
	select 
		@ErrCode = 103, 
		@ErrMsg = 'System is not ready to calculate this match. Please try again after few minutes.'    
	return                    
END

delete @tempBettrans

IF (@action = 'CAL-HT')
BEGIN
	INSERT INTO @tempBettrans (db, betCNT, runningCNT, waitingCNT)
	select 'DBTrans', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from BetTrans_Agent with(nolock) 
	where matchid = @matchid and bettype IN(7,8,12,15,21,30,125)
	UNION ALL
	select 'DB052', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from SVRAGE.RepDB.dbo.BetTrans_Agent with(nolock) 
	where matchid = @matchid and bettype IN(7,8,12,15,21,30,125)	
	UNION ALL
	select 'DB06', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from SVRCSD.RepDB.dbo.BetTrans_Agent with(nolock) 
	where matchid = @matchid and bettype IN(7,8,12,15,21,30,125)	
END
ELSE IF (@action = 'CAL-FT')
BEGIN
	INSERT INTO @tempBettrans (db, betCNT, runningCNT, waitingCNT)
	select 'DBTrans', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from BetTrans_Agent with(nolock) 
	where matchid = @matchid and bettype NOT IN(7,8,12,15,21,30,125) 
		and bettype not between 1301 and 1334 -- exclude sporting solution product
	UNION ALL
	select 'DB052', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)	
	from SVRAGE.RepDB.dbo.BetTrans_Agent with(nolock) 
	where matchid = @matchid and bettype NOT IN(7,8,12,15,21,30,125)
		and bettype not between 1301 and 1334 -- exclude sporting solution product	
	UNION ALL
	select 'DB06', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from SVRCSD.RepDB.dbo.BetTrans_Agent with(nolock) 
	where matchid = @matchid and bettype NOT IN(7,8,12,15,21,30,125)	
		and bettype not between 1301 and 1334 -- exclude sporting solution product
END
ELSE IF (@action = 'CAL')
BEGIN
	INSERT INTO @tempBettrans (db, betCNT, runningCNT, waitingCNT)
	select 'DBTrans', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from BetTrans_Agent with(nolock) 
	where matchid = @matchid
		and bettype not between 1301 and 1334 -- exclude sporting solution product
	UNION ALL 
	select 'DB052', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from SVRAGE.RepDB.dbo.BetTrans_Agent with(nolock) 
	where matchid = @matchid
		and bettype not between 1301 and 1334 -- exclude sporting solution product	
	UNION ALL
	select 'DB06', 
		count(transid), 
		isnull(sum(case statusid when 0 then 1 else 0 end),0),
		isnull(sum(case statusid when 1 then 1 else 0 end),0)
	from SVRCSD.RepDB.dbo.BetTrans_Agent with(nolock) 
	where matchid = @matchid
		and bettype not between 1301 and 1334 -- exclude sporting solution product
END

select @min1b= min(betCNT), @max1b = max(betCNT), @min2b= min(runningCNT), @max2b=max(runningCNT), @maxWaitingb = max(waitingCNT)
from @tempBettrans
--where db <> 'DB052'

IF @max1b > @min1b OR @max2b > @min2b OR @maxWaitingb > 0
BEGIN
	select 
		@ErrCode = 104, 
		@ErrMsg = 'System is not ready to calculate this match. Please try again after few minutes.'    
	return                    
END


GO
GRANT EXECUTE ON [dbo].[Admin_Settlement_Checking] TO [aplweb]
