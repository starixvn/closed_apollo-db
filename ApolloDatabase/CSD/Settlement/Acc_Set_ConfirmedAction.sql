
ALTER PROCEDURE  [dbo].[Acc_Set_ConfirmedAction]		
@matchid INT,
@action smallint,
@fth smallint = NULL,
@fta smallint = NULL,
@hth smallint = NULL,
@hta smallint = NULL,
@goalrecord varchar(50)= NULL,
@betstatus nvarchar(50) = NULL
AS	
/**
 * Created by	: Kaden
 * Date			: 20130318
 * Task			: Update Confirmed Action value
 * DB			: SVRPRO/ProdDB
 * Revisions	:
 *	•
 * Parameters:
	@ConfirmedAction: new action
	@action: action key (0: Unsettlement; 1-9: Calculate; 11-19: Refund)
	@fth: finalhomescore,
	@fta: finalawayscore,
	@hth: hthomescore,
	@hta: htawayscore,
	@goalrecord: Goal Record,
	@betstatus: Bet Status
 */

SET NOCOUNT ON
BEGIN
	-- When action is UnSettle, we need update all action status before to true.
	IF(@action=0)
	BEGIN
		UPDATE match_log WITH(ROWLOCK, UPDLOCK) SET [Disabled] = 1	WHERE matchid = @matchid
	END
	-- Insert into match_log
	INSERT INTO match_log(Matchid, Hthomescore, Htawayscore, FinalHomeScore, FinalAwayScore, BetStatus, GoalRecord, ActionId)
	VALUES(@matchid, @hth, @hta, @fth, @fta, @betstatus, @goalrecord, @action)
END
GRANT EXECUTE ON [dbo].[Acc_Set_ConfirmedAction] TO [aplweb]	