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
	
	-- for web to change status hedge match to complete (ignore hedge match)
	IF @Command = 'Hedge-Update'
	BEGIN
		UPDATE dbo.match with (ROWLOCK,UPDLOCK)
		SET			
			eventstatus_ext = N'completed',								
			changetime_ext = GETDATE(),
			settleTime_ext = GETDATE()							
		WHERE matchid = @MatchID
	END
	ELSE
	IF @Command = 'Admin_Settlement_1-UNDO'
	BEGIN		
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
		SET eventstatus_ext = 'running', finalhomescore_ext = NULL, finalawayscore_ext = NULL, hthomescore_ext = NULL, htawayscore_ext = NULL, betstatus_ext = N'', GoalRecord_ext = ''
			, changetime_ext = GETDATE(), settleTime_ext = GETDATE()			
		WHERE matchid = @MatchID-- and eventstatus_ext = 'completed'

		-- delete disabled actions before the undo action
		DELETE [dbo].[match_log] with (ROWLOCK,UPDLOCK)
		WHERE matchid = @MatchID AND (Disabled=1 or ActionId=0)
	END
	ELSE IF @Command = 'Admin_Settlement_1-CAL'
	BEGIN
		UPDATE dbo.match with (ROWLOCK,UPDLOCK)
		SET
			finalhomescore_ext = @FTHome, finalawayscore_ext = @FTAway,
			hthomescore_ext = @HTHome, htawayscore_ext = @HTAway,
			betstatus_ext = CASE WHEN @action = 'CAL-FT' AND CHARINDEX('Refund HT;',betstatus_ext)>0 THEN 'Refund HT;' + ISNULL(@betstatus,'') ELSE @betstatus END,
			GoalRecord_ext = CASE WHEN @GoalRecord IS NULL OR @GoalRecord = '' THEN GoalRecord_ext ELSE @GoalRecord END,
			eventstatus_ext = CASE	WHEN @action = 'CAL' THEN N'completed'
								WHEN @action = 'CAL-HT' AND @FTDone = 1 THEN N'completed'
								WHEN @action = 'CAL-FT' AND @HTDone = 1 THEN N'completed'
							ELSE eventstatus_ext END,
			changetime_ext = GETDATE(),
			settleTime_ext = CASE 
							WHEN @action = 'CAL' THEN GETDATE()
							WHEN @action = 'CAL-FT' THEN GETDATE()
							ELSE settleTime_ext END	
		WHERE matchid = @MatchID
	END
	ELSE IF @Command = 'Admin_Settlement_Refund_All'
	BEGIN
		UPDATE match WITH(ROWLOCK,UPDLOCK) 
		SET eventstatus_ext='Completed', --ruben=1, 
			finalhomescore_ext=0, finalawayscore_ext=0, hthomescore_ext=0, htawayscore_ext=0,betstatus_ext='Refund', GoalRecord_ext =''
			, changetime_ext = GETDATE(), settleTime_ext = GETDATE()
		WHERE matchid=@MatchID
	END
	ELSE IF @Command = 'Admin_Settlement_RefundFT'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK) 
		SET finalhomescore_ext=0, finalawayscore_ext=0, 
			betstatus_ext = CASE WHEN CHARINDEX('Refund;', betstatus_ext) > 0 THEN betstatus_ext ELSE 'Refund FT;' + replace(ISNULL(betstatus_ext,''), 'Refund FT;', '') END ,
			eventstatus_ext = 'Completed', changetime_ext = GETDATE(), settleTime_ext = GETDATE()
		WHERE matchid=@MatchID AND @HTDone = 1

		--- get rowcount
		SET @RowCount = @@ROWCOUNT
	END
	ELSE IF @Command = 'Admin_Settlement_RefundHT'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK) 
		SET hthomescore_ext=0, htawayscore_ext=0, 
			betstatus_ext = CASE WHEN CHARINDEX('Refund;', betstatus_ext) > 0 THEN betstatus_ext ELSE 'Refund HT;' + replace(ISNULL(betstatus_ext,''), 'Refund HT;', '') END,
			changetime_ext = GETDATE()
		WHERE matchid=@MatchID

		--- get rowcount
		SET @RowCount = @@ROWCOUNT
	END
	ELSE IF @Command = 'Admin_Settlement_FGLG'
	BEGIN
		UPDATE match WITH(ROWLOCK,UPDLOCK)
		SET	betstatus_ext = @betstatus, GoalRecord_ext = @GoalRecord, changetime_ext = GETDATE()
		WHERE matchid = @MatchID
	END
	ELSE IF @Command = 'Admin_Settlement_Parlay'
	BEGIN
		UPDATE match WITH(ROWLOCK,UPDLOCK) SET multiple=multiple, changetime_ext = GETDATE() WHERE matchid=@MatchID
	END
	ELSE IF @Command = 'Admin_Settlement_s161-Refund'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
		SET betstatus_ext = 'Refund',
			eventstatus_ext = 'Completed', changetime_ext = CURRENT_TIMESTAMP, settleTime_ext = CURRENT_TIMESTAMP
		WHERE matchid=@MatchID
	END
	ELSE IF @Command = 'Admin_Settlement_s161-Refund_FT'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
		SET eventstatus_ext = 'Completed',
			betstatus_ext = 'Refund FT',
			changetime_ext = CURRENT_TIMESTAMP

		WHERE matchid=@MatchID
	END
	ELSE IF @Command = 'Admin_Settlement_s161-CAL'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
		SET		
			betstatus_ext = '',
			eventstatus_ext = 'Completed',
			changetime_ext = CURRENT_TIMESTAMP,
			settleTime_ext = CURRENT_TIMESTAMP
		WHERE matchid = @MatchID
	END
	--IF @Command = 'Admin_Settlement_s162-Refund'
	--BEGIN
	--	UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
	--	SET betstatus_ext = 'Refund',
	--		eventstatus_ext = 'Completed', changetime_ext = CURRENT_TIMESTAMP, settleTime_ext = CURRENT_TIMESTAMP
	--	WHERE matchid=@MatchID
	--END
	--IF @Command = 'Admin_Settlement_s162-CAL'
	--BEGIN
	--	UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
	--	SET		
	--		eventstatus_ext = 'Completed',
	--		changetime_ext = CURRENT_TIMESTAMP,
	--		settleTime_ext = CURRENT_TIMESTAMP
	--	WHERE matchid = @MatchID
	--END
	--IF @Command = 'Admin_Settlement_s162-1102-CAL'
	--BEGIN
	--	select @betstatus_ext = Resource_en from RefResource with (rowlock) 
	--	where refid ='RouNumProperty' and 
	--	resourceid in (select finalhomescore_ext from  match with (rowlock) where matchid = @MatchID)
		
	--	UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
	--	SET		
	--		betstatus_ext = @betstatus_ext,
	--		eventstatus_ext = 'Completed',
	--		changetime_ext = CURRENT_TIMESTAMP,
	--		settleTime_ext = CURRENT_TIMESTAMP
	--	WHERE matchid = @MatchID
	--END
	--IF @Command = 'Admin_Settlement_SS-CAL'
	--BEGIN
	--	UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
	--	SET		
	--		eventstatus_ext = 'Completed',
	--		changetime_ext = CURRENT_TIMESTAMP,
	--		settleTime_ext = CURRENT_TIMESTAMP
	--	WHERE matchid = @MatchID
	--END
/*
	IF @Command = 'Admin_Settlement_SS-Refund'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
		SET betstatus_ext = 'Refund',
			eventstatus_ext = 'Completed', changetime_ext = CURRENT_TIMESTAMP, settleTime_ext = CURRENT_TIMESTAMP
		WHERE matchid=@MatchID
	END
*/
END

GO
GRANT EXECUTE ON [dbo].[Admin_Match_Update] TO [aplweb]