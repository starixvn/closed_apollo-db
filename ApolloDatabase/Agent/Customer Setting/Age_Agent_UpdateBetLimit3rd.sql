USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_UpdateBetLimit3rd]    Script Date: 3/29/2013 10:10:30 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_UpdateBetLimit3rd]
	@ActorAgentId		INT				= NULL,
	@AgentId			INT,
	@BetLimit			VARCHAR(MAX)	= '',
	@Language			VARCHAR(2)		= 'E',
	@ErrCode			INT				= 0			OUTPUT,
	@ErrMsg				NVARCHAR(1000)	= ''		OUTPUT,
	@LogData			NVARCHAR(MAX)	= ''		OUTPUT,
	@LogOldData			NVARCHAR(MAX)	= ''		OUTPUT	 		
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Update agent bet limit 3rd
 * DB			: APL.CustDB
 * Revisions	:
 *	• 20132702@Edward	: Implement
 * Parameters:
 *	•	@BetLimit : 
		<ROOT>
			<BetLimit SportType="4" BetType="4" Min="1" Max="1" MaxPerMatch="1" MaxPerBall="1"></BetLimit>
		</ROOT>
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON
	
	DECLARE @xml	XML

	IF @BetLimit <> ''
	BEGIN
		DECLARE @agentHId HIERARCHYID

		-- Get agent hierarchy ID
		SELECT @agentHId = AgentHId
		FROM AgentInfo WITH (NOLOCK)
		WHERE AgentId = @AgentId

		DECLARE @BetLimitTable TABLE(
			SportType SMALLINT,
			BetType SMALLINT,
			MinBet MONEY,
			MaxBet MONEY,
			MaxPerMatch MONEY,
			MaxPerBall MONEY)

		DECLARE @BetLimitCompareTable TABLE(
			SportType SMALLINT,
			BetType SMALLINT,
			MaxMinBet MONEY,
			MinMaxBet MONEY,
			MinMaxPerMatch MONEY,
			MinMaxPerBall MONEY)		

		-- For read xml
		DECLARE @DocHandler int

		EXEC sp_xml_preparedocument @DocHandler OUTPUT, @BetLimit

		INSERT INTO @BetLimitTable (
			SportType,
			BetType,
			MinBet,
			MaxBet,
			MaxPerMatch,
			MaxPerBall)		
		SELECT 			
			Data.SportType,
			Data.BetType,
			Data.Min,
			Data.Max,
			Data.MaxPerMatch,
			Data.MaxPerBall
		FROM OPENXML (@DocHandler, '/ROOT/BetLimit',1) 
		WITH (			
			SportType		SMALLINT,
			BetType			SMALLINT,
			Min				MONEY,
			Max				MONEY,
			MaxPerMatch		MONEY,
			MaxPerBall		MONEY
		) AS Data

		EXEC sp_xml_removedocument @DocHandler
		-- end read xml	

		IF EXISTS (
			SELECT TOP(1) *
			FROM 
				AgentBetLimit3rd AS abt WITH (NOLOCK)
			INNER JOIN @BetLimitTable AS blt
				ON abt.SportType = blt.SportType
				AND abt.BetType = blt.BetType
			WHERE abt.AgentId = @AgentId
			AND (abt.MinBet <> blt.MinBet
				OR abt.MaxBet <> blt.MaxBet
				OR abt.MaxPerMatch <> blt.MaxPerMatch
				OR abt.MaxPerBall <> blt.MaxPerBall)
		)
			BEGIN			
				
				DECLARE @sportType INT

				---- Check validate	> 0	
				SELECT TOP(1) @sportType = SportType 
				FROM @BetLimitTable
				WHERE MinBet < 0 OR MaxBet < 0 OR MaxPerMatch < 0 OR MaxPerBall < 0
					OR  MinBet > MaxBet
					OR MinBet > MaxPerMatch
					OR MaxBet > MaxPerMatch
					OR MinBet > MaxPerBall

				IF @sportType IS NOT NULL 
					BEGIN
						SELECT @ErrCode = 1

						----Message for each sport type	WITH CASE @sportType
						SELECT @ErrMsg	= 'Wrong Min bet/ Max bet/ Max per match/ MaxPerBall.' + ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'

						RETURN			
					END

				---- Check validate data
				INSERT INTO @BetLimitCompareTable(
					SportType,
					BetType,
					MaxMinBet,
					MinMaxBet,
					MinMaxPerMatch,
					MinMaxPerBall)
				SELECT 
					SportType,
					BetType,
					MAX(MinBet),
					MIN(MaxBet),
					MIN(MaxPerMatch),
					MIN(MaxPerBall)
				FROM AgentBetLimit3rd WITH (NOLOCK)
				WHERE AgentId IN (	SELECT AgentId 
									FROM AgentInfo 
									WHERE @AgentHId.IsDescendantOf(AgentHId) = 1 AND AgentId <> @AgentId )
				GROUP BY SportType, BetType

				---- Check validate min bet must be equal to or greater than parent
				SELECT TOP(1) @sportType = btct.SportType
				FROM 
					@BetLimitCompareTable AS btct
					INNER JOIN @BetLimitTable AS btt 
					ON 
						btct.SportType = btt.SportType 
						AND btct.BetType = btt.BetType	
						AND btt.MinBet < btct.MaxMinBet

				IF @sportType IS NOT NULL 
					BEGIN
						SELECT @ErrCode = 1

						----Message for each sport type	WITH CASE @sportType
						SELECT @ErrMsg	= 'Min bet must be equal to or greater than Paret Agent min bet.' + ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'

						RETURN	
					END

				SET @sportType = NULL

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
						SELECT @ErrMsg	= 'Max bet must be equal to or less than Paret Agent max bet.' + ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'

						RETURN	
					END

				SET @sportType = NULL

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
						SELECT @ErrMsg	= 'Max per match must be equal to or less than Paret Agent max per match.' + ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'

						RETURN	
					END

				SET @sportType = NULL

				---- Check validate max per ball must be equal to or less than parent
				SELECT TOP(1) @sportType = btct.SportType
				FROM 
					@BetLimitCompareTable AS btct
					INNER JOIN @BetLimitTable AS btt 
					ON 
						btct.SportType = btt.SportType 
						AND btct.BetType = btt.BetType	
						AND btt.MaxPerBall > btct.MinMaxPerBall

				IF @sportType IS NOT NULL 
					BEGIN
						SELECT @ErrCode = 1

						----Message for each sport type	WITH CASE @sportType
						SELECT @ErrMsg	= 'Max per ball must be equal to or less than Paret Agent max per ball.' + ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'

						RETURN	
					END

				SET @sportType = NULL

				-- write log before update
				
				SET @xml = (
						SELECT  
							abl.SportType		AS '@s'
							,abl.BetType		AS '@b'
							,abl.MinBet			AS '@mib'
							,abl.MaxBet			AS '@mab'
							,abl.MaxPerMatch	AS '@mam'
							,blt.MaxPerBall		AS '@map'
						FROM AgentBetLimit3rd AS abl WITH (NOLOCK)
							INNER JOIN @BetLimitTable AS blt
								ON abl.SportType	= blt.SportType
								AND abl.BetType		= blt.BetType
						WHERE abl.AgentId			= @AgentId				
						FOR XML PATH('z')
				)

				SET @LogOldData = REPLACE(CONVERT(varchar(max), @xml), '" />', '"/"')

				-- end write log

				---- Update for current agent, not effect for all line
				UPDATE 
					abt WITH (ROWLOCK, UPDLOCK)
				SET 
					abt.MinBet			= blt.MinBet,
					abt.MaxBet			= blt.MaxBet,
					abt.MaxPerMatch		= blt.MaxPerMatch,
					abt.MaxPerBall		= blt.MaxPerBall		
				FROM 
					AgentBetLimit3rd AS abt
					INNER JOIN @BetLimitTable AS blt 
						ON blt.SportType = abt.SportType 
						AND blt.BetType = abt.BetType
				WHERE AgentId = @AgentId    

				-- write log after update
				
				SET @xml = (
						SELECT  
							blt.SportType		AS '@s'
							,blt.BetType		AS '@b'
							,blt.MinBet			AS '@mib'
							,blt.MaxBet			AS '@mab'
							,blt.MaxPerMatch	AS '@mam'
							,blt.MaxPerBall		AS '@map'
						FROM @BetLimitTable AS blt						
						FOR XML PATH('z')
				)

				SET @LogData = REPLACE(CONVERT(varchar(max), @xml), '" />', '"/"')

				-- end write log
			END		
	END		  	
END
