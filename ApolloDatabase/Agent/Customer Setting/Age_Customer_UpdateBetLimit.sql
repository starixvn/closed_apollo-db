USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_UpdateBetLimit]    Script Date: 7/17/2013 4:21:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_UpdateBetLimit]
	@ActorAgentId	INT				= NULL,
	@AdminId		INT				= NULL,
	@CustId			INT,	
	@BetLimit		VARCHAR(MAX)	= '',
	@Language		VARCHAR(5)		= 'en-US',
	@ErrCode		INT				= 0			OUTPUT,
	@ErrMsg			NVARCHAR(1000)	= ''		OUTPUT
AS

/**
 * Created by	: Kos
 * Date			: 20130302
 * Task			: Update customer bet limit
 * DB			: SVRCUST.CustDB
 * Revisions	:
 *	• 20131707@Edward	: Add parameter @AdminId for write log
 * Parameters:
 *	• @BetLimit : 
		<ROOT>
			<BetLimit SportType="4" BetType="4" Min="1" Max="1" MaxPerMatch="1"></BetLimit>
		</ROOT>
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON

	-- Check update permission
	DECLARE @hasPermission BIT

	EXEC dbo.Age_Agent_CheckUpdatePermission @ActorAgentId, @CustId, 2, @hasPermission OUTPUT

	IF @hasPermission = 0
		BEGIN
			SELECT 
				@ErrCode = 1000,
				@ErrMsg	= 
					CASE @Language
						WHEN 'en-US' THEN 'You do not have permission to update setting'
						ELSE [dbo].f_Msg_GetContentById (1000, @Language)
					END
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

	IF @BetLimit <> ''
		BEGIN
			DECLARE @BetLimitTable TABLE (
				SportType	SMALLINT,
				BetType		SMALLINT,
				MinBet		MONEY,
				MaxBet		MONEY,
				MaxPerMatch	MONEY)

			DECLARE @BetLimitCompareTable TABLE (
				SportType		SMALLINT,
				BetType			SMALLINT,
				MaxMinBet		MONEY,
				MinMaxBet		MONEY,
				MinMaxPerMatch	MONEY)
			
			DECLARE 
				@agentHId		HIERARCHYID,
				@sportType		INT,
				@betType		INT,
				@SUPERLEVEL		INT

			SET @SUPERLEVEL	= 0

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
				SportType	SMALLINT,
				BetType		SMALLINT,
				Min			MONEY,
				Max			MONEY,
				MaxPerMatch	MONEY
			) AS Data

			EXEC sp_xml_removedocument @DocHandler
			-- end read xml

			-- Check if min >= 0, max >= 0, max per match >= 0
			SELECT TOP(1) @sportType	= SportType 
							,@betType	= BetType
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
				@sportType = SportType
				,@betType= BetType 
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

			-- Get agent hierarchy ID
			SELECT @agentHId = AgentHId
			FROM 
				AgentInfo AS ai WITH (NOLOCK)
				INNER JOIN CustInfo AS ci WITH (NOLOCK) ON ai.AgentId = ci.AgentId
			WHERE ci.CustId = @CustId

			-- Get validate data from its parent and upline
			INSERT INTO @BetLimitCompareTable (
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
									AND AgentLevel <> @SUPERLEVEL)
			GROUP BY 
				SportType, 
				BetType

			-- Check if min bet must be equal to or greater than all parents min bet
			SELECT TOP(1) 
				@sportType = btct.SportType
				,@betType= btct.BetType
			FROM 
				@BetLimitCompareTable AS btct
				INNER JOIN @BetLimitTable AS btt 
					ON btct.SportType = btt.SportType 
					AND btct.BetType = btt.BetType	
			WHERE btt.MinBet < btct.MaxMinBet

			IF @sportType IS NOT NULL 
				BEGIN
					SELECT 
						@ErrCode = 3001,
						@ErrMsg = 
							CASE @Language
								WHEN 'en-US' THEN 'Min Single Bet must be equal to or greater than Parent Agent Min Single Bet' 
								ELSE [dbo].f_Msg_GetContentById (3001, @Language) 
							END + ' (' 
								+ CASE WHEN @sportType = 99 AND @betType = 9
										THEN [dbo].f_Msg_GetContentById (4009, @Language)
										ELSE dbo.f_Sport_GetNameByType(@sportType, @Language) 
									END
								+ ')'
					RETURN	
				END

			-- Check if max bet must be equal to or less than all parents max bet
			SELECT TOP(1) 
				@sportType = btct.SportType
				,@betType = btct.BetType
			FROM 
				@BetLimitCompareTable As btct
				INNER JOIN @BetLimitTable AS btt 
				ON 
					btct.SportType = btt.SportType 
					AND btct.BetType = btt.BetType
					AND btt.MaxBet > btct.MinMaxBet

			IF @sportType IS NOT NULL 
				BEGIN
					SELECT 
						@ErrCode = 3002,
						@ErrMsg = 
							CASE @Language
								WHEN 'en-US' THEN 'Single Bet must be equal to or less than Parent Agent Single Bet' 
								ELSE [dbo].f_Msg_GetContentById (3002, @Language) 
							END + ' (' 
								+ CASE WHEN @sportType = 99 AND @betType = 9
										THEN [dbo].f_Msg_GetContentById (4009, @Language)
										ELSE dbo.f_Sport_GetNameByType(@sportType, @Language) 
									END
								+ ')'
					RETURN	
				END

			-- Check if max per match must be equal to or less than all parents max per match
			SELECT TOP(1) 
				@sportType = btct.SportType
				,@betType= btct.BetType
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
						@ErrCode = 3003,
						@ErrMsg = 
							CASE @Language
								WHEN 'en-US' THEN 'Single Game must be equal to or less than Parent Agent Single Game' 
								ELSE [dbo].f_Msg_GetContentById (3003, @Language) 
							END + ' (' 
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
					cbl.SportType		AS '@s'
					,cbl.BetType		AS '@b'
					,cbl.MinBet			AS '@mib'
					,cbl.MaxBet			AS '@mab'
					,cbl.MaxPerMatch	AS '@mam'
				FROM 
					CustBetLimit AS cbl WITH (NOLOCK)
					--INNER JOIN @BetLimitTable AS blt
					--ON	cbl.SportType	= blt.SportType
					--	AND cbl.BetType	= blt.BetType
				WHERE cbl.CustId = @CustId
				FOR XML PATH('z'), ROOT('r')
			)

			SET @logSPDataOld = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

			-- end write log

			-- Update data
			UPDATE dbo.CustBetLimit WITH (ROWLOCK, UPDLOCK)
			SET 
				CustBetLimit.MinBet			= blt.MinBet,
				CustBetLimit.MaxBet			= blt.MaxBet,
				CustBetLimit.MaxPerMatch	= blt.MaxPerMatch
			FROM 
				CustBetLimit AS pbl
				INNER JOIN @BetLimitTable AS blt 
				ON 
					pbl.SportType = blt.SportType 
					AND pbl.BetType = blt.BetType
			WHERE pbl.CustId = @CustId

			-- write log after update
				
			SET @xml = (
				SELECT  
					SportType		AS '@s'
					,BetType		AS '@b'
					,MinBet			AS '@mib'
					,MaxBet			AS '@mab'
					,MaxPerMatch	AS '@mam'
				FROM @BetLimitTable
				FOR XML PATH('z'), ROOT('r')
			)

			SET @logSPData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

			-- end write log

			SET @endRun		= GETDATE()
			SET @duration	= DATEDIFF(MILLISECOND, @startRun, @endRun) 
		
			IF @@ERROR = 0
				BEGIN TRY
					EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpCust
						@UserId		= @ActorAgentId,
						@AdminId	= @AdminId,
						@SPName		= 'Age_Agent_UpdateBetLimit',
						@LogDate	= @startRun,
						@CustId		= @CustId,
						@Duration	= @Duration,
						@Data		= @logSPData,
						@OldData	= @logSPDataOld
				END	TRY
				BEGIN CATCH
					EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpCust
						@UserId		= @ActorAgentId,
						@AdminId	= @AdminId,
						@SPName		= 'Age_Agent_UpdateBetLimit',
						@LogDate	= @startRun,
						@CustId		= @CustId,
						@Duration	= @Duration,
						@Data		= @logSPData,
						@OldData	= @logSPDataOld
				END CATCH 
		END
END