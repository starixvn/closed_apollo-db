ALTER PROCEDURE [dbo].[Admin_Calculate_9m]
	@matchid int,
	@fth int, @fta int,
	@hth int, @hta int,
	@matchdate datetime,
	@action varchar(10) = 'CAL',
	@TennisTotal tinyint = NULL,
	@VoidTransID varchar(2000) = '',
	@UserID INT = 0
WITH RECOMPILE
AS
/*
	Created by: Dan
	Date: 2013-03-22
	Task: Calculate Mix Parlay 
	DB: SVRTXN/TransDB
	
	Revision:
		- 20140514@Dan: Add 1H FGLG bettypes (127)
*/

IF @@SERVERNAME IN ('DB042', 'DB043', 'DB044') RETURN


-------------------------------------------------------------------------
-------------------------------------------------------------------------

Declare @modds smallmoney

UPDATE BM
SET bettype=o.bettype 
FROM dbo.bettransm BM with (updlock)
	INNER JOIN dbo.odds o with (nolock) ON BM.oddsid = o.oddsid
WHERE
	BM.matchid=@matchid
	AND BM.bettype <> o.bettype

-- ===================================================
IF @action = 'REFUND'
BEGIN
	UPDATE dbo.bettransm
	SET winlostdate=@matchdate,[status]='Refund',statuswinlost=0,ruben=1, statusID = 103
	WHERE matchid=@matchid
		AND bettype NOT IN (14, 127)
		AND statusID NOT IN (101,102)
	
	UPDATE dbo.BetParlayDetail
	SET winlostdate=@matchdate,statuswinlost=0, statusID = 103
	WHERE matchid=@matchid 
		AND bettype NOT IN (14, 127)
		AND statusID NOT IN (101,102)
END
-- ===================================================
ELSE IF @action = 'REFUND-FT'
BEGIN
	UPDATE dbo.bettransm
	SET winlostdate=@matchdate,[status]='Refund',statuswinlost=0,ruben=1, statusID = 103
	WHERE matchid=@matchid AND bettype NOT IN (7,8,12,15,21,30,14,126,127)
		AND statusID NOT IN (101,102)
	
	UPDATE dbo.BetParlayDetail
	SET winlostdate=@matchdate,statuswinlost=0, statusID = 103
	WHERE matchid=@matchid AND bettype NOT IN (7,8,12,15,21,30,14,126,127)
		AND statusID NOT IN (101,102)
END
	
ELSE IF @action = 'REFUND-HT'
BEGIN
	UPDATE dbo.bettransm
	SET winlostdate=@matchdate,[status]='Refund',statuswinlost=0,ruben=1, statusID = 103
	WHERE matchid=@matchid AND bettype IN (7,8,12,15,21,30,126)
		AND statusID NOT IN (101,102)

	UPDATE dbo.BetParlayDetail
	SET winlostdate=@matchdate,statuswinlost=0, statusID = 103
	WHERE matchid=@matchid AND bettype IN (7,8,12,15,21,30,126)
		AND statusID NOT IN (101,102)
END
-- ===================================================
ELSE IF @action = 'VOID'
BEGIN
	
	DECLARE @transtbl TABLE(transid BIGINT)
	INSERT INTO @transtbl
		SELECT CONVERT(BIGINT,val) FROM dbo.strSplit(@VoidTransID,',')	

	UPDATE dbo.bettransm
	SET winlost=CASE WHEN odds>0 THEN stake ELSE stake*ABS(odds) END
		,ruben=1,statuswinlost=0, status = 'VOID', creator = @UserID,statusID = 102,winlostdate = @matchdate
	WHERE matchid=@matchid
		AND statusID NOT IN (101,102)
		AND transid IN (SELECT transid FROM @transtbl)
	
	UPDATE dbo.BetParlayDetail
	SET statuswinlost=0, statusID = 102, winlostdate=@matchdate
	WHERE matchid=@matchid
		AND statusID NOT IN (101,102)
		AND transid IN (SELECT transid FROM @transtbl)

END
-- ===================================================
ELSE IF @action = 'UNDO'
BEGIN
	UPDATE dbo.bettransm
	SET [status]='running',statuswinlost=0,ruben=0, statusID = 0
	WHERE matchid=@matchid
		AND statusID NOT IN (101,102)
	
	UPDATE dbo.BetParlayDetail
	SET statuswinlost=0, statusID = 0
	WHERE matchid=@matchid
		AND statusID NOT IN (101,102)
END
-- ===================================================
-- ===================================================
ELSE IF @action = 'CAL'
BEGIN
	UPDATE dbo.bettransm with (updlock)
	SET
		@modds =
			CASE bettype
				when 1 then -- Handicap
					CASE betteam
					WHEN 'h' THEN (hdp2-hdp1) + (@fth - livehomescore) - (@fta - liveawayscore) 
					WHEN 'a' THEN (hdp1-hdp2) - (@fth - livehomescore) + (@fta - liveawayscore)
					END
				when 7 then -- 1st Handicap
					CASE betteam
					WHEN 'h' THEN (hdp2-hdp1) + (@hth - livehomescore) - (@hta - liveawayscore) 
					WHEN 'a' THEN (hdp1-hdp2) - (@hth - livehomescore) + (@hta - liveawayscore)
					END

				when 3 then -- Over/Under
					CASE betteam
					WHEN 'h' THEN (case when @TennisTotal IS NULL then @fth+@fta else @TennisTotal end) - hdp1 
					WHEN 'a' THEN hdp1 - (case when @TennisTotal IS NULL then @fth+@fta else @TennisTotal end)
					END
				when 8 then -- 1st Over/Under
					CASE betteam
					WHEN 'h' THEN (@hth+@hta) - hdp1
					WHEN 'a' THEN hdp1 - (@hth+@hta)
					END
				when 2 then -- Odd/Even
					case 
						when (betteam = 'h') AND ((case when @TennisTotal IS NULL then @fth+@fta else @TennisTotal end)&1 = 1) then 1
						when (betteam = 'a') AND ((case when @TennisTotal IS NULL then @fth+@fta else @TennisTotal end)&1 = 0) then 1
						else -1
					end
				when 12 then -- 1st Odd/Even
					case 
						when (betteam = 'h') AND ((@hth+@hta)&1 = 1) then 1
						when (betteam = 'a') AND ((@hth+@hta)&1 = 0) then 1
						else -1
					end
				when 4 then -- Correct Score
					case
					when betteam = ( CAST(@fth as varchar(4)) + ':' + CAST(@fta as varchar(4)) ) THEN 1
					when betteam = '5:0' AND (@fth - @fta) >=  5 THEN 1
					when betteam = '0:5' AND (@fth - @fta) <= -5 THEN 1
					else -1
					end
				when 30 then -- 1st Correct Score
					case
					when betteam = ( CAST(@hth as varchar(4)) + ':' + CAST(@hta as varchar(4)) ) THEN 1
					WHEN betteam = '4:0' AND (@hth - @hta) >=  4 THEN 1 -- 4UP for 1st Correct Score
					WHEN betteam = '0:4' AND (@hth - @hta) <=  -4 THEN 1 -- 4UP for 1st Correct Score
					when betteam = '5:0' AND (@hth - @hta) >=  5 THEN 1
					when betteam = '0:5' AND (@hth - @hta) <= -5 THEN 1
					else -1
					end					
				when 16 then -- HT/FT
					case
					when betteam =
						CASE WHEN @hth = @hta THEN '0' WHEN @hth > @hta THEN '1' ELSE '2' END + ':' +
						CASE WHEN @fth = @fta THEN '0' WHEN @fth > @fta THEN '1' ELSE '2' END
						THEN 1
					else -1
					end

				when 5 then -- 1x2
					case
					when (betteam = '1') AND (@fth > @fta) then 1
					when (betteam = '2') AND (@fta > @fth) then 1
					when (betteam = 'x') AND (@fth = @fta) then 1
					else -1
					end
				when 15 then -- 1st 1x2
					case 
					when (betteam = '1') AND (@hth > @hta) then 1
					when (betteam = '2') AND (@hta > @hth) then 1
					when (betteam = 'x') AND (@hth = @hta) then 1
					else -1
					end

				when 6 then -- Total Goal
					case when (
							case when @TennisTotal IS NULL then @fth+@fta else @TennisTotal end >= cast(left(betteam,1)as int) and
							case when @TennisTotal IS NULL then @fth+@fta else @TennisTotal end <= (
									case when right(betteam,1) = 'r' then 999 else 
									cast(right(betteam,1) as int) end
									)
							)  
					then 1 else -1 end

				WHEN 126 THEN -- 1H total goal
					CASE WHEN (
								CASE WHEN @TennisTotal IS NULL THEN @hth + @hta ELSE @TennisTotal END >= CAST(LEFT(betteam,1) AS int) AND
								CASE WHEN @TennisTotal IS NULL then @hth + @hta ELSE @TennisTotal END <= (
									CASE when RIGHT(betteam,1)= 'r' then 999 ELSE CAST(RIGHT(betteam,1)AS int) END 
									)
							) then 1 ELSE -1 END 

				when 13 then -- Clean Sheet
					CASE
						WHEN betteam = 'hy' AND @fta = 0 THEN 1
						WHEN betteam = 'hn' AND @fta > 0 THEN 1
						WHEN betteam = 'ay' AND @fth = 0 THEN 1
						WHEN betteam = 'an' AND @fth > 0 THEN 1
						ELSE -1
					END
				when 20 then -- Money Line
					CASE betteam
						WHEN N'h' THEN @fth - @fta
						ELSE @fta - @fth
					END
				when 21 then -- 1st Money Line
					CASE betteam
						WHEN N'h' THEN @hth - @hta
						ELSE @hta - @hth
					END
				when 24 then -- Double Chance
					CASE
						WHEN betteam = '1X' AND (@fth - @fta) >= 0 THEN 1
						WHEN betteam = '2X' AND (@fth - @fta) <= 0 THEN 1
						WHEN betteam = '12' AND (@fth - @fta) <> 0 THEN 1
						ELSE -1
					END
				when 25 then -- Draw No Bet
					CASE
						WHEN (@fth - @fta) = 0 THEN 0
						WHEN betteam = 'h' AND (@fth - @fta) > 0 THEN 1
						WHEN betteam = 'a' AND (@fth - @fta) < 0 THEN 1
						ELSE -1
					END
				when 26 then -- Both/One/Neither team to score
					CASE
						WHEN betteam = 'b' AND  (@fth > 0 AND @fta >0 ) THEN 1
						WHEN betteam = 'o' AND ((@fth > 0 and @fta = 0) OR (@fta > 0 and @fth = 0)) THEN 1
						WHEN betteam = 'n' AND  (@fth = 0 AND @fta = 0) THEN 1
						ELSE -1
					END
				when 27 then -- To win to nil
					CASE
						WHEN betteam = 'h' AND (@fth > @fta AND @fta = 0 ) THEN 1
						WHEN betteam = 'a' AND (@fta > @fth AND @fth = 0 ) THEN 1
						ELSE -1
					END
				when 28 then -- 3-way handicap
					CASE
						WHEN betteam = '1' AND ( hdp2 - hdp1 + @fth - @fta) > 0 THEN 1
						WHEN betteam = '2' AND ( hdp1 - hdp2 + @fta - @fth) > 0 THEN 1
						WHEN betteam = 'x' AND ((hdp1 - hdp2) - (@fth - @fta)) = 0 THEN 1
						ELSE -1
					END
				when 121 then -- home no bet
					CASE
						WHEN (@fth - @fta) > 0 THEN 0
						WHEN betteam = 'x' AND (@fth - @fta) = 0 THEN 1
						WHEN betteam = 'a' AND (@fth - @fta) < 0 THEN 1
						ELSE -1
					END
				when 122 then -- away no bet
					CASE
						WHEN (@fth - @fta) < 0 THEN 0
						WHEN betteam = 'h' AND (@fth - @fta) > 0 THEN 1
						WHEN betteam = 'x' AND (@fth - @fta) = 0 THEN 1
						ELSE -1
					END
				when 123 then -- draw/no draw
					CASE						
						WHEN betteam = 'h' AND (@fth - @fta) = 0 THEN 1
						WHEN betteam = 'a' AND (@fth - @fta) <> 0 THEN 1
						ELSE -1
					END
			ELSE
				NULL  -- Not support bettype
			END, -- CASE bettype
	-- ========================
		ruben = CASE WHEN @modds IS NULL THEN 0 ELSE 1 END,
		winlostdate=@matchdate,
		[status]=
			case
				when @modds IS NULL then N'running'
				when @modds=0 then N'DRAW'
				when @modds<0 then N'LOSE'
				when @modds>0 then N'WON'
			end ,
		statusID = 
			case
				when @modds IS NULL then 0
				when @modds=0 then 111
				when @modds<0 then 113
				when @modds>0 then 112
			end ,
		statuswinlost=
			case
				when @modds<=-0.5 then 4 -- LOSE
				when @modds>= 0.5 then 2 -- WIN
				when @modds>0 then 1 -- Half WIN
				when @modds<0 then 3 -- Half LOSE
				else 0	-- DRAW
			end
	-- ========================
	FROM dbo.bettransm with (INDEX=IX_matchid)
	WHERE 
		matchid = @matchid
		AND bettype NOT IN (14, 127)
		AND statusID NOT IN (101,102)
	
	-- BetParlayDetail
	UPDATE pd
	SET
		@modds =
			CASE bettype
				when 1 then -- Handicap
					CASE betteam
					WHEN 'h' THEN (hdp2-hdp1) + (@fth - livehomescore) - (@fta - liveawayscore) 
					WHEN 'a' THEN (hdp1-hdp2) - (@fth - livehomescore) + (@fta - liveawayscore)
					END
				when 7 then -- 1st Handicap
					CASE betteam
					WHEN 'h' THEN (hdp2-hdp1) + (@hth - livehomescore) - (@hta - liveawayscore) 
					WHEN 'a' THEN (hdp1-hdp2) - (@hth - livehomescore) + (@hta - liveawayscore)
					END

				when 3 then -- Over/Under
					CASE betteam
					WHEN 'h' THEN (case when @TennisTotal IS NULL then @fth+@fta else @TennisTotal end) - hdp1 
					WHEN 'a' THEN hdp1 - (case when @TennisTotal IS NULL then @fth+@fta else @TennisTotal end)
					END
				when 8 then -- 1st Over/Under
					CASE betteam
					WHEN 'h' THEN (@hth+@hta) - hdp1
					WHEN 'a' THEN hdp1 - (@hth+@hta)
					END
				when 2 then -- Odd/Even
					case 
						when (betteam = 'h') AND ((case when @TennisTotal IS NULL then @fth+@fta else @TennisTotal end)&1 = 1) then 1
						when (betteam = 'a') AND ((case when @TennisTotal IS NULL then @fth+@fta else @TennisTotal end)&1 = 0) then 1
						else -1
					end
				when 12 then -- 1st Odd/Even
					case 
						when (betteam = 'h') AND ((@hth+@hta)&1 = 1) then 1
						when (betteam = 'a') AND ((@hth+@hta)&1 = 0) then 1
						else -1
					end
				when 4 then -- Correct Score
					case
					when betteam = ( CAST(@fth as varchar(4)) + ':' + CAST(@fta as varchar(4)) ) THEN 1
					when betteam = '5:0' AND (@fth - @fta) >=  5 THEN 1
					when betteam = '0:5' AND (@fth - @fta) <= -5 THEN 1
					else -1
					end
				when 30 then -- 1st Correct Score
					case
					when betteam = ( CAST(@hth as varchar(4)) + ':' + CAST(@hta as varchar(4)) ) THEN 1
					WHEN betteam = '4:0' AND (@hth - @hta) >=  4 THEN 1 -- 4UP for 1st Correct Score
					WHEN betteam = '0:4' AND (@hth - @hta) <=  -4 THEN 1 -- 4UP for 1st Correct Score
					when betteam = '5:0' AND (@hth - @hta) >=  5 THEN 1
					when betteam = '0:5' AND (@hth - @hta) <= -5 THEN 1
					else -1
					end					
				when 16 then -- HT/FT
					case
					when betteam =
						CASE WHEN @hth = @hta THEN '0' WHEN @hth > @hta THEN '1' ELSE '2' END + ':' +
						CASE WHEN @fth = @fta THEN '0' WHEN @fth > @fta THEN '1' ELSE '2' END
						THEN 1
					else -1
					end

				when 5 then -- 1x2
					case
					when (betteam = '1') AND (@fth > @fta) then 1
					when (betteam = '2') AND (@fta > @fth) then 1
					when (betteam = 'x') AND (@fth = @fta) then 1
					else -1
					end
				when 15 then -- 1st 1x2
					case 
					when (betteam = '1') AND (@hth > @hta) then 1
					when (betteam = '2') AND (@hta > @hth) then 1
					when (betteam = 'x') AND (@hth = @hta) then 1
					else -1
					end

				when 6 then -- Total Goal
					case when (
							case when @TennisTotal IS NULL then @fth+@fta else @TennisTotal end >= cast(left(betteam,1)as int) and
							case when @TennisTotal IS NULL then @fth+@fta else @TennisTotal end <= (
									case when right(betteam,1) = 'r' then 999 else 
									cast(right(betteam,1) as int) end
									)
							)  
					then 1 else -1 end

				when 126 then -- 1H Total Goal
					case when (
							case when @TennisTotal IS NULL then @hth+@hta else @TennisTotal end >= cast(left(betteam,1)as int) and
							case when @TennisTotal IS NULL then @hth+@hta else @TennisTotal end <= (
									case when right(betteam,1) = 'r' then 999 else 
									cast(right(betteam,1) as int) end
									)
							)  
					then 1 else -1 end

				when 13 then -- Clean Sheet
					CASE
						WHEN betteam = 'hy' AND @fta = 0 THEN 1
						WHEN betteam = 'hn' AND @fta > 0 THEN 1
						WHEN betteam = 'ay' AND @fth = 0 THEN 1
						WHEN betteam = 'an' AND @fth > 0 THEN 1
						ELSE -1
					END
				when 20 then -- Money Line
					CASE betteam
						WHEN 'h' THEN @fth - @fta
						ELSE @fta - @fth
					END
				when 21 then -- 1st Money Line
					CASE betteam
						WHEN 'h' THEN @hth - @hta
						ELSE @hta - @hth
					END
				when 24 then -- Double Chance
					CASE
						WHEN betteam = '1X' AND (@fth - @fta) >= 0 THEN 1
						WHEN betteam = '2X' AND (@fth - @fta) <= 0 THEN 1
						WHEN betteam = '12' AND (@fth - @fta) <> 0 THEN 1
						ELSE -1
					END
				when 25 then -- Draw No Bet
					CASE
						WHEN (@fth - @fta) = 0 THEN 0
						WHEN betteam = 'h' AND (@fth - @fta) > 0 THEN 1
						WHEN betteam = 'a' AND (@fth - @fta) < 0 THEN 1
						ELSE -1
					END
				when 26 then -- Both/One/Neither team to score
					CASE
						WHEN betteam = 'b' AND  (@fth > 0 AND @fta >0 ) THEN 1
						WHEN betteam = 'o' AND ((@fth > 0 and @fta = 0) OR (@fta > 0 and @fth = 0)) THEN 1
						WHEN betteam = 'n' AND  (@fth = 0 AND @fta = 0) THEN 1
						ELSE -1
					END
				when 27 then -- To win to nil
					CASE
						WHEN betteam = 'h' AND (@fth > @fta AND @fta = 0 ) THEN 1
						WHEN betteam = 'a' AND (@fta > @fth AND @fth = 0 ) THEN 1
						ELSE -1
					END
				when 28 then -- 3-way handicap
					CASE
						WHEN betteam = '1' AND ( hdp2 - hdp1 + @fth - @fta) > 0 THEN 1
						WHEN betteam = '2' AND ( hdp1 - hdp2 + @fta - @fth) > 0 THEN 1
						WHEN betteam = 'x' AND ((hdp1 - hdp2) - (@fth - @fta)) = 0 THEN 1
						ELSE -1
					END
				when 121 then -- home no bet
					CASE
						WHEN (@fth - @fta) > 0 THEN 0
						WHEN betteam = 'x' AND (@fth - @fta) = 0 THEN 1
						WHEN betteam = 'a' AND (@fth - @fta) < 0 THEN 1
						ELSE -1
					END
				when 122 then -- away no bet
					CASE
						WHEN (@fth - @fta) < 0 THEN 0
						WHEN betteam = 'h' AND (@fth - @fta) > 0 THEN 1
						WHEN betteam = 'x' AND (@fth - @fta) = 0 THEN 1
						ELSE -1
					END
				when 123 then -- draw/no draw
					CASE						
						WHEN betteam = 'h' AND (@fth - @fta) = 0 THEN 1
						WHEN betteam = 'a' AND (@fth - @fta) <> 0 THEN 1
						ELSE -1
					END
			ELSE
				NULL  -- Not support bettype
			END, -- CASE bettype
	-- ========================
		winlostdate=@matchdate,
		statusID = 
			case
				when @modds IS NULL then 0
				when @modds=0 then 111
				when @modds<0 then 113
				when @modds>0 then 112
			end ,
		statuswinlost=
			case
				when @modds<=-0.5 then 4 -- LOSE
				when @modds>= 0.5 then 2 -- WIN
				when @modds>0 then 1 -- Half WIN
				when @modds<0 then 3 -- Half LOSE
				else 0	-- DRAW
			end
	-- ========================
	FROM dbo.BetParlayDetail pd with (updlock, INDEX=IX_matchid)
	WHERE bettype not IN (14, 127) AND matchid = @matchid AND statusID NOT IN (101,102)
END
-- ===================================================
-- ===================================================
GO

GO
GRANT EXECUTE ON [dbo].[Admin_Calculate_9m] TO [aplweb]

