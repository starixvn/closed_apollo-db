USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_UpdateDiscount]    Script Date: 4/17/2013 2:52:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
DECLARE	@return_value int,
		@ErrCode int,
		@ErrMsg nvarchar(1000)

EXEC	@return_value = [dbo].[Acc_Agent_UpdateDiscount]
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

ALTER PROCEDURE [dbo].[Age_Agent_UpdateDiscount]
	@ActorAgentId	INT				= NULL,
	@AgentId		INT,
	@Discount		VARCHAR(MAX)	= '',	
	@Language		VARCHAR(2)		= 'E',
	@LogDate		DATETIME		= NULL,
	@ErrCode		INT				= 0		OUTPUT,
	@ErrMsg			NVARCHAR(1000)	= ''	OUTPUT 		
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Update agent discount
 * DB			: APL.CustDB
 * Revisions	:
 *	• 20132702@Edward	: Implement
 * Parameters:
 *	• @Discount : 		
		<ROOT>
			<Discount SportType="4" BetType="4" DiscountA="1" DiscountB="1" DiscountC="1" DiscountD="1"></Discount>
		</ROOT>		
 *	• @Discount3rd : 		
			<ROOT>
				<Discount SportType="4" BetType="4" DiscountA="1" DiscountB="1" DiscountC="1" DiscountD="1"></Discount>
			</ROOT>		
 *  
 */

BEGIN
	
	SET NOCOUNT ON
	
	-- Check update permission
	DECLARE @hasPermission BIT
	EXEC dbo.Age_Agent_CheckUpdatePermission @ActorAgentId, @AgentId, 1, @hasPermission OUTPUT 
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
		DECLARE @agentHId			HIERARCHYID
				,@parentAgentId		INT
				,@SUPERLEVEL		INT

		SET @SUPERLEVEL = 0

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
			DiscountA	DECIMAL(9,8),
			DiscountB	DECIMAL(9,8),
			DiscountC	DECIMAL(9,8),
			DiscountD	DECIMAL(9,8))		
	
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
				AgentDiscount AS ad WITH (NOLOCK)
			INNER JOIN @TableDiscount AS dt
				ON ad.SportType = dt.SportType
				AND ad.BetType = dt.BetType
			WHERE ad.AgentId = @AgentId
			AND (
				ad.DiscountA	<> dt.DiscountA
				OR ad.DiscountB <> dt.DiscountB
				OR ad.DiscountC <> dt.DiscountC
				OR ad.DiscountD <> dt.DiscountD
			)
		)
			BEGIN		
						   
				DECLARE @sportType INT

				-- Check validate	range		
				SELECT @sportType = SportType 
				FROM @TableDiscount
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
						SELECT @ErrMsg	= 'Invalid commission rate.' + ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'

						RETURN			
					END

				-- Check validate min bet must be equal to or greater than parent
				SELECT @sportType = ad.SportType
				FROM 
					AgentDiscount AS ad	WITH (NOLOCK)
					INNER JOIN @TableDiscount AS dt 
						ON ad.SportType	= dt.SportType 
						AND ad.BetType	= dt.BetType
					INNER JOIN AgentInfo AS ai WITH (NOLOCK)						
						ON ad.AgentId	= ai.AgentId
				WHERE
					ad.AgentId = @parentAgentId
					AND ai.AgentLevel	<> @SUPERLEVEL
					AND (dt.DiscountA > ad.DiscountA
						OR dt.DiscountB > ad.DiscountB
						OR dt.DiscountC > ad.DiscountC
						OR dt.DiscountD > ad.DiscountD)

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
						FROM AgentDiscount AS ad WITH (NOLOCK)
							INNER JOIN @TableDiscount AS td
								ON ad.SportType		= td.SportType
								AND ad.BetType		= td.BetType
						WHERE ad.AgentId			= @AgentId				
						FOR XML PATH('z'),ROOT('r')
				)

				SET @logSPDataOld = REPLACE(CONVERT(varchar(max), @xml), '" />', '"/"')

				-- end write log

				---- Update for current agent, and for all line
				UPDATE 
					ad WITH (ROWLOCK, UPDLOCK)
				SET 
					ad.DiscountA	= dt.DiscountA,
					ad.DiscountB	= dt.DiscountB,
					ad.DiscountC	= dt.DiscountC,
					ad.DiscountD	= dt.DiscountD
				FROM 
					AgentDiscount AS ad
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
					DiscountA,
					DiscountB,
					DiscountC,
					DiscountD)
				SELECT 
					ad.AgentId,					
					ad.SportType,
					ad.BetType,
					ad.DiscountA,
					ad.DiscountB,
					ad.DiscountC,
					ad.DiscountD
				FROM 
					AgentDiscount AS ad WITH (NOLOCK)
					INNER JOIN AgentInfo AS ai WITH (NOLOCK)
						ON ai.AgentId = ad.AgentId
					INNER JOIN @TableDiscount AS td
						ON ad.SportType = td.SportType
						AND ad.BetType	= td.BetType					
				WHERE 
					ai.ParentId = @AgentId
					AND (ad.DiscountA > td.DiscountA
						OR ad.DiscountB > td.DiscountB
						OR ad.DiscountC > td.DiscountC
						OR ad.DiscountD > td.DiscountD)				
				
				-- Update for upline						
				DECLARE @TempTableAgent TABLE (AgentId INT)

				WHILE EXISTS (
					SELECT TOP(1) * FROM @TableStackDiscountUpdate	
				)
					BEGIN

						UPDATE  
							ad WITH (ROWLOCK, UPDLOCK)
						SET 
							ad.DiscountA	= pad.DiscountA,
							ad.DiscountB	= pad.DiscountB,
							ad.DiscountC	= pad.DiscountC,
							ad.DiscountD	= pad.DiscountD
						FROM AgentDiscount AS ad
							INNER JOIN @TableStackDiscountUpdate AS tad
								ON ad.AgentId		= tad.AgentId
								AND ad.SportType	= tad.SportType
								AND ad.BetType		= tad.BetType
							INNER JOIN AgentInfo AS ai WITH (NOLOCK)
								ON tad.AgentId		= ai.AgentId
							INNER JOIN AgentDiscount AS pad WITH (NOLOCK)
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
							DiscountA,
							DiscountB,
							DiscountC,
							DiscountD)
						SELECT 
							ad.AgentId,					
							ad.SportType,
							ad.BetType,
							ad.DiscountA,
							ad.DiscountB,
							ad.DiscountC,
							ad.DiscountD
						FROM 
							AgentDiscount AS ad WITH (NOLOCK)
							INNER JOIN AgentInfo AS ai WITH (NOLOCK)
								ON ad.AgentId		= ai.AgentId
							INNER JOIN @TableDiscount AS td
								ON ad.SportType		= td.SportType
								AND ad.BetType		= td.BetType					
							INNER JOIN AgentDiscount AS pad WITH (NOLOCK)
								ON ai.ParentId		= pad.AgentId
								AND ad.SportType	= pad.SportType
								AND ad.BetType		= pad.BetType
						WHERE	ai.ParentId IN (SELECT t.AgentId FROM @TempTableAgent AS t)
								AND (pad.DiscountA < ad.DiscountA
								OR pad.DiscountB < ad.DiscountB
								OR pad.DiscountC < ad.DiscountC
								OR pad.DiscountD < ad.DiscountD)	
													
					END	

				IF EXISTS (
					SELECT TOP(1) * FROM @TableAgent
				)
					BEGIN
						UPDATE 
							cd
						SET
							cd.Discount = CASE
												WHEN ad.SportType = 1 AND ad.BetType = 5 THEN ad.DiscountA		-- 1x2
												WHEN ad.SportType = 1 AND ad.BetType = 4 THEN ad.DiscountA		-- Others 
												ELSE
												CASE
													WHEN ci.UGroup = 'a' THEN ad.DiscountA
													WHEN ci.UGroup = 'b' THEN ad.DiscountB
													WHEN ci.UGroup = 'c' THEN ad.DiscountC
													WHEN ci.UGroup = 'd' THEN ad.DiscountD
												END
											END
						FROM 
							CustDiscount AS cd
							INNER JOIN @TableDiscount AS td
								ON cd.SportType = td.SportType
								AND cd.BetType = td.BetType
							INNER JOIN CustInfo AS ci WITH (NOLOCK)
								ON cd.CustId = ci.CustId
							INNER JOIN AgentDiscount AS ad WITH (NOLOCK)
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
						FOR XML PATH('z'),ROOT('r')
				)

				SET @logSPData = REPLACE(CONVERT(varchar(max), @xml), '" />', '"/"')

				-- end write log
			END	
				 
	END		

	SET @endRun		= GETDATE()  
	SET @duration	= DATEDIFF(millisecond, @startRun, @endRun) 

	IF @LogDate IS NULL
		SET @LogDate = GETDATE()
	
	EXEC LogDB.dbo.Age_LogRunSp_Insert
		@UserId			= @ActorAgentId,
		@SPName			= 'Age_Agent_UpdateDiscount',
		@LogDate		= @LogDate,
		@ObjectId		= @AgentId,
		@ObjectTypeId	= 1,			--Object type : Agent						
		@Duration		= @Duration,
		@Data			= @logSPData,
		@OldData		= @logSPDataOld
END
