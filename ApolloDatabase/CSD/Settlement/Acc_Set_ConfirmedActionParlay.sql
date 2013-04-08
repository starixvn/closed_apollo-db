
CREATE PROCEDURE [dbo].[Acc_Set_ConfirmedActionParlay]
(
	@matchids	VARCHAR(2000)
) 
AS
/**
 * Created by	: Kaden
 * Date			: 20130402
 * Task			: Update Confirmed Action value for Mix Parlay
 * DB			: APL.ProdDB
 * Revisions	:
 *	•
 * Parameters:
	@MatchIDs: list matchId
 */
BEGIN
	DECLARE @actionid int
	SET @actionid = 5

	INSERT INTO match_log(Matchid, ActionId)
	SELECT	matchid, @actionid	
	FROM SVRPRO.ProdDB.dbo.Match WITH (ROWLOCK)
	WHERE matchid IN (SELECT val FROM dbo.strSplit(@matchids,','))
END
GRANT EXECUTE ON [dbo].[Acc_Set_ConfirmedActionParlay] TO [aplweb]	