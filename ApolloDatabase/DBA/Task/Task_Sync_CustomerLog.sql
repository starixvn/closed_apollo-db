ALTER PROCEDURE [dbo].[Task_Sync_CustomerLog]	
AS
/*   
 Task : copy CustomerLog data from active server to standby server
 DB: DB054.bodb_customerLog, DB052.bodb_customerLog  
 Revisions:   
  
*/  
SET NOCOUNT ON
BEGIN
	DECLARE @localServer sysname, @remoteServer sysname
	
	SET @localServer = @@servername
	SET @remoteServer = (SELECT * FROM OPENQUERY (SVRLOG, 'select @@servername'))
	--SELECT @localServer, @remoteServer
	
	-- invalid remote server
	IF @localServer = @remoteServer RETURN -- same server, do nothing.
		
	DECLARE @max_id bigint, @startday smalldatetime, @logdate datetime
	SET @startday = DATEADD(dd, -1, CURRENT_TIMESTAMP)				
		
	---- UserLog_Exchange ---
	select @max_id = isnull(max(logid),-1), @logdate = ISNULL(MAX(logdate),@startday)
	FROM dbo.Exchange with(nolock)
	WHERE LogDate >= @startday

	--IF @max_id <> -1
	BEGIN	
		SET IDENTITY_INSERT dbo.Exchange ON
		INSERT INTO dbo.Exchange (
			LogID, UserID, ExchangeID, actualrate, doing, IP, LogDate
		)
		SELECT LogID, UserID, ExchangeID, actualrate, doing, IP, LogDate
		FROM SVRLOG.LogDB.dbo.Exchange with(nolock)
		WHERE LogDate >= @logdate
			and LogID > @max_id		
		SET IDENTITY_INSERT dbo.Exchange OFF
	END	
	---- /UserLog_Exchange ---
	
	---- LoginAgent ---
	select @max_id = isnull(max(logid),-1), @logdate = ISNULL(MAX(logdate),@startday)
	FROM dbo.LoginAgent with(nolock)
	WHERE LogDate >= @startday
	
	--IF @max_id <> -1
	BEGIN	
		SET IDENTITY_INSERT dbo.LoginAgent ON
		INSERT INTO dbo.LoginAgent (
			[LogId], [AgentId],[AgentUserId],[ServerId],[IP],[LogDate],[ActionId],[Doing],
			[DomainName] ,[BrowserName] ,[Platform] ,[CountryCode] ,[Duration]
		)		
		SELECT 	[LogId], [AgentId],[AgentUserId],[ServerId],[IP],[LogDate],[ActionId],[Doing],
			[DomainName] ,[BrowserName] ,[Platform] ,[CountryCode] ,[Duration]
		FROM SVRLOG.LogDB.dbo.LoginAgent with(nolock)
		WHERE LogDate >= @logdate
			and LogID > @max_id		
		SET IDENTITY_INSERT dbo.LoginAgent OFF
	END	
	---- /LoginAgent ---
	
	---- RunSpAgent ---
	select @max_id = isnull(max(logid),-1), @logdate = ISNULL(MAX(logdate),@startday)
	FROM dbo.RunSpAgent with(nolock)
	WHERE LogDate >= @startday
	
	--IF @max_id <> -1
	BEGIN	
		SET IDENTITY_INSERT dbo.RunSpAgent ON
		INSERT INTO dbo.RunSpAgent (
			[LogId],[UserId],[SPName],[LogDate],[AgentId],[ActionId],[Duration],[Data],[OldData]
		)
		SELECT [LogId],[UserId],[SPName],[LogDate],[AgentId],[ActionId],[Duration],[Data],[OldData]
		FROM SVRLOG.LogDB.dbo.RunSpAgent with(nolock)
		WHERE LogDate >= @logdate
			and LogID > @max_id		
		SET IDENTITY_INSERT dbo.UserLog_RunSP OFF
	END	
	---- /RunSpAgent ---

	---- RunSpAgent ---
	select @max_id = isnull(max(logid),-1), @logdate = ISNULL(MAX(logdate),@startday)
	FROM dbo.RunSpCust with(nolock)
	WHERE LogDate >= @startday
	
	--IF @max_id <> -1
	BEGIN	
		SET IDENTITY_INSERT dbo.RunSpCust ON
		INSERT INTO dbo.RunSpCust (			
			[LogId],[UserId] ,[SPName],[LogDate],[CustId] ,[ActionId],[Duration],[Data],[OldData]
		)
		SELECT [LogId],[UserId] ,[SPName],[LogDate],[CustId] ,[ActionId],[Duration],[Data],[OldData]
		FROM SVRLOG.LogDB.dbo.RunSpCust with(nolock)
		WHERE LogDate >= @logdate
			and LogID > @max_id		
		SET IDENTITY_INSERT dbo.RunSpCust OFF
	END	
	---- /RunSpAgent ---
	
	---- Settlement ---
	select @max_id = isnull(max(logid),-1), @logdate = ISNULL(MAX(logdate),@startday)
	FROM dbo.Settlement with(nolock)
	WHERE LogDate >= @startday
	
	--IF @max_id <> -1
	BEGIN	
		SET IDENTITY_INSERT dbo.Settlement ON
		INSERT INTO dbo.Settlement (
			LogID, LogDate, UserID, MatchID, ActionID, finalhomescore, finalawayscore, 
			hthomescore, htawayscore, GoalRecord, betstatus, Remark, IP
		)
		SELECT LogID, LogDate, UserID, MatchID, ActionID, finalhomescore, finalawayscore, 
			hthomescore, htawayscore, GoalRecord, betstatus, Remark, IP
		FROM SVRLOG.LogDB.dbo.Settlement with(nolock)
		WHERE LogDate >= @logdate
			and LogID > @max_id		
		SET IDENTITY_INSERT dbo.UserLog_Settle OFF
	END	
	---- /Settlement ---
	
	
	---- Settlement_Checking ---
	select @max_id = isnull(max(logid),-1), @logdate = ISNULL(MAX(logdate),@startday)
	FROM dbo.Settlement_Checking with(nolock)
	WHERE LogDate >= @startday
	
	--	IF @max_id <> -1
	BEGIN	
		SET IDENTITY_INSERT dbo.Settlement_Checking ON
		INSERT INTO dbo.Settlement_Checking (
			LogID, LogDate, UserID, MatchID, KeyID, ActionID, Remark
		)
		SELECT LogID, LogDate, UserID, MatchID, KeyID, ActionID, Remark
		FROM SVRLOG.LogDB.dbo.Settlement_Checking with(nolock)
		WHERE LogDate >= @logdate
			and LogID > @max_id		
		SET IDENTITY_INSERT dbo.UserLog_Settle_Checking OFF
	END	
	---- /Settlement_Checking ---

END
SET NOCOUNT OFF

