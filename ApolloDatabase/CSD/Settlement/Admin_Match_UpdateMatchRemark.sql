ALTER PROCEDURE [dbo].[Admin_Match_UpdateMatchRemark]
	@matchid int,
	@command varchar(5),
	@ivalue bigint = NULL
/*  
	Created by: Dan
	Created date: 2013-03-08
	Task:  	--part of replication (call by settle_new_test2)
			--MUST modify in all replication if modify the code
	DB: SVRPRO/ProdDB
	Original SP: updateMatch_remark
	
	Revisions:
	
	Param's Explanation: 
*/
AS
SET NOCOUNT ON 

DECLARE @IsHTCal BIT, @Calculate BIT--, @IsPending BIT
SELECT	@IsHTCal = IsHTCal_APL, @Calculate = Calculate_APL--, @IsPending = IsPending
FROM	match_remark WITH (NOLOCK)
WHERE	matchid = @matchid 


IF NOT EXISTS (SELECT * FROM match_remark with (nolock) WHERE matchid = @matchid)
	INSERT INTO match_remark (matchid, LiveTimer, LivePeriod, HomeRedCard, AwayRedCard) 
			VALUES (@matchid, '01 JAN 2000',0,0,0)

--IF @command = 'Q' UPDATE match_remark with (rowlock, updlock) SET Calculate_APL = 0, multiple_APL = 0, calrefund_APL_APL = 0, calStatus = 'Q' WHERE matchid = @matchid
IF @command = 'C' 
	UPDATE match_remark with (rowlock, updlock) 
	SET Calculate_APL = 1, calrefund_APL = 0, IsHTCal_APL = 1
	WHERE matchid = @matchid -- whole match Calculate_APLd

IF @command = 'H'  -- Half Time Calculate_APLd
UPDATE match_remark with (rowlock, updlock) 
SET		IsHTCal_APL = 1 
WHERE	matchid = @matchid -- Half Time Calculate_APLd

IF @command = 'F' UPDATE match_remark with (rowlock, updlock) SET Calculate_APL = 0, IsHTCal_APL = 0, calrefund_APL = 1 WHERE matchid = @matchid -- Match refund_APL

IF @command = 'M' UPDATE match_remark with (rowlock, updlock) SET multiple_APL = 1, refund_APL = 0 WHERE matchid = @matchid -- Mix Parlay Calculate_APLd
IF @command = 'R' UPDATE match_remark with (rowlock, updlock) SET multiple_APL = 0, refund_APL = 1 WHERE matchid = @matchid -- Mix Parlay refund_APL

IF @command = 'U' UPDATE match_remark with (rowlock, updlock) SET IsHTCal_APL = 0, Calculate_APL = 0, multiple_APL = 0, calrefund_APL = 0, refund_APL = 0 WHERE matchid = @matchid -- [U]ndo settlement

-- Total Bet control session
-- relative to UserControl of Totalbet access
	-- HedgeForecast, to tell this game have extra forecast
IF @command = 'HF'  UPDATE match_remark with (rowlock, updlock) SET HedgeForecast = 1 WHERE matchid = @matchid
	-- only select game .. for all bettype [Toggle Deny <match>]
IF @command = 'TDM' UPDATE match_remark with (rowlock, updlock) SET IsTotalBetDenied_1 = 1, IsTotalBetDenied_3 = 1, IsTotalBetDenied_7 = 1, IsTotalBetDenied_8 = 1 WHERE matchid = @matchid
	-- only selected game.. for selected bettype [Toggle Deny <bettype>]
IF @command = 'TD1' UPDATE match_remark with (rowlock, updlock) SET IsTotalBetDenied_1 = 1 WHERE matchid = @matchid
IF @command = 'TD3' UPDATE match_remark with (rowlock, updlock) SET IsTotalBetDenied_3 = 1 WHERE matchid = @matchid
IF @command = 'TD7' UPDATE match_remark with (rowlock, updlock) SET IsTotalBetDenied_7 = 1 WHERE matchid = @matchid
IF @command = 'TD8' UPDATE match_remark with (rowlock, updlock) SET IsTotalBetDenied_8 = 1 WHERE matchid = @matchid
	-- only selected game.. for paired bettype [Toggle Deny <bettype>]
IF @command IN ('TP1', 'TP7') UPDATE match_remark with (rowlock, updlock) SET IsTotalBetDenied_1 = 1, IsTotalBetDenied_7 = 1 WHERE matchid = @matchid
IF @command IN ('TP3', 'TP8') UPDATE match_remark with (rowlock, updlock) SET IsTotalBetDenied_3 = 1, IsTotalBetDenied_8 = 1 WHERE matchid = @matchid

	-- only selected game.. for selected bettype [Toggle Allow <bettype>]
IF @command = 'TA1' UPDATE match_remark with (rowlock, updlock) SET IsTotalBetDenied_1 = 0 WHERE matchid = @matchid
IF @command = 'TA3' UPDATE match_remark with (rowlock, updlock) SET IsTotalBetDenied_3 = 0 WHERE matchid = @matchid
IF @command = 'TA7' UPDATE match_remark with (rowlock, updlock) SET IsTotalBetDenied_7 = 0 WHERE matchid = @matchid
IF @command = 'TA8' UPDATE match_remark with (rowlock, updlock) SET IsTotalBetDenied_8 = 0 WHERE matchid = @matchid
	-- only selected game .. for all bettype [Toggle Allow <match>]
IF @command = 'TAM' UPDATE match_remark with (rowlock, updlock) SET IsTotalBetDenied_1 = 0, IsTotalBetDenied_3 = 0, IsTotalBetDenied_7 = 0, IsTotalBetDenied_8 = 0 WHERE matchid = @matchid
	-- only selected bettype .. for all games [Toggle Allow All <bettpe>]
IF @command = 'TAA1' UPDATE match_remark with (rowlock, updlock) SET IsTotalBetDenied_1 = 0 WHERE IsTotalBetDenied_1 = 1
IF @command = 'TAA3' UPDATE match_remark with (rowlock, updlock) SET IsTotalBetDenied_3 = 0 WHERE IsTotalBetDenied_3 = 1
IF @command = 'TAA7' UPDATE match_remark with (rowlock, updlock) SET IsTotalBetDenied_7 = 0 WHERE IsTotalBetDenied_7 = 1
IF @command = 'TAA8' UPDATE match_remark with (rowlock, updlock) SET IsTotalBetDenied_8 = 0 WHERE IsTotalBetDenied_8 = 1
	-- all bettype, all games [Toggle Allow All Matches]
IF @command = 'TAAM' UPDATE match_remark SET IsTotalBetDenied_1 = 0, IsTotalBetDenied_3 = 0, IsTotalBetDenied_7 = 0, IsTotalBetDenied_8 = 0

	-- LiveTimer section , @ivalue will pass adjustment (in seconds) to adjust with CURRENT_TIMESTAMP
IF @command = 'LP0' UPDATE match_remark with (rowlock, updlock) SET LivePeriod = 0 WHERE matchid = @matchid
IF @command = 'LP1' UPDATE match_remark with (rowlock, updlock) SET LivePeriod = 1, LiveTimer = DATEADD(second, @ivalue, CURRENT_TIMESTAMP) WHERE matchid = @matchid
IF @command = 'LP2' UPDATE match_remark with (rowlock, updlock) SET LivePeriod = 2, LiveTimer = DATEADD(second, @ivalue, CURRENT_TIMESTAMP) WHERE matchid = @matchid
	
--DELETE FROM match_remark WHERE matchid IN (SELECT matchid FROM match14 with (nolock))

GO
GRANT EXECUTE ON [dbo].[Admin_Match_UpdateMatchRemark] TO [aplweb]
GO
