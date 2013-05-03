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

IF NOT EXISTS (SELECT * FROM match_remark_ex WITH (NOLOCK) WHERE matchid = @matchid)
	INSERT INTO match_remark_ex (matchid) 
			VALUES (@matchid)

DECLARE @IsHTCal BIT, @Calculate BIT--, @IsPending BIT
SELECT	@IsHTCal = IsHTCal, @Calculate = Calculate--, @IsPending = IsPending
FROM	match_remark_ex WITH (NOLOCK)
WHERE	matchid = @matchid 

--IF @command = 'Q' UPDATE match_remark with (rowlock, updlock) SET Calculate = 0, multiple = 0, calrefund = 0, calStatus = 'Q' WHERE matchid = @matchid
IF @command = 'C' 
	UPDATE match_remark_ex with (rowlock, updlock) 
	SET Calculate = 1, calrefund = 0, IsHTCal = 1
	WHERE matchid = @matchid -- whole match Calculated

IF @command = 'H'  -- Half Time Calculated
UPDATE match_remark_ex with (rowlock, updlock) 
SET		IsHTCal = 1 
WHERE	matchid = @matchid -- Half Time Calculated

IF @command = 'F' UPDATE match_remark_ex with (rowlock, updlock) SET Calculate = 0, IsHTCal = 0, calrefund = 1 WHERE matchid = @matchid -- Match refund

IF @command = 'M' UPDATE match_remark_ex with (rowlock, updlock) SET multiple = 1, refund = 0 WHERE matchid = @matchid -- Mix Parlay Calculated
IF @command = 'R' UPDATE match_remark_ex with (rowlock, updlock) SET multiple = 0, refund = 1 WHERE matchid = @matchid -- Mix Parlay refund

IF @command = 'U' UPDATE match_remark_ex with (rowlock, updlock) SET IsHTCal = 0, Calculate = 0, multiple = 0, calrefund = 0, refund = 0 WHERE matchid = @matchid -- [U]ndo settlement


--DELETE FROM match_remark WHERE matchid IN (SELECT matchid FROM match14 with (nolock))

GO
GRANT EXECUTE ON [dbo].[Admin_Match_UpdateMatchRemark] TO [aplweb]
GO
