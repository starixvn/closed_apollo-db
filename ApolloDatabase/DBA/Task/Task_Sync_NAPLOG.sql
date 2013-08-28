CREATE PROCEDURE [dbo].[Task_Sync_NAPLOG]	
AS
/*   
 Task : copy NAPLOG data from active server to standby server
 DB: csd standby server
 Revisions:   
  
*/  
SET NOCOUNT ON
BEGIN
	DECLARE @localServer sysname, @remoteServer sysname
	
	SET @localServer = @@servername
	SET @remoteServer = (SELECT * FROM OPENQUERY (SVRCSD, 'select @@servername'))
	--SELECT @localServer, @remoteServer
	
	-- invalid remote server
	IF @localServer = @remoteServer RETURN -- same server, do nothing.
		
	DECLARE @max_id bigint, @startday smalldatetime, @logdate datetime
	SET @startday = DATEADD(dd, -1, CURRENT_TIMESTAMP)				
		
	---- NAPLog_Function ---
	select @max_id = isnull(max(Id),-1) --, @logdate = ISNULL(MAX(logdate),@startday)
	FROM dbo.NAPLog_Function with(nolock)
	--WHERE LogDate >= @startday

	IF @max_id <> -1
	BEGIN	
		SET IDENTITY_INSERT dbo.NAPLog_Function ON
		INSERT INTO dbo.NAPLog_Function (
			[Id], [FunctionId], [SiteId], [UserId], [Params], [LogDate], [IP], [BrowserName]
		)
		SELECT [Id], [FunctionId], [SiteId], [UserId], [Params], [LogDate], [IP], [BrowserName]
		FROM SVRCSD.bodb_NAPLOG.dbo.NAPLog_Function with(nolock)
		WHERE --LogDate >= @logdate
			--and 
			ID > @max_id		
		SET IDENTITY_INSERT dbo.NAPLog_Function OFF
	END	
	---- /UserLog_Exchange ---
	
	---- NAPLog_RUNSP ---
	select @max_id = isnull(max(ID),-1), @logdate = ISNULL(MAX(logdate),@startday)
	FROM dbo.NAPLog_RUNSP with(nolock)
	WHERE LogDate >= @startday
	
	IF @max_id <> -1
	BEGIN	
		SET IDENTITY_INSERT dbo.NAPLog_RUNSP ON
		INSERT INTO dbo.NAPLog_RUNSP (
			[Id],[UserId],[SPName],[ActionId],[ObjectId] ,[ObjectTypeId]
			,[langID],[siteID],[IP],[LogDate],[Duration]
		)		
		SELECT 	[Id],[UserId],[SPName],[ActionId],[ObjectId] ,[ObjectTypeId]
			,[langID],[siteID],[IP],[LogDate],[Duration]
		FROM SVRCSD.bodb_NAPLOG.dbo.NAPLog_RUNSP with(nolock)
		WHERE LogDate >= @logdate
			and ID > @max_id		
		SET IDENTITY_INSERT dbo.NAPLog_RUNSP OFF
	END	
	---- /NAPLog_RUNSP ---
	
	---- NAPLog_RUNSP_Detail ---
		
	IF @max_id <> -1
	BEGIN			
		INSERT INTO dbo.NAPLog_RUNSP_Detail (
			[ID], [ActionID], [Data], [OldData]
		)
		SELECT [ID], [ActionID], [Data], [OldData]
		FROM  SVRCSD.bodb_NAPLOG.dbo.NAPLog_RUNSP_Detail with(nolock)
		WHERE ID > @max_id		
		
	END	
	---- /NAPLog_RUNSP_Detail ---

	---- NAPLog_UserLogin ---
	select @max_id = isnull(max([Id]),-1), @logdate = ISNULL(MAX(logdate),@startday)
	FROM dbo.NAPLog_UserLogin with(nolock)
	WHERE LogDate >= @startday
	
	IF @max_id <> -1
	BEGIN	
		SET IDENTITY_INSERT dbo.NAPLog_UserLogin ON
		INSERT INTO dbo.NAPLog_UserLogin (			
			[Id] ,[UserId],[SiteId],[IP],[LogDate],[Doing],[DomainName]
			,[BrowserName],[Platform],[CountryCode],[Duration]
		)
		SELECT [Id] ,[UserId],[SiteId],[IP],[LogDate],[Doing],[DomainName]
			,[BrowserName],[Platform],[CountryCode],[Duration]
		FROM SVRCSD.bodb_NAPLOG.dbo.NAPLog_UserLogin with(nolock)
		WHERE LogDate >= @logdate
			and [Id] > @max_id
		SET IDENTITY_INSERT dbo.NAPLog_UserLogin OFF
	END	
	---- /NAPLog_UserLogin ---	
END
SET NOCOUNT OFF

