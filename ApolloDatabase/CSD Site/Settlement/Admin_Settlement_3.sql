ALTER PROCEDURE [dbo].[Admin_Settlement_3]
	@creator int,
	@matchid int,
	@mode varchar(6) = 'CAL'
AS
/*
Created By: Dan
Created Date: 2013-03-08
Task : Covered SP for settlement
DB: SVRTXN/TransDB
Original SP: bodb02.[Admin_Settlement_3]
Revisions:
	 - 20140514@Dan: Add new bettype 126
• @Mode:
    CAL : All BetTypes
    CAL-HT : HT Only
    CAL-FT : FT Only (All Except HT)
*/
	SET NOCOUNT ON 

	Declare @fth int, @fta int,
		@hth int, @hta int,
		@sporttype tinyint,
		@betstatus nvarchar(50),
		@GoalRecord varchar(50),
		@matchCode nvarchar(50)

	SELECT
			@sporttype = SportType,
			@matchCode = IsNull(matchCode, '')
	FROM	SVRPRO.ProdDB.dbo.Match with (nolock) WHERE matchid = @matchid

	SELECT
			@fth = FinalHomeScore, @fta = FinalAwayScore,
			@hth = HTHomeScore, @HTA = HTAwayScore,			
			@betstatus = betstatus,
			@GoalRecord = IsNull(GoalRecord, '')			
	FROM	SVRPRO.ProdDB.dbo.match_remark_ex with (nolock) WHERE matchid = @matchid


	Declare @TennisTotal smallint, @T_Home smallint, @T_Away smallint
	IF @SportType IN (5, 6, 9, 30) -- Tennis/VolleyBall/Badminton/Squash : get TotalGamesPlayed
		EXEC dbo.Admin_Settlement_2
			@betstatus = @betstatus,
			@Total =  @TennisTotal OUTPUT,
			@TotalHome = @T_Home OUTPUT,
			@TotalAway = @T_Away OUTPUT
	IF @SportType = 10 -- Golf, using Stroke count, so swap the score to make it become normal stype
	Begin
		Declare @tmp int
		SELECT @tmp = @fth, @fth = @fta
		SELECT @fta = @tmp
	End

	Declare @oddeven smallmoney, @oddevenht smallmoney,
		@totalgoal smallmoney, @totalht smallmoney,
		@scorediff smallmoney, @scorediff_ht smallmoney,
		@correctscore nvarchar(10),@correctscore_ht nvarchar(10), @HTFT nvarchar(10)

	SELECT
		@oddeven	= CASE WHEN @sporttype IN (5, 6, 9, 30) and @TennisTotal > 0 THEN @TennisTotal % 2 ELSE ((@fth + @fta) % 2) END,
		@oddevenht	= ((@hth + @hta) % 2),
		@totalgoal	= CASE WHEN @sporttype IN (5, 6, 9, 30) and @TennisTotal > 0 THEN @TennisTotal ELSE (@fth + @fta) END,
		@totalht	= (@hth + @hta),
		@scorediff	= (@fth - @fta),
		@scorediff_ht	= (@hth - @hta),
		@correctscore	= CAST(@fth as nvarchar(6)) + ':' + CAST(@fta as nvarchar(6)),
		@correctscore_ht	= CAST(@hth as nvarchar(6)) + ':' + CAST(@hta as nvarchar(6)),
		@HTFT	=	CASE WHEN @hth = @hta THEN '0' WHEN @hth > @hta THEN '1' ELSE '2' END + ':' +
					CASE WHEN @fth = @fta THEN '0' WHEN @fth > @fta THEN '1' ELSE '2' END
	
	--2008-06-10: (Michael) Set back to Set handicap (Thien)
	/*
	IF @sporttype = 6 -- VolleyBall, Handicap using "Score" : 20080511 (Farn)(Joe)
		SELECT @fth = @T_Home, @fta = @T_Away
	*/
	
	--2009-02-10: Check goal record (Vinh)--------------
	DECLARE @ErrMsg nvarchar(200)

	--IF (@sporttype = 1 and @mode <> 'CAL-HT' AND len(@GoalRecord) <> @totalgoal and @GoalRecord <> '' and @matchCode not like '%hedge%') 
	IF EXISTS(SELECT transid FROM dbo.bettrans with (nolock) WHERE matchid = @matchid AND bettype = 22)
		IF LEN(@GoalRecord) <> @TotalGoal
		BEGIN
			select @ErrMsg = 'Goal record is not consistent with the score, please correct Goal record before calculating.'
			RaisError (@ErrMsg, 16, 1)
			return
		END

	
	----------------------------------------------------
	
	IF @Mode IN ('CAL-FT', 'CAL')
	BEGIN
	    
	    --------count HDP tickets for checking remote rep (Daniel)---------
		DECLARE @betcount_1 int, @betcount_2 int, @betcount_3 int, @betcount_4 int, 
				@betcount_5 int, @betcount_6 int, @betcount_16 int, @betcount_20 int, @betcount_22 int,
				@betcount_13 int, 
				@betcount_24 int, @betcount_25 int, @betcount_26 int, @betcount_27 int, @betcount_28 int, @betcount_124 int,
				@betcount_121 int, @betcount_122 int, @betcount_123 int 				
		SELECT 
			@betcount_1 = ISNULL(SUM(case bettype when 1 then 1 else 0 end), 0),
			@betcount_2 = ISNULL(SUM(case bettype when 2 then 1 else 0 end), 0),
			@betcount_3 = ISNULL(SUM(case bettype when 3 then 1 else 0 end), 0),
			@betcount_4 = ISNULL(SUM(case bettype when 4 then 1 else 0 end), 0),
			@betcount_5 = ISNULL(SUM(case bettype when 5 then 1 else 0 end), 0),
			@betcount_6 = ISNULL(SUM(case bettype when 6 then 1 else 0 end), 0),
			@betcount_13 = ISNULL(SUM(case bettype when 13 then 1 else 0 end), 0),
			@betcount_16 = ISNULL(SUM(case bettype when 16 then 1 else 0 end), 0), 
			@betcount_20 = ISNULL(SUM(case bettype when 20 then 1 else 0 end), 0),
			@betcount_22 = ISNULL(SUM(case bettype when 22 then 1 else 0 end), 0),
			@betcount_24 = ISNULL(SUM(case bettype when 24 then 1 else 0 end), 0),
 			@betcount_25 = ISNULL(SUM(case bettype when 25 then 1 else 0 end), 0),
			@betcount_26 = ISNULL(SUM(case bettype when 26 then 1 else 0 end), 0),
			@betcount_27 = ISNULL(SUM(case bettype when 27 then 1 else 0 end), 0),
			@betcount_28 = ISNULL(SUM(case bettype when 28 then 1 else 0 end), 0),
			@betcount_121 = ISNULL(SUM(case bettype when 121 then 1 else 0 end), 0),
			@betcount_122 = ISNULL(SUM(case bettype when 122 then 1 else 0 end), 0),
			@betcount_123 = ISNULL(SUM(case bettype when 123 then 1 else 0 end), 0),
			@betcount_124 = ISNULL(SUM(case bettype when 124 then 1 else 0 end), 0)			
		FROM bettrans WITH(NOLOCK) 
		WHERE  matchid = @matchid
			   and bettype in (1,2,3,4,5,6,13,16,20,22,24,25,26,27,28,121,122,123,124)
		
		-- bettype 1 : Handicap
		-- IF @betcount_1 > 0
			EXEC dbo.Admin_Calculate_1 @matchid, 1, @fth, @fta, @betcount_1

		-- bettype 20 : Money Line
		-- IF @betcount_20 > 0 
			EXEC dbo.Admin_Calculate_1 @matchid, 20, @fth, @fta, @betcount_20
			
		-- bettype 124: FT 1x2 HDP 
			EXEC dbo.Admin_Calculate_1 @matchid, 124, @fth, @fta, @betcount_124  ---parametter @betcount has not used, will be removed later

		-- bettype 2 : Odd/Even
		-- IF @betcount_2 > 0  
			EXEC dbo.Admin_Calculate_2 @matchid, 2, @oddeven, @betcount_2

		-- bettype 3 : Over/Under
		-- IF @betcount_3 > 0
			EXEC dbo.Admin_Calculate_3 @matchid, 3, @totalgoal, @betcount_3
		
		-- bettype 4, 16 : Correct Score
		-- IF @betcount_4 > 0
			EXEC dbo.Admin_Calculate_4 @matchid,  4, @correctscore, @scorediff, NULL, @betcount_4
						
		-- bettype 5 : 1x2
		-- IF @betcount_5 > 0
			EXEC dbo.Admin_Calculate_5 @matchid,  5, @scorediff, @betcount_5

		-- bettype 6 : Total Goal
		-- IF @betcount_6 > 0
			EXEC dbo.Admin_Calculate_6 @matchid, 6, @totalgoal, @betcount_6

		-- bettype 13 : Clean Sheet 
		-- IF @betcount_13 > 0 
			EXEC dbo.Admin_Calculate_13 @matchid, 13, @fth, @fta, @betcount_13

		-- bettype 16 : HT/FT		
		-- IF @betcount_16 > 0	
			EXEC dbo.Admin_Calculate_4 @matchid, 16, @HTFT, @scorediff, NULL, @betcount_16  --reuse 

		-- bettype 22 : Next Goal	
		-- IF @betcount_22 > 0
			EXEC dbo.Admin_Calculate_22 @matchid, 22, @GoalRecord, @betcount_22

		-- bettype 24 : Double Chance 
		-- IF @betcount_24 > 0
			EXEC dbo.Admin_Calculate_24 @matchid, 24, @scorediff, @betcount_24

		-- bettype 25 : Draw no bet 
		-- IF @betcount_25 > 0
			EXEC dbo.Admin_Calculate_25 @matchid, 25, @scorediff, @betcount_25

		-- bettype 26 : Both/One/Neither team to score  
		-- IF @betcount_26 > 0 
			EXEC dbo.Admin_Calculate_26 @matchid, 26, @fth, @fta, @betcount_26

		-- bettype 27 : To win to nil 
		-- IF @betcount_27 > 0 
			EXEC dbo.Admin_Calculate_27 @matchid, 27, @fth, @fta, @betcount_27

		-- bettype 28 : 3-way handicap
		-- IF @betcount_28 > 0 
			EXEC dbo.Admin_Calculate_28 @matchid, 28, @fth, @fta, @betcount_28
			
		-- bettype 121 : Home no bet 
		-- IF @betcount_121 > 0
			EXEC dbo.Admin_Calculate_25 @matchid, 121, @scorediff, @betcount_121
			
		-- bettype 122 : Away no bet 
		-- IF @betcount_121 > 0
			EXEC dbo.Admin_Calculate_25 @matchid, 122, @scorediff, @betcount_122

		-- bettype 123 : Draw/No Draw
		-- IF @betcount_123 > 0
			EXEC dbo.Admin_Calculate_25 @matchid, 123, @scorediff, @betcount_123
	END

	IF @Mode IN ('CAL-HT', 'CAL') 
	BEGIN
	    DECLARE @betcount_7 int, @betcount_8 int, @betcount_12 int, @betcount_15 int, @betcount_21 int, @betcount_30 int, @betcount_125 int, @betcount_126 int
	    SELECT 
			  @betcount_7 = ISNULL(SUM(case bettype when 7 then 1 else 0 end), 0)
			, @betcount_8 = ISNULL(SUM(case bettype when 8 then 1 else 0 end), 0)
			, @betcount_12 = ISNULL(SUM(case bettype when 12 then 1 else 0 end), 0)
			, @betcount_15 = ISNULL(SUM(case bettype when 15 then 1 else 0 end), 0)
			, @betcount_21 = ISNULL(SUM(case bettype when 21 then 1 else 0 end), 0)
			, @betcount_30 = ISNULL(SUM(case bettype when 30 then 1 else 0 end), 0)
			, @betcount_125 = ISNULL(SUM(case bettype when 125 then 1 else 0 end), 0)
			, @betcount_126 = ISNULL(SUM(case bettype when 126 then 1 else 0 end), 0)
		FROM bettrans WITH(NOLOCK) 
		WHERE  matchid = @matchid
			   and bettype in (7,8,12,15,21,30,125,126)

		-- exec in all cases, both 'FT' and 'HT'
		-- bettype 7 : 1st Handicap
		-- IF @betcount_7 > 0
			EXEC dbo.Admin_Calculate_7 @matchid, 7, @hth, @hta, @betcount_7
		
		-- bettype 21: 1st moneyline
		-- IF @betcount_21 > 0
			EXEC dbo.Admin_Calculate_7 @matchid, 21, @hth, @hta, @betcount_21		
			
		-- bettype 125 : 1st 1x2 Handicap
			EXEC dbo.Admin_Calculate_7 @matchid, 125, @hth, @hta, @betcount_125 ---parametter @betcount has not used, will be removed later

		-- bettype 8 : 1st Over/Under
		-- IF @betcount_8 > 0
			EXEC dbo.Admin_Calculate_8 @matchid, 8, @totalht, @betcount_8
		
		-- bettype 12 : 1st Odd/Even
		-- IF @betcount_12 > 0
			EXEC dbo.Admin_Calculate_2 @matchid, 12, @oddevenht, @betcount_12
		
		-- bettype 15 : 1st 1x2
		-- IF @betcount_15 > 0
			EXEC dbo.Admin_Calculate_5 @matchid, 15, @scorediff_ht, @betcount_15			
		
		-- bettype 30: 1st Correct Score (Reuse with bettype 4)
		-- IF @betcount_30 > 0
			EXEC dbo.Admin_Calculate_4 @matchid, 30, @correctscore_ht, @scorediff_ht, NULL, @betcount_30	
		 
		 --bettype 126 : 1H Total Goal
			EXEC dbo.Admin_Calculate_6 @matchid, 126, @totalht, @betcount_126
	END

GO
GRANT EXECUTE ON [dbo].[Admin_Settlement_3] TO [aplweb] AS [dbo]
--GO
--GRANT VIEW DEFINITION ON [dbo].[Admin_Settlement_3] TO [vnteam] AS [dbo]