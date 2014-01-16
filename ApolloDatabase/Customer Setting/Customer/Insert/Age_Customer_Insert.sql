USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_Insert]    Script Date: 1/16/2014 3:34:26 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_Customer_Insert]
	@CustId				INT,	
	@Username			NVARCHAR(50),
	@AgentId			INT,	
	@Status				TINYINT			= 1,
	@BetStatus			TINYINT			= 1,
	@MatchLimit			SMALLMONEY		= 0,
	@VirtualMultiplier	SMALLMONEY		= 1,
	@DoubleCommLosing	BIT				= 0,	
	@Danger				TINYINT			= 0,
	@IPLogin			VARCHAR(40)		= NULL,
	@UGroup				VARCHAR(3)		= 'b',				-- Group B
	@Creator			INT				= NULL,
	@ErrCode			INT				= 0			OUTPUT,
	@ErrMsg				NVARCHAR(1000)	= ''		OUTPUT
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Add new customer information and default setting
 * DB			: APL.CustDB
 * Revisions	:
 *	• 20130227@Edward	: Implement
 *	• 20130415@Kos		: Add statuses
 *	• 20130415@Edward	: Write log
 *	• 2013070/@Edward	: Insert CustPositionTaking
 *	• 20130823@Kos		: Change default UGroup to 'b'
 *	• 20130902@Kos		: Enhance performance
 *	• 20131120@Sophia	: Don't care UplineStatus, UplineBetStatus
 *	• 20140116@Edward	: Fix bug check MaxDownDelta > 0
 * Parameters:
 *	•
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON

	-- set creator default is agent
	IF @Creator IS NULL
		SET @Creator = @AgentId

	-- Check if customer ID exists
	IF EXISTS ( SELECT 1 FROM CustInfo WITH (NOLOCK) WHERE CustId = @CustId )
		BEGIN
			SELECT 
				@ErrCode = 5201, 
				@ErrMsg = 'Customer ID duplicated [CustId = ' + COALESCE(CAST(@CustId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END	

	-- Check if username exists
	IF EXISTS ( SELECT 1 FROM CustInfo WITH (NOLOCK) WHERE Username = @Username )
		BEGIN
			SELECT 
				@ErrCode = 5203, 
				@ErrMsg = 'Username duplicated [Username = ' + COALESCE(@Username, SPACE(1)) + ']'
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

	-- For write log
	DECLARE 
		@startRun					DATETIME,
		@endRun						DATETIME,
		@duration					INT,
		@logCustSPData				NVARCHAR(MAX),		
		@logBetLimitSPData			NVARCHAR(MAX),
		@logDiscountSPData			NVARCHAR(MAX),
		@logPositionTakingSPData	NVARCHAR(MAX),
		@xml						XML,
		@agentHId					HIERARCHYID,
		@agentUsername				NVARCHAR(50),
		@tempCustId					INT				= NULL

	SELECT 
		@agentHId = AgentHId,
		@agentUsername = Username
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @AgentId

	SET @startRun = GETDATE()

	SET @UGroup = LOWER(@Ugroup)

	-- Check agent has member ?
	SELECT TOP(1) @tempCustId = CustId FROM CustInfo WITH (NOLOCK) WHERE AgentId = @AgentId	

	-- Insert into CustInfo
	INSERT INTO CustInfo (
		CustId,
		AgentId,
		Username,
		Currency,
		AutoSuspend,
		MatchLimit,
		VirtualMultiplier,
		Danger,
		Creator,
		CreateDate,
		LastLogged,
		IPLogin,
		UGroup,
		DoubleCommLosing,
		Status,
		BetStatus,
		--UplineStatus,
		--UplineBetStatus,
		IsUGroupChanged)
	SELECT	
		@CustId,
		@AgentId,
		@Username,
		Currency,
		0,					-- AutoSuspend
		@MatchLimit,
		@VirtualMultiplier,
		@Danger,
		@Creator,
		GETDATE(),
		NULL,
		@IPLogin,
		@UGroup,
		@DoubleCommLosing,
		@Status,
		@BetStatus,
		--CASE WHEN Status = 2 OR UplineStatus = 2 THEN 2 ELSE 1 END,			-- UplineStatus
		--CASE WHEN BetStatus = 2 OR UplineBetStatus = 2 THEN 2 ELSE 1 END,	-- UplineBetStatus
		0
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @AgentId

	-- Not support for multiple language
	IF @@ERROR > 0
		BEGIN
			SELECT 
				@ErrCode = 5204, 
				@ErrMsg = 'Failed to insert customer [CustId = ' + COALESCE(CAST(@CustId AS VARCHAR(10)), SPACE(1)) + ']'
			RETURN
		END

	-- Insert default customer bet limit (from it's parent)
	INSERT INTO CustBetLimit (
		CustId,
		SportType,
		BetType,
		MinBet,
		MaxBet,
		MaxPerMatch )
	SELECT 	
		@CustId,
		SportType,
		BetType,
		MinBet,
		MaxBet,
		MaxPerMatch
	FROM AgentBetLimit WITH (NOLOCK)
	WHERE AgentId = @AgentId
	
	------ Insert default customer discount (from it's parent)
	INSERT INTO CustDiscount (
		CustId,
		SportType,
		BetType,
		Discount )
	SELECT 
		@CustId,
		SportType,
		BetType,
		CASE  
			WHEN SportType = 1 AND BetType = 1 AND @UGroup = 'a' THEN DiscountA
			WHEN SportType = 1 AND BetType = 1 AND @UGroup = 'b' THEN DiscountB
			WHEN SportType = 1 AND BetType = 1 AND @UGroup = 'c' THEN DiscountC
			WHEN SportType = 1 AND BetType = 1 AND @UGroup = 'd' THEN DiscountD
			ELSE DiscountA
		END
	FROM AgentDiscount WITH (NOLOCK)
	WHERE AgentId = @AgentId

	IF @tempCustId IS NULL
	BEGIN
		-- Get upline agent
		DECLARE @TableAgent TABLE (
			AgentId		INT, 
			AgentLevel	SMALLINT, 
			Username	NVARCHAR(50) )

		;WITH Tree(AgentId, AgentLevel, Username, Path)
		AS
		(
			SELECT 
				AgentId,
				AgentLevel,
				Username,
				AgentHId 
			FROM AgentInfo WITH (NOLOCK)
			WHERE AgentId = @AgentId

			UNION ALL

			SELECT  
				ai.AgentId,
				CAST(ai.AgentLevel AS SMALLINT) AS AgentLevel,
				ai.Username,
				ai.AgentHId        
			FROM
				AgentInfo AS ai WITH (NOLOCK)
				INNER JOIN Tree AS t ON	t.[Path].GetAncestor(1) = ai.AgentHId
			WHERE ai.AgentLevel > 0
		)   

		INSERT INTO @TableAgent
		SELECT 
			AgentId,
			AgentLevel,
			Username  
		FROM Tree
		ORDER BY AgentLevel		
	
		-- Insert default position taking
		DECLARE @TableUpdatePT TABLE (
			AgentId			INT,
			AgentLevel		SMALLINT,
			SportType		SMALLINT,
			BetType			SMALLINT,
			IsLive			BIT,
			PositionTaking	SMALLINT,
			MinGiven		SMALLINT,
			SumDownline		SMALLINT,
			MaxDownDelta	SMALLINT)	

		INSERT INTO @TableUpdatePT (
			AgentId
			,AgentLevel
			,SportType
			,BetType
			,IsLive
			,PositionTaking
			,MinGiven
			,SumDownline
			,MaxDownDelta)		   
		SELECT 
			apt.AgentId
			,ai.AgentLevel
			,apt.SportType
			,apt.BetType
			,apt.IsLive
			,CASE	
				WHEN apt.AgentId = @AgentId THEN apt.MaxGivenPositionTaking 
				ELSE capt.MaxUpperPositionTaking
			END
			,apt.MinGivenPositionTaking
			,0
			,0		
		FROM 
			AgentPositionTaking AS apt WITH (NOLOCK)			
			INNER JOIN @TableAgent AS ai ON apt.AgentId	= ai.AgentId
			LEFT JOIN @TableAgent AS ta	ON ai.AgentLevel = ta.AgentLevel - 1
			LEFT JOIN AgentPositionTaking AS capt WITH (NOLOCK)
				ON capt.AgentId		= ta.AgentId
				AND capt.SportType	= apt.SportType
				AND capt.BetType	= apt.BetType
				AND capt.IsLive		= apt.IsLive				
	
		-- Get downline position taking
		UPDATE tupt
		SET tupt.SumDownline = temp.SumDownline
		FROM 
			@TableUpdatePT AS tupt
			INNER JOIN 
				(
					SELECT 
						m.AgentId,
						m.SportType,
						m.BetType,
						m.IsLive,
						SUM(s.PositionTaking) AS SumDownline
					FROM 
						@TableUpdatePT AS m
						INNER JOIN @TableUpdatePT AS s 
						ON
							m.AgentLevel <= s.AgentLevel
							AND m.SportType = s.SportType
							AND m.BetType = s.BetType
							AND m.IsLive = s.IsLive
					WHERE m.AgentId <> @AgentId AND m.MinGiven > 0
					GROUP BY 
						m.AgentId,
						m.SportType,
						m.BetType,
						m.IsLive				
				) AS temp
			ON tupt.AgentId	= temp.AgentId
				AND tupt.SportType	= temp.SportType
				AND tupt.BetType	= temp.BetType
				AND tupt.IsLive		= temp.IsLive
				
		-- Insert max downline delta (min - downline PT)
		UPDATE tupt
		SET tupt.MaxDownDelta = temp.MaxDownDelta
		FROM 
			@TableUpdatePT AS tupt
			INNER JOIN 
				(
					SELECT 
						m.AgentId,
						m.SportType,
						m.BetType,
						m.IsLive,
						MAX(CASE WHEN s.AgentId <> @AgentId THEN s.MinGiven - s.SumDownline ELSE 0 END) AS MaxDownDelta
					FROM 
						@TableUpdatePT AS m
						INNER JOIN @TableUpdatePT AS s 
						ON
							m.AgentLevel < s.AgentLevel
							AND m.SportType = s.SportType
							AND m.BetType = s.BetType
							AND m.IsLive = s.IsLive
					WHERE m.AgentId <> @AgentId AND m.MinGiven > 0 AND s.MinGiven > 0
					GROUP BY 
						m.AgentId,
						m.SportType,
						m.BetType,
						m.IsLive				
				) AS temp
			ON tupt.AgentId	= temp.AgentId
				AND tupt.SportType	= temp.SportType
				AND tupt.BetType	= temp.BetType
				AND tupt.IsLive		= temp.IsLive
		WHERE tupt.AgentId <> @AgentId
			AND temp.MaxDownDelta > 0
			
		-- Update position taking if break min rule
		UPDATE @TableUpdatePT
		SET PositionTaking = PositionTaking + MinGiven - SumDownline - MaxDownDelta
		WHERE MinGiven - SumDownline > MaxDownDelta
		AND AgentId <> @AgentId

		-- Insert customer position taking
		INSERT INTO AgentCustPositionTaking (
			AgentCustId
			,AgentId
			,SportType
			,BetType
			,IsLive
			,PositionTaking)
		SELECT 
			@AgentId
			 ,AgentId
			 ,SportType
			 ,BetType
			 ,IsLive
			 ,PositionTaking
		FROM @TableUpdatePT
	END

	-- Insert into balance tables 	
	INSERT INTO SVRTXN.TransDB.dbo.BalanceCredit (CustId, Balance)
	VALUES (@CustId, 0)

	INSERT INTO SVRTXN.TransDB.dbo.BalanceDebit (CustId, Balance)
	VALUES (@CustId, 0)

	-- Write log cust info
	SET @xml = (
		SELECT	
			@Username			AS '@u',
			@agentUsername		AS '@a',
			@Status				AS '@s',
			@BetStatus			AS '@bs',
			@MatchLimit			AS '@ml',
			@VirtualMultiplier	AS '@vm',
			@DoubleCommLosing	AS '@dc',
			@Danger				AS '@d',
			@IPLogin			AS '@il',
			@UGroup				AS '@ug'
		 FOR XML PATH('z'), ROOT('r')
	)

	SET @logCustSPData = REPLACE(CONVERT(NVARCHAR(MAX), @xml), '" />', '"/"')

	-- write log bet limit
	SET @xml = (
		SELECT  
			SportType		AS '@s'
			,BetType		AS '@b'
			,MinBet			AS '@mib'
			,MaxBet			AS '@mab'
			,MaxPerMatch	AS '@mam'
		FROM CustBetLimit WITH (NOLOCK)
		WHERE CustId = @CustId
		FOR XML PATH('z'), ROOT('r')
	)

	SET @logBetLimitSPData = REPLACE(CONVERT(NVARCHAR(MAX), @xml), '" />', '"/"')

	-- write log discount
	SET @xml = (
		SELECT  
			SportType	AS '@s',
			BetType		AS '@b',			
			Discount	AS '@d'
		FROM CustDiscount WITH (NOLOCK)
		WHERE CustId = @CustId
		FOR XML PATH('z')--, ROOT('r')
	)
	
	SET @logDiscountSPData = '<r g="'+ @UGroup +'">' + REPLACE(CONVERT(NVARCHAR(MAX), @xml), '" />', '"/"') + '</r>'
	
	-- Write log posistion taking
	SET @xml = (
		SELECT 
			SportType		AS '@s',
			BetType			AS '@b',
			IsLive			AS '@i',
			PositionTaking	AS '@p'
		FROM AgentCustPositionTaking WITH (NOLOCK)
		WHERE AgentCustId = @AgentId AND AgentId = @AgentId
		ORDER BY 
			SportType
			--,BetType
			,IsLive
		FOR XML PATH('z')
	)

	SET @logPositionTakingSPData = '<r a="' + @agentUsername + '">' + REPLACE(CONVERT(NVARCHAR(MAX), @xml), '" />', '"/"') + '</r>'

	-- end write log 

	SET @endRun = GETDATE()
	SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun) 

	IF @@ERROR = 0
		BEGIN TRY
			EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpCust
				@UserId		= @Creator,
				@SPName		= 'Age_Customer_Insert',
				@LogDate	= @startRun,
				@CustId		= @CustId,
				@Duration	= @Duration,
				@Data		= @logCustSPData,
				@OldData	= NULL

			EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpCust
				@UserId		= @Creator,
				@AdminId	= NULL,
				@SPName		= 'Age_Customer_InsertBetLimit',
				@LogDate	= @startRun,
				@CustId		= @CustId,
				@Duration	= @Duration,
				@Data		= @logBetLimitSPData,
				@OldData	= NULL

			EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpCust
				@UserId		= @Creator,
				@AdminId	= NULL,
				@SPName		= 'Age_Customer_InsertDiscount',
				@LogDate	= @startRun,
				@CustId		= @CustId,
				@Duration	= @Duration,
				@Data		= @logDiscountSPData,
				@OldData	= NULL

			EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpCust
				@UserId		= @Creator,
				@AdminId	= NULL,
				@SPName		= 'Age_Customer_InsertPositionTaking',
				@LogDate	= @startRun,
				@CustId		= @CustId,
				@Duration	= @Duration,
				@Data		= @logPositionTakingSPData,
				@OldData	= NULL
		END	TRY
		BEGIN CATCH
			EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpCust
				@UserId		= @Creator,
				@SPName		= 'Age_Customer_Insert',
				@LogDate	= @startRun,
				@CustId		= @CustId,
				@Duration	= @Duration,
				@Data		= @logCustSPData,
				@OldData	= NULL

			EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpCust
				@UserId		= @Creator,
				@AdminId	= NULL,
				@SPName		= 'Age_Customer_InsertBetLimit',
				@LogDate	= @startRun,
				@CustId		= @CustId,
				@Duration	= @Duration,
				@Data		= @logBetLimitSPData,
				@OldData	= NULL

			EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpCust
				@UserId		= @Creator,
				@AdminId	= NULL,
				@SPName		= 'Age_Customer_InsertDiscount',
				@LogDate	= @startRun,
				@CustId		= @CustId,
				@Duration	= @Duration,
				@Data		= @logDiscountSPData,
				@OldData	= NULL

			EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpCust
				@UserId		= @Creator,
				@AdminId	= NULL,
				@SPName		= 'Age_Customer_InsertPositionTaking',
				@LogDate	= @startRun,
				@CustId		= @CustId,
				@Duration	= @Duration,
				@Data		= @logPositionTakingSPData,
				@OldData	= NULL
		END CATCH
END										


