USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_GetBetLimit]    Script Date: 4/17/2013 2:58:03 PM ******/
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
 * Task			: Get customer bet limit and bet limit 3rd
 * DB			: APL.CustDB
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
		MaxPerMatch,
		0 AS MaxPerBall	 
	FROM CustBetLimit WITH (NOLOCK)
	WHERE CustId = @CustId	

END	 