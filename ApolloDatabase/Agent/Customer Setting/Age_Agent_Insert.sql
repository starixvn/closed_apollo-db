USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_Insert]    Script Date: 3/29/2013 10:08:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Age_Agent_Insert]
	@AgentId				INT,
	@AgentUserId			INT,
	@Username				VARCHAR(50),
	@Currency				TINYINT,
	@ParentId				INT,
	@AutoSuspend			BIT				= 0,
	@Suspended				BIT				= 0,
	@Credit					MONEY			= 0,
	@Closed					BIT				= 0,
	@MatchLimit				SMALLMONEY		= 0,
	@VirtualMultiplier		SMALLMONEY		= 0,
	@Enabled				BIT				= 1,
	@DoubleCommLosing		BIT				= 0,
	@PageAccess				VARCHAR(50)		= '',
	@CreateDate				DATETIME,
	@Creator				INT,
	@ErrCode				INT				= 0			OUTPUT,
	@ErrMsg					NVARCHAR(1000)	= ''		OUTPUT 
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Add new agent information and default setting
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

	DECLARE @UplineNode HIERARCHYID,
			@LastChild HIERARCHYID

	---- Get Hierarchyid of UplineID
	SELECT	@UplineNode = AgentHId
	FROM	[CustDB].[dbo].[AgentInfo] WITH (NOLOCK)
	WHERE	AgentId = @ParentId

	---- Get Hierarchyid of of LastChild
	SELECT	@LastChild = Max(AgentHId) 
	FROM	[CustDB].[dbo].[AgentInfo]
	WHERE	AgentHId.GetAncestor(1) = @UplineNode


	---- Insert AgentInfo
	INSERT INTO AgentInfo(
		AgentId,
		AgentHId,
		Username,
		Currency,
		ParentId,
		AutoSuspend,
		Suspended,
		Credit,
		Closed,
		MatchLimit,
		VirtualMultiplier,
		Enabled,
		DoubleCommLosing)
	VALUES(
		 @AgentId,
		@UplineNode.GetDescendant(@LastChild,NULL),
		@Username,
		@Currency,
		@ParentId,
		@AutoSuspend,
		@Suspended,
		@Credit,
		@Closed,
		@MatchLimit,
		@VirtualMultiplier,
		@Enabled,
		@DoubleCommLosing)	

	---- Not support for multiple language
	IF @@ERROR > 0
	BEGIN
		SELECT 
			@ErrCode = 1, 
			@ErrMsg = 'Failed to insert agent [AgentId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
		RETURN
	END	

	---- Insert AgentUser isMaster = true
	INSERT INTO AgentUser(
		AgentUserId,
		AgentId,
		Username,
		IsMaster,
		PageAccess,
		CreateDate,
		Closed,
		Creator,
		LoginCount)
	VALUES(
		@AgentUserId,
		@AgentId,
		@Username,
		1,
		@PageAccess,
		@CreateDate,
		@Closed,
		@Creator,
		0)

	---- Not support for multiple language
	IF @@ERROR > 0
	BEGIN
		SELECT 
			@ErrCode = 1, 
			@ErrMsg = 'Failed to insert agent user [AgentUserId = ' + COALESCE(CAST(@AgentUserId AS VARCHAR(10)), SPACE(1)) + ']'
		RETURN
	END

	---- Insert default agent bet limit (From it's parent)
	INSERT INTO AgentBetLimit(
		AgentId,
		SportType,
		BetType,
		MinBet,
		MaxBet,
		MaxPerMatch)
	SELECT 	
		@AgentId,
		abl.SportType,
		abl.BetType,
		0,
		0,
		0
	FROM AgentBetLimit AS abl WITH (NOLOCK)
	WHERE abl.AgentId = @ParentId

	INSERT INTO AgentBetLimit3rd(
		AgentId,
		SportType,
		BetType,
		MinBet,
		MaxBet,
		MaxPerMatch,
		MaxPerBall)
	SELECT 	
		@AgentId,
		abl.SportType,
		abl.BetType,
		0,
		0,
		0,
		0
	FROM AgentBetLimit3rd AS abl WITH (NOLOCK)
	WHERE abl.AgentId = @ParentId

	---- Insert default agent discount (From it's parent)
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
		ad.SportType,
		ad.BetType,
		0,
		0,
		0,
		0
	FROM AgentDiscount AS ad WITH (NOLOCK)
	WHERE ad.AgentId = @ParentId

	INSERT INTO AgentDiscount3rd(
		AgentId,
		SportType,
		BetType,
		DiscountA,
		DiscountB,
		DiscountC,
		DiscountD)
	SELECT 
		@AgentId,
		ad.SportType,
		ad.BetType,
		0,
		0,
		0,
		0
	FROM AgentDiscount3rd AS ad WITH (NOLOCK)
	WHERE ad.AgentId = @ParentId

	---- Insert default agent position taking (From it's parent)
	INSERT INTO AgentPositionTaking(
		AgentId,
		SportType,
		BetType,
		IsLive,
		PresetPositionTaking,
		MaxPositionTaking,
		MinPositionTaking)
	SELECT
		@AgentId,
		apt.SportType,
		apt.BetType,
		apt.IsLive,
		0,
		0,
		0
	FROM AgentPositionTaking AS apt WITH (NOLOCK)
	WHERE apt.AgentId = @ParentId		

	INSERT INTO AgentPositionTaking3rd(
		AgentId,
		SportType,
		BetType,
		IsLive,
		PresetPositionTaking,
		MaxPositionTaking,
		MinPositionTaking)
	SELECT
		@AgentId,
		apt.SportType,
		apt.BetType,
		apt.IsLive,
		0,
		0,
		0
	FROM AgentPositionTaking3rd AS apt WITH (NOLOCK)
	WHERE apt.AgentId = @ParentId	
		
END


