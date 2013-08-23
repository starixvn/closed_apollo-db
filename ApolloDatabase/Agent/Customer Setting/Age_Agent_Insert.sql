USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_Insert]    Script Date: 8/23/2013 9:34:40 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_Insert]
	@AgentId			INT,
	@Username			NVARCHAR(50),
	@ParentId			INT,
	@Currency			INT,
	@Status				TINYINT			= 1,
	@BetStatus			TINYINT			= 1,
	@UplineStatus		TINYINT			= 1,
	@UplineBetStatus	TINYINT			= 1,
	@MatchLimit			SMALLMONEY		= 0,
	@VirtualMultiplier	SMALLMONEY		= 1,
	@DoubleCommLosing	BIT				= 0,
	@Creator			INT				= NULL,
	@ErrCode			INT				= 0			OUTPUT,
	@ErrMsg				NVARCHAR(1000)	= ''		OUTPUT 
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Add new agent information and default setting
 * DB			: APL.CustDB
 * Revisions	:
 *	• 20130227@Edward	: Implement
 *	• 20130412@Kos		: Remove AgentUserId
 *	• 20130415@Edward	: Write log
 *	• 20130424@Kos		: Remove Credit
 *	• 20130823@Kos		: Add 
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON

	-- Set default creator is parent agent
	IF @Creator IS NULL
		SET @Creator = @ParentId

	-- Check if agent ID exists
	IF EXISTS ( SELECT 1 FROM AgentInfo WITH (NOLOCK) WHERE AgentId = @AgentId )
		BEGIN
			SELECT 
				@ErrCode = 5101, 
				@ErrMsg = 'Agent ID duplicated [AgentId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	-- Check if username exists
	IF EXISTS ( SELECT 1 FROM AgentInfo WITH (NOLOCK) WHERE Username = @Username )
		BEGIN
			SELECT 
				@ErrCode = 5103, 
				@ErrMsg = 'Username duplicated [Username = ' + COALESCE(@Username, SPACE(1)) + ']'
			RETURN
		END	

	-- Check if agent user ID exists
	IF EXISTS ( SELECT 1 FROM AgentUser WITH (NOLOCK) WHERE AgentUserId = @AgentId )
		BEGIN
			SELECT 
				@ErrCode = 5301, 
				@ErrMsg = 'Agent user ID duplicated [AgentUserId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	-- Check if username exists
	IF EXISTS ( SELECT 1 FROM AgentUser WITH (NOLOCK) WHERE Username = @Username )
		BEGIN
			SELECT 
				@ErrCode = 5303, 
				@ErrMsg = 'Username duplicated [Username = ' + COALESCE(@Username, SPACE(1)) + ']'
			RETURN
		END	

	-- Check if parent ID not exist
	IF NOT EXISTS ( SELECT 1 FROM AgentInfo WITH (NOLOCK) WHERE AgentId = @ParentId )
		BEGIN
			SELECT 
				@ErrCode = 5101, 
				@ErrMsg = 'Parent ID not exist [ParentId = ' + COALESCE(CAST(@ParentId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	-- For write log
	DECLARE 
		@startRun					DATETIME,
		@endRun						DATETIME,
		@duration					INT,
		@logAgentSPData				NVARCHAR(MAX),
		@logAgentUserSPData			NVARCHAR(MAX),
		@logDiscountSpData			NVARCHAR(MAX),
		@logBetLimitSpData			NVARCHAR(MAX),
		@logPositionTakingSpData	NVARCHAR(MAX),
		@xml						XML

	SET @startRun = GETDATE()

	-- Begin update
	DECLARE @UplineNode				HIERARCHYID
			,@LastChild				HIERARCHYID
			,@ParentStatus			TINYINT
			,@ParentBetStatus		TINYINT
			,@ParentUplineStatus	TINYINT
			,@ParentUplineBetStatus	TINYINT
			,@MAINSHAREHOLDERPRESET	SMALLINT		= 1200
			,@MAINSHAREHOLDERMAX	SMALLINT		= 8800			
			,@SHAREHOLDERMAX		SMALLINT		= 5000
			,@SHAREHOLDERMIN		SMALLINT		= 5000
			,@agentLevel			SMALLINT
			,@MAINSHAREHOLDERLEVEL	SMALLINT		= 1
			,@SHAREHOLDERLEVEL		SMALLINT		= 2

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

	-- Get upline status if not a main shareholder
	IF @ParentId > 1
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
		@Currency,
		@ParentId,
		0,				-- AutoSuspend
		@MatchLimit,
		@VirtualMultiplier,
		@DoubleCommLosing,
		@Status,
		@BetStatus,
		@UplineStatus,
		@UplineBetStatus
	)	

	SELECT @agentLevel = AgentLevel FROM AgentInfo WITH (NOLOCK) WHERE AgentId = @AgentId

	-- Not support for multiple language
	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 5104, 
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

	-- Check error
	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 5304, 
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
		MinBet,			-- MinBet
		MaxBet,			-- MaxBet
		MaxPerMatch		-- MaxPerMatch
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
		DiscountA,		-- DiscountA
		DiscountB,		-- DiscountB
		DiscountC,		-- DiscountC
		DiscountD		-- DiscountD
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
		CASE 
			WHEN @agentLevel > @SHAREHOLDERLEVEL		THEN MaxGivenPositionTaking
			WHEN @agentLevel = @SHAREHOLDERLEVEL		THEN 0
			WHEN @agentLevel = @MAINSHAREHOLDERLEVEL	THEN @MAINSHAREHOLDERPRESET 			
		END ,		-- max upper
		CASE 
			WHEN @agentLevel > @SHAREHOLDERLEVEL		THEN 0
			WHEN @agentLevel = @SHAREHOLDERLEVEL		THEN MaxGivenPositionTaking
			WHEN @agentLevel = @MAINSHAREHOLDERLEVEL	THEN @MAINSHAREHOLDERMAX
		END ,			-- max given
		CASE 
			WHEN @agentLevel = @SHAREHOLDERLEVEL THEN @SHAREHOLDERMIN									
			ELSE 0
		END 			-- min given
	FROM AgentPositionTaking WITH (NOLOCK)
	WHERE AgentId = @ParentId		

	-- Write log for insert agent
	SET @xml = (
		SELECT	
			@Username			AS '@u',
			(SELECT Username FROM AgentInfo WITH (NOLOCK) WHERE AgentId = @ParentId)				AS '@p',
			(SELECT currency FROM SVRAGE.RepDB.dbo.Exchange WITH (NOLOCK) WHERE exchangeid = @Currency)	AS '@c',
			@Status				AS '@s',
			@BetStatus			AS '@bs',
			@UplineStatus		AS '@us',
			@UplineBetStatus	AS '@ubs',
			@MatchLimit			AS '@ml',
			@VirtualMultiplier	AS '@vm',
			@DoubleCommLosing	AS '@dc'
		 FOR XML PATH('z'), ROOT('r')
	)

	SET @logAgentSPData = REPLACE(CONVERT(NVARCHAR(MAX), @xml), '" />', '"/"')

	-- Write log for insert agent user
	SET @xml = (
		SELECT	
			@Username	AS '@u',
			@Username	AS '@a',
			''			AS '@pa',
			1			AS '@im',
			@Status		AS '@s'
		 FOR XML PATH('z'), ROOT('r')
	)

	SET @logAgentUserSPData = REPLACE(CONVERT(NVARCHAR(MAX), @xml), '" />', '"/"')

	-- Write log bet limit for agent
	SET @xml = (
		SELECT  
			SportType		AS '@s'
			,BetType		AS '@b'
			,MinBet			AS '@mib'
			,MaxBet			AS '@mab'
			,MaxPerMatch	AS '@mam'
		FROM AgentBetLimit WITH (NOLOCK)
		WHERE AgentId = @AgentId 
		FOR XML PATH('z'), ROOT('r')
	)

	SET @logBetLimitSpData = REPLACE(CONVERT(NVARCHAR(MAX), @xml), '" />', '"/"')

	-- Write log discount for agent
	SET @xml = (
		SELECT  
			SportType	AS '@s'
			,BetType	AS '@b'
			,DiscountA	AS '@ga'
			,DiscountB	AS '@gb'
			,DiscountC	AS '@gc'
			,DiscountD	AS '@gd'
		FROM AgentDiscount WITH (NOLOCK)
		WHERE AgentId = @AgentId
		FOR XML PATH('z'),ROOT('r')
	)

	SET @logDiscountSpData = REPLACE(CONVERT(NVARCHAR(MAX), @xml), '" />', '"/"')

	-- Write position taking for agent
	SET @xml = (
		SELECT  
			SportType				AS '@s'
			,BetType				AS '@b'
			,IsLive					AS '@i'
			,MaxUpperPositionTaking	AS '@p'
			,MaxGivenPositionTaking	AS '@ma'
			,MinGivenPositionTaking	AS '@mi'
		FROM AgentPositionTaking WITH (NOLOCK)
		WHERE AgentId = @AgentId 
		FOR XML PATH('z'), ROOT('r')
	)

	SET @logPositionTakingSpData = REPLACE(CONVERT(NVARCHAR(MAX), @xml), '" />', '"/"')

	SET @endRun = GETDATE()
	SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun) 	

	IF @@ERROR = 0
		BEGIN TRY
			EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpAgent
				@UserId		= @Creator,
				@SPName		= 'Age_Agent_Insert',
				@LogDate	= @startRun,
				@AgentId	= @AgentId,
				@Duration	= @Duration,
				@Data		= @logAgentSPData,
				@OldData	= NULL

			EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpAgent
				@UserId		= @Creator,
				@SPName		= 'Age_AgentUser_Insert',
				@LogDate	= @startRun,
				@AgentId	= @AgentId,
				@Duration	= @Duration,
				@Data		= @logAgentUserSPData,
				@OldData	= NULL

			EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpAgent
				@UserId		= @Creator,
				@AdminId	= NULL,
				@SPName		= 'Age_Agent_InsertBetLimit',
				@LogDate	= @startRun,
				@AgentId	= @AgentId,
				@Duration	= @Duration,
				@Data		= @logBetLimitSpData,
				@OldData	= NULL

			EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpAgent
				@UserId		= @Creator,
				@AdminId	= NULL,
				@SPName		= 'Age_Agent_InsertDiscount',
				@LogDate	= @startRun,
				@AgentId	= @AgentId,
				@Duration	= @Duration,
				@Data		= @logDiscountSpData,
				@OldData	= NULL

			EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpAgent
				@UserId		= @Creator,
				@AdminId	= NULL,
				@SPName		= 'Age_Agent_InsertPositionTaking',
				@LogDate	= @startRun,
				@AgentId	= @AgentId,
				@Duration	= @Duration,
				@Data		= @logPositionTakingSpData,
				@OldData	= NULL
		END	TRY
		BEGIN CATCH
			EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpAgent
				@UserId		= @Creator,
				@SPName		= 'Age_Agent_Insert',
				@LogDate	= @startRun,
				@AgentId	= @AgentId,
				@Duration	= @Duration,
				@Data		= @logAgentSPData,
				@OldData	= NULL

			EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpAgent
				@UserId		= @Creator,
				@SPName		= 'Age_AgentUser_Insert',
				@LogDate	= @startRun,
				@AgentId	= @AgentId,
				@Duration	= @Duration,
				@Data		= @logAgentUserSPData,
				@OldData	= NULL

			EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpAgent
				@UserId		= @Creator,
				@AdminId	= NULL,
				@SPName		= 'Age_Agent_InsertBetLimit',
				@LogDate	= @startRun,
				@AgentId	= @AgentId,
				@Duration	= @Duration,
				@Data		= @logBetLimitSpData,
				@OldData	= NULL

			EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpAgent
				@UserId		= @Creator,
				@AdminId	= NULL,
				@SPName		= 'Age_Agent_InsertDiscount',
				@LogDate	= @startRun,
				@AgentId	= @AgentId,
				@Duration	= @Duration,
				@Data		= @logDiscountSpData,
				@OldData	= NULL

			EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpAgent
				@UserId		= @Creator,
				@AdminId	= NULL,
				@SPName		= 'Age_Agent_InsertPositionTaking',
				@LogDate	= @startRun,
				@AgentId	= @AgentId,
				@Duration	= @Duration,
				@Data		= @logPositionTakingSpData,
				@OldData	= NULL
		END CATCH	
END
