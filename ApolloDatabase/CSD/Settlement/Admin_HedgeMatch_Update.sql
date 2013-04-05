ALTER PROCEDURE [dbo].[Admin_HedgeMatch_Update]
(
	@matchid INT
) 
AS
/**
 * Created by	: Kaden
 * Date			: 20130402
 * Task			: Update Match Hedge
 * DB			: APL.ProdDB
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

	SELECT @hedgeMatchId = matchid FROM match WITH (NOLOCK)
	WHERE leagueid = @leagueid
		AND homeid = @homeid
		AND awayid = @awayid
		AND eventdate = @eventdate
		AND matchid <> @matchid
		AND matchcode LIKE '%hedge%'
		AND (eventstatus_ext IS NULL OR eventstatus_ext <> N'completed')

	IF(@hedgeMatchId>0)
	BEGIN 
		EXEC SVRPRO.ProdDB.dbo.Admin_Match_Update @Command = 'Hedge-Update', @MatchID = @hedgeMatchId
	END
END
GRANT EXECUTE ON [dbo].[Admin_HedgeMatch_Update] TO [aplweb]	