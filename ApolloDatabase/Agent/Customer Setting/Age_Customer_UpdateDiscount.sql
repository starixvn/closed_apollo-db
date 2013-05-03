USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_UpdateDiscount]    Script Date: 4/17/2013 2:55:07 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_UpdateDiscount]
	@ActorAgentId	INT				= NULL,
	@CustId			INT,	
	@UGroup			VARCHAR(3),
	@Discount		VARCHAR(MAX)	= '',	
	@LogDate		DATETIME		= NULL,
	@ErrCode		INT				= 0			OUTPUT,
	@ErrMsg			NVARCHAR(1000)	= ''		OUTPUT 		
AS

/**
 * Created by	: Kos
 * Date			: 20130302
 * Task			: Update customer discount
 * DB			: APL.CustDB
 * Revisions	:
 *	• 
 * Parameters:
 *	• @Discount : 		
		<ROOT>
			<Discount SportType="4" BetType="4" Discount="1" ></Discount>
		</ROOT>		
*	• @Discount3rd : 		
		<ROOT>
			<Discount SportType="4" BetType="4" Discount="1" ></Discount>
		</ROOT>		
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON
	
	-- Check update permission
	DECLARE @hasPermission BIT
	EXEC dbo.Age_Agent_CheckUpdatePermission @ActorAgentId, @CustId, 2, @hasPermission OUTPUT 
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

	IF @Discount <> ''
		BEGIN
			SET @UGroup = LOWER(@Ugroup)

			DECLARE @OldUGroup VARCHAR(3)	

			DECLARE @DiscountTable TABLE(
				SportType SMALLINT,
				BetType SMALLINT,
				Discount DECIMAL(9,8))

			DECLARE @DiscountCompareTable TABLE(
				SportType SMALLINT,
				BetType SMALLINT,
				Discount DECIMAL(9,8))
			
			DECLARE	@agentHId HIERARCHYID
			DECLARE @sportType INT

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
				SportType		SMALLINT,
				BetType			SMALLINT,
				Discount		DECIMAL(9,8)				
			) AS Data

			EXEC sp_xml_removedocument @DocHandler
			-- end read xml	

			---- Check validate	range		
			SELECT @sportType = SportType 
			FROM @DiscountTable 
			WHERE 
				(Discount NOT BETWEEN 0 AND 0.0025 AND @UGroup = 'a')	
				OR (Discount NOT BETWEEN 0 AND 0.005 AND @UGroup = 'b')
				OR (Discount NOT BETWEEN 0 AND 0.0075 AND @UGroup = 'c')
				OR (Discount NOT BETWEEN 0 AND 0.01 AND @UGroup = 'd')
				OR (Discount NOT BETWEEN 0 AND 0.0025 AND SportType = 1 AND BetType = 5)	-- 1x2
				OR (Discount NOT BETWEEN 0 AND 0.01 AND SportType = 1 AND BetType = 4)		-- Others

			IF @sportType IS NOT NULL 
				BEGIN
					SELECT @ErrCode = 1

					----Message for each sport type	WITH CASE @sportType
					SELECT @ErrMsg	= 'Invalid commission rate. Sport Type = ' + COALESCE(CAST(@sportType AS VARCHAR(10)), SPACE(1)) 						

					RETURN			
				END

			DECLARE @AgentId INT
			SELECT @AgentId = pli.AgentId 
			FROM CustInfo AS pli WITH (NOLOCK)
			WHERE pli.CustId = @CustId

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
			FROM AgentDiscount 
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
					SELECT @ErrCode = 1

					----Message for each sport type	WITH CASE @sportType
					SELECT @ErrMsg	= 'Discount must be equal to or less than Parent Agent discount. Sport Type = ' + COALESCE(CAST(@sportType AS VARCHAR(10)), SPACE(1)) 												

					RETURN	
				END

			-- write log before update
				
			SET @xml = (
					SELECT  
						cd.SportType		AS '@s'
						,cd.BetType			AS '@b'
						,cd.Discount		AS '@d'						
					FROM CustDiscount AS cd WITH (NOLOCK)
						INNER JOIN @DiscountTable AS td
							ON cd.SportType		= td.SportType
							AND cd.BetType		= td.BetType
					WHERE cd.CustId			= @CustId				
					FOR XML PATH('z'), ROOT('r')
			)

			SET @logSPDataOld = REPLACE(CONVERT(varchar(max), @xml), '" />', '"/"')

			-- end write log

			-- Update data
			UPDATE CustDiscount WITH (ROWLOCK, UPDLOCK)
			SET CustDiscount.Discount	= dt.Discount
			FROM 
				CustDiscount AS pd
				INNER JOIN @DiscountTable AS dt 
					ON pd.SportType = dt.SportType 
					AND pd.BetType	= dt.BetType
			WHERE CustId = @CustId
			

			SELECT @OldUGroup = UGroup 
			FROM CustInfo WITH (NOLOCK)
			WHERE CustId = @CustId

			IF @OldUGroup <> @UGroup
				BEGIN
					UPDATE CustInfo WITH (ROWLOCK, UPDLOCK)
					SET 
						UGroup		= @UGroup
					WHERE CustId	= @CustId
				END

			-- write log before update
				
			SET @xml = (
					SELECT  
						td.SportType		AS '@s'
						,td.BetType			AS '@b'
						,td.Discount		AS '@d'						
					FROM @DiscountTable AS td						
					FOR XML PATH('z'), ROOT('r')
			)

			SET @logSPData = REPLACE(CONVERT(varchar(max), @xml), '" />', '"/"')

			-- end write log 
		END

	SET @endRun		= GETDATE()  
	SET @duration	= DATEDIFF(millisecond, @startRun, @endRun) 

	IF @LogDate IS NULL
		SET @LogDate = GETDATE()

	EXEC LogDB.dbo.Age_LogRunSp_Insert
		@UserId			= @ActorAgentId,
		@SPName			= 'Age_Customer_UpdateDiscount',
		@LogDate		= @LogDate,
		@ObjectId		= @CustId,
		@ObjectTypeId	= 2,			--Object type : Cust						
		@Duration		= @Duration,
		@Data			= @logSPData,
		@OldData		= @logSPDataOld
END
