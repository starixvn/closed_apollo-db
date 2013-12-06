ALTER PROCEDURE [dbo].[Admin_Settlement_CloseMatch]
	@matchid int,
	@adminid int,	
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
as


/*
Created By: Bobby
Date: 2013-12-05
Task : Allow user to change match's event status to "Closed" manually
DB: SVRTXN/TransDB
Original: 

Revisions:
		
Param's Explanation:
• @matchid: matchid of match to close

*/
SET NOCOUNT ON 

IF (IsNull(@matchid,0) <= 0 OR IsNull(@adminid,0) <= 0)
BEGIN
	SELECT  @ErrCode = 100
		, @ErrMsg = 'This match or admin user is invalid.'; 
	RETURN;
END

/**begin to close match**/

--validate IBC match event status and Apolo match disabledAutoSettle
DECLARE @disabledAutoSettle bit = 0
	, @matchEvenStatus nvarchar(50)
	, @matchEvenStatusEx nvarchar(50);

SELECT TOP(1) @matchEvenStatus=LOWER(mt.eventstatus)
	, @matchEvenStatusEx=LOWER(mtex.eventstatus)  
	, @disabledAutoSettle=mtex.DisabledAutoSettle
FROM dbo.match_remark_ex mtex with (nolock)
JOIN dbo.match mt with (nolock) ON mtex.matchid=mt.matchid
WHERE mtex.matchid=@matchid

IF @matchEvenStatus='closed' 
	AND (@disabledAutoSettle=1 AND @matchEvenStatusEx = 'running')
BEGIN
	--validate trans to close
	IF(EXISTS(SELECT TOP(1) 1 FROM dbo.BetTrans trans with (nolock) 
				WHERE trans.matchid=@matchid))
	BEGIN
		SELECT @ErrCode = 104,
				@ErrMsg = 'Sorry!Operation failed because there exists bet tickets for this match.'
		RETURN;
	END

	--execute to close match
	BEGIN TRY
		EXEC [SVRPRO].[ProdDB].[dbo].[Admin_Match_Update] @Command='Admin_Settlement_CloseMatch', @MatchID=@matchid;

		SELECT @ErrMsg = 'Operation succeed.'
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 999 + ERROR_NUMBER(),--system error
				@ErrMsg = ERROR_MESSAGE();
	END CATCH
END
ELSE
BEGIN
	IF @matchEvenStatus IS NULL OR @disabledAutoSettle IS NULL
		SELECT  @ErrCode = 102,
				@ErrMsg = 'Sorry!Operation rejected because this macth was not exists.'
	ELSE IF(@disabledAutoSettle=0 OR @matchEvenStatusEx <> 'running')
		SELECT  @ErrCode = 103,
				@ErrMsg = 'Sorry!Operation rejected due to auto settlement constraint.'
	ELSE
		SELECT  @ErrCode = 101,
				@ErrMsg = 'Sorry!Operation rejected due to any constraints.'
	RETURN;
END

--write log
--IF (@@Error = 0)
--BEGIN
--	BEGIN TRY
--		EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
--			@UserID = @adminid,
--			@Matchid = @matchid, 
--			@KeyID = 1,
--			@ActionID = 110, 
--			@Remark = 'CLOSE SUCCESS'
--	END TRY
--	BEGIN CATCH
--		SELECT @Remark = 'CLOSE SUCCESS ErrMsg=' + left(ERROR_MESSAGE(), 400)
--		EXEC LogDB.dbo.WriteLog_Settlement_Checking 
--			@UserID = @adminid,
--			@Matchid = @matchid, 
--			@KeyID = 1,
--			@ActionID = 110, 
--			@Remark = @Remark
--	END CATCH
--END
--ELSE
--BEGIN
--	BEGIN TRY
--		EXEC SVRLOG.LogDB.dbo.WriteLog_Settlement_Checking 
--			@UserID = @adminid,
--			@Matchid = @matchid, 
--			@KeyID = 1,
--			@ActionID = 110, 
--			@Remark = 'CLOSE FAILED'
--	END TRY
--	BEGIN CATCH
--		SELECT @Remark = 'CLOSE FAILED ErrMsg=' + left(ERROR_MESSAGE(), 400)
--		EXEC LogDB.dbo.WriteLog_Settlement_Checking 
--			@UserID = @adminid,
--			@Matchid = @matchid, 
--			@KeyID = 1,
--			@ActionID = 110, 
--			@Remark = @Remark
--	END CATCH
--END

GO
GRANT EXECUTE ON [dbo].[Admin_Settlement_CloseMatch] TO [aplweb]
