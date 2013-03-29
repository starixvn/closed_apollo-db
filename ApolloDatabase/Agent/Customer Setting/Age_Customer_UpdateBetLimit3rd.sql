USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_UpdateBetLimit3rd]    Script Date: 3/29/2013 10:45:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_UpdateBetLimit3rd]
	@ActorAgentId	INT				= NULL,
	@CustId			INT,	
	@BetLimit		VARCHAR(MAX)	= '',
	@Language		VARCHAR(2)		= 'E',
	@ErrCode		INT				= 0			OUTPUT,
	@ErrMsg			NVARCHAR(1000)	= ''		OUTPUT,
	@LogData		NVARCHAR(MAX)	= ''		OUTPUT,
	@LogOldData		NVARCHAR(MAX)	= ''		OUTPUT 		
AS

/**
 * Created by	: Kos
 * Date			: 20130302
 * Task			: Update customer bet limit 3rd
 * DB			: APL.CustDB
 * Revisions	:
 *	• 
 * Parameters:
 *	• @BetLimit : 
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
			
			DECLARE @agentHId	HIERARCHYID
			DECLARE @sportType	INT		

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

			-- Check if min >= 0, max >= 0, max per match >= 0, max per ball >= 0
			SELECT TOP(1) @sportType = SportType 
			FROM @BetLimitTable
			WHERE MinBet < 0 OR MaxBet < 0 OR MaxPerMatch < 0 OR MaxPerBall < 0 
	
			IF @sportType IS NOT NULL 
				BEGIN
					SELECT @ErrCode = 1

					----Message for each sport type	WITH CASE @sportType
					SELECT @ErrMsg	= 'Wrong Min bet/ Max bet/ Max per match/ Max per ball.' + ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'

					RETURN			
				END

			-- Get agent hierarchy ID
			SELECT @agentHId = AgentHId
			FROM AgentInfo WITH (NOLOCK)
			WHERE AgentId = (
						SELECT pli.AgentId
						FROM CustInfo AS pli WITH (NOLOCK)
						WHERE pli.CustId = @CustId
					)

			-- Get validate data from its parent and upline
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
								FROM AgentInfo WITH (NOLOCK)
								WHERE @AgentHId.IsDescendantOf(AgentHId) = 1)
			GROUP BY SportType, BetType

			-- Check if min bet must be equal to or greater than all parents min bet
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

			-- Check if max bet must be equal to or less than all parents max bet
			SELECT TOP(1) @sportType = btct.SportType
			FROM 
				@BetLimitCompareTable As btct
				INNER JOIN @BetLimitTable AS btt ON btct.SportType = btt.SportType 
					AND btct.BetType = btt.BetType	
					AND btt.MaxBet > btct.MinMaxBet

			IF @sportType IS NOT NULL 
				BEGIN
					SELECT @ErrCode = 1

					----Message for each sport type	WITH CASE @sportType
					SELECT @ErrMsg	= 'Max bet must be equal to or less than Parent Agent max bet.' + ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'

					RETURN	
				END

			-- Check if max per match must be equal to or less than all parents max per match
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
					SELECT @ErrMsg	= 'Max per match must be equal to or less than Parent Agent max per match.' + ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'

					RETURN	
				END

			-- Check if max per ball must be equal to or less than all parents max per ball
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
					SELECT @ErrMsg	= 'Max per ball must be equal to or less than Parent Agent max per ball.' + ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'

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
						,cbl.MaxPerBall		AS '@map'
					FROM CustBetLimit3rd AS cbl WITH (NOLOCK)
						INNER JOIN @BetLimitTable AS blt
							ON cbl.SportType	= blt.SportType
							AND cbl.BetType		= blt.BetType
					WHERE cbl.CustId			= @CustId				
					FOR XML PATH('z')
			)

			SET @LogOldData = REPLACE(CONVERT(varchar(max), @xml), '" />', '"/"')

			-- end write log

			-- Update data
			UPDATE CustBetLimit3rd WITH (ROWLOCK, UPDLOCK)
			SET 
				CustBetLimit3rd.MinBet		= blt.MinBet,
				CustBetLimit3rd.MaxBet		= blt.MaxBet,
				CustBetLimit3rd.MaxPerMatch	= blt.MaxPerMatch,
				CustBetLimit3rd.MaxPerBall	= blt.MaxPerBall
			FROM 
				CustBetLimit3rd AS pbl
				INNER JOIN @BetLimitTable AS blt ON pbl.SportType = blt.SportType AND pbl.BetType = blt.BetType
			WHERE pbl.CustId = @CustId

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