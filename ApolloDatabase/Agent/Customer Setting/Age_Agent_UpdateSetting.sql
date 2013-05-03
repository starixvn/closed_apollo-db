USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_UpdateSetting]    Script Date: 5/3/2013 4:33:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_UpdateSetting]
	@ActorAgentId		INT				= NULL,
	@AgentId			INT,
	@BetLimit			VARCHAR(MAX)	= '',
	@Discount			VARCHAR(MAX)	= '',
	@PositionTaking		VARCHAR(MAX)	= '',
	@Language			VARCHAR(5)		= 'en-US',
	@ErrCode			INT				= 0			OUTPUT,
	@ErrMsg				NVARCHAR(1000)	= ''		OUTPUT
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Update agent setting
 * DB			: SVRCUST.CustDB
 * Revisions	:
 *	•  20132702@Edward	: Implement
 * Parameters:
 *	•	@BetLimit : 		
			<ROOT>
				<Discount SportType="4" BetType="4" DiscountA="1" DiscountB="1" DiscountC="1" DiscountD="1"></Discount>
			</ROOT>
 *	•	@Discount : 		
			<ROOT>
				<Discount SportType="4" BetType="4" DiscountA="1" DiscountB="1" DiscountC="1" DiscountD="1"></Discount>
			</ROOT>	
*	•	@PositionTaking : 
			<ROOT>
				<ROOT><PositionTaking SportType="4" BetType="4" IsLive="1" Preset="10" Max="1" Min="1"></PositionTaking></ROOT>
			</ROOT>
 */

BEGIN
	
	SET NOCOUNT ON
	
	-- Check update permission
	DECLARE @hasPermission BIT
	EXEC dbo.Age_Agent_CheckUpdatePermission @ActorAgentId, @AgentId, 1, @hasPermission OUTPUT 
	SELECT @hasPermission
	IF @hasPermission = 0
		BEGIN
			SELECT @ErrCode = 1
			
			SELECT @ErrMsg	= 'Do not permission for update.'

			RETURN
		END	

	EXEC Age_Agent_UpdateBetLimit @ActorAgentId, @AgentId, @BetLimit, @Language, @ErrCode OUTPUT, @ErrMsg OUTPUT

	EXEC Age_Agent_UpdateDiscount @ActorAgentId, @AgentId, @Discount, @Language, @ErrCode OUTPUT, @ErrMsg OUTPUT

	EXEC Age_Agent_UpdatePositionTaking_xtest @ActorAgentId, @AgentId, @PositionTaking, @Language, @ErrCode OUTPUT, @ErrMsg OUTPUT

END
