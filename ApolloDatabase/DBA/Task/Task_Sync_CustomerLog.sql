USE [LogDB]
GO
/****** Object:  StoredProcedure [dbo].[Task_Sync_CustomerLog]    Script Date: 2/17/2014 12:33:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
		WHERE LogDate >= @startday--@logdate
			and LogID > @max_id		
		SET IDENTITY_INSERT dbo.RunSpAgent OFF
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
		WHERE LogDate >= @startday--@logdate
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
		SET IDENTITY_INSERT dbo.Settlement OFF
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
		SET IDENTITY_INSERT dbo.Settlement_Checking OFF
	END	
	---- /Settlement_Checking ---

		---- SettlementOutright ---
	select @max_id = isnull(max(logid),-1), @logdate = ISNULL(MAX(logdate),@startday)
	FROM dbo.SettlementOutright with(nolock)
	WHERE LogDate >= @startday
	
	--	IF @max_id <> -1
	BEGIN	
		SET IDENTITY_INSERT dbo.SettlementOutright ON
		INSERT INTO dbo.SettlementOutright (
			[LogId]  ,[LogDate]  ,[UserId] ,[OrId],[LeagueId],[ActionId] ,[status] ,[deadheat]
			,[Remark] ,[IP]
		)
		SELECT [LogId]  ,[LogDate]  ,[UserId] ,[OrId],[LeagueId],[ActionId] ,[status] ,[deadheat]
			,[Remark] ,[IP]
		FROM SVRLOG.LogDB.dbo.SettlementOutright with(nolock)
		WHERE LogDate >= @logdate
			and LogID > @max_id		
		SET IDENTITY_INSERT dbo.SettlementOutright OFF
	END	
	---- /Settlement_Checking ---
	---- AutoSettlementCommand_History ---
	select @max_id = isnull(max(execID),-1)
	FROM dbo.AutoSettlementCommand_History with(nolock)	
	
	--	IF @max_id <> -1
	BEGIN	
		
		INSERT INTO dbo.AutoSettlementCommand_History (
			[StatusID]
		  ,[SPName]
		  ,[SQLCommand]
		  ,[ActionId]
		  ,[CreatedDate]
		  ,[ExecutedDate]
		  ,[RetryCount]
		  ,[MatchID]
		  ,[Status]
		  ,[Duration]
		  ,[AllowedDate]
		)
		SELECT [StatusID]
		  ,[SPName]
		  ,[SQLCommand]
		  ,[ActionId]
		  ,[CreatedDate]
		  ,[ExecutedDate]
		  ,[RetryCount]
		  ,[MatchID]
		  ,[Status]
		  ,[Duration]
		  ,[AllowedDate]
		FROM SVRLOG.LogDB.dbo.AutoSettlementCommand_History with(nolock)
		WHERE execID > @max_id				
	END	
	---- /AutoSettlementCommand_History ---
	---- /Settlement_Checking ---
	---- rmUserLog_RunSP ---
	select @max_id = isnull(max(LogID),-1)
	FROM dbo.rmUserLog_RunSP with(nolock)	
	
	--	IF @max_id <> -1
	BEGIN			
		SET IDENTITY_INSERT dbo.[rmUserLog_RunSP] ON
		INSERT INTO [dbo].[rmUserLog_RunSP]
			   ([LogID],
				[UserID]
			   ,[Logdate]
			   ,[CustID]
			   ,[ActionID]
			   ,[TrackingValue]
			   ,[Duration]
			   ,[TrackingValue2])
		SELECT [LogID]
			  ,[UserID]
			  ,[Logdate]
			  ,[CustID]
			  ,[ActionID]
			  ,[TrackingValue]
			  ,[Duration]
			  ,[TrackingValue2]
		FROM SVRLOG.LogDB.dbo.[rmUserLog_RunSP] WITH(NOLOCK)
		WHERE LogID > @max_id				

		SET IDENTITY_INSERT dbo.[rmUserLog_RunSP] OFF
	END	
	---- /rmUserLog_RunSP ---
END
SET NOCOUNT OFF


