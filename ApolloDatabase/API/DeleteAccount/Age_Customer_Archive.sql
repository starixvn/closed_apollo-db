USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_Archive]    Script Date: 10/17/2013 3:47:22 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_Archive]
	@CustId		INT,
	@ErrCode	INT				= 0		OUTPUT,
	@ErrMsg		NVARCHAR(1000)	= ''	OUTPUT 
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Archive agent data
 * DB			: SVRCUST.CustDB
 * Revisions	:
 *	• 
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON
	
	--########## Step 1: Check condition #########--

	-- Check if agent ID exists
	IF NOT EXISTS ( SELECT 1 FROM CustInfo WITH (NOLOCK) WHERE CustId = @CustId )
		BEGIN
			SELECT 
				@ErrCode = 5100, 
				@ErrMsg = 'Customer ID not exist [CustId = ' + COALESCE(CAST(@CustId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END
	
	

	-- For write log
	DECLARE 
		@startRun	DATETIME,
		@endRun		DATETIME,
		@duration	INT,
		@logData	NVARCHAR(MAX),
		@xml		XML,
		@agentId	INT,
		@Username	NVARCHAR(50),
		@Currency	int,
		@CurrencyName VARCHAR(5),
		@ActualRate FLOAT, 
		@Now		Datetime

	SELECT	@Username = C.Username, @Currency = C.Currency, @CurrencyName = E.Currency , @ActualRate = E.ActualRate
	FROM	CustInfo C WITH (NOLOCK)
	INNER JOIN  Exchange E WITH (NOLOCK)  
			ON C.Currency = E.ExchangeId
	WHERE	CustId = @CustId
 
 	SELECT   @Now = CURRENT_TIMESTAMP
	SELECT   @startRun = @Now

	
	IF EXISTS (	 SELECT 1 FROM SVRTXN.TransDB.dbo.bettrans WITH (NOLOCK) WHERE custid = @CustId And bettype NOT IN (19999,20000))
	BEGIN
		SELECT @ErrMsg = @Username +':'+ 'There is active transactions. Please re-check!!', @ErrCode = 5101
		RETURN
	END

	--########## Step 2: Archive #########--

	-- Archive AgentInfo
	INSERT INTO SVRCUSTARC.CustArchiveDB.dbo.CustInfo (
		CustId,
		AgentId,
		Username,
		Currency,
		AutoSuspend,
		MatchLimit,
		VirtualMultiplier,
		Danger,
		Creator,
		CreateDate,
		LastLogged,
		IPLogin,
		UGroup,
		DoubleCommLosing,
		Status,
		BetStatus,
		UplineStatus,
		UplineBetStatus,
		IsUGroupChanged,
		ArchiveDate
	)
	SELECT 
		CustId,
		AgentId,
		Username,
		Currency,
		AutoSuspend,
		MatchLimit,
		VirtualMultiplier,
		Danger,
		Creator,
		CreateDate,
		LastLogged,
		IPLogin,
		UGroup,
		DoubleCommLosing,
		Status,
		BetStatus,
		UplineStatus,
		UplineBetStatus,
		IsUGroupChanged,
		@Now
	FROM CustInfo WITH (NOLOCK)
	WHERE CustId = @CustId

	-- Check error
	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 5206, 
				@ErrMsg = 'Failed to archive customer [CustId = ' + COALESCE(CAST(@CustId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	-- Archive agent bet limit
	INSERT INTO SVRCUSTARC.CustArchiveDB.dbo.CustBetLimit (
		CustId,
		SportType,
		BetType,
		MinBet,
		MaxBet,
		MaxPerMatch,
		ArchiveDate)
	SELECT 	
		CustId,
		SportType,
		BetType,
		MinBet,			
		MaxBet,			
		MaxPerMatch,
		@Now
	FROM CustBetLimit WITH (NOLOCK)
	WHERE CustId = @CustId

	-- Check error
	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 5207, 
				@ErrMsg = 'Failed to archive customer bet limit [CustId = ' + COALESCE(CAST(@CustId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	-- Archive agent discount
	INSERT INTO SVRCUSTARC.CustArchiveDB.dbo.CustDiscount (
		CustId,
		SportType,
		BetType,
		Discount,
		ArchiveDate)
	SELECT 
		CustId,
		SportType,
		BetType,
		Discount,
		@Now
	FROM CustDiscount WITH (NOLOCK)
	WHERE CustId = @CustId

	-- Check error
	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 5208, 
				@ErrMsg = 'Failed to archive customer discount [CustId = ' + COALESCE(CAST(@CustId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	
	--########## Step 3: Clear balance #########--
	
	 EXEC	SVRTXN.TransDB.dbo.Age_Customer_ClearBalance 	
			@CustID = @CustID ,	@Username = @Username, @Currency = @Currency, @CurrencyName = @CurrencyName,
			@ActualRate = @ActualRate, @ErrCode = @ErrCode OUTPUT,	@ErrMsg = @ErrMsg OUTPUT
	
	IF @ErrCode <> 0 RETURN

	--########## Step 4: Delete Data  #########--

	-- Delete data in CustDB
	DELETE FROM CustInfo WITH (ROWLOCK)
	WHERE CustId = @CustId

	DELETE FROM CustBetLimit WITH (ROWLOCK)
	WHERE CustId = @CustId

	DELETE FROM CustDiscount WITH (ROWLOCK)
	WHERE CustId = @CustId

	-- Write log for archive agent
	SET @xml = (
		SELECT	
			@CustId		AS '@c',
			@username	AS '@u'
		FOR XML PATH('z'), ROOT('r')
	)

	SET @logData = REPLACE(CONVERT(NVARCHAR(MAX), @xml), '" />', '"/"')

	SET @endRun = GETDATE()
	SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun) 	

	IF @@ERROR = 0
		BEGIN TRY
			EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpCust
				@UserId		= @agentId,
				@SPName		= 'Age_Customer_Archive',
				@LogDate	= @startRun,
				@CustId		= @CustId,
				@Duration	= @Duration,
				@Data		= @logData,
				@OldData	= NULL
		END	TRY
		BEGIN CATCH
			EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpCust
				@UserId		= @agentId,
				@SPName		= 'Age_Customer_Archive',
				@LogDate	= @startRun,
				@CustId		= @CustId,
				@Duration	= @Duration,
				@Data		= @logData,
				@OldData	= NULL
		END CATCH	
END
