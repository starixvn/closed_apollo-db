ALTER PROCEDURE [dbo].[Acc_Set_MatchSelDetail]
	@matchid int,
	@excludeRefundFGLG	bit = 0	
AS
/**
 * Created by	: Kaden
 * Date			: 20130318
 * Task			: Select match detail
 * DB			: SVRTXN/TransDB
 * Revisions	:
 	- 20140523@Dan: Add new bettype 1H total goal, 1H FGLG (126, 127)
 * Parameters:
 	- @matchid: match id
 
 */

SET NOCOUNT ON 
DECLARE @NextAllowSettleTime DATETIME, 
	@IsExistFGLG BIT,
	@IsExistLG BIT,
	@IsHTOnly BIT,
	@IsLive BIT,
	@DelayTime INT,
	@IsExistHTFGLG BIT,
	@IsExistHTLG BIT
	
SELECT @IsExistLG = 0, @IsExistFGLG = 0, @DelayTime = 0, @IsHTOnly = 0, @IsLive = 0 ,
	@IsExistHTFGLG = 0, @IsExistHTLG = 0

SELECT @NextAllowSettleTime = VValue FROM SystemSettings WITH (NOLOCK) WHERE VName = 'NextAllowSettleTime' 
SELECT @DelayTime = CASE WHEN DATEDIFF(ss, getdate(), @NextAllowSettleTime) < 0 THEN 0
							ELSE DATEDIFF(ss, getdate(), @NextAllowSettleTime) END

IF @excludeRefundFGLG=0
BEGIN
	--@IsExistLG
	IF EXISTS (select top 1 1 from bettrans WITH (NOLOCK) WHERE matchid = @matchid AND bettype = 14 AND RIGHT(BETTEAM,1) = '2' AND statusID NOT IN (101,102))
		SELECT @IsExistLG = 1
	ELSE
		IF EXISTS (select top 1 1 from bettransm WITH (NOLOCK) WHERE matchid = @matchid AND bettype = 14 AND RIGHT(BETTEAM,1) = '2' AND statusID NOT IN (101,102))
			SELECT @IsExistLG = 1

	--@IsExistFGLG
	IF (@IsExistLG = 0)
	BEGIN
		IF EXISTS (select top 1 1 from bettrans WITH (NOLOCK) WHERE matchid = @matchid AND bettype = 14 AND statusID NOT IN (101,102))
			SELECT @IsExistFGLG = 1
		ELSE
			IF EXISTS (select top 1 1 from bettransm WITH (NOLOCK) WHERE matchid = @matchid AND bettype = 14 AND statusID NOT IN (101,102))
				SELECT @IsExistFGLG = 1
	END
	ELSE
		SELECT @IsExistFGLG = 1

	--@IsExistHTLG
	IF EXISTS (select top 1 1 from bettrans WITH (NOLOCK) WHERE matchid = @matchid AND bettype = 127 AND RIGHT(BETTEAM,1) = '2' AND statusID NOT IN (101,102))
		SELECT @IsExistHTLG = 1
	ELSE
		IF EXISTS (select top 1 1 from bettransm WITH (NOLOCK) WHERE matchid = @matchid AND bettype = 127 AND RIGHT(BETTEAM,1) = '2' AND statusID NOT IN (101,102))
			SELECT @IsExistHTLG = 1

	--@IsExistHTFGLG
	IF (@IsExistHTLG = 0)
	BEGIN
		IF EXISTS (select top 1 1 from bettrans WITH (NOLOCK) WHERE matchid = @matchid AND bettype = 127 AND statusID NOT IN (101,102))
			SELECT @IsExistHTFGLG = 1
		ELSE
			IF EXISTS (select top 1 1 from bettransm WITH (NOLOCK) WHERE matchid = @matchid AND bettype = 127 AND statusID NOT IN (101,102))
				SELECT @IsExistHTFGLG = 1
	END
	ELSE
		SELECT @IsExistHTFGLG = 1
END 
ELSE
BEGIN
	--@IsExistLG
	IF EXISTS (select top 1 1 from bettrans WITH (NOLOCK) WHERE matchid = @matchid AND bettype = 14 AND RIGHT(BETTEAM,1) = '2' AND statusID NOT IN (101,102,103))
		SELECT @IsExistLG = 1
	ELSE
		IF EXISTS (select top 1 1 from bettransm WITH (NOLOCK) WHERE matchid = @matchid AND bettype = 14 AND RIGHT(BETTEAM,1) = '2' AND statusID NOT IN (101,102,103))
			SELECT @IsExistLG = 1

	--@IsExistFGLG
	IF (@IsExistLG = 0)
	BEGIN
		IF EXISTS (select top 1 1 from bettrans WITH (NOLOCK) WHERE matchid = @matchid AND bettype = 14 AND statusID NOT IN (101,102,103))
			SELECT @IsExistFGLG = 1
		ELSE
			IF EXISTS (select top 1 1 from bettransm WITH (NOLOCK) WHERE matchid = @matchid AND bettype = 14 AND statusID NOT IN (101,102,103))
				SELECT @IsExistFGLG = 1
	END
	ELSE
		SELECT @IsExistFGLG = 1

	-- @IsExistHTLG
	IF EXISTS (select top 1 1 from bettrans WITH (NOLOCK) WHERE matchid = @matchid AND bettype = 127 AND RIGHT(BETTEAM,1) = '2' AND statusID NOT IN (101,102,103))
		SELECT @IsExistHTLG = 1
	ELSE
		IF EXISTS (select top 1 1 from bettransm WITH (NOLOCK) WHERE matchid = @matchid AND bettype = 127 AND RIGHT(BETTEAM,1) = '2' AND statusID NOT IN (101,102,103))
			SELECT @IsExistHTLG = 1

	--@IsExistHTFGLG
	IF (@IsExistHTLG = 0)
	BEGIN
		IF EXISTS (select top 1 1 from bettrans WITH (NOLOCK) WHERE matchid = @matchid AND bettype = 127 AND statusID NOT IN (101,102,103))
			SELECT @IsExistHTFGLG = 1
		ELSE
			IF EXISTS (select top 1 1 from bettransm WITH (NOLOCK) WHERE matchid = @matchid AND bettype = 127 AND statusID NOT IN (101,102,103))
				SELECT @IsExistHTFGLG = 1
	END
	ELSE
		SELECT @IsExistHTFGLG = 1
END
if
( 
	exists
	(
		select	1 
		from	SVRPRO.ProdDB.dbo.match m with (nolock) 				
		where	m.matchid=@matchid 
				AND sporttype = 1 
				AND datediff(minute,kickofftime,CURRENT_TIMESTAMP) < 100
				AND (datediff(minute,kickofftime,CURRENT_TIMESTAMP) > 45)
	)	
)		
BEGIN
	Select @IsHTOnly = 1
END
	
Declare @status TABLE ([Group] tinyint, BetCount int, InRunning int)
INSERT INTO @status
	SELECT
		CASE -- 0:FT , 1:HT , 2:FGLG , 3:1H FGLG
			WHEN bettype IN (7, 8, 12, 15, 21, 30, 125, 126) THEN 1
			WHEN bettype = 14 THEN 2
			WHEN bettype = 127 THEN 3
			ELSE 0 END,
		--SUM(CASE WHEN [status] IN (N'VOID',N'REJECT') THEN 0 ELSE 1 END),
		SUM(CASE WHEN [statusID] IN (101,102) THEN 0 ELSE 1 END),
		--SUM(CASE WHEN [status] = N'running' THEN 1 ELSE 0 END)
		SUM(CASE WHEN [statusID] = 0 THEN 1 ELSE 0 END)
	FROM
		bettrans with (nolock)
	WHERE
		matchid = @matchid and bettype not between 1301 and 1334
	GROUP BY		
		CASE WHEN bettype IN (7, 8, 12, 15, 21, 30, 125, 126) THEN 1 
				 WHEN bettype = 14 THEN 2 
				 when bettype = 127 THEN 3
				 ELSE 0 END

IF NOT EXISTS(SELECT * FROM @status WHERE [Group] = 0) INSERT INTO @status VALUES (0,0,0)
IF NOT EXISTS(SELECT * FROM @status WHERE [Group] = 1) INSERT INTO @status VALUES (1,0,0)
IF NOT EXISTS(SELECT * FROM @status WHERE [Group] = 2) INSERT INTO @status VALUES (2,0,0)
IF NOT EXISTS(SELECT * FROM @status WHERE [Group] = 3) INSERT INTO @status VALUES (3,0,0)

Declare @FTStatus nvarchar(10), @HTStatus nvarchar(10), @FGLGStatus nvarchar(30), @HTFGLGStatus nvarchar(30)
DECLARE @ParlayRunningFGLG BIT /* NULL no ticket, 1 running, 0 settled*/
		,@ParlayRunningHTFGLG BIT /* NULL no ticket, 1 running, 0 settled*/
	
SELECT TOP 1 @ParlayRunningFGLG = CASE WHEN statusID = 0 THEN 1 ELSE 0 END
FROM bettransm WITH(NOLOCK)
WHERE matchid = @matchid AND bettype = 14 AND statusID NOT IN (101,102)

SELECT TOP 1 @ParlayRunningHTFGLG = CASE WHEN statusID = 0 THEN 1 ELSE 0 END
FROM bettransm WITH(NOLOCK)
WHERE matchid = @matchid AND bettype = 127 AND statusID NOT IN (101,102)

Select @FTStatus = CASE
		WHEN betcount  = 0 THEN N'No Ticket'
		WHEN inRunning = 0 THEN N'Calculated'
		ELSE N'Running' END FROM @status WHERE [Group] = 0
Select @HTStatus = CASE
		WHEN betcount  = 0 THEN N'No Ticket'
		WHEN inRunning = 0 THEN N'Calculated'
		ELSE N'Running' END FROM @status WHERE [Group] = 1
Select @FGLGStatus = CASE
		WHEN betcount  = 0 THEN CASE WHEN @ParlayRunningFGLG IS NULL THEN N'No Ticket'
										WHEN @ParlayRunningFGLG = 1 THEN N'Parlay Running'	
										WHEN @ParlayRunningFGLG = 0 THEN N'Parlay Calculated'
								END
		WHEN inRunning = 0 THEN N'Calculated'
		ELSE N'Running' END FROM @status WHERE [Group] = 2
Select @HTFGLGStatus = CASE
		WHEN betcount  = 0 THEN CASE WHEN @ParlayRunningHTFGLG IS NULL THEN N'No Ticket'
										WHEN @ParlayRunningHTFGLG = 1 THEN N'Parlay Running'	
										WHEN @ParlayRunningHTFGLG = 0 THEN N'Parlay Calculated'
								END
		WHEN inRunning = 0 THEN N'Calculated'
		ELSE N'Running' END FROM @status WHERE [Group] = 3


IF EXISTS(select top 1 1 from bettrans (nolock) where matchid = @matchid AND liveindicator = 1)
	Select @IsLive = 1		

SELECT	match.sporttype, 
		mr.betstatus betstatus, 
		mr.hthomescore hthomescore, mr.htawayscore htawayscore,
		datediff(minute,kickofftime,CURRENT_TIMESTAMP) playtime,	
		match.leagueid,
		match.matchid,  
		match.homeid,
		match.awayid,	
		match.matchcode,match.kickofftime,
		mr.finalhomescore finalhomescore, mr.finalawayscore finalawayscore,
		mr.eventstatus eventstatus,
		isnull(mr.refund,0) IsRefund, isnull(mr.calrefund,0) IsCalRefund,
		isnull(mr.calculate,0) IsCalculated, isnull(mr.multiple,0) IsMultiCaled,
		isnull(match.isNeutral, CONVERT(BIT,0)) as IsNeutral,
		mr.ishtcal ishtcal,
		mr.GoalRecord as GoalRecord,
		@HTStatus HTStatus,
		@FTStatus FTStatus,
		@FGLGStatus fglgstatus,
		@IsExistHTFGLG AS IsExistHTFGLG,
		@IsExistHTLG AS IsExistHTLG,	
		@IsExistFGLG AS IsExistFGLG,
		@IsExistLG AS IsExistLG,		
		@IsHTOnly as IsHTOnly,	
		@IsLive as IsLive,
		@DelayTime DelayTime		
FROM	SVRPRO.ProdDB.dbo.match with (nolock) 	
		left outer join SVRPRO.ProdDB.dbo.match_remark_ex mr with (nolock) on match.matchid = mr.matchid
WHERE match.matchid = @matchid

GO
GRANT EXECUTE ON [dbo].[Acc_Set_MatchSelDetail] TO [aplweb]	
