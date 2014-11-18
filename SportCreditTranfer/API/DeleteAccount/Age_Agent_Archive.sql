USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_Archive]    Script Date: 10/25/2013 8:59:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_Archive]
	@AgentId	INT,
	@ErrCode	INT				= 0		OUTPUT,
	@ErrMsg		NVARCHAR(1000)	= ''	OUTPUT 
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Archive agent data
 * DB			: SVRCUST.CustDB
 * Revisions	:
 *	• 20131218@Sophia: revise
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON
	
	--########## Step 1: Check condition #########--

	-- Check if agent ID exists
	IF NOT EXISTS ( SELECT 1 FROM AgentInfo WITH (NOLOCK) WHERE AgentId = @AgentId )
		BEGIN
			SELECT 
				@ErrCode = 5100, 
				@ErrMsg = 'Agent ID not exist [AgentId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	-- Check if child agent exists
	IF EXISTS ( SELECT 1 FROM AgentInfo WITH (NOLOCK) WHERE ParentId = @AgentId )
		BEGIN
			SELECT 
				@ErrCode = 5108, 
				@ErrMsg = 'Downline agent exists [AgentId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	-- Check if direct member exists
	IF EXISTS ( SELECT 1 FROM CustInfo WITH (NOLOCK) WHERE AgentId = @AgentId )
		BEGIN
			SELECT 
				@ErrCode = 5109, 
				@ErrMsg = 'Direct member exists [AgentId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	-- For write log
	DECLARE 
		@startRun	DATETIME,
		@endRun		DATETIME,
		@duration	INT,
		@logData	NVARCHAR(MAX),
		@xml		XML,
		@Username	NVARCHAR(50),
		@Currency	int,
		@CurrencyName VARCHAR(5),
		@ActualRate FLOAT,
		@Now		Datetime
		 
		
		SELECT	@Username = C.Username, @Currency = C.Currency, @CurrencyName = E.Currency , @ActualRate = E.ActualRate
		FROM	AgentInfo C WITH (NOLOCK)
		INNER JOIN Exchange E WITH (NOLOCK)  
				ON C.Currency = E.ExchangeId
		WHERE	AgentID = @AgentID
	 
	 
 		SELECT   @Now = CURRENT_TIMESTAMP
		SELECT   @startRun = @Now
	
	--########## Step 2: Archive data #########--

	-- Archive AgentInfo
	IF NOT EXISTS  (SELECT TOP 1 1 FROM CustArchiveDB.dbo.AgentInfo WITH (NOLOCK)  WHERE AgentID = @AgentId)
	INSERT INTO CustArchiveDB.dbo.AgentInfo (
		AgentId,
		AgentHId,
		AgentLevel,
		Username,
		Currency,
		ParentId,
		AutoSuspend,
		MatchLimit,
		VirtualMultiplier,
		DoubleCommLosing,
		Status,
		BetStatus,
		--UplineStatus,
		--UplineBetStatus,
		ArchiveDate
	)
	SELECT 
		AgentId,
		AgentHId.ToString(),
		AgentLevel,
		Username,
		Currency,
		ParentId,
		AutoSuspend,
		MatchLimit,
		VirtualMultiplier,
		DoubleCommLosing,
		Status,
		BetStatus,
		--UplineStatus,
		--UplineBetStatus,
		GETDATE()
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @AgentId

	-- Check error
	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 5110, 
				@ErrMsg = 'Failed to archive agent [AgentId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	
	-- Archive AgentUser (master and shadow)
	DECLARE @ArchivedAgentUser AS TABLE (AgentUserID INT)

	INSERT INTO	@ArchivedAgentUser 
	SELECT	AgentUserID 	
	FROM	CustArchiveDB.dbo.AgentUser WITH (NOLOCK) 
	WHERE	AgentID = @AgentId	

	------IF NOT EXISTS  (SELECT TOP 1 1 FROM CustArchiveDB.dbo.AgentUser WITH (NOLOCK) WHERE AgentID = @AgentId)
	INSERT INTO CustArchiveDB.dbo.AgentUser (
		AgentUserId,
		AgentId,
		Username,
		IsMaster,
		PageAccess,
		CreateDate,
		Creator,
		LoginCount,
		Status,
		ArchiveDate
	)
	SELECT 
		AgentUserId,
		AgentId,
		Username,
		IsMaster,
		PageAccess,
		CreateDate,
		Creator,
		LoginCount,
		Status,
		GETDATE()
	FROM AgentUser A WITH (NOLOCK)
	WHERE AgentId = @AgentId 
		  AND AgentUserId NOT IN (SELECT AgentUserId FROM @ArchivedAgentUser)

	-- Check error
	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 5111, 
				@ErrMsg = 'Failed to archive agent user [AgentId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	


	-- Archive agent user permission (master and shadow)

	DECLARE @ArchivedAgentUserFunction AS TABLE (AgentUserID INT)

	INSERT INTO	@ArchivedAgentUserFunction
	SELECT	AgentUserID 
	FROM	CustArchiveDB.dbo.AgentUserFunction WITH (NOLOCK) 
	WHERE	AgentID = @AgentId	

	-----IF NOT EXISTS  (SELECT TOP 1 1 FROM CustArchiveDB.dbo.AgentUserFunction WITH (NOLOCK) WHERE AgentID = @AgentId)
	INSERT INTO CustArchiveDB.dbo.AgentUserFunction (
		AgentUserId,
		FunctionId,
		AgentId,
		Policy,
		ArchiveDate
	)
	SELECT 
		AgentUserId,
		FunctionId,
		AgentId,
		Policy,
		GETDATE()
	FROM AgentUserFunction WITH (NOLOCK)
	WHERE AgentId = @AgentId
		AND AgentUserId NOT IN (Select AgentUserId from @ArchivedAgentUserFunction)

	-- Check error
	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 5116, 
				@ErrMsg = 'Failed to archive agent user permission [AgentId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	


	-- Archive agent bet limit
	IF NOT EXISTS  (SELECT TOP 1 1 FROM CustArchiveDB.dbo.AgentBetLimit WITH (NOLOCK) WHERE AgentID = @AgentId)
	INSERT INTO CustArchiveDB.dbo.AgentBetLimit (
		AgentId,
		SportType,
		BetType,
		MinBet,
		MaxBet,
		MaxPerMatch,
		ArchiveDate)
	SELECT 	
		AgentId,
		SportType,
		BetType,
		MinBet,			
		MaxBet,			
		MaxPerMatch,
		GETDATE()
	FROM AgentBetLimit WITH (NOLOCK)
	WHERE AgentId = @AgentId

	-- Check error
	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 5112, 
				@ErrMsg = 'Failed to archive agent bet limit [AgentId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	-- Archive agent discount
	IF NOT EXISTS  (SELECT TOP 1 1 FROM CustArchiveDB.dbo.AgentDiscount WITH (NOLOCK) WHERE AgentID = @AgentId)
	INSERT INTO CustArchiveDB.dbo.AgentDiscount (
		AgentId,
		SportType,
		BetType,
		DiscountA,
		DiscountB,
		DiscountC,
		DiscountD,
		ArchiveDate)
	SELECT 
		AgentId,
		SportType,
		BetType,
		DiscountA,		
		DiscountB,		
		DiscountC,		
		DiscountD,
		GETDATE()
	FROM AgentDiscount WITH (NOLOCK)
	WHERE AgentId = @AgentId

	-- Check error
	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 5113, 
				@ErrMsg = 'Failed to archive agent discount [AgentId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	-- Archive agent position taking
	IF NOT EXISTS  (SELECT TOP 1 1 FROM CustArchiveDB.dbo.AgentPositionTaking WITH (NOLOCK) WHERE AgentID = @AgentId)
	INSERT INTO CustArchiveDB.dbo.AgentPositionTaking (
		AgentId,
		SportType,
		BetType,
		IsLive,
		MaxUpperPositionTaking,
		MaxGivenPositionTaking,
		MinGivenPositionTaking,
		ArchiveDate)
	SELECT 
		AgentId,
		SportType,
		BetType,
		IsLive,
		MaxUpperPositionTaking,
		MaxGivenPositionTaking,
		MinGivenPositionTaking,
		GETDATE()
	FROM AgentPositionTaking WITH (NOLOCK)
	WHERE AgentId = @AgentId

	-- Check error
	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 5114, 
				@ErrMsg = 'Failed to archive agent position taking [AgentId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	-- Archive agent cust position taking
	IF NOT EXISTS  (SELECT TOP 1 1 FROM CustArchiveDB.dbo.AgentCustPositionTaking WITH (NOLOCK) WHERE AgentCustId = @AgentId)
	INSERT INTO CustArchiveDB.dbo.AgentCustPositionTaking (
		AgentCustId,
		AgentId,
		SportType,
		BetType,
		IsLive,
		PositionTaking,
		ArchiveDate)
	SELECT 
		AgentCustId,
		AgentId,
		SportType,
		BetType,
		IsLive,
		PositionTaking,
		GETDATE()
	FROM AgentCustPositionTaking WITH (NOLOCK)
	WHERE AgentCustId = @AgentId

	-- Check error
	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 5115, 
				@ErrMsg = 'Failed to archive agent cust position taking [AgentId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	----########## Step 3: Clear Balance #########--
	-- EXEC	SVRTXN.TransDB.dbo.Age_Agent_ClearBalance 	
	--		@AgentId = @AgentId ,	@Username = @Username, @Currency = @Currency, @CurrencyName = @CurrencyName,
	--		@ActualRate = @ActualRate, @ErrCode = @ErrCode OUTPUT,	@ErrMsg = @ErrMsg OUTPUT
	
	--IF @ErrCode <> 0 RETURN
		

	--########## Step 4: Delete data #########--
	--------- Delete data in CustDB

	
	DELETE FROM AgentBetLimit WITH (ROWLOCK)
	WHERE AgentId = @AgentId
	-- Check error
			IF @@ERROR > 0
			BEGIN
				SELECT 
					@ErrCode = 5119, 
					@ErrMsg = 'Failed to delete agent bet limit [AgentID = ' + COALESCE(CAST(@AgentID AS VARCHAR(10)), SPACE(1)) + ']'						 
				RETURN
			END	

	DELETE FROM AgentDiscount WITH (ROWLOCK)
	WHERE AgentId = @AgentId
	-- Check error
			IF @@ERROR > 0
			BEGIN
				SELECT 
					@ErrCode = 5120, 
					@ErrMsg = 'Failed to delete agent discount [AgentID = ' + COALESCE(CAST(@AgentID AS VARCHAR(10)), SPACE(1)) + ']'						 
				RETURN
			END	

	DELETE FROM AgentPositionTaking WITH (ROWLOCK)
	WHERE AgentId = @AgentId
	-- Check error
			IF @@ERROR > 0
			BEGIN
				SELECT 
					@ErrCode = 5121, 
					@ErrMsg = 'Failed to delete agent position taking [AgentID = ' + COALESCE(CAST(@AgentID AS VARCHAR(10)), SPACE(1)) + ']'						 
				RETURN
			END	

	DELETE FROM AgentCustPositionTaking WITH (ROWLOCK)
	WHERE  AgentCustId  = @AgentId
	-- Check error
			IF @@ERROR > 0
			BEGIN
				SELECT 
					@ErrCode = 5122, 
					@ErrMsg = 'Failed to delete agent cust position taking [AgentID = ' + COALESCE(CAST(@AgentID AS VARCHAR(10)), SPACE(1)) + ']'						 
				RETURN
			END	

	DELETE FROM AgentUserFunction WITH (ROWLOCK)
	WHERE AgentId = @AgentId
	-- Check error
			IF @@ERROR > 0
			BEGIN
				SELECT 
					@ErrCode = 5123, 
					@ErrMsg = 'Failed to delete agent user permission [AgentID = ' + COALESCE(CAST(@AgentID AS VARCHAR(10)), SPACE(1)) + ']'						 
				RETURN
			END

	DELETE FROM AgentUser WITH (ROWLOCK)
	WHERE AgentId = @AgentId
	-- Check error
			IF @@ERROR > 0
			BEGIN
				SELECT 
					@ErrCode = 5124, 
					@ErrMsg = 'Failed to delete agent user [AgentID = ' + COALESCE(CAST(@AgentID AS VARCHAR(10)), SPACE(1)) + ']'						 
				RETURN
			END		

	DELETE FROM AgentInfo WITH (ROWLOCK)
	WHERE AgentId = @AgentId
		-- Check error
			IF @@ERROR > 0
			BEGIN
				SELECT 
					@ErrCode = 5125, 
					@ErrMsg = 'Failed to delete agent [AgentID = ' + COALESCE(CAST(@AgentID AS VARCHAR(10)), SPACE(1)) + ']'						 
				RETURN
			END	


	-- Write log for archive agent
	SET @xml = (
		SELECT	
			@AgentId	AS '@a',
			@username	AS '@u'
		FOR XML PATH('z'), ROOT('r')
	)

	SET @logData = REPLACE(CONVERT(NVARCHAR(MAX), @xml), '" />', '"/"')

	SET @endRun = GETDATE()
	SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun) 	

	IF @@ERROR = 0
		BEGIN TRY
			EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpAgent
				@UserId		= @AgentId,
				@SPName		= 'Age_Agent_Archive',
				@LogDate	= @startRun,
				@AgentId	= @AgentId,
				@Duration	= @Duration,
				@Data		= @logData,
				@OldData	= NULL
		END	TRY
		BEGIN CATCH
			EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpAgent
				@UserId		= @AgentId,
				@SPName		= 'Age_Agent_Archive',
				@LogDate	= @startRun,
				@AgentId	= @AgentId,
				@Duration	= @Duration,
				@Data		= @logData,
				@OldData	= NULL
		END CATCH	
END
GO

GRANT EXECUTE ON [dbo].[Age_Agent_Archive]  TO [apollo_srv]