USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_InsertDiscount3rd]    Script Date: 3/29/2013 10:43:43 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_InsertDiscount3rd]
	@CustId		INT,
	@AgentId	INT,
	@Discount	VARCHAR(MAX)	= '',
	@ErrCode	INT				= 0			OUTPUT,
	@ErrMsg		NVARCHAR(1000)	= ''		OUTPUT 		
AS

/**
 * Created by	: Kos
 * Date			: 20130302
 * Task			: Insert customer discount 3rd
 * DB			: APL.CustDB
 * Revisions	:
 *	• 
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
	
	---- Check validate	range		
	SELECT @sportType = SportType 
	FROM @DiscountTable 
	WHERE Discount NOT BETWEEN 0 AND 0.0025

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
		MIN(DiscountA)
	FROM AgentDiscount3rd WITH (NOLOCK)
	WHERE AgentId IN (	SELECT AgentId 
						FROM AgentInfo WITH (NOLOCK)
						WHERE @AgentHId.IsDescendantOf(AgentHId) = 1 OR AgentId = @AgentId)
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
	INSERT INTO dbo.CustDiscount3rd
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
	  	
END
