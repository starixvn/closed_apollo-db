
ALTER PROCEDURE [dbo].[Acc_Set_MatchSelDetail]
	@matchid int,
	@excludeRefundFGLG	bit = 0	
AS
/**
 * Created by	: Kaden
 * Date			: 20130318
 * Task			: Select match detail
 * DB			: APL.TransDB
 * Revisions	:
 *	•
 * Parameters:
 *
	@matchid: match id
 *  
 */

SET NOCOUNT ON 
DECLARE @NextAllowSettleTime DATETIME, 
	@IsExistFGLG BIT,
	@IsExistLG BIT,
	@IsHTOnly BIT,
	@IsLive BIT,
	@DelayTime INT
	
SELECT @IsExistLG = 0, @IsExistFGLG = 0, @DelayTime = 0, @IsHTOnly = 0, @IsLive = 0 

SELECT @NextAllowSettleTime = VValue FROM SystemSettings WITH (NOLOCK) WHERE VName = 'NextAllowSettleTime' 
SELECT @DelayTime = CASE WHEN DATEDIFF(ss, getdate(), @NextAllowSettleTime) < 0 THEN 0
							ELSE DATEDIFF(ss, getdate(), @NextAllowSettleTime) END

IF @excludeRefundFGLG=0
BEGIN
	IF EXISTS (select top 1 1 from bettrans WITH (NOLOCK) WHERE matchid = @matchid AND bettype = 14 AND RIGHT(BETTEAM,1) = '2' AND statusID NOT IN (101,102))
		SELECT @IsExistLG = 1
	ELSE
		IF EXISTS (select top 1 1 from bettransm WITH (NOLOCK) WHERE matchid = @matchid AND bettype = 14 AND RIGHT(BETTEAM,1) = '2' AND statusID NOT IN (101,102))
			SELECT @IsExistLG = 1

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
END 
ELSE
BEGIN
	IF EXISTS (select top 1 1 from bettrans WITH (NOLOCK) WHERE matchid = @matchid AND bettype = 14 AND RIGHT(BETTEAM,1) = '2' AND statusID NOT IN (101,102,103))
		SELECT @IsExistLG = 1
	ELSE
		IF EXISTS (select top 1 1 from bettransm WITH (NOLOCK) WHERE matchid = @matchid AND bettype = 14 AND RIGHT(BETTEAM,1) = '2' AND statusID NOT IN (101,102,103))
			SELECT @IsExistLG = 1

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
END
if
( 
	exists
	(
		select	1 
		from	match m with (nolock) 
				inner join match_remark mr with (nolock) on m.matchid = mr.matchid
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
		CASE -- 0:FT , 1:HT , 2:FGLG
			WHEN bettype IN (7, 8, 12, 15, 21, 30, 125) THEN 1
			WHEN bettype = 14 THEN 2
			ELSE 0 END,
		--SUM(CASE WHEN [status] IN (N'VOID',N'REJECT') THEN 0 ELSE 1 END),
		SUM(CASE WHEN [statusID] IN (101,102) THEN 0 ELSE 1 END),
		--SUM(CASE WHEN [status] = N'running' THEN 1 ELSE 0 END)
		SUM(CASE WHEN [statusID] = 0 THEN 1 ELSE 0 END)
	FROM
		bettrans with (nolock)
	WHERE
		matchid = @matchid
	GROUP BY
		CASE WHEN bettype IN (7, 8, 12, 15, 21, 30, 125) THEN 1 WHEN bettype = 14 THEN 2 ELSE 0 END

IF NOT EXISTS(SELECT * FROM @status WHERE [Group] = 0) INSERT INTO @status VALUES (0,0,0)
IF NOT EXISTS(SELECT * FROM @status WHERE [Group] = 1) INSERT INTO @status VALUES (1,0,0)
IF NOT EXISTS(SELECT * FROM @status WHERE [Group] = 2) INSERT INTO @status VALUES (2,0,0)

Declare @FTStatus nvarchar(10), @HTStatus nvarchar(10), @FGLGStatus nvarchar(10)

Select @FTStatus = CASE
		WHEN betcount  = 0 THEN N'No Ticket'
		WHEN inRunning = 0 THEN N'Calculated'
		ELSE N'Running' END FROM @status WHERE [Group] = 0
Select @HTStatus = CASE
		WHEN betcount  = 0 THEN N'No Ticket'
		WHEN inRunning = 0 THEN N'Calculated'
		ELSE N'Running' END FROM @status WHERE [Group] = 1
Select @FGLGStatus = CASE
		WHEN betcount  = 0 THEN N'No Ticket'
		WHEN inRunning = 0 THEN N'Calculated'
		ELSE N'Running' END FROM @status WHERE [Group] = 2

IF EXISTS(select top 1 1 from bettrans (nolock) where matchid = @matchid AND liveindicator = 1)
	Select @IsLive = 1		

select	match.sporttype, match.betstatus, hthomescore_ext,htawayscore_ext,
		datediff(minute,kickofftime,CURRENT_TIMESTAMP) playtime,	
		match.leagueid,
		match.matchid,  
		match.homeid,
		match.awayid,	
		match.matchcode,match.kickofftime,
		match.finalhomescore_ext finalhomescore,match.finalawayscore_ext finalawayscore,
		match.eventstatus_ext eventstatus,
		isnull(mr.refund_ext,0) IsRefund, isnull(mr.calrefund_ext,0) IsCalRefund,
		isnull(mr.calculate_ext,0) IsCalculated, isnull(mr.multiple_ext,0) IsMultiCaled,
		isnull(match.isNeutral, CONVERT(BIT,0)) as IsNeutral,
		mr.ishtcal,
		match.GoalRecord_ext as GoalRecord,
		@HTStatus HTStatus,
		@FTStatus FTStatus,
		@FGLGStatus fglgstatus,
		@IsExistFGLG AS IsExistFGLG,
		@IsExistLG AS IsExistLG,		
		@IsHTOnly as IsHTOnly,	
		@IsLive as IsLive,
		@DelayTime DelayTime		
from	match with (nolock) 	
		left outer join match_remark mr with (nolock) on match.matchid = mr.matchid
where match.matchid = @matchid
GRANT EXECUTE ON [dbo].[Acc_Set_MatchSelDetail] TO [aplweb]	
