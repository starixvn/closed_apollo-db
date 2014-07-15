USE [CustDB]
GO
ALTER PROCEDURE [dbo].[Age_Customer_UpdateSettingMultiple]
	@ActorAgentId		INT				= NULL,
	@AdminId			INT				= NULL,
	@AgentId			INT,
	@CustIds			VARCHAR(MAX),
	@UGroup				VARCHAR(3),
	@BetLimit			VARCHAR(MAX)	= '',
	@Discount			VARCHAR(MAX)	= '',
	@PositionTaking		VARCHAR(MAX)	= '',
	@Language			VARCHAR(5)		= 'en-US',
	@AllowUpdateMinBet	BIT				= 0,
	@ErrCode			INT				= 0			OUTPUT,
	@ErrMsg				NVARCHAR(MAX)	= ''		OUTPUT	
AS

/**
 * Created by	: Edward
 * Date			: 20130809
 * Task			: Update customer setting multiple
 * DB			: SVRCUST/CustDB
 * Revisions	:
 *	• 20140224@Patrick	: Add more param: Allow update min bet when called from CSD site
 * Parameters:
 *	•	@BetLimit :
 *			<ROOT>
 *				<BetLimit SportType="4" BetType="4" Min="1" Max="1" MaxPerMatch="1"></BetLimit>
 *			</ROOT>
 *	•	@Discount :
 *			<ROOT>
 *				<Discount SportType="4" BetType="4" Discount="1" ></Discount>
 *			</ROOT>	
 *	•	@PositionTaking : 
 *			<ROOT>
 *				<PositionTaking SportType="4" BetType="4" IsLive="1" PT="10" ></PositionTaking>
 *			</ROOT>
 */

BEGIN	  	
	SET NOCOUNT ON	   
	
	DECLARE @TempMsg NVARCHAR(MAX)

	EXEC Age_Customer_UpdateDiscountMultiple 
		@ActorAgentId = @ActorAgentId
		, @AdminId = @AdminId
		, @CustIds = @CustIds
		, @UGroup = @UGroup
		, @Discount = @Discount
		, @Language = @Language
		, @ErrCode = @ErrCode OUTPUT
		, @ErrMsg = @TempMsg OUTPUT		
	
	IF @TempMsg IS NOT NULL	
	BEGIN	
		SET @ErrMsg  = @TempMsg
		SET @TempMsg = NULL 
	END	
	
	EXEC Age_Customer_UpdateBetLimitMultiple
		@ActorAgentId = @ActorAgentId
		, @AdminId = @AdminId
		, @CustIds = @CustIds
		, @BetLimit = @BetLimit
		, @Language = @Language
		, @ErrCode = @ErrCode OUTPUT
		, @ErrMsg = @TempMsg OUTPUT

	IF @TempMsg IS NOT NULL
	BEGIN
		SET @ErrMsg  = @ErrMsg +'^^'+ @TempMsg
		SET @TempMsg = NULL 
	END

	EXEC Age_Customer_UpdatePositionTakingMultiple 
		@ActorAgentId = @ActorAgentId
		, @AdminId = @AdminId
		, @AgentId = @AgentId
		, @CustIds = @CustIds
		, @PositionTaking = @PositionTaking
		, @Language = @Language
		, @ErrCode = @ErrCode OUTPUT
		, @ErrMsg = @TempMsg OUTPUT	

	IF @TempMsg IS NOT NULL
	BEGIN
		SET @ErrMsg  = @ErrMsg +'^^'+ @TempMsg
		SET @TempMsg = NULL 
	END
END

GO

GRANT EXECUTE ON [dbo].[Age_Customer_UpdateSettingMultiple] TO [aplweb] AS [dbo]
GO


