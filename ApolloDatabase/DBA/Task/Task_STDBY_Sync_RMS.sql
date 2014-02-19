USE [bodb_RMS]
GO
/****** Object:  StoredProcedure [dbo].[Task_STDBY_Sync_RMS]    Script Date: 01/21/2014 03:56:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Task_STDBY_Sync_RMS]

AS 
/*
	Created by: Dan 
	Date: 2014-01-21
	Task: Synchronize data bodb_RMS 
			+ rmCustomer 
			
	Revisions:
	

*/
BEGIN
	SET NOCOUNT ON
	DECLARE	 @ctCurrentVersion			BIGINT
			,@ctLastSyncVersion			BIGINT
			,@ctMinVersionRMCustomer	BIGINT
			,@rowcntRMCustomer			BIGINT

	SELECT	 @ctCurrentVersion			= CHANGE_TRACKING_CURRENT_VERSION()
			,@ctMinVersionRMCustomer	= 0
			
	SELECT	@ctLastSyncVersion = LastSyncVersion
	FROM	dbo.rmCTLastSyncVersion WITH (NOLOCK)
	WHERE	CTID = 1 
	
	IF	@ctLastSyncVersion >= @ctCurrentVersion RETURN	-- No changes 
	
	DECLARE	@tmpRMCustomer TABLE(
		 ChangedVersion		BIGINT
		,ChangedOperation	NVARCHAR(1)
		,CustID				INT
		,UserName			VARCHAR(30)
		,Level				TINYINT
		,CreatedDate		DATETIME NULL
		,Creator			INT	NULL
	)
	
	INSERT INTO @tmpRMCustomer(
		 ChangedVersion
		,ChangedOperation
		,CustID
		,UserName
		,Level
		,CreatedDate
		,Creator	
	)
	
	SELECT   c.SYS_CHANGE_VERSION
			,c.SYS_CHANGE_OPERATION 
			,c.CustID
			,rmC.username
			,rmC.[level]
			,rmC.createdDate
			,rmC.creator
	FROM	CHANGETABLE(CHANGES dbo.rmCustomer,@ctLastSyncVersion) AS c
			LEFT JOIN dbo.rmCustomer rmC WITH (NOLOCK) ON c.CustID = rmC.custid
	WHERE	c.SYS_CHANGE_VERSION BETWEEN @ctMinVersionRMCustomer AND @ctCurrentVersion 
		
	SELECT	@rowcntRMCustomer = @@ROWCOUNT 
	
	IF @rowcntRMCustomer <> 0 
	BEGIN
		INSERT INTO SVRRMS_STDBY.bodb_RMS.dbo.RMCustomer(
			 CustID
			,UserName
			,Level
			,CreatedDate
			,Creator	
		)
		SELECT  tc.CustID
				,tc.UserName
				,tc.Level
				,tc.CreatedDate
				,tc.Creator
		FROM	@tmpRMCustomer tc 
				LEFT JOIN SVRRMS_STDBY.bodb_RMS.dbo.RMCustomer rmc WITH (NOLOCK) ON tc.CustID = rmc.CustID
		WHERE	tc.ChangedOperation ='I'
				AND rmc.CustID IS NULL
		
		
		UPDATE	rmc WITH (UPDLOCK,ROWLOCK)
		SET		 rmc.UserName		= tc.UserName
				,rmc.Level			= tc.Level
				,rmc.CreatedDate	= tc.CreatedDate
				,rmc.Creator		= tc.Creator 
		FROM	@tmpRMCustomer tc
				INNER JOIN SVRRMS_STDBY.bodb_RMS.dbo.RMCustomer rmc ON tc.CustID = rmc.CustID
		WHERE	tc.ChangedOperation IN ('I','U')
				AND rmc.CustID IS NOT NULL 			
		
		DELETE	rmc WITH (UPDLOCK,ROWLOCK)
		FROM	@tmpRMCustomer tc
				INNER JOIN SVRRMS_STDBY.bodb_RMS.dbo.RMCustomer rmc ON tc.CustID = rmc.CustID
		WHERE	tc.ChangedOperation IN ('D')
	
	END
	UPDATE	dbo.rmCTLastSyncVersion WITH (UPDLOCK,ROWLOCK)
	SET		 LastSyncVersion = @ctCurrentVersion 
			,ExtractionDate	= GETDATE()
	WHERE	CTID = 1
	
	PRINT  @ctCurrentVersion

END