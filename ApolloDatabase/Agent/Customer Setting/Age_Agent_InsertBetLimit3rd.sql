USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_InsertBetLimit3rd]    Script Date: 3/29/2013 10:08:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_InsertBetLimit3rd]
	@AgentId	INT,
	@BetLimit	VARCHAR(MAX)	= '',
	@ErrCode	INT				= 0			OUTPUT,
	@ErrMsg		NVARCHAR(1000)	= ''		OUTPUT 		
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Insert agent bet limit 3rd
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
	SELECT @sportType = SportType 
	FROM @BetLimitTable 
	WHERE MinBet < 0 OR MaxBet < 0 OR MaxPerMatch < 0 OR MaxPerBall < 0 
	
	IF @sportType IS NOT NULL 
		BEGIN
			SELECT @ErrCode = 1

			----Message for each sport type	WITH CASE @sportType
			SELECT @ErrMsg	= 'Wrong Min bet/ Max bet/ Max per match/ Max per ball. Sport Type = ' + COALESCE(CAST(@sportType AS VARCHAR(10)), SPACE(1)) 						

			RETURN			
		END

	-- Get agent hierarchy ID
	SELECT @agentHId = AgentHId
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @AgentId

	-- Get validate data from upline
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
	WHERE AgentId IN ( 
		SELECT AgentId 
		FROM AgentInfo WITH (NOLOCK)
		WHERE @AgentHId.IsDescendantOf(AgentHId) = 1 
	)		
	GROUP BY SportType, BetType

	-- Check if min bet must be equal to or greater than all parents min bet
	SELECT @sportType = btct.SportType
	FROM 
		@BetLimitCompareTable AS btct
		INNER JOIN @BetLimitTable AS btt ON btct.SportType = btt.SportType 
			AND btct.BetType = btt.BetType	
			AND btt.MinBet < btct.MaxMinBet

	IF @sportType IS NOT NULL 
		BEGIN
			SELECT @ErrCode = 1

			----Message for each sport type	WITH CASE @sportType
			SELECT @ErrMsg	= 'Min bet must be equal to or greater than Parent Agent min bet. Sport Type = ' + COALESCE(CAST(@sportType AS VARCHAR(10)), SPACE(1)) 												

			RETURN	
		END

	-- Check if max bet must be equal to or less than all parents max bet
	SELECT @sportType = btct.SportType
	FROM 
		@BetLimitCompareTable As btct
		INNER JOIN @BetLimitTable AS btt ON btct.SportType = btt.SportType 
			AND btct.BetType = btt.BetType	
			AND btt.MaxBet > btct.MinMaxBet

	IF @sportType IS NOT NULL 
		BEGIN
			SELECT @ErrCode = 1

			----Message for each sport type	WITH CASE @sportType
			SELECT @ErrMsg	= 'Max bet must be equal to or less than Parent Agent max bet. Sport Type = ' + COALESCE(CAST(@sportType AS VARCHAR(10)), SPACE(1)) 												

			RETURN	
		END

	-- Check if max per match must be equal to or less than all parents max per match
	SELECT @sportType = btct.SportType
	FROM 
		@BetLimitCompareTable AS btct
		INNER JOIN @BetLimitTable AS btt ON btct.SportType = btt.SportType 
		AND btct.BetType = btt.BetType	
		AND btt.MaxPerMatch > btct.MinMaxPerMatch

	IF @sportType IS NOT NULL 
		BEGIN
			SELECT @ErrCode = 1

			----Message for each sport type	WITH CASE @sportType
			SELECT @ErrMsg	= 'Max Per Match must be equal to or less than Parent Agent max per match. Sport Type = ' + COALESCE(CAST(@sportType AS VARCHAR(10)), SPACE(1)) 											

			RETURN	
		END

	-- Check if max per ball must be equal to or less than all parents max per ball
	SELECT @sportType = btct.SportType
	FROM 
		@BetLimitCompareTable AS btct
		INNER JOIN @BetLimitTable AS btt ON btct.SportType = btt.SportType 
		AND btct.BetType = btt.BetType	
		AND btt.MaxPerBall > btct.MinMaxPerBall

	IF @sportType IS NOT NULL 
		BEGIN
			SELECT @ErrCode = 1

			----Message for each sport type	WITH CASE @sportType
			SELECT @ErrMsg	= 'Max Per Ball must be equal to or less than Parent Agent max per ball. Sport Type = ' + COALESCE(CAST(@sportType AS VARCHAR(10)), SPACE(1)) 											

			RETURN	
		END

	-- Insert data
	INSERT INTO dbo.AgentBetLimit3rd
	(
		AgentId,
		SportType,
		BetType,
		MinBet,
		MaxBet,
		MaxPerMatch,
		MaxPerBall
	)
	SELECT
		@AgentId,
		SportType,
		BetType,
		MinBet,
		MaxBet,
		MaxPerMatch,
		MaxPerBall
	FROM @BetLimitTable
	
END