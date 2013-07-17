USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_UpdateBetLimit]    Script Date: 7/17/2013 4:22:26 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[Age_Agent_UpdateBetLimit]
	@ActorAgentId	INT				= NULL,
	@AdminId		INT				= NULL,
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
 *	• 20131707@Edward	: Add parameter @AdminId for write log
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
			DECLARE @agentHId		HIERARCHYID,
					@SUPERLEVEL		INT

			SET @SUPERLEVEL = 0

			-- Get agent hierarchy ID
			SELECT @agentHId		= AgentHId					
			FROM AgentInfo WITH (NOLOCK)
			WHERE AgentId = @AgentId

			DECLARE @TableAgent TABLE (
				AgentId		INT, 
				AgentLevel	SMALLINT, 
				Username	NVARCHAR(50) 
			)

			INSERT INTO @TableAgent
			SELECT 
				AgentId,
				AgentLevel,
				Username 
			FROM AgentInfo WITH (NOLOCK) 
			WHERE AgentHId.IsDescendantOf(@agentHId) = 1									

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
			
			DECLARE @BetLimitUpdateTable TABLE (
				AgentId	INT,
				SportType SMALLINT,
				BetType SMALLINT,
				MinBet MONEY,
				MaxBet MONEY,
				MaxPerMatch MONEY)

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
										WHEN 'en-US' THEN 'Wrong Single Game / Single Bet / Min Single Bet' 
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
										WHEN 'en-US' THEN 'Invalid Single Game / Single Bet / Min Single Bet' 
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
										WHEN 'en-US' THEN 'Min Single Bet must be less than or equal to Single Bet' 
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
										WHEN 'en-US' THEN 'Min Single Bet must be less than or equal to Single Game' 
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
										WHEN 'en-US' THEN 'Single Bet must be less than or equal to Single Game' 
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
										WHEN 'en-US' THEN 'Min Single Bet must be equal to or greater than Parent Agent Min Single Bet' 
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
										WHEN 'en-US' THEN 'Single Bet must be equal to or less than Parent Agent Single Bet' 
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
										WHEN 'en-US' THEN 'Single Game must be equal to or less than Parent Agent Single Game' 
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

					---- Update for direct member
					UPDATE cbt
					SET cbt.MinBet			= CASE WHEN cbt.MinBet < but.MinBet THEN but.MinBet ELSE cbt.MinBet END
						,cbt.MaxBet			= CASE WHEN cbt.MaxBet > but.MaxBet THEN but.MaxBet ELSE cbt.MaxBet END
						,cbt.MaxPerMatch	= CASE WHEN cbt.MaxPerMatch > but.MaxPerMatch THEN but.MaxPerMatch ELSE cbt.MaxPerMatch END
					FROM CustBetLimit AS cbt WITH (ROWLOCK, UPDLOCK)
						INNER JOIN CustInfo AS ci WITH (NOLOCK)
							ON cbt.CustId	= ci.CustId
						INNER JOIN @BetLimitTable AS but
							ON cbt.SportType	= but.SportType
							AND cbt.BetType		= but.BetType
					WHERE (cbt.MinBet		< but.MinBet
							OR cbt.MaxBet		> but.MaxBet
							OR cbt.MaxPerMatch	> but.MaxPerMatch)
						AND	ci.AgentId = @AgentId

					---- Get agent downline break rule
					INSERT INTO @BetLimitUpdateTable(
						AgentId
						,SportType
						,BetType
						,MinBet
						,MaxBet
						,MaxPerMatch
					)
					SELECT 
						abt.AgentId
						,abt.SportType
						,abt.BetType
						,bt.MinBet
						,bt.MaxBet
						,bt.MaxPerMatch
					FROM AgentBetLimit AS abt WITH (NOLOCK)
						INNER JOIN @TableAgent AS ta 
							ON abt.AgentId		= ta.AgentId
						INNER JOIN @BetLimitTable AS bt
							ON abt.SportType	= bt.SportType
							AND abt.BetType		= bt.BetType
					WHERE abt.MinBet		< bt.MinBet
						OR abt.MaxBet		> bt.MaxBet
						OR abt.MaxPerMatch	> bt.MaxPerMatch

					---- Update for agent downline
					UPDATE abt
					SET abt.MinBet			= CASE WHEN abt.MinBet < but.MinBet THEN but.MinBet ELSE abt.MinBet END
						,abt.MaxBet			= CASE WHEN abt.MaxBet > but.MaxBet THEN but.MaxBet ELSE abt.MaxBet END
						,abt.MaxPerMatch	= CASE WHEN abt.MaxPerMatch > but.MaxPerMatch THEN but.MaxPerMatch ELSE abt.MaxPerMatch END
					FROM AgentBetLimit AS abt WITH (ROWLOCK, UPDLOCK)
						INNER JOIN @BetLimitUpdateTable AS but
							ON abt.AgentId		= but.AgentId
							AND abt.SportType	= but.SportType
							AND abt.BetType		= but.BetType

					---- Update for member downline
					UPDATE cbt
					SET cbt.MinBet			= CASE WHEN cbt.MinBet < but.MinBet THEN but.MinBet ELSE cbt.MinBet END
						,cbt.MaxBet			= CASE WHEN cbt.MaxBet > but.MaxBet THEN but.MaxBet ELSE cbt.MaxBet END
						,cbt.MaxPerMatch	= CASE WHEN cbt.MaxPerMatch > but.MaxPerMatch THEN but.MaxPerMatch ELSE cbt.MaxPerMatch END
					FROM CustBetLimit AS cbt WITH (ROWLOCK, UPDLOCK)
						INNER JOIN CustInfo AS ci WITH (NOLOCK)
							ON cbt.CustId	= ci.CustId
						INNER JOIN @BetLimitUpdateTable AS but
							ON ci.AgentId		= but.AgentId
							AND cbt.SportType	= but.SportType
							AND cbt.BetType		= but.BetType
					WHERE cbt.MinBet		< but.MinBet
						OR cbt.MaxBet		> but.MaxBet
						OR cbt.MaxPerMatch	> but.MaxPerMatch					
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
						@AdminId		= @AdminId,
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
						@AdminId		= @AdminId,
						@SPName			= 'Age_Agent_UpdateBetLimit',
						@LogDate		= @startRun,
						@AgentId		= @AgentId,
						@Duration		= @Duration,
						@Data			= @logSPData,
						@OldData		= @logSPDataOld
				END CATCH
		END 
END

