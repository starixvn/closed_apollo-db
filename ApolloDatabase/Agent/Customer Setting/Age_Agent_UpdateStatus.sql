USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_UpdateStatus]    Script Date: 9/5/2013 5:02:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_UpdateStatus_Xtest]
	@AgentId	INT,
	@Type		TINYINT,
	@Status		TINYINT,
	@Modifier	INT				= NULL,
	@ErrCode	INT				= 0			OUTPUT,
	@ErrMsg		NVARCHAR(1000)	= ''		OUTPUT
AS

/**
 * Created by	: Kos
 * Date			: 20130415
 * Task			: Update agent status
 * DB			: APL.CustDB
 * Revisions	:
 *	• 20130417@Edward : Write log
 *	• 20131120@Sophia	: Don't care UplineStatus, UplineBetStatus
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

	-- Check if agent ID is valid (not super)
	IF @AgentId = 1
		BEGIN
			SELECT 
				@ErrCode = 5106, 
				@ErrMsg = 'Invalid agent ID [AgentId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	-- Check if agent ID exists
	IF NOT EXISTS ( SELECT 1 FROM AgentInfo WITH (NOLOCK) WHERE AgentId = @AgentId )
		BEGIN
			SELECT 
				@ErrCode = 5100, 
				@ErrMsg = 'Agent ID not exist [AgentId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	-- Check if agent user ID exists
	IF NOT EXISTS ( SELECT 1 FROM AgentUser WITH (NOLOCK) WHERE AgentUserId = @AgentId )
		BEGIN
			SELECT 
				@ErrCode = 5300, 
				@ErrMsg = 'Agent user ID not exist [AgentUserId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
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
			@Type AS '@t',
			CASE 
				WHEN @Type = 1 THEN Status 
				ELSE BetStatus 
			END	AS '@s'
			--BetStatus	AS '@bs'
		FROM AgentInfo WITH (NOLOCK)
		WHERE AgentId = @AgentId
		FOR XML PATH('z'), ROOT('r')
	)

	SET @logSPDataOld = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	DECLARE @AgentHId HIERARCHYID
	DECLARE @CurrentStatus TINYINT
	DECLARE @CurrentBetStatus TINYINT
	--DECLARE @CurrentUplineStatus TINYINT
	--DECLARE @CurrentUplineBetStatus TINYINT
	DECLARE @CurrentAgentUserStatus TINYINT

	-- Get information
	SELECT 
		@AgentHId = AgentHId,
		@CurrentStatus = Status,
		@CurrentBetStatus = BetStatus
		--@CurrentUplineStatus = UplineStatus,
		--@CurrentUplineBetStatus = UplineBetStatus
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @AgentId

	SELECT @CurrentAgentUserStatus = Status
	FROM AgentUser WITH (NOLOCK)
	WHERE AgentUserId = @AgentId

	--DECLARE @Agent TABLE (AgentId INT)

	--INSERT @Agent
	--SELECT AgentId
	--FROM AgentInfo WITH (NOLOCK)
	--WHERE AgentHId.IsDescendantOf(@AgentHId) = 1

	IF @Type = 1 		-- Account status
		BEGIN
			IF @Status <> 3 AND @CurrentStatus <> @Status	-- New status is not Locked
				BEGIN
					-- Update agent status
					UPDATE AgentInfo WITH (ROWLOCK, UPDLOCK)
					SET Status = @Status
					WHERE AgentId = @AgentId

					IF @@ERROR > 0
						BEGIN
							SELECT 
								@ErrCode = 6100, 
								@ErrMsg = 'Failed to update agent status [AgentId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
							RETURN
						END	

					---- Update downline status if upline status is Active
					--IF @CurrentUplineStatus = 1
					--	BEGIN			  							
					--		IF @Status = 2
					--			BEGIN
					--				-- Update agent downline
					--				UPDATE AgentInfo WITH (ROWLOCK, UPDLOCK)
					--				SET UplineStatus = @Status
					--				WHERE AgentId IN ( SELECT AgentId FROM @Agent )
					--					AND AgentId <> @AgentId

					--				-- Update customer downline
					--				UPDATE CustInfo WITH (ROWLOCK, UPDLOCK)	
					--				SET UplineStatus = @Status
					--				WHERE AgentId IN ( SELECT AgentId FROM @Agent )	
					--			END
					--		ELSE
					--			BEGIN
					--				-- Update agent downline
					--				UPDATE ai 
					--				SET ai.UplineStatus = @Status
					--				FROM AgentInfo AS ai WITH (ROWLOCK, UPDLOCK)
					--				WHERE 
					--					ai.AgentId IN ( SELECT AgentId FROM @Agent )	
					--					AND ai.AgentId <> @AgentId
					--					AND NOT EXISTS (	SELECT 1 FROM AgentInfo AS t WITH (NOLOCK)
					--										WHERE ai.AgentHId.IsDescendantOf(t.AgentHId) = 1
					--											AND t.Status = 2
					--											AND t.AgentId <> ai.AgentId)
									
					--				-- Update customer downline
					--				UPDATE ci 
					--				SET ci.UplineStatus = CASE WHEN ai.Status = 1 AND ai.UplineStatus = 1 THEN 1 ELSE 2 END
					--				FROM 
					--					CustInfo AS ci WITH (ROWLOCK, UPDLOCK)											
					--					INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON ci.AgentId = ai.AgentId
					--				WHERE EXISTS (	SELECT 1 FROM AgentInfo WITH (NOLOCK)
					--								WHERE AgentHId.IsDescendantOf(@AgentHId) = 1 
					--									AND AgentId = ci.AgentId)	
					--					AND ci.UplineStatus <> CASE WHEN ai.Status = 1 AND ai.UplineStatus = 1 THEN 1 ELSE 2 END
					--			END
					--	END

					-- Update agent user status if new status is Active
					IF @Status = 1 AND @CurrentAgentUserStatus <> 1
						BEGIN
							UPDATE AgentUser WITH (ROWLOCK, UPDLOCK)
							SET Status = @Status
							WHERE AgentUserId = @AgentId

							IF @@ERROR > 0
								BEGIN
									SELECT 
										@ErrCode = 6300, 
										@ErrMsg = 'Failed to update agent user status [AgentUserId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
									RETURN
								END	
						END
				END
			ELSE IF @Status <> 2 AND @CurrentAgentUserStatus <> @Status		-- New status is not Stopped
				BEGIN
					-- Update agent user status
					UPDATE AgentUser WITH (ROWLOCK, UPDLOCK)
					SET Status = @Status
					WHERE AgentUserId = @AgentId

					IF @@ERROR > 0
						BEGIN
							SELECT 
								@ErrCode = 6300, 
								@ErrMsg = 'Failed to update agent user status [AgentUserId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
							RETURN
						END	
				END
		END
	ELSE IF @Type = 2 AND @CurrentBetStatus <> @Status	-- Bet status
		BEGIN
			-- Update agent bet status
			UPDATE AgentInfo WITH (ROWLOCK, UPDLOCK)
			SET BetStatus = @Status
			WHERE AgentId = @AgentId

			IF @@ERROR > 0
				BEGIN
					SELECT 
						@ErrCode = 6100, 
						@ErrMsg = 'Failed to update agent status [AgentId = ' + COALESCE(CAST(@AgentId AS VARCHAR(10)), SPACE(1)) + ']'
					RETURN
				END	

			---- Update downline bet status if upline bet status is Active
			--IF @CurrentUplineBetStatus = 1
			--	BEGIN
			--		IF @Status = 2
			--			BEGIN
			--				-- Update agent downline
			--				UPDATE AgentInfo WITH (ROWLOCK, UPDLOCK)
			--				SET UplineBetStatus = @Status
			--				WHERE 
			--					AgentId IN ( SELECT AgentId FROM @Agent )
			--					AND AgentId <> @AgentId

			--				-- Update customer downline						
			--				UPDATE CustInfo WITH (ROWLOCK, UPDLOCK)		
			--				SET UplineBetStatus = @Status
			--				WHERE AgentId IN ( SELECT AgentId FROM @Agent )
			--			END	
			--		ELSE
			--			BEGIN
			--				-- Update agent downline
			--				UPDATE ai 
			--				SET ai.UplineBetStatus = @Status
			--				FROM AgentInfo AS ai WITH (ROWLOCK, UPDLOCK)
			--				WHERE 
			--					ai.AgentId IN ( SELECT AgentId FROM @Agent )
			--					AND ai.AgentId <> @AgentId
			--					AND NOT EXISTS (	SELECT 1 FROM AgentInfo AS t WITH (NOLOCK)
			--										WHERE ai.AgentHId.IsDescendantOf(t.AgentHId) = 1
			--											AND t.BetStatus = 2
			--											AND t.AgentId <> ai.AgentId)
									
			--				-- Update customer downline
			--				UPDATE ci 
			--				SET ci.UplineBetStatus = CASE WHEN ai.BetStatus = 1 AND ai.UplineBetStatus = 1 THEN 1 ELSE 2 END
			--				FROM 
			--					CustInfo AS ci WITH (ROWLOCK, UPDLOCK)											
			--					INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON ci.AgentId = ai.AgentId
			--				WHERE EXISTS (	SELECT 1 FROM AgentInfo AS t WITH (NOLOCK)
			--								WHERE t.AgentHId.IsDescendantOf(@AgentHId) = 1 
			--									AND ci.AgentId = t.AgentId )	
			--					AND ci.UplineBetStatus <> CASE WHEN ai.BetStatus = 1 AND ai.UplineBetStatus = 1 THEN 1 ELSE 2 END
			--			END				
			--	END
		END
	
	SET @xml = (
		SELECT	
			@Type	AS '@t',
			@Status	AS '@s'
		FROM AgentInfo WITH (NOLOCK)
		WHERE AgentId = @AgentId
		FOR XML PATH('z'), ROOT('r')
	)

	SET @logSPData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	SET @endRun = GETDATE()  
	SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun) 
	
	SELECT @Modifier = ParentId
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @AgentId

	IF @@ERROR = 0
		BEGIN TRY
			EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpAgent
				@UserId			= @Modifier,
				@SPName			= 'Age_Agent_UpdateStatus',
				@LogDate		= @startRun,
				@AgentId		= @AgentId,
				@Duration		= @Duration,
				@Data			= @logSPData,
				@OldData		= @logSPDataOld
		END	TRY
		BEGIN CATCH
			EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpAgent
				@UserId			= @Modifier,
				@SPName			= 'Age_Agent_UpdateStatus',
				@LogDate		= @startRun,
				@AgentId		= @AgentId,
				@Duration		= @Duration,
				@Data			= @logSPData,
				@OldData		= @logSPDataOld
		END CATCH 	
END
