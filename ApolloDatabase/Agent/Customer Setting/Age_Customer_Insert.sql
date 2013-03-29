USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_Insert]    Script Date: 3/29/2013 10:42:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_Insert]
	@CustId				INT,	
	@AgentId			INT,
	@Username			VARCHAR(50),
	@Currency			TINYINT,
	@AutoSuspend		BIT,
	@Suspended			BIT,
	@Credit				MONEY,
	@Closed				BIT,
	@MatchLimit			SMALLMONEY,
	@VirtualMultiplier	SMALLMONEY,
	@Enabled			BIT,
	@Danger				TINYINT,
	@Creator			INT,
	@CreateDate			DATETIME,	
	@LastLogged			DATETIME,
	@IPLogin			VARCHAR(40),
	@UGroup				VARCHAR(3),
	@DoubleCommLosing	BIT,	
	@ErrCode			INT				= 0			OUTPUT,
	@ErrMsg				NVARCHAR(1000)	= ''		OUTPUT 
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Add new customer information and default setting
 * DB			: APL.CustDB
 * Revisions	:
 *	• 20132702@Edward	: Implement
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON
		
	---- Insert CustInfo
	INSERT INTO CustInfo(
		CustId,
		AgentId,
		Username,
		Currency,
		AutoSuspend,
		Suspended,
		Credit,
		Closed,
		MatchLimit,
		VirtualMultiplier,
		Enabled,
		Danger,
		Creator,
		CreateDate,
		LastLogged,
		IPLogin,
		UGroup,
		DoubleCommLosing)
	VALUES(
		@CustId,
		@AgentId,
		@Username,
		@Currency,
		@AutoSuspend,
		@Suspended,
		@Credit,
		@Closed,
		@MatchLimit,
		@VirtualMultiplier,
		@Enabled,
		@Danger,
		@Creator,
		@CreateDate,
		@LastLogged,
		@IPLogin,
		@UGroup,
		@DoubleCommLosing)	

	---- Not support for multiple language
	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 1, 
				@ErrMsg = 'Failed to insert customer [CustId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	---- Insert default customer bet limit (from it's parent)
	INSERT INTO CustBetLimit(
		CustId,
		SportType,
		BetType,
		MinBet,
		MaxBet,
		MaxPerMatch)
	SELECT 	
		@CustId,
		SportType,
		BetType,
		MinBet,
		MaxBet,
		MaxPerMatch
	FROM AgentBetLimit WITH (NOLOCK)
	WHERE AgentId = @AgentId

	INSERT INTO CustBetLimit3rd(
		CustId,
		SportType,
		BetType,
		MinBet,
		MaxBet,
		MaxPerMatch,
		MaxPerBall)
	SELECT 	
		@CustId,
		SportType,
		BetType,
		MinBet,
		MaxBet,
		MaxPerMatch,
		MaxPerBall
	FROM AgentBetLimit3rd WITH (NOLOCK)
	WHERE AgentId = @AgentId

	---- Insert default customer discount (From it's parent)
	INSERT INTO CustDiscount(
		CustId,		
		SportType,
		BetType,
		Discount)
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

	INSERT INTO CustDiscount3rd(
		CustId,		
		SportType,
		BetType,
		Discount)
	SELECT 
		@CustId,		
		SportType,
		BetType,
		DiscountA		
	FROM AgentDiscount3rd WITH (NOLOCK)
	WHERE AgentId = @AgentId

	---- Insert default customer position taking (From it's parent)
	INSERT INTO CustPositionTaking(
		CustId,
		AgentId,
		SportType,
		BetType,
		IsLive,
		PositionTaking)
	SELECT
		@CustId,
		@AgentId,
		SportType,
		BetType,
		IsLive,
		MaxPositionTaking
	FROM AgentPositionTaking WITH (NOLOCK)
	WHERE AgentId = @AgentId		

	INSERT INTO CustPositionTaking3rd(
		CustId,
		AgentId,
		SportType,
		BetType,
		IsLive,
		PositionTaking)
	SELECT
		@CustId,
		@AgentId,
		SportType,
		BetType,
		IsLive,
		MaxPositionTaking
	FROM AgentPositionTaking3rd WITH (NOLOCK)
	WHERE AgentId = @AgentId	
		
END
