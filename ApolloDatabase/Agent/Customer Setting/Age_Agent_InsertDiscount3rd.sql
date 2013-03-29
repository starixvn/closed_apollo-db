USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_InsertDiscount3rd]    Script Date: 3/29/2013 10:09:22 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Agent_InsertDiscount3rd]
	@AgentId	INT,
	@Discount	VARCHAR(MAX)	= '',
	@ErrCode	INT				= 0			OUTPUT,
	@ErrMsg		NVARCHAR(1000)	= ''		OUTPUT 		
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Insert agent discount 3rd
 * DB			: APL.CustDB
 * Revisions	:
 *	• 20132702@Edward	: Implement
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
	
	DECLARE @DiscountTable TABLE(
		SportType SMALLINT,
		BetType SMALLINT,
		DiscountA DECIMAL(9,8),
		DiscountB DECIMAL(9,8),
		DiscountC DECIMAL(9,8),
		DiscountD DECIMAL(9,8))
	
	DECLARE @parentId	INT
	DECLARE @sportType	INT

	---- Get parent of agent
	SELECT @parentId = ParentId
	FROM AgentInfo WITH (NOLOCK)
	WHERE AgentId = @AgentId	

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

	-- Check validate	range 
	SELECT @sportType = SportType 
	FROM @DiscountTable 
	WHERE DiscountA NOT BETWEEN 0 AND 0.0025

	IF @sportType IS NOT NULL 
		BEGIN
			SELECT @ErrCode = 1

			----Message for each sport type	WITH CASE @sportType
			SELECT @ErrMsg	= 'Invalid commission rate. Sport Type = ' + COALESCE(CAST(@sportType AS VARCHAR(10)), SPACE(1)) 						

			RETURN			
		END

	---- Check if discount must be equal to or less than parent
	SELECT @sportType = ad.SportType
	FROM 
		AgentDiscount3rd AS ad WITH (NOLOCK)
		INNER JOIN @DiscountTable AS dt 
		ON 
			ad.SportType = dt.SportType 
			AND ad.BetType = dt.BetType	
			AND dt.DiscountA > ad.DiscountA
			AND dt.DiscountB > ad.DiscountB
			AND dt.DiscountC > ad.DiscountC
			AND dt.DiscountD > ad.DiscountD
	WHERE ad.AgentId = @parentId

	IF @sportType IS NOT NULL 
		BEGIN
			SELECT @ErrCode = 1

			----Message for each sport type	WITH CASE @sportType
			SELECT @ErrMsg	= 'Discount must be equal to or less than Parent Agent discount. Sport Type = ' + COALESCE(CAST(@sportType AS VARCHAR(10)), SPACE(1)) 												

			RETURN	
		END

	-- Insert data
	INSERT INTO dbo.AgentDiscount3rd
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
	  	
END
