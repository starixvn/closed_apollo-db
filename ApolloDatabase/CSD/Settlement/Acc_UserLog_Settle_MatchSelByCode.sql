ALTER PROCEDURE [dbo].[Acc_UserLog_Settle_MatchSelByCode] 
	@matchCode varchar(50) = '',
	@FromDate DATETIME = '',
	@ToDate DATETIME = '',
	@BalanceUpDay DATETIME = ''
AS
/**
 * Created by	: Kaden
 * Date			: 20130403
 * Task			: View match info - settlement log
 * DB			: SVRAGE/RepDB
 * Revisions	:
 *	•
 * Parameters:
	@matchCode: Match code
	@FromDate: From date
	@ToDate: To date
	@BalanceUpDay: Balance up day
*/

SET NOCOUNT ON
DECLARE @matchId INT

BEGIN TRY	
	SET @matchid = CASE WHEN ISNUMERIC(@matchcode) = 1 THEN CAST(@matchcode AS INT) ELSE NULL END
END TRY
BEGIN CATCH
	SET @matchid=NULL
END CATCH			

DECLARE  @TMP_ALL_MatchInfo TABLE (
									matchid INT, 
									homeid INT, 
									awayid INT, 
									eventdate DATETIME, 
									leagueid INT, 
									isneutral BIT, 
									sporttype INT,
									showtime nvarchar(50),
									homeid2 INT
								)

IF @Todate >= @BalanceUpDay    
BEGIN
	INSERT INTO @TMP_ALL_MatchInfo
	SELECT matchid , homeid , awayid ,  eventdate , leagueid, isneutral, sporttype, showtime, 
		   CASE WHEN ISNULL(homeid2,0) = 0 AND sporttype = 162 THEN 1101 ELSE homeid2 END as homeid2  -- contains bettype of Live Casino 
	FROM match WITH (NOLOCK)
	WHERE (matchId = @matchid or matchcode = @matchCode )
		and eventdate BETWEEN @FromDate and @ToDate

	IF @BalanceUpDay < @FromDate     
		SELECT @BalanceUpDay=@FromDate  
	INSERT INTO @TMP_ALL_MatchInfo
	SELECT matchid , homeid , awayid ,  eventdate , leagueid, isneutral, sporttype, showtime,
		   CASE WHEN ISNULL(homeid2,0) = 0 AND sporttype = 162 THEN 1101 ELSE homeid2 END AS homeid2  -- contains bettype of Live Casino 
	FROM match14 WITH (NOLOCK)
	WHERE (matchId = @matchid or matchcode = @matchCode )
		and eventdate BETWEEN @BalanceUpDay and @ToDate
END

IF @FromDate < @BalanceUpDay   
BEGIN
	IF @ToDate >= DATEADD(dd, -1, @BalanceUpDay)  
		SELECT @ToDate = DATEADD(dd, -1, @BalanceUpDay)  

	INSERT INTO @TMP_ALL_MatchInfo
	SELECT matchid , homeid , awayid , eventdate , leagueid, isneutral, sporttype, showtime,
		   CASE WHEN ISNULL(homeid2,0) = 0 AND sporttype = 162 THEN 1101 ELSE homeid2 END AS homeid2  -- contains bettype of Live Casino 
	FROM SVRARC.ArchiveDB.dbo.match_bk WITH (NOLOCK) 
	WHERE (matchId = @matchid or matchcode = @matchCode )
		AND eventdate BETWEEN @FromDate and @ToDate
END

SELECT t.matchid , t.homeid , t.awayid , t.eventdate , t.leagueid, isneutral, sporttype, showtime, homeid2 
FROM @TMP_ALL_MatchInfo t
GRANT EXECUTE ON [dbo].[Acc_UserLog_Settle_MatchSelByCode] TO [aplweb]