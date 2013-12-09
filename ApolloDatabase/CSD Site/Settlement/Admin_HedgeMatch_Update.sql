ALTER PROCEDURE [dbo].[Admin_HedgeMatch_Update]
(
	@matchid INT
) 
AS
/**
 * Created by	: Kaden
 * Date			: 20130402
 * Task			: Update Match Hedge
 * DB			: SVRPRO/ProdDB
 * Revisions	:
 *	•
 * Parameters:
	@MatchID: main match
 */
BEGIN
	
	Declare @hedgeMatchId INT, @leagueid INT, @homeid INT, @awayid INT, @eventdate DATETIME     
	SELECT @leagueid = leagueid
		 , @homeid = homeid
		 , @awayid = awayid
		 , @eventdate = eventdate
	FROM
		match WITH (NOLOCK)
	WHERE
		matchid = @matchid

	SELECT @hedgeMatchId = match.matchid 
	FROM match WITH (NOLOCK) LEFT JOIN match_remark_ex mr WITH (NOLOCK) ON match.matchid = mr.matchid
	WHERE leagueid = @leagueid
		AND homeid = @homeid
		AND awayid = @awayid
		AND eventdate = @eventdate
		AND match.matchid <> @matchid
		AND matchcode LIKE '%hedge%'
		AND (mr.eventstatus IS NULL OR mr.eventstatus <> N'completed')

	IF(@hedgeMatchId>0)
	BEGIN 
		EXEC SVRPRO.ProdDB.dbo.Admin_Match_Update @Command = 'Hedge-Update', @MatchID = @hedgeMatchId
	END
END
GRANT EXECUTE ON [dbo].[Admin_HedgeMatch_Update] TO [aplweb]	