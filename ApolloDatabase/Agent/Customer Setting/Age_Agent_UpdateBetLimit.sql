USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_UpdateBetLimit]    Script Date: 4/17/2013 2:52:30 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_UpdateBetLimit]
	@ActorAgentId	INT				= NULL,
	@AgentId		INT,
	@BetLimit		VARCHAR(MAX)	= '',	
	@Language		VARCHAR(2)		= 'E',
	@LogDate		DATETIME		= NULL,
	@ErrCode		INT				= 0			OUTPUT,
	@ErrMsg			NVARCHAR(1000)	= ''		OUTPUT 		
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Update agent bet limit
 * DB			: APL.CustDB
 * Revisions	:
 *	• 20132702@Edward	: Implement
 * Parameters:
 *	• @BetLimit : 
		<ROOT>
			<BetLimit SportType="4" BetType="4" Min="1" Max="1" MaxPerMatch="1"></BetLimit>
		</ROOT>
 *	@BetLimit3rd : 
		<ROOT>
			<BetLimit SportType="4" BetType="4" Min="1" Max="1" MaxPerMatch="1" MaxPerBall="1"></BetLimit>
		</ROOT>
 *  
 */

BEGIN
	
	SET NOCOUNT ON
	
	-- Check update permission
	DECLARE @hasPermission BIT
	EXEC dbo.Age_Agent_CheckUpdatePermission @ActorAgentId, @AgentId, 1, @hasPermission OUTPUT 
	SELECT @hasPermission
	IF @hasPermission = 0
		BEGIN
			SELECT @ErrCode = 1
			
			SELECT @ErrMsg	= 'Do not permission for update.'

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
		DECLARE @agentHId HIERARCHYID
				,@SUPERLEVEL		INT

		SET @SUPERLEVEL = 0

		-- Get agent hierarchy ID
		SELECT @agentHId = AgentHId
		FROM AgentInfo WITH (NOLOCK)
		WHERE AgentId = @AgentId

		DECLARE @BetLimitTable TABLE(
			SportType SMALLINT,
			BetType SMALLINT,
			MinBet MONEY,
			MaxBet MONEY,
			MaxPerMatch MONEY)

		DECLARE @BetLimitCompareTable TABLE(
			SportType SMALLINT,
			BetType SMALLINT,
			MaxMinBet MONEY,
			MinMaxBet MONEY,
			MinMaxPerMatch MONEY)	

		-- For read xml
		DECLARE @DocHandler int

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

		IF EXISTS (
			SELECT TOP(1) *
			FROM 
				AgentBetLimit AS abt WITH (NOLOCK)
			INNER JOIN @BetLimitTable AS blt
				ON abt.SportType = blt.SportType
				AND abt.BetType = blt.BetType
			WHERE abt.AgentId = @AgentId
			AND (abt.MinBet <> blt.MinBet
				OR abt.MaxBet <> blt.MaxBet
				OR abt.MaxPerMatch <> blt.MaxPerMatch)
		)
			BEGIN		

				DECLARE @sportType INT

				-- Check validate > 0	
				SELECT TOP(1) @sportType = SportType 
				FROM @BetLimitTable 
				WHERE MinBet < 0 OR MaxBet < 0 OR MaxPerMatch < 0 
					OR  MinBet > MaxBet
					OR MinBet > MaxPerMatch
					OR MaxBet > MaxPerMatch
	
				IF @sportType IS NOT NULL 
					BEGIN
						SELECT @ErrCode = 1

						----Message for each sport type	WITH CASE @sportType
						SELECT @ErrMsg	= 'Wrong Min bet/ Max bet/ Max per match.' + ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'						

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
									FROM AgentInfo 
									WHERE @AgentHId.IsDescendantOf(AgentHId) = 1 
									AND AgentId		<> @AgentId
									AND AgentLevel	<> @SUPERLEVEL )
				GROUP BY SportType, BetType			

				---- Check validate min bet must be equal to or greater than parent
				SELECT TOP(1) @sportType = btct.SportType
				FROM 
					@BetLimitCompareTable AS btct
					INNER JOIN @BetLimitTable AS btt ON btct.SportType = btt.SportType 
						AND btct.BetType = btt.BetType	
						AND btt.MinBet < btct.MaxMinBet

				IF @sportType IS NOT NULL 
					BEGIN
						SELECT @ErrCode = 1

						----Message for each sport type	WITH CASE @sportType
						SELECT @ErrMsg	= 'Min bet must be equal to or greater than Parent Agent min bet.' + ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'

						RETURN	
					END	

				---- Check validate max bet must be equal to or less than parent
				SELECT TOP(1) @sportType = btct.SportType
				FROM 
					@BetLimitCompareTable AS btct
					INNER JOIN @BetLimitTable AS btt 
					ON 
						btct.SportType = btt.SportType 
						AND btct.BetType = btt.BetType	
						AND btt.MaxBet > btct.MinMaxBet				

				IF @sportType IS NOT NULL 
					BEGIN
						SELECT @ErrCode = 1

						----Message for each sport type	WITH CASE @sportType
						SELECT @ErrMsg	= 'Max bet must be equal to or less than Parent Agent max bet.' + ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'

						RETURN	
					END	

				---- Check validate max per match must be equal to or less than parent
				SELECT TOP(1) @sportType = btct.SportType
				FROM 
					@BetLimitCompareTable AS btct
					INNER JOIN @BetLimitTable AS btt 
					ON 
						btct.SportType = btt.SportType 
						AND btct.BetType = btt.BetType	
						AND btt.MaxPerMatch > btct.MinMaxPerMatch

				IF @sportType IS NOT NULL 
					BEGIN
						SELECT @ErrCode = 1

						----Message for each sport type	WITH CASE @sportType
						SELECT @ErrMsg	= 'Max Per Match must be equal to or less than Parent Agent max per match.' + ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'

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
						FROM AgentBetLimit AS abl WITH (NOLOCK)
							INNER JOIN @BetLimitTable AS blt
								ON abl.SportType	= blt.SportType
								AND abl.BetType		= blt.BetType
						WHERE abl.AgentId			= @AgentId				
						FOR XML PATH('z'),ROOT('r')
				)

				SET @logSPDataOld = REPLACE(CONVERT(varchar(max), @xml), '" />', '"/"')

				-- end write log

				---- Update for current agent, not effect for all line
				UPDATE 
					abt WITH (ROWLOCK, UPDLOCK)
				SET abt.MinBet		= blt.MinBet,
					abt.MaxBet		= blt.MaxBet,
					abt.MaxPerMatch	= blt.MaxPerMatch
				FROM 
					AgentBetLimit AS abt
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
						FOR XML PATH('z'),ROOT('r')
				)

				SET @logSPData = REPLACE(CONVERT(varchar(max), @xml), '" />', '"/"')

				-- end write log
			END	   					
	END	

	SET @endRun		= GETDATE()  
	SET @duration	= DATEDIFF(millisecond, @startRun, @endRun) 

	IF @LogDate IS NULL
		SET @LogDate = GETDATE()	

	EXEC LogDB.dbo.Age_LogRunSp_Insert
		@UserId			= @ActorAgentId,
		@SPName			= 'Age_Agent_UpdateBetLimit',
		@LogDate		= @LogDate,
		@ObjectId		= @AgentId,
		@ObjectTypeId	= 1,			--Object type : Agent						
		@Duration		= @Duration,
		@Data			= @logSPData,
		@OldData		= @logSPDataOld
END
