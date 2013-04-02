USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Common_GetDiscountMapping]    Script Date: 3/29/2013 10:02:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Age_Common_GetDiscountMapping]
	@InSportType	SMALLINT,
	@InBetType		SMALLINT,
	@OutSportType	SMALLINT	OUTPUT,
	@OutBetType		SMALLINT	OUTPUT
AS

/**
 * Created by	: Kos
 * Date			: 20130309
 * Task			: Get discount mapping output of sport type and bet type
 * DB			: APL.CustDB
 * Revisions	:
 *	• 
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON

	SELECT 
		@OutSportType = OutSportType,
		@OutBetType = OutBetType
	FROM DiscountMappingTable WITH (NOLOCK)
	WHERE 
		InSportType = @InSportType 
		AND InBetType = @InBetType
		
END

