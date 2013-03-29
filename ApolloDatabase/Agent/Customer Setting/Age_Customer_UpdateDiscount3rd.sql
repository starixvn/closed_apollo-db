USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_UpdateDiscount3rd]    Script Date: 3/29/2013 10:45:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_Customer_UpdateDiscount3rd]
	@ActorAgentId	INT				= NULL,
	@CustId			INT,	
	@Discount		VARCHAR(MAX)	= '',
	@ErrCode		INT				= 0			OUTPUT,
	@ErrMsg			NVARCHAR(1000)	= ''		OUTPUT,
	@LogData		NVARCHAR(MAX)	= ''		OUTPUT,
	@LogOldData		NVARCHAR(MAX)	= ''		OUTPUT	 		
AS

/**
 * Created by	: Kos
 * Date			: 20130302
 * Task			: Update customer discount 3rd
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
	
	DECLARE @xml	XML

	IF @Discount <> ''
		BEGIN
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
				DiscountA
			FROM AgentDiscount3rd 
			WHERE AgentId = @AgentId			

			-- Check if discount must be equal to or less than all parents discount
			SELECT @sportType = dct.SportType
			FROM 
				@DiscountCompareTable AS dct
				INNER JOIN @DiscountTable AS dt ON dct.SportType = dt.SportType 
					AND dct.BetType = dt.BetType	
					AND dt.Discount > dct.Discount

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
					FROM CustDiscount3rd AS cd WITH (NOLOCK)
						INNER JOIN @DiscountTable AS td
							ON cd.SportType		= td.SportType
							AND cd.BetType		= td.BetType
					WHERE cd.CustId			= @CustId				
					FOR XML PATH('z')
			)

			SET @LogOldData = REPLACE(CONVERT(varchar(max), @xml), '" />', '"/"')

			-- end write log

			-- Update data
			UPDATE CustDiscount3rd WITH (ROWLOCK, UPDLOCK)
			SET CustDiscount3rd.Discount	= dt.Discount
			FROM 
				CustDiscount3rd AS pd
				INNER JOIN @DiscountTable AS dt ON pd.SportType = dt.SportType AND pd.BetType = dt.BetType
			WHERE CustId = @CustId 

			-- write log before update
				
			SET @xml = (
					SELECT  
						td.SportType		AS '@s'
						,td.BetType			AS '@b'
						,td.Discount		AS '@d'						
					FROM @DiscountTable AS td						
					FOR XML PATH('z')
			)

			SET @LogData = REPLACE(CONVERT(varchar(max), @xml), '" />', '"/"')

			-- end write log
		END	  	
END
