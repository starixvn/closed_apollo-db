USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_InsertBetLimit]    Script Date: 4/17/2013 2:50:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_InsertBetLimit]
	@AgentId	INT,
	@BetLimit	VARCHAR(MAX)	= '',
	@Creator	INT				= NUL,
	@LogDate	DATETIME		= NULL,
	@ErrCode	INT				= 0			OUTPUT,
	@ErrMsg		NVARCHAR(1000)	= ''		OUTPUT
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Insert agent bet limit
 * DB			: APL.CustDB
 * Revisions	:
 *	•	20130417@Edward	: Write log and add @Creator, @LogDate
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

	-- For write log
	DECLARE @startRun			DATETIME
			,@endRun			DATETIME
			,@duration			INT
			,@logSPData			VARCHAR(5000)
			,@logSPDataOld		VARCHAR(5000)
			,@xml				XML

	SET @startRun = GETDATE()	

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

	-- Check if min >= 0, max >= 0, max per match >= 0
	SELECT @sportType = SportType 
	FROM @BetLimitTable 
	WHERE MinBet < 0 OR MaxBet < 0 OR MaxPerMatch < 0 
	
	IF @sportType IS NOT NULL 
		BEGIN
			SELECT @ErrCode = 1

			----Message for each sport type	WITH CASE @sportType
			SELECT @ErrMsg	= 'Wrong Min bet/ Max bet/ Max per match. Sport Type = ' + COALESCE(CAST(@sportType AS VARCHAR(10)), SPACE(1)) 						

			RETURN
		END

	SET @sportType = NULL

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
		MinMaxPerMatch)
	SELECT 
		SportType,
		BetType,
		MAX(MinBet),
		MIN(MaxBet),
		MIN(MaxPerMatch)
	FROM AgentBetLimit WITH (NOLOCK)
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

	-- Check validate max per match must be equal to or less than all parents max per match
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

	-- Insert data
	INSERT INTO dbo.AgentBetLimit
	(
		AgentId,
		SportType,
		BetType,
		MinBet,
		MaxBet,
		MaxPerMatch
	)
	SELECT
		@AgentId,
		SportType,
		BetType,
		MinBet,
		MaxBet,
		MaxPerMatch
	FROM @BetLimitTable
	
	SET @xml = (
		SELECT SportType		AS '@s' 
				,BetType		AS '@b'
				,MinBet			AS '@mi'
				,MaxBet			AS '@ma'
				,MaxPerMatch	AS '@mpm'
		FROM @BetLimitTable
		FOR XML PATH('z'), ROOT('r')
	)

	SET @logSPData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	SET @endRun		= GETDATE()
	SET @duration	= DATEDIFF(MILLISECOND, @startRun, @endRun) 

	IF @LogDate IS NULL
		SET @LogDate = GETDATE()

	EXEC LogDB.dbo.Age_LogRunSp_Insert
		@UserId			= @Creator,
		@SPName			= 'Age_Agent_InsertBetLimit',
		@LogDate		= @LogDate,
		@ObjectId		= @AgentId,
		@ObjectTypeId	= 1,			--Object type : Agent
		@Duration		= @Duration,
		@Data			= @logSPData,
		@OldData		= @logSPDataOld
END