USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_UpdateSetting]    Script Date: 5/6/2013 11:10:37 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_UpdateSetting]
	@ActorAgentId		INT				= NULL,
	@AgentId			INT,
	@CustId				INT,
	@UGroup				VARCHAR(3),
	@BetLimit			VARCHAR(MAX)	= '',
	@Discount			VARCHAR(MAX)	= '',
	@PositionTaking		VARCHAR(MAX)	= '',
	@Language			VARCHAR(5)		= 'en-US',
	@ErrCode			INT				= 0			OUTPUT,
	@ErrMsg				NVARCHAR(1000)	= ''		OUTPUT
AS

/**
 * Created by	: Kos
 * Date			: 20130302
 * Task			: Update customer setting
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

	-- Check update permission
	DECLARE @hasPermission BIT

	EXEC dbo.Age_Agent_CheckUpdatePermission @ActorAgentId, @CustId, 2, @hasPermission OUTPUT 
	
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

	EXEC Age_Customer_UpdateBetLimit @ActorAgentId, @CustId, @BetLimit, @Language, @ErrCode OUTPUT, @ErrMsg OUTPUT
	
	IF @ErrCode > 0
		RETURN

	EXEC Age_Customer_UpdateDiscount @ActorAgentId, @CustId, @UGroup, @Discount, @Language, @ErrCode OUTPUT, @ErrMsg OUTPUT	

	IF @ErrCode > 0
		RETURN

	EXEC Age_Customer_UpdatePositionTaking @ActorAgentId, @AgentId, @CustId, @PositionTaking, @Language, @ErrCode OUTPUT, @ErrMsg OUTPUT	

	IF @ErrCode > 0
		RETURN
END