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
	
	IF @Command = 'Admin_Settlement_1-UNDO'
	BEGIN
		declare @posUndo int

		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
		SET eventstatus_APL = 'running', finalhomescore_APL = NULL, finalawayscore_APL = NULL, hthomescore_APL = NULL, htawayscore_APL = NULL, betstatus_APL = N'', GoalRecord_APL = ''
			, changetime_APL = GETDATE(), settleTime_APL = GETDATE()			
		WHERE matchid = @MatchID-- and eventstatus_APL = 'completed'
	END
	IF @Command = 'Admin_Settlement_1-CAL'
	BEGIN
		UPDATE dbo.match with (ROWLOCK,UPDLOCK)
		SET
			finalhomescore_APL = @FTHome, finalawayscore_APL = @FTAway,
			hthomescore_APL = @HTHome, htawayscore_APL = @HTAway,
			betstatus_APL = CASE WHEN @action = 'CAL-FT' AND CHARINDEX('Refund HT;',betstatus_APL)>0 THEN 'Refund HT;' + ISNULL(@betstatus,'') ELSE @betstatus END,
			GoalRecord_APL = CASE WHEN @GoalRecord IS NULL OR @GoalRecord = '' THEN GoalRecord_APL ELSE @GoalRecord END,
			eventstatus_APL = CASE	WHEN @action = 'CAL' THEN N'completed'
								WHEN @action = 'CAL-HT' AND @FTDone = 1 THEN N'completed'
								WHEN @action = 'CAL-FT' AND @HTDone = 1 THEN N'completed'
							ELSE eventstatus_APL END,
			changetime_APL = GETDATE(),
			settleTime_APL = CASE 
							WHEN @action = 'CAL' THEN GETDATE()
							WHEN @action = 'CAL-FT' THEN GETDATE()
							ELSE settleTime_APL END	
		WHERE matchid = @MatchID
	END
	IF @Command = 'Admin_Settlement_Refund_All'
	BEGIN
		UPDATE match WITH(ROWLOCK,UPDLOCK) 
		SET eventstatus_APL='Completed', --ruben=1, 
			finalhomescore_APL=0, finalawayscore_APL=0, hthomescore_APL=0, htawayscore_APL=0,betstatus_APL='Refund', GoalRecord_APL =''
			, changetime_APL = GETDATE(), settleTime_APL = GETDATE()
		WHERE matchid=@MatchID
	END
	IF @Command = 'Admin_Settlement_RefundFT'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK) 
		SET finalhomescore_APL=0, finalawayscore_APL=0, 
			betstatus_APL = CASE WHEN CHARINDEX('Refund;', betstatus_APL) > 0 THEN betstatus_APL ELSE 'Refund FT;' + replace(ISNULL(betstatus_APL,''), 'Refund FT;', '') END ,
			eventstatus_APL = 'Completed', changetime_APL = GETDATE(), settleTime_APL = GETDATE()
		WHERE matchid=@MatchID AND @HTDone = 1

		--- get rowcount
		SET @RowCount = @@ROWCOUNT
	END
	IF @Command = 'Admin_Settlement_RefundHT'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK) 
		SET hthomescore_APL=0, htawayscore_APL=0, 
			betstatus_APL = CASE WHEN CHARINDEX('Refund;', betstatus_APL) > 0 THEN betstatus_APL ELSE 'Refund HT;' + replace(ISNULL(betstatus_APL,''), 'Refund HT;', '') END,
			changetime_APL = GETDATE()
		WHERE matchid=@MatchID

		--- get rowcount
		SET @RowCount = @@ROWCOUNT
	END
	IF @Command = 'Admin_Settlement_FGLG'
	BEGIN
		UPDATE match WITH(ROWLOCK,UPDLOCK)
		SET	betstatus_APL = @betstatus, GoalRecord_APL = @GoalRecord, changetime_APL = GETDATE()
		WHERE matchid = @MatchID
	END
	IF @Command = 'Admin_Settlement_Parlay'
	BEGIN
		UPDATE match WITH(ROWLOCK,UPDLOCK) SET multiple=multiple, changetime_APL = GETDATE() WHERE matchid=@MatchID
	END
	IF @Command = 'Admin_Settlement_s161-Refund'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
		SET betstatus_APL = 'Refund',
			eventstatus_APL = 'Completed', changetime_APL = CURRENT_TIMESTAMP, settleTime_APL = CURRENT_TIMESTAMP
		WHERE matchid=@MatchID
	END
	IF @Command = 'Admin_Settlement_s161-Refund_FT'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
		SET eventstatus_APL = 'Completed',
			betstatus_APL = 'Refund FT',
			changetime_APL = CURRENT_TIMESTAMP

		WHERE matchid=@MatchID
	END
	IF @Command = 'Admin_Settlement_s161-CAL'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
		SET		
			betstatus_APL = '',
			eventstatus_APL = 'Completed',
			changetime_APL = CURRENT_TIMESTAMP,
			settleTime_APL = CURRENT_TIMESTAMP
		WHERE matchid = @MatchID
	END
	--IF @Command = 'Admin_Settlement_s162-Refund'
	--BEGIN
	--	UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
	--	SET betstatus_APL = 'Refund',
	--		eventstatus_APL = 'Completed', changetime_APL = CURRENT_TIMESTAMP, settleTime_APL = CURRENT_TIMESTAMP
	--	WHERE matchid=@MatchID
	--END
	--IF @Command = 'Admin_Settlement_s162-CAL'
	--BEGIN
	--	UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
	--	SET		
	--		eventstatus_APL = 'Completed',
	--		changetime_APL = CURRENT_TIMESTAMP,
	--		settleTime_APL = CURRENT_TIMESTAMP
	--	WHERE matchid = @MatchID
	--END
	--IF @Command = 'Admin_Settlement_s162-1102-CAL'
	--BEGIN
	--	select @betstatus_APL = Resource_en from RefResource with (rowlock) 
	--	where refid ='RouNumProperty' and 
	--	resourceid in (select finalhomescore_APL from  match with (rowlock) where matchid = @MatchID)
		
	--	UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
	--	SET		
	--		betstatus_APL = @betstatus_APL,
	--		eventstatus_APL = 'Completed',
	--		changetime_APL = CURRENT_TIMESTAMP,
	--		settleTime_APL = CURRENT_TIMESTAMP
	--	WHERE matchid = @MatchID
	--END
	--IF @Command = 'Admin_Settlement_SS-CAL'
	--BEGIN
	--	UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
	--	SET		
	--		eventstatus_APL = 'Completed',
	--		changetime_APL = CURRENT_TIMESTAMP,
	--		settleTime_APL = CURRENT_TIMESTAMP
	--	WHERE matchid = @MatchID
	--END
/*
	IF @Command = 'Admin_Settlement_SS-Refund'
	BEGIN
		UPDATE dbo.match WITH(ROWLOCK,UPDLOCK)
		SET betstatus_APL = 'Refund',
			eventstatus_APL = 'Completed', changetime_APL = CURRENT_TIMESTAMP, settleTime_APL = CURRENT_TIMESTAMP
		WHERE matchid=@MatchID
	END
*/
END

GO
GRANT EXECUTE ON [dbo].[Admin_Match_Update] TO [aplweb]