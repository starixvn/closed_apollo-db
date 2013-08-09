USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_UpdateSettingMultiple]    Script Date: 8/9/2013 11:13:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
	@ErrCode			INT				= 0			OUTPUT,
	@ErrMsgBetLimit		NVARCHAR(MAX)	= ''		OUTPUT,
	@ErrMsgDiscount		NVARCHAR(MAX)	= ''		OUTPUT,
	@ErrMsgPositionTaking	NVARCHAR(MAX)	= ''		OUTPUT
AS

/**
 * Created by	: Edward
 * Date			: 20130809
 * Task			: Update customer setting multiple
 * DB			: SVRCUST.CustDB
 * Revisions	:
 *	•  
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
	
	EXEC Age_Customer_UpdateBetLimitMultiple @ActorAgentId, @AdminId, @CustIds, @BetLimit, @Language, @ErrCode OUTPUT, @ErrMsgBetLimit OUTPUT

	EXEC Age_Customer_UpdateDiscountMultiple @ActorAgentId, @AdminId, @CustIds, @UGroup, @Discount, @Language, @ErrCode OUTPUT, @ErrMsgDiscount OUTPUT	

	EXEC Age_Customer_UpdatePositionTakingMultiple @ActorAgentId, @AdminId, @AgentId, @CustIds, @PositionTaking, @Language, @ErrCode OUTPUT, @ErrMsgPositionTaking OUTPUT	
END
