USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_UpdateSetting]    Script Date: 5/6/2013 11:31:14 AM ******/
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
				<PositionTaking SportType="1" BetType="1" IsLive="0" MaxUpper="122" MaxGiven="7761" MinGiven="0"></PositionTaking>
			</ROOT>
 */

BEGIN
	
	SET NOCOUNT ON
	
	-- Check update permission
	DECLARE @hasPermission BIT

	EXEC dbo.Age_Agent_CheckUpdatePermission @ActorAgentId, @AgentId, 1, @hasPermission OUTPUT 

	IF @hasPermission = 0
		BEGIN
			SELECT 
				@ErrCode = 1000,
				@ErrMsg = 
					CASE @Language
						WHEN 'en-US' THEN 'You do not have permission to update setting'
						ELSE [dbo].f_Msg_GetContentById (1000, @Language)
					END

			RETURN
		END

	EXEC Age_Agent_UpdateBetLimit @ActorAgentId, @AgentId, @BetLimit, @Language, @ErrCode OUTPUT, @ErrMsg OUTPUT

	IF @ErrCode > 0		
		RETURN		

	EXEC Age_Agent_UpdateDiscount @ActorAgentId, @AgentId, @Discount, @Language, @ErrCode OUTPUT, @ErrMsg OUTPUT

	IF @ErrCode > 0		
		RETURN		

	EXEC Age_Agent_UpdatePositionTaking @ActorAgentId, @AgentId, @PositionTaking, @Language, @ErrCode OUTPUT, @ErrMsg OUTPUT

	IF @ErrCode > 0		
		RETURN		
END
