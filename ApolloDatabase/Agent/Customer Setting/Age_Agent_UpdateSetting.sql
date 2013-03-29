USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_UpdateSetting]    Script Date: 3/29/2013 10:42:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_UpdateSetting]
	@ActorAgentId		INT				= NULL,
	@AgentId			INT,
	@BetLimit			VARCHAR(MAX)	= '',
	@BetLimit3rd		VARCHAR(MAX)	= '',
	@Discount			VARCHAR(MAX)	= '',
	@Discount3rd		VARCHAR(MAX)	= '',
	@PositionTaking		VARCHAR(MAX)	= '',
	@PositionTaking3rd	VARCHAR(MAX)	= '',
	@ErrCode			INT				= 0			OUTPUT,
	@ErrMsg				NVARCHAR(1000)	= ''		OUTPUT 		
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Update agent setting
 * DB			: APL.CustDB
 * Revisions	:
 *	•  20132702@Edward	: Implement
 * Parameters:
 *	•	@BetLimit : 		
			<ROOT>
				<Discount SportType="4" BetType="4" DiscountA="1" DiscountB="1" DiscountC="1" DiscountD="1"></Discount>
			</ROOT>
	•	@BetLimit3rd : 
			<ROOT>
				<BetLimit SportType="4" BetType="4" Min="1" Max="1" MaxPerMatch="1" MaxPerBall="1"></BetLimit>
			</ROOT>
 *	•	@Discount : 		
			<ROOT>
				<Discount SportType="4" BetType="4" DiscountA="1" DiscountB="1" DiscountC="1" DiscountD="1"></Discount>
			</ROOT>	
 *  •	@Discount3rd : 		
			<ROOT>
				<Discount SportType="4" BetType="4" DiscountA="1" DiscountB="1" DiscountC="1" DiscountD="1"></Discount>
			</ROOT>
*	•	@PositionTaking : 
			<ROOT>
				<ROOT><PositionTaking SportType="4" BetType="4" IsLive="1" Preset="10" Max="1" Min="1"></PositionTaking></ROOT>
			</ROOT>
*	•	@PositionTaking3rd : 
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

	EXEC Age_Agent_UpdateBetLimit @ActorAgentId, @AgentId, @BetLimit, @BetLimit3rd, @ErrCode OUTPUT, @ErrMsg OUTPUT

	EXEC Age_Agent_UpdateDiscount @ActorAgentId, @AgentId, @Discount, @Discount3rd, @ErrCode OUTPUT, @ErrMsg OUTPUT

	EXEC Age_Agent_UpdatePositionTaking @ActorAgentId, @AgentId, @PositionTaking, @PositionTaking3rd, @ErrCode OUTPUT, @ErrMsg OUTPUT

END
