CREATE PROCEDURE [dbo].[Acc_Rpt_TicketsListing]
	@MatchId INT,
	@BetTypes VARCHAR(1000) ,
	@BetTypesLive VARCHAR(1000) ,
	@LiveType SMALLINT = 2,
	@LiveHomeScore smallint = NULL,
    @LiveAwayscore smallint = NULL,
    @FromTransdate Datetime = NULL,
	@ToTransdate Datetime = NULL,
	@Type SMALLINT = 0,
    @SAFilter tinyint = 0, 		
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg VARCHAR(1000) = '' OUTPUT
AS
/*	Created by: @Sophia
	Date: 20130228
	Task: Show Tickets Listing
	DB: SVRCSD.RepDB

	Revisions:	
		
	Param's Explanation:
	- @Type: sports type
		0: Sportsbook
		1: Number Game
	- @BetTypes: String of BetType for Sportsbook, Virtual sports and for Dead Ball - Number game
	- @BetTypesLive: String of BetType ONLY for Live - Number game 
	- @LiveType: Combo Type, used only for Sportsbook
		0: Dead ball
		1: Live ball
		2: All	
	- Because the interface is separated with sportbook and number game
		==>	SportsBook: Use @BetTypes and @LiveType to indicate Live ball or Dead ball
			Number game: Use @BetTypes and @BetTypesLive to indicate Live ball or Dead ball
    - @SAFilter: 
      + 0: All tickets
      + 1: Normal tickets only
      + 2: SA tickets only	  		
*/

SET NOCOUNT ON
--- Check MatchId
DECLARE @Matchcode nvarchar(100), @homeid int, @awayid int, @eventdate datetime, @IsNeutral bit, @sporttype smallint
SET @sporttype = 0

---- If number game or virtual sports then don't care @livetype , so set @LiveType to zero
IF @Type = 1 or @Type = 2
SELECT @LiveType = 0

----Show Match description
SELECT	@Matchcode = Matchcode, @homeid = homeid, @awayid = awayid, @eventdate = eventdate, @IsNeutral = IsNeutral, @sporttype = sporttype
FROM	Match  WITH (NOLOCK)
WHERE	MatchId = @MatchId
 
IF ISNULL(@sporttype,0) = 0 OR (@sporttype > 99 and @sporttype <> 161)
BEGIN 
	SET @ErrCode = 1
	SET @ErrMsg ='Invalid MatchId.'   
	RETURN
END
ELSE
IF @sporttype > 99 AND @Type = 0  
BEGIN
	SET @ErrCode = 2  
	SET @ErrMsg ='This MatchId is not sportsbook.'  
	RETURN
END
ELSE
IF @sporttype <> 161 AND @Type = 1 
BEGIN 
	SET @ErrCode =  3  
	SET @ErrMsg ='This MatchId is not number game.' 
	RETURN
END 
ELSE
	SELECT @Matchcode as Matchcode, @homeid as homeid, @awayid as awayid, @eventdate as eventdate, @MatchId as MatchId, @IsNeutral as IsNeutral

---------
DECLARE @TmpTotal TABLE (OrderNo int, TotalTrans bigint, BetType smallint, LiveIndicator bit )

CREATE TABLE #TmpBetTrans (BetType smallint, liveindicator bit, statusID tinyint, MatchId int, cnt int)
INSERT INTO #TmpBetTrans

SELECT BetType, liveindicator , statusID, MatchId, count(transid) as cnt
FROM BetTrans WITH (NOLOCK)
WHERE MatchId = @MatchId
  AND statusID NOT IN (101,102,121)--('Void', 'Reject', 'Dummy')
  AND
   (   
    (
     BetType IN (SELECT CONVERT(INT,val) FROM dbo.StrSplit(@BetTypes,','))
     AND CASE WHEN @LiveType <> 2 THEN liveindicator ELSE 0 END = CASE WHEN @LiveType <> 2 THEN @LiveType ELSE 0 END
     AND LiveHomeScore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveType = 1 THEN @LiveHomeScore ELSE LiveHomeScore END
	 AND LiveAwayscore = CASE WHEN @LiveAwayscore IS NOT NULL AND @LiveType = 1 THEN @LiveAwayscore ELSE LiveAwayscore END
	 AND transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveType = 1 THEN @FromTransdate ELSE transdate END 
				   AND	   CASE WHEN @ToTransdate IS NOT NULL AND @LiveType = 1 THEN @ToTransdate ELSE transdate END 
    )
     OR
    (
     BetType IN (SELECT CONVERT(INT,val) FROM dbo.StrSplit(@BetTypesLive,','))
     AND liveindicator = 1 
     
    )
   )
   AND ISNULL(SecAcceptFlag,0) = CASE @SAFilter WHEN 0 then ISNULL(SecAcceptFlag,0) WHEN 1 THEN 0 WHEN 2 THEN 1 END
GROUP BY MatchId, BetType, liveindicator, statusid
 

	 
		IF @BetTypes <> '9' AND @BetTypes <> '29' AND @BetTypes <> '9,29'
			INSERT	INTO @TmpTotal (OrderNo, TotalTrans, BetType, LiveIndicator)
			SELECT	0 as OrderNo, sum(cnt) as TotalTrans, BetType, CASE WHEN @type = 1 THEN b.liveindicator ELSE 0 END
			FROM	#TmpBetTrans b WITH (NOLOCK)
			GROUP BY b.BetType, b.liveindicator

		---mix parlay
		IF charindex('9', @BetTypes , 1) <> 0
			INSERT INTO @TmpTotal (OrderNo, TotalTrans, BetType, LiveIndicator)
			SELECT	0 as OrderNo, Count(DISTINCT b.transid) as TotalTrans, b.BetType, 0
			FROM	BetTransm bm WITH (NOLOCK)
				INNER JOIN BetTrans b WITH (NOLOCK) ON bm.refno= b.refno
				INNER JOIN dbo.StrSplit(@BetTypes,',') t ON b.BetType = t.val
			WHERE	bm.MatchId = @MatchId 
					AND b.statusID NOT IN (101,102) ---('Void', 'Reject')
					AND b.BetType IN (9,29) AND b.MatchId IN (9,29)
					AND CASE WHEN @LiveType <> 2 THEN bm.liveindicator ELSE 0 END = CASE WHEN @LiveType <> 2 THEN @LiveType ELSE 0 END
					AND bm.LiveHomeScore = CASE WHEN @LiveHomeScore IS NOT NULL AND @LiveType = 1 THEN @LiveHomeScore ELSE bm.LiveHomeScore END
					AND bm.LiveAwayscore = CASE WHEN @LiveAwayscore IS NOT NULL AND @LiveType = 1 THEN @LiveAwayscore ELSE bm.LiveAwayscore END
					AND bm.transdate BETWEEN CASE WHEN @FromTransdate IS NOT NULL AND @LiveType = 1 THEN @FromTransdate ELSE bm.transdate END 
									 AND		CASE WHEN @ToTransdate IS NOT NULL AND @LiveType = 1 THEN @ToTransdate ELSE bm.transdate END
					AND CASE when @SAFilter = 2 then 0 else 1 END = 1
					AND (b.betid = 0 OR b.betid IS NULL)
			GROUP BY  b.BetType, bm.liveIndicator
			HAVING  Count(B.Refno) >0
	 	
	 
	 
SELECT SUM (TotalTrans) TotalTrans, OrderNo, BetType, LiveIndicator 
FROM @TmpTotal
GROUP BY OrderNo, BetType, LiveIndicator
ORDER BY OrderNo, BetType, LiveIndicator

DROP TABLE #TmpBetTrans

GO
GRANT EXECUTE ON [dbo].[Acc_Rpt_TicketsListing] TO [aplweb] AS [dbo]
GO
--GRANT VIEW DEFINITION ON [dbo].[Acc_Rpt_TicketsListing] TO [vnteam] AS [dbo]