USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Common_GetBetLimitMapping]    Script Date: 5/6/2013 3:52:05 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Common_GetBetLimitMapping]
	@InSportType	SMALLINT,
	@InBetType		SMALLINT,
	@OutSportType	SMALLINT	OUTPUT,
	@OutBetType		SMALLINT	OUTPUT
AS

/**
 * Created by	: Kos
 * Date			: 20130309
 * Task			: Get bet limit mapping output of sport type and bet type
 * DB			: SVRAGE.RepDB
 * Revisions	:
 *	• 
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON

	SET @OutSportType = @InSportType
	SET @OutBetType = @InBetType

	IF EXISTS ( SELECT 1 
				FROM AgentBetLimit WITH (NOLOCK) 
				WHERE SportType = @InSportType AND BetType = @InBetType )
		BEGIN
			RETURN
		END

	SET @OutSportType = 99		-- Other sports
	SET @OutBetType = 1			-- Handicap
		
END
