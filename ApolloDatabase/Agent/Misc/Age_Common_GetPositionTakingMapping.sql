USE [RepDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Common_GetPositionTakingMapping]    Script Date: 3/29/2013 10:02:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Age_Common_GetPositionTakingMapping]
	@InSportType	SMALLINT,
	@InBetType		SMALLINT,
	@OutSportType	SMALLINT	OUTPUT,
	@OutBetType		SMALLINT	OUTPUT
AS

/**
 * Created by	: Kos
 * Date			: 20130309
 * Task			: Get position taking mapping output of sport type and bet type
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

	SET @OutSportType = 
		CASE
			WHEN @InBetType IN (13, 24, 25, 26, 27, 28, 121, 122, 123) THEN 1
			WHEN @InSportType = 26 THEN 3
			WHEN @InSportType = 32 THEN 2
			WHEN @InSportType NOT IN (1, 2, 3, 5, 8, 10, 11, 151, 161, 180) THEN 99
			ELSE @InSportType 
		END

	SET @OutBetType = 
		CASE
			WHEN @InBetType = 82 THEN 81      --Get 1st ball Over/Under for Last ball Over/Under
			WHEN @InBetType = 84 THEN 83      --Get 1st ball Odd/Even for Last ball Odd/Even
			WHEN @InBetType IN (13, 22, 24, 25, 26, 27, 28, 121, 122, 123) THEN 1 
			WHEN @InBetType = 7 AND @InSportType IN (3, 8, 26) THEN 1 --Get Fulltime Handicap for 1st Handicap
			WHEN @InBetType = 8 AND @InSportType IN (3, 8, 26) THEN 3 --Get Fulltime Over/Under for 1st Over/Under
			WHEN @InBetType = 21 AND @InSportType = 8 THEN 20 --Get Fulltime moneyline for 1st money
			WHEN @InBetType = 3 AND @InSportType = 11 THEN 1 --Motorsport (11) don't have OverUnder (3) setting, get from HDP (1)
			WHEN @InBetType = 15 THEN 5				--Get Fulltime 1x2 for 1st 1x2
			WHEN @InBetType = 12 THEN 2				--20080620: Get Fulltime OE for 1st OE (Thien)
			WHEN @InBetType IN (16, 14, 30) THEN 4  --Get CorrectScore for HTFT, FGLG,1st_CS
			--WHEN @InBetType IN (32, 33) THEN 31		--20081223_Thien: Get WIN for PLACE and WIN/PLACE for HorseRacing TOTE
			--WHEN @InBetType IN (42, 43) THEN 41		--20090811_Thien: Get WIN for PLACE and WIN/PLACE for HorseRacing FIXED ODDS
			--WHEN @InBetType = 22 THEN 1				--20090205_Vivi:  don't have Next Goal (22) setting, get from HDP (1)
			--WHEN @InSportType = 180 THEN 1201		--20120815_TWJoe:  Virtual Soccer
			ELSE @InBetType 
		END

	SET @OutBetType = 
		CASE
			WHEN @InSportType = 26 AND @InBetType = 5 THEN 1 --20090317_Vivi: don't have Rugby(26) FT.1X2 setting, get from Footbal(3)+HDP(1)
			WHEN @OutSportType >= 2 AND @OutBetType = 5 THEN 2
			WHEN @OutBetType NOT IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 21, 22, 31, 41, 81, 83, 85, 86, 87, 88, 89, 90, 1201) THEN 2
			ELSE @OutBetType 
		END
		
END	

