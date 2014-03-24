ALTER FUNCTION [dbo].[f_GetCommBase]
(
	 @Stake		MONEY,
	 @Odds		SMALLMONEY,
	 @Bettype	SMALLINT,
	 @MOdds		SMALLMONEY 
)
RETURNS MONEY 
AS
/*
	* Created by	: Sophia
	* Date			: 20140225
	* Task			: Get CommBase
	* DB			: SVRAGE.REPDB/SVRCSD.REPDB/SVRTXN.TransDB
	* Parameters:
 
	* Revisions	:
		- 20140224@Sophia: Only use formula for bettype in (1,2,3,7,8,12)

*/
BEGIN
	DECLARE @CommBase MONEY 

	---Malay, HK, Dec Odds (the same with Malay)
	IF @Bettype IN (1,2,3,7,8,12)
	BEGIN 
		IF @Odds > 0 
		BEGIN			
			SELECT @CommBase =	CASE
									WHEN @modds >  0.25 	THEN @Stake * @Odds
									WHEN @modds =  0.25 	THEN @Stake * @Odds * 0.5
									WHEN @modds =  0    	THEN 0
									WHEN @modds = -0.25 	THEN @Stake * 0.5
									WHEN @modds < -0.25 	THEN @Stake 
								END
		
		END
		ELSE 
		IF @Odds < 0 
		BEGIN
			SELECT @CommBase =	CASE
									WHEN @modds >  0.25 	THEN @Stake
									WHEN @modds =  0.25 	THEN @Stake * 0.5
									WHEN @modds =  0    	THEN 0
									WHEN @modds = -0.25 	THEN @Stake * ABS(@Odds) * 0.5
									WHEN @modds < -0.25 	THEN @Stake * ABS(@Odds) 
								END
		END
		ELSE 
		BEGIN
			SELECT @CommBase = 0
		END		
	END
	-----Decimal always
	--ELSE IF @Bettype IN (5,15,13,24,25,26,27,28,121,122,123) 
	--BEGIN 
	--	SELECT @CommBase =	CASE
	--								WHEN @modds >  0.25 	THEN @Stake * (@Odds -1)
	--								WHEN @modds =  0.25 	THEN @Stake * (@Odds -1) * 0.5
	--								WHEN @modds =  0    	THEN 0
	--								WHEN @modds = -0.25 	THEN @Stake * 0.5
	--								WHEN @modds < -0.25 	THEN @Stake
	--							END

	--END
	--ELSE 

	--Parlay, outright
	IF @Bettype IN (9,29,10) 
	BEGIN
		SELECT @CommBase = @Stake --not care modds (1/2 won,lose)
	END

	--ELSE
	--BEGIN
	-----Others
	--	SELECT @CommBase =	CASE
	--								WHEN @modds >  0.25 	THEN @Stake 
	--								WHEN @modds =  0.25 	THEN @Stake * 0.5
	--								WHEN @modds =  0    	THEN 0
	--								WHEN @modds = -0.25 	THEN @Stake * 0.5
	--								WHEN @modds < -0.25 	THEN @Stake
	--							END
	--END		 

	RETURN @CommBase
END


GO
GRANT EXECUTE ON [dbo].[F_GetCommBase] TO [aplweb]
GO