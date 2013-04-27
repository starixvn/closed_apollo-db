USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_UpdateStatus]    Script Date: 4/23/2013 12:52:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_UpdateStatus]
	@AgentId	INT,
	@Type		TINYINT,
	@Status		TINYINT,
	@Modifier	INT				= NULL,
	@LogDate	DATETIME		= NULL,
	@ErrCode	INT				= 0			OUTPUT,
	@ErrMsg		NVARCHAR(1000)	= ''		OUTPUT
AS

/**
 * Created by	: Kos
 * Date			: 20130415
 * Task			: Update agent status
 * DB			: APL.CustDB
 * Revisions	:
 *	• 20130417@Edward : Add @LogDate and Write log
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
			Status		AS '@as',
			BetStatus	AS '@bs'
		FROM AgentInfo WITH (NOLOCK)
		WHERE AgentId = @AgentId
		FOR XML PATH('z'), ROOT('r')
	)

	SET @logSPDataOld = REPLACE(CONVERT(varchar(max), @xml), '" />', '"/"')

	DECLARE @AgentHId HIERARCHYID
	DECLARE @CurrentStatus TINYINT
	DECLARE @CurrentBetStatus TINYINT
	DECLARE @CurrentUplineStatus TINYINT
	DECLARE @CurrentUplineBetStatus TINYINT
	DECLARE @CurrentAgentUserStatus TINYINT

	SELECT 
		@AgentHId = AgentHId,
		@CurrentStatus = Status,
		@CurrentBetStatus = BetStatus,
		@CurrentUplineStatus = UplineStatus,
		@CurrentUplineBetStatus = UplineBetStatus
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @AgentId

	SELECT @CurrentAgentUserStatus = Status
	FROM AgentUser WITH (NOLOCK)
	WHERE AgentUserId = @AgentId

	IF @Type = 1 		-- Account status
		BEGIN
			IF @Status <> 3 AND @CurrentStatus <> @Status	-- New status is not Locked
				BEGIN
					-- Update agent status
					UPDATE AgentInfo
					SET Status = @Status
					WHERE AgentId = @AgentId

					IF @@ERROR > 0
						BEGIN
							SELECT 
								@ErrCode = 1107, 
								@ErrMsg = 'Failed to update agent status [AgentId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
							RETURN
						END	

					-- Update downline status if upline status is Active
					IF @CurrentUplineStatus = 1
						BEGIN
							-- Update agent downline
							UPDATE AgentInfo
							SET UplineStatus = @Status
							WHERE 
								AgentHId.IsDescendantOf(@AgentHId) = 1
								AND AgentId <> @AgentId

							-- Update customer downline
							UPDATE CustInfo
							SET UplineStatus = @Status
							WHERE AgentId IN (	SELECT AgentId
												FROM AgentInfo WITH (NOLOCK)
												WHERE AgentHId.IsDescendantOf(@AgentHId) = 1 )
						END

					-- Update agent user status if new status is Active
					IF @Status = 1 AND @CurrentAgentUserStatus <> 1
						BEGIN
							UPDATE AgentUser
							SET Status = @Status
							WHERE AgentUserId = @AgentId

							IF @@ERROR > 0
								BEGIN
									SELECT 
										@ErrCode = 1207, 
										@ErrMsg = 'Failed to update agent user status [AgentUserId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
									RETURN
								END	
						END
				END
			ELSE IF @Status <> 2 AND @CurrentAgentUserStatus <> @Status		-- New status is not Stopped
				BEGIN
					-- Update agent user status
					UPDATE AgentUser
					SET Status = @Status
					WHERE AgentUserId = @AgentId

					IF @@ERROR > 0
						BEGIN
							SELECT 
								@ErrCode = 1207, 
								@ErrMsg = 'Failed to update agent user status [AgentUserId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
							RETURN
						END	
				END
		END
	ELSE IF @Type = 2 AND @CurrentBetStatus <> @Status	-- Bet status
		BEGIN
			-- Update agent bet status
			UPDATE AgentInfo
			SET BetStatus = @Status
			WHERE AgentId = @AgentId

			IF @@ERROR > 0
				BEGIN
					SELECT 
						@ErrCode = 1107, 
						@ErrMsg = 'Failed to update agent status [AgentId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
					RETURN
				END	

			-- Update downline bet status if upline bet status is Active
			IF @CurrentUplineBetStatus = 1
				BEGIN
					-- Update agent downline
					UPDATE AgentInfo
					SET UplineBetStatus = @Status
					WHERE 
						AgentHId.IsDescendantOf(@AgentHId) = 1
						AND AgentId <> @AgentId

					-- Update customer downline
					UPDATE CustInfo
					SET UplineBetStatus = @Status
					WHERE AgentId IN (	SELECT AgentId
										FROM AgentInfo WITH (NOLOCK)
										WHERE AgentHId.IsDescendantOf(@AgentHId) = 1 )
				END
		END
	
	SET @xml = (
		SELECT	
			@Type		AS '@t',
			Status		AS '@as',
			BetStatus	AS '@bs'
		FROM AgentInfo WITH (NOLOCK)
		WHERE AgentId = @AgentId
		FOR XML PATH('z'), ROOT('r')
	)

	SET @logSPData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	SET @endRun = GETDATE()  
	SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun) 

	IF @LogDate IS NULL
		SET @LogDate = GETDATE()	

	EXEC LogDB.dbo.Age_LogRunSp_Insert
		@UserId			= @Modifier,
		@SPName			= 'Age_Agent_UpdateStatus',
		@LogDate		= @LogDate,
		@ObjectId		= @AgentId,
		@ObjectTypeId	= 1,			-- Object type : Agent
		@Duration		= @Duration,
		@Data			= @logSPData,
		@OldData		= @logSPDataOld
		
END
