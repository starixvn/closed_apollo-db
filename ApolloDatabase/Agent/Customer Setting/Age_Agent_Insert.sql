USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_Insert]    Script Date: 4/23/2013 12:45:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_Insert]
	@AgentId				INT,
	@Username				NVARCHAR(50),
	@ParentId				INT,
	@Currency				VARCHAR(3),
	@Status					TINYINT			= 1,
	@BetStatus				TINYINT			= 1,
	@UplineStatus			TINYINT			= 1,
	@UplineBetStatus		TINYINT			= 1,
	@Credit					MONEY			= 0,
	@MatchLimit				SMALLMONEY		= 0,
	@VirtualMultiplier		SMALLMONEY		= 0,
	@DoubleCommLosing		BIT				= 0,
	@Creator				INT				= NULL,
	@LogDate				DATETIME		= NULL,
	@ErrCode				INT				= 0			OUTPUT,
	@ErrMsg					NVARCHAR(1000)	= ''		OUTPUT 
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Add new agent information and default setting
 * DB			: APL.CustDB
 * Revisions	:
 *	• 20130227@Edward	: Implement
 *	• 20130412@Kos		: Remove AgentUserId
 *	• 20130415@Edward	: Write log	and add @LogDate

 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON

	-- For write log
	DECLARE 
		@startRun		DATETIME,
		@endRun			DATETIME,
		@duration		INT,
		@logSPData		VARCHAR(5000),
		@logSPDataOld	VARCHAR(5000),
		@xml			XML

	SET @startRun = GETDATE()

	-- Check if agent ID exists
	IF EXISTS ( SELECT 1 FROM AgentInfo WITH (NOLOCK) WHERE AgentId = @AgentId )
		BEGIN
			SELECT 
				@ErrCode = 1102, 
				@ErrMsg = 'Agent ID duplicated [AgentId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	-- Check if username exists
	IF EXISTS ( SELECT 1 FROM AgentInfo WITH (NOLOCK) WHERE Username = @Username )
		BEGIN
			SELECT 
				@ErrCode = 1104, 
				@ErrMsg = 'Username duplicated [Username = ' + COALESCE(@Username, SPACE(1)) + ']'
			RETURN
		END	

	-- Begin update
	DECLARE @UplineNode				HIERARCHYID
	DECLARE	@LastChild				HIERARCHYID
	DECLARE @ExchangeId				INT
	DECLARE @ParentStatus			TINYINT
	DECLARE @ParentBetStatus		TINYINT
	DECLARE @ParentUplineStatus		TINYINT
	DECLARE @ParentUplineBetStatus	TINYINT

	-- Get parent information
	SELECT	
		@UplineNode = AgentHId,
		@ParentStatus = Status,
		@ParentBetStatus = BetStatus,
		@ParentUplineStatus = UplineStatus,
		@ParentUplineBetStatus = UplineBetStatus
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @ParentId

	-- Get last child hierarchyid 
	SELECT @LastChild = MAX(AgentHId) 
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentHId.GetAncestor(1) = @UplineNode

	SELECT	@ExchangeId = exchangeid
	FROM [SVRTXN].[TransDB].[dbo].[Exchange] WITH (NOLOCK)
	WHERE UPPER(Code) = UPPER(@Currency)

	-- Get upline status if not a main shareholder
	IF @ParentId > 0 
		BEGIN
			SELECT
				@UplineStatus = CASE WHEN @ParentStatus = 2 OR @ParentUplineStatus = 2 THEN 2 ELSE 1 END,
				@UplineBetStatus = CASE WHEN @ParentBetStatus = 2 OR @ParentUplineBetStatus = 2 THEN 2 ELSE 1 END
		END

	-- Insert into AgentInfo
	INSERT INTO AgentInfo (
		AgentId,
		AgentHId,
		Username,
		Currency,
		ParentId,
		AutoSuspend,
		Credit,
		MatchLimit,
		VirtualMultiplier,
		DoubleCommLosing,
		Status,
		BetStatus,
		UplineStatus,
		UplineBetStatus
	)
	VALUES (
		@AgentId,
		@UplineNode.GetDescendant(@LastChild, NULL),
		@Username,
		@ExchangeId,
		@ParentId,
		0,				-- AutoSuspend
		@Credit,
		@MatchLimit,
		@VirtualMultiplier,
		@DoubleCommLosing,
		@Status,
		@BetStatus,
		@UplineStatus,
		@UplineBetStatus
	)	

	-- Not support for multiple language
	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 1105, 
				@ErrMsg = 'Failed to insert agent [AgentId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	-- Insert into AgentUser
	INSERT INTO AgentUser (
		AgentUserId,
		AgentId,
		Username,
		IsMaster,
		PageAccess,
		CreateDate,
		Creator,
		LoginCount,
		Status
	)
	VALUES (
		@AgentId,
		@AgentId,
		@Username,
		1,			-- master
		'',			
		GETDATE(),
		@Creator,
		0,			-- LoginCount
		1			-- Status
	)	

	-- Not support for multiple language
	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 1205, 
				@ErrMsg = 'Failed to insert agent user [AgentUserId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	-- Insert default agent bet limit (from its parent)
	INSERT INTO AgentBetLimit(
		AgentId,
		SportType,
		BetType,
		MinBet,
		MaxBet,
		MaxPerMatch)
	SELECT 	
		@AgentId,
		SportType,
		BetType,
		0,			-- MinBet
		0,			-- MaxBet
		0			-- MaxPerMatch
	FROM AgentBetLimit WITH (NOLOCK)
	WHERE AgentId = @ParentId

	---- Insert default agent discount (from its parent)
	INSERT INTO AgentDiscount(
		AgentId,
		SportType,
		BetType,
		DiscountA,
		DiscountB,
		DiscountC,
		DiscountD)
	SELECT 
		@AgentId,
		SportType,
		BetType,
		0,			-- DiscountA
		0,			-- DiscountB
		0,			-- DiscountC
		0			-- DiscountD
	FROM AgentDiscount WITH (NOLOCK)
	WHERE AgentId = @ParentId

	---- Insert default agent position taking (From it's parent)
	INSERT INTO AgentPositionTaking(
		AgentId,
		SportType,
		BetType,
		IsLive,
		MaxUpperPositionTaking,
		MaxGivenPositionTaking,
		MinGivenPositionTaking)
	SELECT
		@AgentId,
		SportType,
		BetType,
		IsLive,
		0,			-- preset
		0,			-- max
		0			-- min
	FROM AgentPositionTaking WITH (NOLOCK)
	WHERE AgentId = @ParentId		
	-- End update			

	SET @xml = (
		SELECT	
			@Username			AS '@u',
			@ParentId			AS '@p',
			@Currency			AS '@c',
			@Status				AS '@s',
			@BetStatus			AS '@bs',
			@UplineStatus		AS '@us',
			@UplineBetStatus	AS '@ubs',
			@Credit				AS '@cr',
			@MatchLimit			AS '@ml',
			@VirtualMultiplier	AS '@vm',
			@DoubleCommLosing	AS '@dc'
		 FOR XML PATH('z'), ROOT('r')
	)

	SET @logSPData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	SET @endRun = GETDATE()
	SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun) 

	IF @LogDate IS NULL
		SET @LogDate = GETDATE()

	EXEC LogDB.dbo.Age_LogRunSp_Insert
		@UserId			= @Creator,
		@SPName			= 'Age_Agent_Insert',
		@LogDate		= @LogDate,
		@ObjectId		= @AgentId,
		@ObjectTypeId	= 1,			--Object type : Agent
		@Duration		= @Duration,
		@Data			= @logSPData,
		@OldData		= @logSPDataOld
END
