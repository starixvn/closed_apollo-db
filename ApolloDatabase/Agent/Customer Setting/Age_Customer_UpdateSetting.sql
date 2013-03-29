USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_UpdateSetting]    Script Date: 3/29/2013 10:45:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_UpdateSetting]
	@ActorAgentId		INT				= NULL,
	@CustId				INT,	
	@UGroup				VARCHAR(3),
	@BetLimit			VARCHAR(MAX)	= '',
	@BetLimit3rd		VARCHAR(MAX)	= '',
	@Discount			VARCHAR(MAX)	= '',
	@Discount3rd		VARCHAR(MAX)	= '',	
	@ErrCode			INT				= 0			OUTPUT,
	@ErrMsg				NVARCHAR(1000)	= ''		OUTPUT 		
AS

/**
 * Created by	: Kos
 * Date			: 20130302
 * Task			: Update customer setting
 * DB			: APL.CustDB
 * Revisions	:
 *	•  
 * Parameters:
 *	•	@BetLimit : 		
 *			<ROOT>
 *				<BetLimit SportType="4" BetType="4" Min="1" Max="1" MaxPerMatch="1"></BetLimit>
 *			</ROOT>
 *	•	@BetLimit3rd : 
 *			<ROOT>
 *				<BetLimit SportType="4" BetType="4" Min="1" Max="1" MaxPerMatch="1" MaxPerBall="1"></BetLimit>
 *			</ROOT>
 *	•	@Discount : 		
 *			<ROOT>
 *				<Discount SportType="4" BetType="4" Discount="1" ></Discount>
 *			</ROOT>	
 *  •	@Discount3rd : 		
 *			<ROOT>
 *				<Discount SportType="4" BetType="4" Discount="1" ></Discount>
 *			</ROOT>
 *	•	@PositionTaking : 
 *			<ROOT>
 *				<PositionTaking SportType="4" BetType="4" IsLive="1" PT="10" ></PositionTaking>
 *			</ROOT>
 *	•	@PositionTaking3rd : 
 *			<ROOT>
 *				<PositionTaking SportType="4" BetType="4" IsLive="1" PT="10" ></PositionTaking>
 *			</ROOT>
 */

BEGIN
	
	SET NOCOUNT ON

	-- Check update permission
	DECLARE @hasPermission BIT
	EXEC dbo.Age_Agent_CheckUpdatePermission @ActorAgentId, @CustId, 2, @hasPermission OUTPUT 
	SELECT @hasPermission
	IF @hasPermission = 0
		BEGIN
			SELECT @ErrCode = 1
			
			SELECT @ErrMsg	= 'Do not permission for update.'

			RETURN			
		END	

	EXEC Age_Customer_UpdateBetLimit @ActorAgentId, @CustId, @BetLimit, @BetLimit3rd, @ErrCode, @ErrMsg
	
	EXEC Age_Customer_UpdateDiscount @ActorAgentId, @CustId, @UGroup, @Discount, @Discount3rd, @ErrCode, @ErrMsg	

END