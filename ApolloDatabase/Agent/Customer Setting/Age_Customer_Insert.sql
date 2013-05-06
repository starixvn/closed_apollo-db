USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_Insert]    Script Date: 5/6/2013 12:41:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_Insert]
	@CustId				INT,	
	@Username			NVARCHAR(50),
	@AgentId			INT,	
	@Status				TINYINT			= 1,
	@BetStatus			TINYINT			= 1,
	@MatchLimit			SMALLMONEY		= 0,
	@VirtualMultiplier	SMALLMONEY		= 0,
	@DoubleCommLosing	BIT				= 0,	
	@Danger				TINYINT			= 0,
	@IPLogin			VARCHAR(40)		= NULL,
	@UGroup				VARCHAR(3)		= 'a',				-- Group A
	@Creator			INT				= NULL,
	@ErrCode			INT				= 0			OUTPUT,
	@ErrMsg				NVARCHAR(1000)	= ''		OUTPUT
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Add new customer information and default setting
 * DB			: APL.CustDB
 * Revisions	:
 *	• 20130227@Edward	: Implement
 *	• 20130415@Kos		: Add statuses
 *	• 20130415@Edward	: Write log
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON

	-- Check if customer ID exists
	IF EXISTS ( SELECT 1 FROM CustInfo WITH (NOLOCK) WHERE CustId = @CustId )
		BEGIN
			SELECT 
				@ErrCode = 5201, 
				@ErrMsg = 'Customer ID duplicated [CustId = ' + COALESCE(CAST(@CustId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	-- Check if username exists
	IF EXISTS ( SELECT 1 FROM CustInfo WITH (NOLOCK) WHERE Username = @Username )
		BEGIN
			SELECT 
				@ErrCode = 5203, 
				@ErrMsg = 'Username duplicated [Username = ' + COALESCE(@Username, SPACE(1)) + ']'
			RETURN
		END	

	-- For write log
	DECLARE 
		@startRun		DATETIME,
		@endRun			DATETIME,
		@duration		INT,
		@logSPData		VARCHAR(5000),
		@logSPDataOld	VARCHAR(5000),
		@xml			XML

	SET @startRun = GETDATE()

	SET @UGroup = LOWER(@Ugroup)

	-- Insert into CustInfo
	INSERT INTO CustInfo (
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
		UplineBetStatus )
	SELECT	
		@CustId,
		@AgentId,
		@Username,
		Currency,
		0,					-- AutoSuspend
		@MatchLimit,
		@VirtualMultiplier,
		@Danger,
		@Creator,
		GETDATE(),
		NULL,
		@IPLogin,
		@UGroup,
		@DoubleCommLosing,
		@Status,
		@BetStatus,
		CASE WHEN Status = 2 OR UplineStatus = 2 THEN 2 ELSE 1 END,			-- UplineStatus
		CASE WHEN BetStatus = 2 OR UplineBetStatus = 2 THEN 2 ELSE 1 END	-- UplineBetStatus
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @AgentId

	-- Not support for multiple language
	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 5204, 
				@ErrMsg = 'Failed to insert customer [CustId = ' + COALESCE(CAST(@CustId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END

	-- Insert default customer bet limit (from it's parent)
	INSERT INTO CustBetLimit (
		CustId,
		SportType,
		BetType,
		MinBet,
		MaxBet,
		MaxPerMatch )
	SELECT 	
		@CustId,
		SportType,
		BetType,
		MinBet,
		MaxBet,
		MaxPerMatch
	FROM AgentBetLimit WITH (NOLOCK)
	WHERE AgentId = @AgentId
	
	-- Insert default customer discount (from it's parent)
	INSERT INTO CustDiscount (
		CustId,
		SportType,
		BetType,
		Discount )
	SELECT 
		@CustId,
		SportType,
		BetType,
		CASE  
			WHEN SportType = 1 AND BetType = 1 AND @UGroup = 'a' THEN DiscountA
			WHEN SportType = 1 AND BetType = 1 AND @UGroup = 'b' THEN DiscountB
			WHEN SportType = 1 AND BetType = 1 AND @UGroup = 'c' THEN DiscountC
			WHEN SportType = 1 AND BetType = 1 AND @UGroup = 'd' THEN DiscountD
			ELSE DiscountA
		END
	FROM AgentDiscount WITH (NOLOCK)
	WHERE AgentId = @AgentId

	-- Insert default customer position taking (from it's parent)
	INSERT INTO CustPositionTaking (
		CustId,
		AgentId,
		SportType,
		BetType,
		IsLive,
		PositionTaking )
	SELECT
		@CustId,
		@AgentId,
		SportType,
		BetType,
		IsLive,
		MaxGivenPositionTaking
	FROM AgentPositionTaking WITH (NOLOCK)
	WHERE AgentId = @AgentId	
	
	-- Insert into balance tables 	
	INSERT INTO SVRTXN.TransDB.dbo.BalanceCredit (CustId, Balance)
	VALUES (@CustId, 0)

	INSERT INTO SVRTXN.TransDB.dbo.BalanceDebit (CustId, Balance)
	VALUES (@CustId, 0)

	SET @xml = (
		SELECT	
			@Username			AS '@u',
			@AgentId			AS '@ai',
			@Status				AS '@s',
			@BetStatus			AS '@bs',
			@MatchLimit			AS '@ml',
			@VirtualMultiplier	AS '@vm',
			@DoubleCommLosing	AS '@dc',
			@Danger				AS '@d',
			@IPLogin			AS '@il',
			@UGroup				AS '@ug'
		 FOR XML PATH('z'), ROOT('r')
	)

	SET @logSPData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	SET @endRun = GETDATE()
	SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun) 
		
	IF @@Error = 0
		BEGIN TRY
			EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpCust
			@UserId			= @Creator,
			@SPName			= 'Age_Customer_Insert',
			@LogDate		= @startRun,
			@CustId			= @CustId,
			@Duration		= @Duration,
			@Data			= @logSPData,
			@OldData		= @logSPDataOld
		END	TRY
		BEGIN CATCH
			EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpCust
			@UserId			= @Creator,
			@SPName			= 'Age_Customer_Insert',
			@LogDate		= @startRun,
			@CustId			= @CustId,
			@Duration		= @Duration,
			@Data			= @logSPData,
			@OldData		= @logSPDataOld
		END CATCH
END										