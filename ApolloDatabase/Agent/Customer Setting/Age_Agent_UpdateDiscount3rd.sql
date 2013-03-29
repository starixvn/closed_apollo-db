USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_UpdateDiscount3rd]    Script Date: 3/29/2013 10:38:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
DECLARE	@return_value int,
		@ErrCode int,
		@ErrMsg nvarchar(1000)

EXEC	@return_value = [dbo].[Acc_Agent_UpdateDiscount3rd]
		@AgentId = 2,
		@Discount = N'
		<ROOT>
			<Discount SportType="1" BetType="1" DiscountA="0.00025" DiscountB="0.005" DiscountC="0.00075" DiscountD="0.01"></Discount>
			<Discount SportType="1" BetType="4" DiscountA="0" DiscountB="0" DiscountC="0" DiscountD="0"></Discount>
			<Discount SportType="1" BetType="5" DiscountA="0.03" DiscountB="0" DiscountC="0" DiscountD="0"></Discount>
			<Discount SportType="1" BetType="81" DiscountA="0" DiscountB="0" DiscountC="0" DiscountD="0"></Discount>
		</ROOT>',
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT

SELECT	@ErrCode as N'@ErrCode',
		@ErrMsg as N'@ErrMsg'

SELECT	'Return Value' = @return_value
*/

ALTER PROCEDURE [dbo].[Age_Agent_UpdateDiscount3rd]
	@ActorAgentId		INT				= NULL,
	@AgentId			INT,
	@Discount			VARCHAR(MAX)	= '',
	@Language			VARCHAR(2)		= 'E',
	@ErrCode			INT				= 0			OUTPUT,
	@ErrMsg				NVARCHAR(1000)	= ''		OUTPUT,
	@LogData			NVARCHAR(MAX)	= ''		OUTPUT,
	@LogOldData			NVARCHAR(MAX)	= ''		OUTPUT	 		 		
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Update agent discount
 * DB			: APL.CustDB
 * Revisions	:
 *	• 20132702@Edward	: Implement
 * Parameters:
 *	•	@Discount : 		
			<ROOT>
				<Discount SportType="4" BetType="4" DiscountA="1" DiscountB="1" DiscountC="1" DiscountD="1"></Discount>
			</ROOT>		
 *	•
 *  
 */

BEGIN
	
	SET NOCOUNT ON
	
	DECLARE @xml	XML
		
	IF @Discount <> ''
	BEGIN		
		DECLARE @agentHId			HIERARCHYID
				,@parentAgentId		INT

		DECLARE @TableAgent	TABLE( AgentId INT)

		-- Get agent hierarchy ID
		SELECT 
			@agentHId		= AgentHId
			,@parentAgentId	= ParentId
		FROM 
			AgentInfo WITH (NOLOCK)
		WHERE 
			AgentId = @AgentId

		DECLARE @TableDiscount TABLE(
			SportType	SMALLINT,
			BetType		SMALLINT,
			DiscountA	DECIMAL(9,8),
			DiscountB	DECIMAL(9,8),
			DiscountC	DECIMAL(9,8),
			DiscountD	DECIMAL(9,8))

		DECLARE @TableStackDiscountUpdate TABLE(
			AgentId		INT,			
			SportType	SMALLINT,
			BetType		SMALLINT,
			DiscountA	DECIMAL(9,8))		
	
		-- For read xml
		DECLARE @DocHandler int

		EXEC sp_xml_preparedocument @DocHandler OUTPUT, @Discount

		INSERT INTO @TableDiscount (
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

		IF EXISTS (
			SELECT TOP(1) *
			FROM 
				AgentDiscount3rd AS ad WITH (NOLOCK)
			INNER JOIN @TableDiscount AS dt
				ON ad.SportType = dt.SportType
				AND ad.BetType = dt.BetType
			WHERE ad.AgentId = @AgentId
			AND (ad.DiscountA <> dt.DiscountA)
		)
			BEGIN		
				
				DECLARE @sportType INT

				-- Check validate	range		
				SELECT @sportType = SportType 
				FROM @TableDiscount
				WHERE (DiscountA NOT BETWEEN 0 AND 0.0025)		-- Group A					

				IF @sportType IS NOT NULL 
					BEGIN
						SELECT @ErrCode = 1

						----Message for each sport type	WITH CASE @sportType
						SELECT @ErrMsg	= 'Invalid commission rate.' + ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'						

						RETURN			
					END

				-- Check validate min bet must be equal to or greater than parent
				SELECT @sportType = ad.SportType
				FROM 
					AgentDiscount3rd AS ad
					INNER JOIN @TableDiscount AS dt 
					ON 	ad.SportType	= dt.SportType 
						AND ad.BetType	= dt.BetType	
				WHERE
					ad.AgentId = @parentAgentId
					AND (dt.DiscountA > ad.DiscountA)

				IF @sportType IS NOT NULL 
					BEGIN
						SELECT @ErrCode = 1

						----Message for each sport type	WITH CASE @sportType
						SELECT @ErrMsg	= 'Min bet must be equal to or greater than Paret Agent discount.' + ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'						

						RETURN	
					END

			   -- write log before update
				
				SET @xml = (
						SELECT  
							ad.SportType		AS '@s'
							,ad.BetType			AS '@b'
							,ad.DiscountA		AS '@ga'
							,ad.DiscountB		AS '@gb'
							,ad.DiscountC		AS '@gc'
							,ad.DiscountD		AS '@gd'
						FROM AgentDiscount3rd AS ad WITH (NOLOCK)
							INNER JOIN @TableDiscount AS td
								ON ad.SportType		= td.SportType
								AND ad.BetType		= td.BetType
						WHERE ad.AgentId			= @AgentId				
						FOR XML PATH('z')
				)

				SET @LogOldData = REPLACE(CONVERT(varchar(max), @xml), '" />', '"/"')

				-- end write log

				---- Update for current agent, and for all line
				UPDATE 
					ad WITH (ROWLOCK, UPDLOCK)
				SET 
					ad.DiscountA	= dt.DiscountA					
				FROM 
					AgentDiscount3rd AS ad
					INNER JOIN @TableDiscount AS dt 
						ON ad.SportType = dt.SportType 
						AND ad.BetType	= dt.BetType
				WHERE AgentId = @AgentId    

				INSERT INTO @TableAgent(AgentId)
				VALUES(@AgentId)

				-- Get discount up line
				INSERT INTO @TableStackDiscountUpdate(
					AgentId,					
					SportType,
					BetType,
					DiscountA)
				SELECT 
					ad.AgentId,					
					ad.SportType,
					ad.BetType,
					ad.DiscountA
				FROM 
					AgentDiscount3rd AS ad WITH (NOLOCK)
					INNER JOIN AgentInfo AS ai WITH (NOLOCK)
						ON ai.AgentId = ad.AgentId
					INNER JOIN @TableDiscount AS td
						ON ad.SportType = td.SportType
						AND ad.BetType	= td.BetType					
				WHERE 
					ai.ParentId = @AgentId
					AND (ad.DiscountA > td.DiscountA)				
				
				-- Update for upline						
				DECLARE @TempTableAgent TABLE (AgentId INT)

				WHILE EXISTS (
					SELECT TOP(1) * FROM @TableStackDiscountUpdate	
				)
					BEGIN

						UPDATE 
							ad WITH (ROWLOCK, UPDLOCK)
						SET 
							ad.DiscountA	= pad.DiscountA
						FROM AgentDiscount3rd AS ad
							INNER JOIN @TableStackDiscountUpdate AS tad
								ON ad.AgentId		= tad.AgentId
								AND ad.SportType	= tad.SportType
								AND ad.BetType		= tad.BetType
							INNER JOIN AgentInfo AS ai WITH (NOLOCK)
								ON tad.AgentId		= ai.AgentId
							INNER JOIN AgentDiscount3rd AS pad WITH (NOLOCK)
								ON ai.ParentId		= pad.AgentId
								AND ad.SportType	= pad.SportType
								AND ad.BetType		= pad.BetType								
					
						INSERT INTO @TableAgent(AgentId)
						SELECT AgentId FROM @TableStackDiscountUpdate

						DELETE @TempTableAgent
						INSERT INTO @TempTableAgent(AgentId)
						SELECT AgentId FROM @TableStackDiscountUpdate

						DELETE @TableStackDiscountUpdate

						INSERT INTO @TableStackDiscountUpdate(
							AgentId,					
							SportType,
							BetType,
							DiscountA)
						SELECT 
							ad.AgentId,					
							ad.SportType,
							ad.BetType,
							ad.DiscountA
						FROM 
							AgentDiscount3rd AS ad WITH (NOLOCK)
							INNER JOIN AgentInfo AS ai WITH (NOLOCK)
								ON ad.AgentId = ai.AgentId
							INNER JOIN @TableDiscount AS td
								ON ad.SportType = td.SportType
								AND ad.BetType	= td.BetType					
							INNER JOIN AgentDiscount3rd AS pad WITH (NOLOCK)
								ON ai.ParentId = pad.AgentId
								AND ad.SportType = pad.SportType
								AND ad.BetType = pad.BetType
						WHERE	ai.ParentId IN (SELECT t.AgentId FROM @TempTableAgent AS t)
								AND (pad.DiscountA < ad.DiscountA)							
					END	

				IF EXISTS (
					SELECT TOP(1) * FROM @TableAgent
				)
					BEGIN
						UPDATE 
							cd WITH (ROWLOCK, UPDLOCK)
						SET
							cd.Discount = ad.DiscountA
						FROM 
							CustDiscount3rd AS cd
							INNER JOIN @TableDiscount AS td
								ON cd.SportType = td.SportType
								AND cd.BetType = td.BetType
							INNER JOIN CustInfo AS ci WITH (NOLOCK)
								ON cd.CustId = ci.CustId
							INNER JOIN AgentDiscount3rd AS ad WITH (NOLOCK)
								ON ci.AgentId = ad.AgentId
								AND ad.SportType = cd.SportType
								AND ad.BetType = cd.BetType
						WHERE ad.AgentId IN (
											SELECT AgentId FROM @TableAgent)							
						
					END

				-- write log before update
				
				SET @xml = (
						SELECT  
							ad.SportType		AS '@s'
							,ad.BetType			AS '@b'
							,ad.DiscountA		AS '@ga'
							,ad.DiscountB		AS '@gb'
							,ad.DiscountC		AS '@gc'
							,ad.DiscountD		AS '@gd'
						FROM @TableDiscount AS ad						
						FOR XML PATH('z')
				)

				SET @LogData = REPLACE(CONVERT(varchar(max), @xml), '" />', '"/"')

				-- end write log
			END		 
	END	
		  	
END
