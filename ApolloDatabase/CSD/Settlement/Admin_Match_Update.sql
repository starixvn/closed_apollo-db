alter PROCEDURE [dbo].[Admin_Match_Update]
(
	@Command VARCHAR(100),
	@MatchID INT,
	@FTHome SMALLINT = NULL,
	@FTAway SMALLINT = NULL,
	@HTHome SMALLINT = NULL,
	@HTAway SMALLINT = NULL,
	@betstatus NVARCHAR(50) = NULL,
	@GoalRecord VARCHAR(50) = NULL,
	@Action VARCHAR(10) = NULL,
	@FTDone BIT = 0,
	@HTDone BIT = 0,
	@RowCount INT = 0 OUTPUT,
	@Creator INT = 0
) 
AS
/*
	Created by: Dan
	Created date: 2013-03-08
	Task : Update information into match table (when run settlement)
	DB: SVRPRO/ProdDB
	Original: bodb02.[Admin_Match_Update]

	Revisions:
	
*/
BEGIN
	SET @betstatus = ISNULL(@betstatus, N'')

	IF NOT EXISTS (SELECT 1 FROM match_remark_ex WITH (NOLOCK) WHERE matchid = @matchid)
	INSERT INTO match_remark_ex (matchid) 
			VALUES (@matchid)

	-- for web to change status hedge match to complete (ignore hedge match)
	IF @Command = 'Hedge-Update'
	BEGIN
		UPDATE dbo.match_remark_ex with (ROWLOCK,UPDLOCK)
		SET			
			eventstatus = N'completed',								
			changetime = GETDATE(),
			settleTime = GETDATE()							
		WHERE matchid = @MatchID
	END
	ELSE
	IF @Command = 'Admin_Settlement_1-UNDO'
	BEGIN		
		UPDATE dbo.match_remark_ex WITH(ROWLOCK,UPDLOCK)
		SET eventstatus = 'running', finalhomescore = NULL, finalawayscore = NULL, hthomescore = NULL, htawayscore = NULL, betstatus = N'', GoalRecord = ''
			, changetime = GETDATE(), settleTime = GETDATE()			
		WHERE matchid = @MatchID-- and eventstatus = 'completed'

		/*
		-- delete disabled actions before the undo action
		DELETE [dbo].[match_log] with (ROWLOCK,UPDLOCK)
		WHERE matchid = @MatchID AND (Disabled=1 or ActionId=0)
		*/
	END
	ELSE IF @Command = 'Admin_Settlement_1-CAL'
	BEGIN
		UPDATE dbo.match_remark_ex with (ROWLOCK,UPDLOCK)
		SET
			finalhomescore = @FTHome, finalawayscore = @FTAway,
			hthomescore = @HTHome, htawayscore = @HTAway,
			betstatus = CASE WHEN @action = 'CAL-FT' AND CHARINDEX('Refund HT;',betstatus)>0 THEN 'Refund HT;' + ISNULL(@betstatus,'') ELSE @betstatus END,
			GoalRecord = CASE WHEN @GoalRecord IS NULL OR @GoalRecord = '' THEN GoalRecord ELSE @GoalRecord END,
			eventstatus = CASE	WHEN @action = 'CAL' THEN N'completed'
								WHEN @action = 'CAL-HT' AND @FTDone = 1 THEN N'completed'
								WHEN @action = 'CAL-FT' AND @HTDone = 1 THEN N'completed'
							ELSE eventstatus END,
			changetime = GETDATE(),
			settleTime = CASE 
							WHEN @action = 'CAL' THEN GETDATE()
							WHEN @action = 'CAL-FT' THEN GETDATE()
							ELSE settleTime END	
		WHERE matchid = @MatchID
	END
	ELSE IF @Command = 'Admin_Settlement_Refund_All'
	BEGIN				
		UPDATE match_remark_ex WITH(ROWLOCK,UPDLOCK) 
		SET eventstatus='Completed', ruben=1, finalhomescore=0, finalawayscore=0, hthomescore=0, htawayscore=0
			,betstatus= 'Refund' + CASE WHEN CHARINDEX('FL:',ISNULL(betstatus,'')) = 0 THEN '' ELSE ';' + SUBSTRING(ISNULL(betstatus,''),CHARINDEX('FL:',ISNULL(betstatus,'')),6) END	
			,GoalRecord =''
			,changetime = GETDATE(), settleTime = GETDATE()
		WHERE matchid=@MatchID
	END
	ELSE IF @Command = 'Admin_Settlement_RefundFT'
	BEGIN
		UPDATE dbo.match_remark_ex WITH(ROWLOCK,UPDLOCK) 
		SET finalhomescore=0, finalawayscore=0, 
			betstatus = CASE WHEN CHARINDEX('Refund;', betstatus) > 0 THEN betstatus ELSE 'Refund FT;' + replace(ISNULL(betstatus,''), 'Refund FT;', '') END ,
			eventstatus = 'Completed', changetime = GETDATE(), settleTime = GETDATE()
		WHERE matchid=@MatchID AND @HTDone = 1

		--- get rowcount
		SET @RowCount = @@ROWCOUNT
	END
	ELSE IF @Command = 'Admin_Settlement_RefundHT'
	BEGIN
		UPDATE dbo.match_remark_ex WITH(ROWLOCK,UPDLOCK) 
		SET hthomescore=0, htawayscore=0, 
			betstatus = CASE WHEN CHARINDEX('Refund;', betstatus) > 0 THEN betstatus ELSE 'Refund HT;' + replace(ISNULL(betstatus,''), 'Refund HT;', '') END,
			changetime = GETDATE()
		WHERE matchid=@MatchID

		--- get rowcount
		SET @RowCount = @@ROWCOUNT
	END
	ELSE IF @Command = 'Admin_Settlement_FGLG'
	BEGIN
		UPDATE dbo.match_remark_ex WITH(ROWLOCK,UPDLOCK)
		SET	betstatus = @betstatus, GoalRecord = @GoalRecord, changetime = GETDATE()
		WHERE matchid = @MatchID
	END
	IF @Command = 'Admin_Settlement_Refund_FGLG'
	BEGIN
		UPDATE dbo.match_remark_ex WITH(ROWLOCK,UPDLOCK) 
		SET betstatus = @BetStatus, changetime = GETDATE() 
		WHERE matchid=@MatchID
	END
	ELSE IF @Command = 'Admin_Settlement_Parlay'
	BEGIN
		UPDATE dbo.match_remark_ex WITH(ROWLOCK,UPDLOCK) SET multiple=multiple, changetime = GETDATE() WHERE matchid=@MatchID
	END
	ELSE IF @Command = 'Admin_Settlement_s161-Refund'
	BEGIN
		UPDATE dbo.match_remark_ex WITH(ROWLOCK,UPDLOCK)
		SET betstatus = 'Refund',
			eventstatus = 'Completed', changetime = CURRENT_TIMESTAMP, settleTime = CURRENT_TIMESTAMP
		WHERE matchid=@MatchID
	END
	ELSE IF @Command = 'Admin_Settlement_s161-Refund_FT'
	BEGIN
		UPDATE dbo.match_remark_ex WITH(ROWLOCK,UPDLOCK)
		SET eventstatus = 'Completed',
			betstatus = 'Refund FT',
			changetime = CURRENT_TIMESTAMP

		WHERE matchid=@MatchID
	END
	ELSE IF @Command = 'Admin_Settlement_s161-CAL'
	BEGIN
		UPDATE dbo.match_remark_ex WITH(ROWLOCK,UPDLOCK)
		SET		
			betstatus = '',
			eventstatus = 'Completed',
			changetime = CURRENT_TIMESTAMP,
			settleTime = CURRENT_TIMESTAMP
		WHERE matchid = @MatchID
	END
	/**@bobby: add to close match**/
	ELSE IF @Command = 'Admin_Settlement_CloseMatch'
	BEGIN
		UPDATE dbo.match_remark_ex WITH(ROWLOCK,UPDLOCK)
		SET		
			betstatus = '',
			eventstatus = 'Closed',
			changetime = CURRENT_TIMESTAMP,
			settleTime = CURRENT_TIMESTAMP
		WHERE matchid = @MatchID
	END
	
END

GO
GRANT EXECUTE ON [dbo].[Admin_Match_Update] TO [aplweb]