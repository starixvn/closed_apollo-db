USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_UpdateBetLimit]    Script Date: 6/29/2013 9:09:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_UpdateBetLimit]
	@ActorAgentId	INT				= NULL,
	@AgentId		INT,
	@BetLimit		VARCHAR(MAX)	= '',
	@Language		VARCHAR(5)		= 'en-US',
	@ErrCode		INT				= 0			OUTPUT,
	@ErrMsg			NVARCHAR(1000)	= ''		OUTPUT
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Update agent bet limit
 * DB			: SVRCUST.CustDB
 * Revisions	:
 *	• 20132702@Edward	: Implement
 * Parameters:
 *	• @BetLimit : 
		<ROOT>
			<BetLimit SportType="4" BetType="4" Min="1" Max="1" MaxPerMatch="1"></BetLimit>
		</ROOT>
 *  
 */

BEGIN
	
	SET NOCOUNT ON
	
	-- Check update permission
	DECLARE @hasPermission BIT

	EXEC dbo.Age_Agent_CheckUpdatePermission @ActorAgentId, @AgentId, 1, @hasPermission OUTPUT 
	
	IF @hasPermission = 0
		BEGIN
			SELECT	
				@ErrCode = 1000,
				@ErrMsg = 
					CASE @Language
						WHEN 'en-US' THEN 'You do not have permission to update setting'
						ELSE [dbo].f_Msg_GetContentById (1000, @Language)
					END
			RETURN
		END	

	-- For write log
    DECLARE @startRun			DATETIME
			,@endRun			DATETIME
			,@duration			INT
			,@logSPData			VARCHAR(5000)
			,@logSPDataOld		VARCHAR(5000)
			,@xml				XML

	SET @startRun = GETDATE()

	-- begin update	 
	IF @BetLimit <> ''
		BEGIN
			DECLARE 
				@agentHId	HIERARCHYID,
				@SUPERLEVEL	INT

			SET @SUPERLEVEL = 0

			-- Get agent hierarchy ID
			SELECT @agentHId = AgentHId
			FROM AgentInfo WITH (NOLOCK)
			WHERE AgentId = @AgentId

			DECLARE @BetLimitTable TABLE (
				SportType SMALLINT,
				BetType SMALLINT,
				MinBet MONEY,
				MaxBet MONEY,
				MaxPerMatch MONEY)

			DECLARE @BetLimitCompareTable TABLE (
				SportType SMALLINT,
				BetType SMALLINT,
				MaxMinBet MONEY,
				MinMaxBet MONEY,
				MinMaxPerMatch MONEY)

			-- For read xml
			DECLARE @DocHandler INT

			EXEC sp_xml_preparedocument @DocHandler OUTPUT, @BetLimit

			INSERT INTO @BetLimitTable (
				SportType,
				BetType,
				MinBet,
				MaxBet,
				MaxPerMatch)
			SELECT
				Data.SportType,
				Data.BetType,
				Data.Min,
				Data.Max,
				Data.MaxPerMatch
			FROM OPENXML (@DocHandler, '/ROOT/BetLimit',1) 
			WITH (			
				SportType		SMALLINT,
				BetType			SMALLINT,
				Min				MONEY,
				Max				MONEY,
				MaxPerMatch		MONEY
			) AS Data

			EXEC sp_xml_removedocument @DocHandler
			-- end read xml

			IF EXISTS (	SELECT TOP(1) *
						FROM 
							AgentBetLimit AS abt WITH (NOLOCK)
							INNER JOIN @BetLimitTable AS blt
							ON abt.SportType = blt.SportType
							AND abt.BetType = blt.BetType
						WHERE 
							abt.AgentId = @AgentId
							AND (abt.MinBet <> blt.MinBet
							OR abt.MaxBet <> blt.MaxBet
							OR abt.MaxPerMatch <> blt.MaxPerMatch) )
				BEGIN

					DECLARE 
						@sportType	INT,
						@betType	INT

					-- Check validate > 0	
					SELECT TOP(1) 
						@sportType	= SportType,
						@betType	= BetType
					FROM @BetLimitTable 
					WHERE MinBet < 0 OR MaxBet < 0 OR MaxPerMatch < 0
	
					IF @sportType IS NOT NULL 
						BEGIN
							SELECT 
								@ErrCode = 3000,
								@ErrMsg = 
									CASE @Language
										WHEN 'en-US' THEN 'Wrong Min bet/ Max bet/ Max per match' 
										ELSE [dbo].f_Msg_GetContentById (3000, @Language)
									END + ' (' 
										+ CASE WHEN @sportType = 99 AND @betType = 9
												THEN [dbo].f_Msg_GetContentById (4009, @Language)
												ELSE dbo.f_Sport_GetNameByType(@sportType, @Language) 
											END 
										+ ')'

							RETURN
						END	

					-- Check validate 
					SELECT TOP(1) 
						@sportType	= SportType,
						@betType	= BetType 
					FROM @BetLimitTable 
					WHERE FLOOR(MinBet)			< MinBet
						OR FLOOR(MaxBet)		< MaxBet
						OR FLOOR(MaxPerMatch)	< MaxPerMatch
	
					IF @sportType IS NOT NULL 
						BEGIN
							SELECT 
								@ErrCode = 3007,
								@ErrMsg = 
									CASE @Language
										WHEN 'en-US' THEN 'Invalid Min bet/ Max bet/ Max per match' 
										ELSE [dbo].f_Msg_GetContentById (3007, @Language)
									END + ' (' 
										+ CASE WHEN @sportType = 99 AND @betType = 9
												THEN [dbo].f_Msg_GetContentById (4009, @Language)
												ELSE dbo.f_Sport_GetNameByType(@sportType, @Language) 
											END
										+ ')'

							RETURN
						END

					-- Min Bet > Max Bet
					SELECT TOP(1) 
						@sportType	= SportType,
						@betType	= BetType 
					FROM @BetLimitTable 
					WHERE MinBet > MaxBet
	
					IF @sportType IS NOT NULL 
						BEGIN
							SELECT
								@ErrCode = 3004,
								@ErrMsg = 
									CASE @Language
										WHEN 'en-US' THEN 'Min Bet must be less than or equal to Max Bet' 
										ELSE [dbo].f_Msg_GetContentById (3004, @Language)
									END + ' (' 
										+ CASE WHEN @sportType = 99 AND @betType = 9
												THEN [dbo].f_Msg_GetContentById (4009, @Language)
												ELSE dbo.f_Sport_GetNameByType(@sportType, @Language) 
											END
										+ ')'
							RETURN
						END	
	
					-- Min Bet > Max Per Match
					SELECT TOP(1) 
						@sportType	= SportType,
						@betType	= BetType
					FROM @BetLimitTable 
					WHERE MinBet > MaxPerMatch
	
					IF @sportType IS NOT NULL 
						BEGIN
							SELECT
								@ErrCode = 3005,
								@ErrMsg = 
									CASE @Language
										WHEN 'en-US' THEN 'Min Bet must be less than or equal to Max Per Match' 
										ELSE [dbo].f_Msg_GetContentById (3005, @Language)
									END + ' (' 
										+ CASE WHEN @sportType = 99 AND @betType = 9
												THEN [dbo].f_Msg_GetContentById (4009, @Language)
												ELSE dbo.f_Sport_GetNameByType(@sportType, @Language) 
											END
										+ ')'

							RETURN
						END	

					-- Max Bet > Max Per Match
					SELECT TOP(1) 
						@sportType	= SportType,
						@betType	= BetType 
					FROM @BetLimitTable 
					WHERE MaxBet > MaxPerMatch
	
					IF @sportType IS NOT NULL 
						BEGIN
							SELECT 
								@ErrCode = 3006,
								@ErrMsg = 
									CASE @Language
										WHEN 'en-US' THEN 'Max Bet must be less than or equal to Max Per Match' 
										ELSE [dbo].f_Msg_GetContentById (3006, @Language)
									END + ' (' 
										+ CASE WHEN @sportType = 99 AND @betType = 9
												THEN [dbo].f_Msg_GetContentById (4009, @Language)
												ELSE dbo.f_Sport_GetNameByType(@sportType, @Language) 
											END
										+ ')'
							RETURN
						END	

					-- Get validate data
					INSERT INTO @BetLimitCompareTable(
						SportType,
						BetType,
						MaxMinBet,
						MinMaxBet,
						MinMaxPerMatch)
					SELECT 
						SportType,
						BetType,
						MAX(MinBet),
						MIN(MaxBet),
						MIN(MaxPerMatch)
					FROM AgentBetLimit WITH (NOLOCK)
					WHERE AgentId IN (	SELECT AgentId 
										FROM AgentInfo WITH (NOLOCK)
										WHERE 
											@AgentHId.IsDescendantOf(AgentHId) = 1 
											AND AgentId		<> @AgentId
											AND AgentLevel	<> @SUPERLEVEL )
					GROUP BY 
						SportType, 
						BetType

					-- Check validate min bet must be equal to or greater than parent
					SELECT TOP(1)
						@sportType	= btct.SportType,
						@betType	= btct.BetType
					FROM 
						@BetLimitCompareTable AS btct
						INNER JOIN @BetLimitTable AS btt 
						ON	btct.SportType = btt.SportType 
							AND btct.BetType = btt.BetType	
							AND btt.MinBet < btct.MaxMinBet

					IF @sportType IS NOT NULL 
						BEGIN
							SELECT 
								@ErrCode = 3001,
								@ErrMsg = 
									CASE @Language
										WHEN 'en-US' THEN 'Min bet must be equal to or greater than Parent Agent min bet' 
										ELSE [dbo].f_Msg_GetContentById (3001, @Language) 
									END	+ ' (' 
										+ CASE WHEN @sportType = 99 AND @betType = 9
												THEN [dbo].f_Msg_GetContentById (4009, @Language)
												ELSE dbo.f_Sport_GetNameByType(@sportType, @Language) 
											END
										+ ')'

							RETURN
						END	

					---- Check validate max bet must be equal to or less than parent
					SELECT TOP(1) 
						@sportType	= btct.SportType,
						@betType	= btct.BetType
					FROM 
						@BetLimitCompareTable AS btct
						INNER JOIN @BetLimitTable AS btt 
						ON 
							btct.SportType = btt.SportType 
							AND btct.BetType = btt.BetType
							AND btt.MaxBet > btct.MinMaxBet

					IF @sportType IS NOT NULL 
						BEGIN
							SELECT 
								@ErrCode	= 3002,
								@ErrMsg		= 
									CASE @Language
										WHEN 'en-US' THEN 'Max bet must be equal to or less than Parent Agent max bet' 
										ELSE [dbo].f_Msg_GetContentById (3002, @Language) 
									END	+ ' (' 
										+ CASE WHEN @sportType = 99 AND @betType = 9
												THEN [dbo].f_Msg_GetContentById (4009, @Language)
												ELSE dbo.f_Sport_GetNameByType(@sportType, @Language) 
											END
										+ ')'

							RETURN
						END	

					---- Check validate max per match must be equal to or less than parent
					SELECT TOP(1) 
						@sportType	= btct.SportType,
						@betType	= btct.BetType
					FROM 
						@BetLimitCompareTable AS btct
						INNER JOIN @BetLimitTable AS btt 
						ON 
							btct.SportType = btt.SportType 
							AND btct.BetType = btt.BetType	
							AND btt.MaxPerMatch > btct.MinMaxPerMatch

					IF @sportType IS NOT NULL 
						BEGIN
							SELECT 
								@ErrCode	= 3003,
								@ErrMsg		= 
									CASE @Language
										WHEN 'en-US' THEN 'Max per match must be equal to or less than Parent Agent max per match' 
										ELSE [dbo].f_Msg_GetContentById (3003, @Language) 
									END	+ ' (' 
										+ CASE WHEN @sportType = 99 AND @betType = 9
												THEN [dbo].f_Msg_GetContentById (4009, @Language)
												ELSE dbo.f_Sport_GetNameByType(@sportType, @Language) 
											END
										+ ')'
							RETURN
						END	
	
					-- write log before update
				
					SET @xml = (
						SELECT  
							abl.SportType		AS '@s'
							,abl.BetType		AS '@b'
							,abl.MinBet			AS '@mib'
							,abl.MaxBet			AS '@mab'
							,abl.MaxPerMatch	AS '@mam'
						FROM 
							AgentBetLimit AS abl WITH (NOLOCK)
							--INNER JOIN @BetLimitTable AS blt
							--	ON abl.SportType	= blt.SportType
							--	AND abl.BetType		= blt.BetType
						WHERE abl.AgentId = @AgentId
						FOR XML PATH('z'),ROOT('r')
					)

					SET @logSPDataOld = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

					-- end write log

					---- Update for current agent, not effect for all line
					UPDATE abt 
					SET 
						abt.MinBet		= blt.MinBet,
						abt.MaxBet		= blt.MaxBet,
						abt.MaxPerMatch	= blt.MaxPerMatch
					FROM 
						AgentBetLimit AS abt WITH (ROWLOCK, UPDLOCK)
						INNER JOIN @BetLimitTable AS blt 
							ON blt.SportType	= abt.SportType 
							AND blt.BetType		= abt.BetType
					WHERE AgentId = @AgentId 

					-- write log after update
				
					SET @xml = (
						SELECT  
							blt.SportType		AS '@s'
							,blt.BetType		AS '@b'
							,blt.MinBet			AS '@mib'
							,blt.MaxBet			AS '@mab'
							,blt.MaxPerMatch	AS '@mam'
						FROM @BetLimitTable AS blt
						FOR XML PATH('z'), ROOT('r')
					)

					SET @logSPData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

					-- end write log
				END
			

			SET @endRun		= GETDATE()
			SET @duration	= DATEDIFF(MILLISECOND, @startRun, @endRun)

			IF @@ERROR = 0
				BEGIN TRY
					EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpAgent
					@UserId			= @ActorAgentId,
					@SPName			= 'Age_Agent_UpdateBetLimit',
					@LogDate		= @startRun,
					@AgentId		= @AgentId,
					@Duration		= @Duration,
					@Data			= @logSPData,
					@OldData		= @logSPDataOld
				END	TRY
				BEGIN CATCH
					EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpAgent
					@UserId			= @ActorAgentId,
					@SPName			= 'Age_Agent_UpdateBetLimit',
					@LogDate		= @startRun,
					@AgentId		= @AgentId,
					@Duration		= @Duration,
					@Data			= @logSPData,
					@OldData		= @logSPDataOld
				END CATCH
		END 
END
