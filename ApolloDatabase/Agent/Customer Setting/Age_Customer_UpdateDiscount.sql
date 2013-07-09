USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_UpdateDiscount]    Script Date: 7/9/2013 10:56:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_UpdateDiscount]
	@ActorAgentId	INT				= NULL,
	@CustId			INT,	
	@UGroup			VARCHAR(3),
	@Discount		VARCHAR(MAX)	= '',
	@Language		VARCHAR(5)		= 'en-US',
	@ErrCode		INT				= 0			OUTPUT,
	@ErrMsg			NVARCHAR(1000)	= ''		OUTPUT
AS

/**
 * Created by	: Kos
 * Date			: 20130302
 * Task			: Update customer discount
 * DB			: SVRCUST.CustDB
 * Revisions	:
 *	• 
 * Parameters:
 *	• @Discount :
		<ROOT>
			<Discount SportType="4" BetType="4" Discount="1" ></Discount>
		</ROOT>		
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
				@ErrMsg = 
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
		
	-- begin update

	SET @UGroup = LOWER(@Ugroup)

	DECLARE 
		@agentHId	HIERARCHYID
		,@sportType	INT
		,@groupCode	INT
		,@OldUGroup VARCHAR(3)

	SELECT @OldUGroup = LOWER(UGroup)
	FROM CustInfo WITH (NOLOCK)
	WHERE CustId = @CustId

	IF @UGroup <> '' OR @Discount <> ''
		BEGIN
			-- write log before update
				
			SET @xml = (
				SELECT
					cd.SportType	AS '@s'
					,cd.BetType		AS '@b'
					--@OldUGroup		AS '@g'
					,cd.Discount	AS '@d'
				FROM CustDiscount AS cd WITH (NOLOCK)
					--INNER JOIN @DiscountTable AS td
					--	ON cd.SportType	= td.SportType
					--	AND cd.BetType	= td.BetType
				WHERE cd.CustId = @CustId
				FOR XML PATH('z')--, ROOT('r')
			)

			SET @logSPDataOld = '<r g="'+ @OldUGroup +'">' + REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')+ '</r>'

			-- end write log
		END

	IF @UGroup <> ''
		BEGIN

			IF	@UGroup <> 'a'
				AND @UGroup <> 'b'
				AND @UGroup <> 'c'
				AND @UGroup <> 'd'
				BEGIN
					SELECT 
						@ErrCode	= 2008,
						@ErrMsg		= 
							CASE @Language
								WHEN 'en-US' THEN 'Invalid commission line '
								ELSE [dbo].f_Msg_GetContentById (2008, @Language)
							END
					RETURN	
				END

			IF @Discount = '' AND @UGroup <> @OldUGroup
				BEGIN
					SELECT
						@sportType = SportType,
						@groupCode = 
							CASE
								WHEN Discount NOT BETWEEN 0 AND 0.0225 AND @UGroup = 'a' THEN 2001
								WHEN Discount NOT BETWEEN 0 AND 0.0125 AND @UGroup = 'b' THEN 2002
								WHEN Discount NOT BETWEEN 0 AND 0.0075 AND @UGroup = 'c' THEN 2003
								WHEN Discount NOT BETWEEN 0 AND 0 AND @UGroup = 'd' THEN 2004						
							END 
					FROM CustDiscount WITH (NOLOCK)
					WHERE 
						(	
							(Discount NOT BETWEEN 0 AND 0.0225 AND @UGroup = 'a')		-- Group A
							OR (Discount NOT BETWEEN 0 AND 0.0125 AND @UGroup = 'b')	-- Group B
							OR (Discount NOT BETWEEN 0 AND 0.0075 AND @UGroup = 'c')	-- Group C
							OR (Discount NOT BETWEEN 0 AND 0 AND @UGroup = 'd')			-- Group D					
						)	AND CustId = @CustId

			IF @sportType IS NOT NULL 
				BEGIN
					SELECT 
						@ErrCode	= 2000,
						@ErrMsg		= 
							CASE @Language
								WHEN 'en-US' THEN 'Invalid commission rate '
								ELSE [dbo].f_Msg_GetContentById (2000, @Language)
							END + ' (' + [dbo].f_Msg_GetContentById (@groupCode, @Language) + ')'
					RETURN
				END			
				END
	
			IF @OldUGroup <> @UGroup
				BEGIN
					UPDATE CustInfo WITH (ROWLOCK, UPDLOCK)
					SET UGroup = @UGroup
					WHERE CustId = @CustId
				END
		END

	IF @Discount <> ''
		BEGIN
			DECLARE @DiscountTable TABLE (
				SportType SMALLINT,
				BetType SMALLINT,
				Discount DECIMAL(9,8))

			DECLARE @DiscountCompareTable TABLE (
				SportType SMALLINT,
				BetType SMALLINT,
				Discount DECIMAL(9,8))	

			-- For read xml
			DECLARE @DocHandler int

			EXEC sp_xml_preparedocument @DocHandler OUTPUT, @Discount

			INSERT INTO @DiscountTable (
				SportType,
				BetType,
				Discount)
			SELECT
				Data.SportType,
				Data.BetType,
				Data.Discount
			FROM OPENXML (@DocHandler, '/ROOT/Discount',1) 
			WITH (
				SportType	SMALLINT,
				BetType		SMALLINT,
				Discount	DECIMAL(9,8)
			) AS Data

			EXEC sp_xml_removedocument @DocHandler
			-- end read xml

			-- Check validate range
			SELECT
				@sportType = SportType,
				@groupCode = 
					CASE
						WHEN Discount NOT BETWEEN 0 AND 0.0225 AND @UGroup = 'a' THEN 2001
						WHEN Discount NOT BETWEEN 0 AND 0.0125 AND @UGroup = 'b' THEN 2002
						WHEN Discount NOT BETWEEN 0 AND 0.0075 AND @UGroup = 'c' THEN 2003
						WHEN Discount NOT BETWEEN 0 AND 0 AND @UGroup = 'd' THEN 2004
						WHEN Discount NOT BETWEEN 0 AND 0 AND SportType = 1 AND BetType = 5 THEN 2005
						WHEN Discount NOT BETWEEN 0 AND 0 AND SportType = 1 AND BetType = 4 THEN 2006
					END 
			FROM @DiscountTable 
			WHERE 
				(Discount NOT BETWEEN 0 AND 0.0225 AND @UGroup = 'a')		-- Group A
				OR (Discount NOT BETWEEN 0 AND 0.0125 AND @UGroup = 'b')	-- Group B
				OR (Discount NOT BETWEEN 0 AND 0.0075 AND @UGroup = 'c')	-- Group C
				OR (Discount NOT BETWEEN 0 AND 0 AND @UGroup = 'd')			-- Group D
				OR (Discount NOT BETWEEN 0 AND 0 AND SportType = 1 AND BetType = 5) -- 1x2
				OR (Discount NOT BETWEEN 0 AND 0 AND SportType = 1 AND BetType = 4) -- Others

			IF @sportType IS NOT NULL 
				BEGIN
					SELECT 
						@ErrCode	= 2000,
						@ErrMsg		= 
							CASE @Language
								WHEN 'en-US' THEN 'Invalid commission rate '
								ELSE [dbo].f_Msg_GetContentById (2000, @Language)
							END + ' (' + [dbo].f_Msg_GetContentById (@groupCode, @Language) + ')'
					RETURN
				END

			-- End check validate range

			DECLARE @AgentId INT

			SELECT @AgentId = AgentId 
			FROM CustInfo WITH (NOLOCK)
			WHERE CustId = @CustId

			-- Get agent hierarchy ID
			SELECT @agentHId = AgentHId
			FROM AgentInfo WITH (NOLOCK)
			WHERE AgentId = @AgentId

			-- Get validate data from its parent and upline
			INSERT INTO @DiscountCompareTable(
				SportType,
				BetType,
				Discount)
			SELECT 
				SportType,
				BetType,
				CASE
					WHEN SportType = 1 AND BetType = 5 THEN DiscountA		-- 1x2
					WHEN SportType = 1 AND BetType = 4 THEN DiscountA		-- Others
					ELSE
						CASE 
							WHEN @UGroup = 'a' THEN DiscountA
							WHEN @UGroup = 'b' THEN DiscountB
							WHEN @UGroup = 'c' THEN DiscountC
							WHEN @UGroup = 'd' THEN DiscountD
						END
				END
			FROM AgentDiscount WITH (NOLOCK)
			WHERE AgentId = @AgentId

			-- Check if discount must be equal to or less than all parents discount
			SELECT @sportType = dct.SportType
			FROM 
				@DiscountCompareTable AS dct
				INNER JOIN @DiscountTable AS dt 
					ON dct.SportType	= dt.SportType 
					AND dct.BetType		= dt.BetType	
					AND dt.Discount		> dct.Discount
			
			IF @sportType IS NOT NULL 
				BEGIN
					SELECT 
						@ErrCode = 2007,
						@ErrMsg = 
							CASE @Language
								WHEN 'en-US' THEN 'Discount must be equal to or less than Parent Agent discount'
								ELSE [dbo].f_Msg_GetContentById (2007, @Language)  
							END
					RETURN
				END			

			-- Update data
			UPDATE CustDiscount WITH (ROWLOCK, UPDLOCK)
			SET CustDiscount.Discount = dt.Discount
			FROM 
				CustDiscount AS pd
				INNER JOIN @DiscountTable AS dt 
					ON pd.SportType = dt.SportType 
					AND pd.BetType	= dt.BetType
			WHERE CustId = @CustId
		END

	IF @UGroup <> '' OR @Discount <> ''
		BEGIN
			
			-- write log before update
				
			SET @xml = (
				SELECT  
					SportType	AS '@s',
					BetType		AS '@b',
					--@UGroup		AS '@g',
					Discount	AS '@d'
				FROM @DiscountTable
				FOR XML PATH('z')--, ROOT('r')
			)

			IF @xml IS NOT NULL
				SET @logSPData = '<r g="'+ @UGroup +'">' + REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"') + '</r>'
			ELSE
				SET @logSPData = '<r g="'+ @UGroup +'"></r>'
			-- end write log 

			SET @endRun		= GETDATE()
			SET @duration	= DATEDIFF(MILLISECOND, @startRun, @endRun) 

			IF @@ERROR = 0
				BEGIN TRY
					EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpCust
						@UserId		= @ActorAgentId,
						@SPName		= 'Age_Customer_UpdateDiscount',
						@LogDate	= @startRun,
						@CustId		= @CustId,
						@Duration	= @Duration,
						@Data		= @logSPData,
						@OldData	= @logSPDataOld
				END	TRY
				BEGIN CATCH
					EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpCust
						@UserId		= @ActorAgentId,
						@SPName		= 'Age_Customer_UpdateDiscount',
						@LogDate	= @startRun,
						@CustId		= @CustId,
						@Duration	= @Duration,
						@Data		= @logSPData,
						@OldData	= @logSPDataOld
				END CATCH
		END
END
