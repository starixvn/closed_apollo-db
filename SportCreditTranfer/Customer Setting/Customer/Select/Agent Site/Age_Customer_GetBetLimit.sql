USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetBetLimit]    Script Date: 5/3/2013 4:58:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Age_Customer_GetBetLimit]
	@CustId		INT	
AS

/**
 * Created by	: Kos
 * Date			: 20130302
 * Task			: Get customer bet limit
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	•	
 * Parameters:
 *	•
 */

BEGIN
	
	SET NOCOUNT ON

	SELECT 
		SportType,
		BetType,
		MinBet,
		MaxBet,
		MaxPerMatch
	FROM CustBetLimit WITH (NOLOCK)
	WHERE CustId = @CustId	

END	 