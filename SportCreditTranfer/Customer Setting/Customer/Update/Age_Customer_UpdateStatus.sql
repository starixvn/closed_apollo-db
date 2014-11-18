USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_UpdateStatus]    Script Date: 8/9/2013 9:04:22 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_UpdateStatus]
	@CustId		INT,	
	@Type		TINYINT,
	@Status		TINYINT,
	@Modifier	INT				= NULL,
	@ErrCode	INT				= 0			OUTPUT,
	@ErrMsg		NVARCHAR(1000)	= ''		OUTPUT	
AS

/**
 * Created by	: Kos
 * Date			: 20130415
 * Task			: Update customer status
 * DB			: APL.CustDB
 * Revisions	:
 *	• 
 * Parameters:
 *	• @Type		:	1 : Account status
 *					2 : Bet status
 *	• @Status	:	1 : Active
 *					2 : Stopped
 *					3 : Locked
 *  
 */

BEGIN
	
	SET NOCOUNT ON

	-- Check if customer ID exists
	IF NOT EXISTS ( SELECT 1 FROM CustInfo WITH (NOLOCK) WHERE CustId = @CustId )
		BEGIN
			SELECT 
				@ErrCode = 5200, 
				@ErrMsg = 'Customer ID not exist [CustId = ' + COALESCE(CAST(@CustId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	-- For write log
    DECLARE 
		@startRun		DATETIME,
		@endRun			DATETIME,
		@duration		INT,
		@logSPData		VARCHAR(5000),
		@logSPDataOld	VARCHAR(5000),
		@xml			XML			

	SET @startRun = GETDATE()

	SET @xml = (
		SELECT	
			@Type		AS '@t',
			CASE WHEN @Type = 1 THEN Status ELSE BetStatus END	AS '@s'
		FROM CustInfo WITH (NOLOCK)
		WHERE CustId = @CustId
		FOR XML PATH('z'), ROOT('r')
	)

	SET @logSPDataOld = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	IF @Type = 1  			-- Account status
		BEGIN
			UPDATE CustInfo WITH (ROWLOCK, UPDLOCK)
			SET Status = @Status
			WHERE 
				CustId = @CustId
				AND Status <> @Status

			IF @@ERROR > 0
				BEGIN
					SELECT 
						@ErrCode = 6200, 
						@ErrMsg = 'Failed to update customer status [CustId = ' + COALESCE(CAST(@CustId AS VARCHAR(10)), SPACE(1)) + ']'
					RETURN
				END	
		END
	ELSE IF @Type = 2		-- Bet status
		BEGIN
			UPDATE CustInfo WITH (ROWLOCK, UPDLOCK)
			SET BetStatus = @Status
			WHERE 
				CustId = @CustId
				AND BetStatus <> @Status

			IF @@ERROR > 0
				BEGIN
					SELECT 
						@ErrCode = 6200, 
						@ErrMsg = 'Failed to update customer status [CustId = ' + COALESCE(CAST(@CustId AS VARCHAR(10)), SPACE(1)) + ']'
					RETURN
				END	
		END
	
	SET @xml = (
		SELECT	
			@Type		AS '@t',
			@Status		AS '@s'			
		FROM CustInfo WITH (NOLOCK)
		WHERE CustId = @CustId
		FOR XML PATH('z'), ROOT('r')
	)

	SET @logSPData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	SET @endRun = GETDATE()
	SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun) 
	
	IF @Modifier IS NULL
		BEGIN	
			SELECT @Modifier = AgentId
			FROM CustInfo WITH (NOLOCK)
			WHERE CustId = @CustId
		END

	IF @@Error = 0
		BEGIN TRY
			EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpCust
			@UserId		= @Modifier,
			@SPName		= 'Age_Customer_UpdateStatus',
			@LogDate	= @startRun,
			@CustId		= @CustId,
			@Duration	= @Duration,
			@Data		= @logSPData,
			@OldData	= @logSPDataOld
		END TRY
		BEGIN CATCH
			EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpCust
			@UserId		= @Modifier,
			@SPName		= 'Age_Customer_UpdateStatus',
			@LogDate	= @startRun,
			@CustId		= @CustId,
			@Duration	= @Duration,
			@Data		= @logSPData,
			@OldData	= @logSPDataOld
		END CATCH

END
