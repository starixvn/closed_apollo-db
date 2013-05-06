USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_InsertDiscount]    Script Date: 5/6/2013 12:42:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_InsertDiscount]
	@CustId		INT,
	@AgentId	INT,
	@UGroup		VARCHAR(3),
	@Discount	VARCHAR(MAX)	= '',
	@Creator	INT				= NULL,	
	@ErrCode	INT				= 0			OUTPUT,
	@ErrMsg		NVARCHAR(1000)	= ''		OUTPUT 		
AS

/**
 * Created by	: Kos
 * Date			: 20130302
 * Task			: Insert customer discount
 * DB			: APL.CustDB
 * Revisions	:
 *	•	20130417@Edward	: Write log and add @Creator, @LogDate 
 * Parameters:
 *	• @Discount : 		
		<ROOT>
			<Discount SportType="4" BetType="4" Discount="1" ></Discount>
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

	DECLARE @DiscountTable TABLE(
		SportType SMALLINT,
		BetType SMALLINT,
		Discount DECIMAL(9,8))

	DECLARE @DiscountCompareTable TABLE(
		SportType SMALLINT,
		BetType SMALLINT,
		Discount DECIMAL(9,8))
	
	DECLARE	@agentHId	HIERARCHYID
	DECLARE @sportType	INT

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
	
	-- Check validate range		
	SELECT @sportType = SportType 
	FROM @DiscountTable 
	WHERE 
		(Discount NOT BETWEEN 0 AND 0.0225 AND SportType = 1 AND BetType = 1 AND @UGroup = 'a')		-- Group A
		OR (Discount NOT BETWEEN 0 AND 0.0125 AND SportType = 1 AND BetType = 1 AND @UGroup = 'b')	-- Group B
		OR (Discount NOT BETWEEN 0 AND 0.0075 AND SportType = 1 AND BetType = 1 AND @UGroup = 'c')	-- Group C
		OR (Discount NOT BETWEEN 0 AND 0 AND SportType = 1 AND BetType = 1 AND @UGroup = 'd')	-- Group D
		OR (Discount NOT BETWEEN 0 AND 0 AND SportType = 1 AND BetType = 5)					-- 1x2
		OR (Discount NOT BETWEEN 0 AND 0 AND SportType = 1 AND BetType = 4)						-- Others

	IF @sportType IS NOT NULL 
		BEGIN
			SELECT @ErrCode = 1

			----Message for each sport type	WITH CASE @sportType
			SELECT @ErrMsg	= 'Invalid commission rate. Sport Type = ' + COALESCE(CAST(@sportType AS VARCHAR(10)), SPACE(1)) 						

			RETURN			
		END

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
			WHEN SportType = 1 AND BetType = 5 THEN MIN(DiscountA)		-- 1x2
			WHEN SportType = 1 AND BetType = 4 THEN MIN(DiscountA)		-- Others
			ELSE
				CASE 
					WHEN @UGroup = 'A' THEN MIN(DiscountA)
					WHEN @UGroup = 'B' THEN MIN(DiscountB)
					WHEN @UGroup = 'C' THEN MIN(DiscountC)
					WHEN @UGroup = 'D' THEN MIN(DiscountD)
				END
		END
	FROM AgentDiscount WITH (NOLOCK)
	WHERE AgentId IN (	SELECT AgentId 
						FROM AgentInfo  WITH (NOLOCK)
						WHERE @AgentHId.IsDescendantOf(AgentHId) = 1)
	GROUP BY SportType, BetType

	-- Check if discount must be equal to or less than all parents discount
	SELECT @sportType = dct.SportType
	FROM 
		@DiscountCompareTable AS dct
		INNER JOIN @DiscountTable AS dt ON dct.SportType = dt.SportType 
			AND dct.BetType = dt.BetType	
			AND dt.Discount < dct.Discount

	IF @sportType IS NOT NULL 
		BEGIN
			SELECT @ErrCode = 1

			----Message for each sport type	WITH CASE @sportType
			SELECT @ErrMsg	= 'Discount must be equal to or greater than Parent Agent discount. Sport Type = ' + COALESCE(CAST(@sportType AS VARCHAR(10)), SPACE(1)) 												

			RETURN	
		END

	-- Insert data
	INSERT INTO dbo.CustDiscount
	(
		CustId,
		SportType,
		BetType,
		Discount
	)
	SELECT
		@CustId,
		SportType,
		BetType,
		Discount
	FROM @DiscountTable
	
	 
	SET @xml = (
		SELECT SportType	AS '@s' 
				,BetType	AS '@b'
				,Discount	AS '@d'				
		FROM @DiscountTable
		FOR XML PATH('z'), ROOT('r')
	)

	SET @logSPData = REPLACE(CONVERT(varchar(max), @xml), '" />', '"/"')

	SET @endRun		= GETDATE()  
	SET @duration	= DATEDIFF(millisecond, @startRun, @endRun) 
	
	IF @@Error = 0
		BEGIN TRY
			EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpCust
			@UserId			= @Creator,
			@SPName			= 'Age_Customer_InsertDiscount',
			@LogDate		= @startRun,
			@CustId			= @CustId,
			@Duration		= @Duration,
			@Data			= @logSPData,
			@OldData		= @logSPDataOld
		END	TRY
		BEGIN CATCH
			EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpCust
			@UserId			= @Creator,
			@SPName			= 'Age_Customer_InsertDiscount',
			@LogDate		= @startRun,
			@CustId			= @CustId,
			@Duration		= @Duration,
			@Data			= @logSPData,
			@OldData		= @logSPDataOld
		END CATCH  	
END
