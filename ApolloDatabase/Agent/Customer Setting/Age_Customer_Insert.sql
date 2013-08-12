USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_Insert]    Script Date: 8/9/2013 9:01:45 AM ******/
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
	@UGroup				VARCHAR(3)		= 'd',				-- Group A
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
		@startRun			DATETIME,
		@endRun				DATETIME,
		@duration			INT,
		@logCustSPData				NVARCHAR(MAX),		
		@logBetLimitSPData			NVARCHAR(MAX),
		@logDiscountSPData			NVARCHAR(MAX),
		@logPositionTakingSPData	NVARCHAR(MAX),
		@xml				XML,
		@agentHId			HIERARCHYID

	SELECT @agentHId = AgentHId
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @AgentId

	SET @startRun = GETDATE()

	SET @UGroup = LOWER(@Ugroup)

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
		UplineStatus,
		UplineBetStatus,
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
		CASE WHEN Status = 2 OR UplineStatus = 2 THEN 2 ELSE 1 END,			-- UplineStatus
		CASE WHEN BetStatus = 2 OR UplineBetStatus = 2 THEN 2 ELSE 1 END,	-- UplineBetStatus
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
	
	-- Insert default customer discount (from it's parent)
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

	-- Insert pt of direct agent 
	INSERT CustPositionTaking (
		CustId
		,AgentId
		,SportType
		,BetType
		,IsLive
		,PositionTaking				
		)
	SELECT @custId
		,@AgentId
		,SportType
		,BetType
		,IsLive
		,MaxGivenPositionTaking		
	FROM AgentPositionTaking
	WHERE AgentId = @AgentId

	-- Insert pt for upline
	--INSERT INTO CustPositionTaking (
	--	CustId,
	--	AgentId,
	--	SportType,
	--	BetType,
	--	IsLive,
	--	PositionTaking )
	--SELECT
	--	@CustId,
	--	b.ParentId,
	--	a.SportType,
	--	a.BetType,
	--	a.IsLive,
	--	a.MaxGivenPositionTaking
	--FROM 
	--	AgentPositionTaking AS a WITH (NOLOCK)
	--	INNER JOIN AgentInfo AS b WITH (NOLOCK)	ON a.AgentId = b.AgentId
	--WHERE @agentHId.IsDescendantOf(b.AgentHId) = 1			
	--	AND b.AgentLevel > 1
	
	DECLARE @TableAgent TABLE (
		AgentId		INT, 
		AgentLevel	SMALLINT, 
		Username	NVARCHAR(50) )

	DECLARE @TableUpdatePT TABLE(
		AgentId			INT,
		AgentLevel		SMALLINT,
		SportType		SMALLINT,
		BetType			SMALLINT,
		IsLive			BIT,
		MaxUpper		SMALLINT,
		MaxUpperUpdate	SMALLINT,
		MinGiven		SMALLINT)	

	INSERT INTO @TableAgent
	SELECT 
		AgentId,
		AgentLevel,
		Username 
	FROM AgentInfo WITH (NOLOCK) 
	WHERE @agentHId.IsDescendantOf(AgentHId) = 1				
	
	INSERT INTO @TableUpdatePT(
		AgentId
		,AgentLevel
		,SportType
		,BetType
		,IsLive
		,MaxUpper
		,MaxUpperUpdate
		,MinGiven)		   
	SELECT apt.AgentId
		,ai.AgentLevel
		,apt.SportType
		,apt.BetType
		,apt.IsLive
		,apt.MaxUpperPositionTaking
		,capt.MaxUpperPositionTaking
		,apt.MinGivenPositionTaking
	FROM AgentPositionTaking AS apt WITH (NOLOCK)			
		INNER JOIN AgentInfo AS ai WITH (NOLOCK)
			ON apt.AgentId		= ai.AgentId
		LEFT JOIN @TableAgent AS ta
			ON ai.AgentLevel	= ta.AgentLevel - 1
		LEFT JOIN AgentPositionTaking AS capt WITH(NOLOCK)
			ON capt.AgentId		= ta.AgentId
			AND capt.SportType	= apt.SportType
			AND capt.BetType	= apt.BetType
			AND capt.IsLive		= apt.IsLive	
	WHERE apt.AgentId IN (SELECT temp.AgentId FROM @TableAgent AS temp)
		AND apt.AgentId		<> @AgentId
		AND ai.AgentLevel	> 0
	
	INSERT INTO CustPositionTaking (
		CustId
		,AgentId
		,SportType
		,BetType
		,IsLive
		,PositionTaking)
	SELECT @CustId
		 ,tupt.AgentId
		 ,tupt.SportType
		 ,tupt.BetType
		 ,tupt.IsLive
		 ,tupt.MaxUpperUpdate
	FROM @TableUpdatePT AS tupt			
	WHERE tupt.MinGiven = 0	 	

	DELETE @TableUpdatePT WHERE MinGiven = 0

	DECLARE @currentAgentId			INT,
			@currentAgentLevel 		SMALLINT
	
	WHILE EXISTS(
		SELECT TOP(1) * FROM @TableUpdatePT
	)
		BEGIN
			SELECT TOP(1) @currentAgentId	= AgentId
					,@currentAgentLevel		= AgentLevel
			FROM @TableUpdatePT
			ORDER BY AgentLevel DESC				

			INSERT INTO CustPositionTaking (
				CustId
				,AgentId
				,SportType
				,BetType
				,IsLive
				,PositionTaking)
			SELECT	@CustId
				 ,tupt.AgentId
				 ,tupt.SportType
				 ,tupt.BetType
				 ,tupt.IsLive
				 ,CASE WHEN tupt.MinGiven - temp.SumOfDownlinePT > tupt.MaxUpperUpdate
					THEN tupt.MinGiven - temp.SumOfDownlinePT
					ELSE tupt.MaxUpperUpdate
				END
			FROM @TableUpdatePT AS tupt					
				INNER JOIN(
					SELECT 
						cpt.SportType,
						cpt.BetType,
						cpt.IsLive,
						SUM(cpt.PositionTaking) AS SumOfDownlinePT
					FROM dbo.CustPositionTaking AS cpt WITH (NOLOCK)
						INNER JOIN AgentInfo AS ai WITH (NOLOCK)
							ON cpt.AgentId = ai.AgentId 
					WHERE 
						CustId = @CustId
						AND ai.AgentLevel > @currentAgentLevel
					GROUP BY  
						SportType,
						BetType,
						IsLive
				) AS temp
					ON temp.SportType	= tupt.SportType
					AND temp.BetType	= tupt.BetType
					AND temp.IsLive		= tupt.IsLive
			WHERE tupt.AgentId	= @currentAgentId				  

			DELETE @TableUpdatePT WHERE AgentId = @currentAgentId
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
			(SELECT Username FROM AgentInfo WHERE AgentId = @AgentId)	AS '@a',
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
		FROM CustPositionTaking WITH (NOLOCK)
		WHERE CustId = @CustId
			AND AgentId = @AgentId
		ORDER BY SportType
				--,BetType
				,IsLive
		FOR XML PATH('z')
	)

	SET @logPositionTakingSPData = '<r a="'+(SELECT Username FROM AgentInfo WITH (NOLOCK) WHERE AgentId = @AgentId)+'">'+REPLACE(CONVERT(NVARCHAR(MAX), @xml), '" />', '"/"')+'</r>'

	-- end write log 

	SET @endRun = GETDATE()
	SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun) 

	IF @@Error = 0
		BEGIN TRY
			EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpCust
			@UserId			= @Creator,
			@SPName			= 'Age_Customer_Insert',
			@LogDate		= @startRun,
			@CustId			= @CustId,
			@Duration		= @Duration,
			@Data			= @logCustSPData,
			@OldData		= NULL

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
			@UserId			= @Creator,
			@SPName			= 'Age_Customer_Insert',
			@LogDate		= @startRun,
			@CustId			= @CustId,
			@Duration		= @Duration,
			@Data			= @logCustSPData,
			@OldData		= NULL

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