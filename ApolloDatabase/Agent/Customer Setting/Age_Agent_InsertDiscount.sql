USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_InsertDiscount]    Script Date: 4/17/2013 2:51:26 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_InsertDiscount]
	@AgentId	INT,
	@Discount	VARCHAR(MAX)	= '',
	@Creator	INT				= NULL,
	@LogDate	DATETIME		= NULL,
	@ErrCode	INT				= 0			OUTPUT,
	@ErrMsg		NVARCHAR(1000)	= ''		OUTPUT 		
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Insert agent discount
 * DB			: APL.CustDB
 * Revisions	:
 *	• 20132702@Edward	: Implement
 *	•	20130417@Edward	: Write log and add @Creator, @LogDate
 * Parameters:
 *	• @Discount : 		
		<ROOT>
			<Discount SportType="4" BetType="4" DiscountA="1" DiscountB="1" DiscountC="1" DiscountD="1"></Discount>
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
		DiscountA DECIMAL(9,8),
		DiscountB DECIMAL(9,8),
		DiscountC DECIMAL(9,8),
		DiscountD DECIMAL(9,8))
	
	DECLARE @parentId	INT
	DECLARE @sportType	INT

	-- Get parent of agent
	SELECT @parentId = ai.ParentId
	FROM AgentInfo AS ai WITH (NOLOCK)
	WHERE ai.AgentId = @AgentId	

	-- For read xml
	DECLARE @DocHandler int

	EXEC sp_xml_preparedocument @DocHandler OUTPUT, @Discount

	INSERT INTO @DiscountTable (
		SportType,
		BetType,
		DiscountA,
		DiscountB,
		DiscountC,
		DiscountD)			
	SELECT 			
		Data.SportType,
		Data.BetType,
		Data.DiscountA,
		Data.DiscountB,
		Data.DiscountC,
		Data.DiscountD
	FROM OPENXML (@DocHandler, '/ROOT/Discount',1) 
	WITH (			
		SportType		SMALLINT,
		BetType			SMALLINT,
		DiscountA		DECIMAL(9,8),
		DiscountB		DECIMAL(9,8),
		DiscountC		DECIMAL(9,8),
		DiscountD		DECIMAL(9,8)
	) AS Data

	EXEC sp_xml_removedocument @DocHandler
	-- end read xml

	---- Check validate	range		
	SELECT @sportType = SportType 
	FROM @DiscountTable 
	WHERE 
		(DiscountA NOT BETWEEN 0 AND 0.0025 AND SportType = 1 AND BetType = 1)		-- Group A
		OR (DiscountB NOT BETWEEN 0 AND 0.005 AND SportType = 1 AND BetType = 1)	-- Group B
		OR (DiscountC NOT BETWEEN 0 AND 0.0075 AND SportType = 1 AND BetType = 1)	-- Group C
		OR (DiscountD NOT BETWEEN 0 AND 0.01 AND SportType = 1 AND BetType = 1)		-- Group D
		OR (DiscountA NOT BETWEEN 0 AND 0.0025 AND SportType = 1 AND BetType = 5)	-- 1x2
		OR (DiscountA NOT BETWEEN 0 AND 0.01 AND SportType = 1 AND BetType = 4)		-- Others

	IF @sportType IS NOT NULL 
		BEGIN
			SELECT @ErrCode = 1

			----Message for each sport type	WITH CASE @sportType
			SELECT @ErrMsg	= 'Invalid commission rate. Sport Type = ' + COALESCE(CAST(@sportType AS VARCHAR(10)), SPACE(1)) 						

			RETURN			
		END

	---- Check if discount must be equal to or greater than parent
	SELECT @sportType = ad.SportType
	FROM 
		AgentDiscount AS ad WITH (NOLOCK)
		INNER JOIN @DiscountTable AS dt 
		ON 
			ad.SportType = dt.SportType 
			AND ad.BetType = dt.BetType	
			AND (dt.DiscountA > ad.DiscountA
			OR dt.DiscountB > ad.DiscountB
			OR dt.DiscountC > ad.DiscountC
			OR dt.DiscountD > ad.DiscountD)
	WHERE ad.AgentId = @parentId

	IF @sportType IS NOT NULL 
		BEGIN
			SELECT @ErrCode = 1

			----Message for each sport type	WITH CASE @sportType
			SELECT @ErrMsg	= 'Commission must be equal to or greater than Paret Agent commission. Sport Type = ' + COALESCE(CAST(@sportType AS VARCHAR(10)), SPACE(1)) 												

			RETURN	
		END

	-- Insert data
	INSERT INTO dbo.AgentDiscount
	(
		AgentId,
		SportType,
		BetType,
		DiscountA,
		DiscountB,
		DiscountC,
		DiscountD
	)
	SELECT
		@AgentId,
		SportType,
		BetType,
		DiscountA,
		DiscountB,
		DiscountC,
		DiscountD
	FROM @DiscountTable
	 
	SET @xml = (
		SELECT SportType	AS '@s' 
				,BetType	AS '@b'
				,DiscountA	AS '@da'
				,DiscountB	AS '@db'
				,DiscountC	AS '@dc'
				,DiscountD	AS '@dd'
		FROM @DiscountTable
		FOR XML PATH('z'), ROOT('r')
	)

	SET @logSPData = REPLACE(CONVERT(varchar(max), @xml), '" />', '"/"')

	SET @endRun		= GETDATE()  
	SET @duration	= DATEDIFF(millisecond, @startRun, @endRun) 

	IF @LogDate IS NULL
		SET @LogDate = GETDATE()	

	EXEC LogDB.dbo.Age_LogRunSp_Insert
		@UserId			= @Creator,
		@SPName			= 'Age_Agent_InsertDiscount',
		@LogDate		= @LogDate,
		@ObjectId		= @AgentId,
		@ObjectTypeId	= 1,			--Object type : Agent						
		@Duration		= @Duration,
		@Data			= @logSPData,
		@OldData		= @logSPDataOld 	
END
