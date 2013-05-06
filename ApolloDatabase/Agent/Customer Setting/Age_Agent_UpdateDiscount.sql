USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_UpdateDiscount]    Script Date: 5/6/2013 10:32:04 AM ******/
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
	@Language		VARCHAR(5)		= 'en-US',
	@ErrCode		INT				= 0		OUTPUT,
	@ErrMsg			NVARCHAR(1000)	= ''	OUTPUT 
AS

/**
 * Created by	: Kos
 * Date			: 20130227
 * Task			: Update agent discount
 * DB			: SVRCUST.CustDB
 * Revisions	:
 *	• 20132702@Edward	: Implement
 * Parameters:
 *	• @Discount :
		<ROOT>
			<Discount SportType="4" BetType="4" DiscountA="1" DiscountB="1" DiscountC="1" DiscountD="1"></Discount>
		</ROOT>
 */

BEGIN
	
	SET NOCOUNT ON
	
	-- Check update permission
	DECLARE @hasPermission BIT

	EXEC dbo.Age_Agent_CheckUpdatePermission @ActorAgentId, @AgentId, 1, @hasPermission OUTPUT

	IF @hasPermission = 0
		BEGIN
			SELECT 
				@ErrCode	= 1000,
				@ErrMsg		= 
					CASE @Language
						WHEN 'en-US' THEN 'You do not have permission to update setting'
						ELSE [dbo].f_Msg_GetContentById (1000, @Language)
					END

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
			DECLARE 
				@agentHId		HIERARCHYID,
				@parentAgentId	INT,
				@SUPERLEVEL		INT

			SET @SUPERLEVEL = 0

			-- Get agent hierarchy ID
			SELECT 
				@agentHId = AgentHId,
				@parentAgentId = ParentId
			FROM AgentInfo WITH (NOLOCK)
			WHERE AgentId = @AgentId

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
				SportType	SMALLINT,
				BetType		SMALLINT,
				DiscountA	DECIMAL(9,8),
				DiscountB	DECIMAL(9,8),
				DiscountC	DECIMAL(9,8),
				DiscountD	DECIMAL(9,8)
			) AS Data

			EXEC sp_xml_removedocument @DocHandler
			-- end read xml

			IF EXISTS ( SELECT 1
						FROM 
							AgentDiscount AS ad WITH (NOLOCK)
							INNER JOIN @TableDiscount AS dt
							ON ad.SportType = dt.SportType
							AND ad.BetType = dt.BetType
						WHERE 
							ad.AgentId = @AgentId
							AND (
								ad.DiscountA	<> dt.DiscountA
								OR ad.DiscountB <> dt.DiscountB
								OR ad.DiscountC <> dt.DiscountC
								OR ad.DiscountD <> dt.DiscountD
							) )
				BEGIN

					DECLARE
						@sportType	INT,
						@groupCode	INT

					-- Check validate range
					SELECT	
						@sportType = SportType ,
						@groupCode = 
						CASE
							WHEN DiscountA NOT BETWEEN 0 AND 0.0225 AND SportType = 1 AND BetType = 1 THEN 2001
							WHEN DiscountB NOT BETWEEN 0 AND 0.0125 AND SportType = 1 AND BetType = 1 THEN 2002
							WHEN DiscountC NOT BETWEEN 0 AND 0.0075 AND SportType = 1 AND BetType = 1 THEN 2003
							WHEN DiscountD NOT BETWEEN 0 AND 0 AND SportType = 1 AND BetType = 1 THEN 2004
							WHEN DiscountA NOT BETWEEN 0 AND 0 AND SportType = 1 AND BetType = 5 THEN 2005
							WHEN DiscountA NOT BETWEEN 0 AND 0 AND SportType = 1 AND BetType = 4 THEN 2006
						END
					FROM @TableDiscount
					WHERE 
						(DiscountA NOT BETWEEN 0 AND 0.0225 AND SportType = 1 AND BetType = 1)		-- Group A
						OR (DiscountB NOT BETWEEN 0 AND 0.0125 AND SportType = 1 AND BetType = 1)	-- Group B
						OR (DiscountC NOT BETWEEN 0 AND 0.0075 AND SportType = 1 AND BetType = 1)	-- Group C
						OR (DiscountD NOT BETWEEN 0 AND 0 AND SportType = 1 AND BetType = 1)		-- Group D
						OR (DiscountA NOT BETWEEN 0 AND 0 AND SportType = 1 AND BetType = 5)		-- 1x2
						OR (DiscountA NOT BETWEEN 0 AND 0 AND SportType = 1 AND BetType = 4)		-- Others

					IF @sportType IS NOT NULL 
						BEGIN
							SELECT 
								@ErrCode	= 2000,
								@ErrMsg		= 
									CASE @Language
										WHEN 'en-US' THEN 'Invalid commission rate'
										ELSE [dbo].f_Msg_GetContentById (2000, @Language)  
									END	+ '(' + [dbo].f_Msg_GetContentById (@groupCode, @Language) + ')'
							RETURN
						END
				
					-- End check validate range

					-- Check validate min bet must be equal to or greater than parent
					SELECT
						@sportType = ad.SportType,
						@groupCode = 
							CASE
								WHEN dt.DiscountA > ad.DiscountA AND ad.SportType = 1 AND ad.BetType = 1 THEN 2001
								WHEN dt.DiscountB > ad.DiscountB THEN 2002
								WHEN dt.DiscountC > ad.DiscountC THEN 2003
								WHEN dt.DiscountD > ad.DiscountD THEN 2004
								WHEN dt.DiscountA > ad.DiscountA AND ad.SportType = 1 AND ad.BetType = 5 THEN 2005
								WHEN dt.DiscountA > ad.DiscountA AND ad.SportType = 1 AND ad.BetType = 4 THEN 2006
							END
					FROM 
						AgentDiscount AS ad WITH (NOLOCK)
						INNER JOIN @TableDiscount AS dt 
							ON ad.SportType	= dt.SportType 
							AND ad.BetType	= dt.BetType
						INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON ad.AgentId	= ai.AgentId
					WHERE
						ad.AgentId = @parentAgentId
						AND ai.AgentLevel	<> @SUPERLEVEL
						AND (dt.DiscountA > ad.DiscountA
							OR dt.DiscountB > ad.DiscountB
							OR dt.DiscountC > ad.DiscountC
							OR dt.DiscountD > ad.DiscountD)

					IF @sportType IS NOT NULL 
						BEGIN
							SELECT 
								@ErrCode	= 2007,
								@ErrMsg		= 
									CASE @Language
										WHEN 'en-US' THEN 'Discount must be equal to or greater than Paret Agent discount'
										ELSE [dbo].f_Msg_GetContentById (2007, @Language)  
									END	+ '(' + [dbo].f_Msg_GetContentById (@groupCode, @Language) + ')'

							RETURN	
						END

					-- write log before update
				
					SET @xml = (
						SELECT  
							ad.SportType	AS '@s'
							,ad.BetType		AS '@b'
							,ad.DiscountA	AS '@ga'
							,ad.DiscountB	AS '@gb'
							,ad.DiscountC	AS '@gc'
							,ad.DiscountD	AS '@gd'
						FROM 
							AgentDiscount AS ad WITH (NOLOCK)
							INNER JOIN @TableDiscount AS td
								ON ad.SportType		= td.SportType
								AND ad.BetType		= td.BetType
						WHERE ad.AgentId = @AgentId
						FOR XML PATH('z'),ROOT('r')
					)

					SET @logSPDataOld = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

					-- end write log

					---- Update for current agent, and for all line
					UPDATE ad WITH (ROWLOCK, UPDLOCK)
					SET 
						ad.DiscountA = dt.DiscountA,
						ad.DiscountB = dt.DiscountB,
						ad.DiscountC = dt.DiscountC,
						ad.DiscountD = dt.DiscountD
					FROM 
						AgentDiscount AS ad
						INNER JOIN @TableDiscount AS dt 
							ON ad.SportType = dt.SportType 
							AND ad.BetType	= dt.BetType
					WHERE AgentId = @AgentId
				
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
						td.DiscountA,
						td.DiscountB,
						td.DiscountC,
						td.DiscountD
					FROM 
						AgentDiscount AS ad WITH (NOLOCK)
						INNER JOIN AgentInfo AS ai WITH (NOLOCK) ON ai.AgentId = ad.AgentId
						INNER JOIN @TableDiscount AS td
							ON ad.SportType = td.SportType
							AND ad.BetType	= td.BetType
					WHERE 
						ai.AgentHId.IsDescendantOf(@agentHId) = 1
						AND ai.AgentId <> @AgentId
						AND (ad.DiscountA > td.DiscountA
							OR ad.DiscountB > td.DiscountB
							OR ad.DiscountC > td.DiscountC
							OR ad.DiscountD > td.DiscountD)

					UPDATE ad WITH (ROWLOCK, UPDLOCK)
					SET ad.DiscountA = tad.DiscountA
					FROM AgentDiscount AS ad
						INNER JOIN @TableStackDiscountUpdate AS tad
							ON ad.AgentId		= tad.AgentId
							AND ad.SportType	= tad.SportType
							AND ad.BetType		= tad.BetType
					WHERE ad.DiscountA > tad.DiscountA

					UPDATE ad WITH (ROWLOCK, UPDLOCK)
					SET ad.DiscountB	= tad.DiscountB
					FROM 
						AgentDiscount AS ad
						INNER JOIN @TableStackDiscountUpdate AS tad
							ON ad.AgentId		= tad.AgentId
							AND ad.SportType	= tad.SportType
							AND ad.BetType		= tad.BetType
					
					UPDATE ad WITH (ROWLOCK, UPDLOCK)
					SET ad.DiscountC	= tad.DiscountC
					FROM 
						AgentDiscount AS ad
						INNER JOIN @TableStackDiscountUpdate AS tad
							ON ad.AgentId		= tad.AgentId
							AND ad.SportType	= tad.SportType
							AND ad.BetType		= tad.BetType
					
					UPDATE ad WITH (ROWLOCK, UPDLOCK)
					SET ad.DiscountD = tad.DiscountD
					FROM 
						AgentDiscount AS ad
						INNER JOIN @TableStackDiscountUpdate AS tad
							ON ad.AgentId		= tad.AgentId
							AND ad.SportType	= tad.SportType
							AND ad.BetType		= tad.BetType

					IF EXISTS (
						SELECT TOP(1) * FROM @TableStackDiscountUpdate
					)
						BEGIN
							UPDATE cd
							SET cd.Discount =	CASE
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
								INNER JOIN CustInfo AS ci WITH (NOLOCK) ON cd.CustId = ci.CustId
								INNER JOIN AgentDiscount AS ad WITH (NOLOCK)
									ON ci.AgentId = ad.AgentId
									AND ad.SportType = cd.SportType
									AND ad.BetType = cd.BetType
							WHERE ad.AgentId IN ( SELECT DISTINCT AgentId FROM @TableStackDiscountUpdate )
						
						END

					-- write log before update
				
					SET @xml = (
						SELECT  
							ad.SportType	AS '@s'
							,ad.BetType		AS '@b'
							,ad.DiscountA	AS '@ga'
							,ad.DiscountB	AS '@gb'
							,ad.DiscountC	AS '@gc'
							,ad.DiscountD	AS '@gd'
						FROM @TableDiscount AS ad
						FOR XML PATH('z'),ROOT('r')
					)

					SET @logSPData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

					-- end write log
				END

		END

	SET @endRun		= GETDATE()  
	SET @duration	= DATEDIFF(MILLISECOND, @startRun, @endRun) 
		
	IF @@Error = 0
		BEGIN TRY
			EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpAgent
			@UserId		= @ActorAgentId,
			@SPName		= 'Age_Agent_UpdateDiscount',
			@LogDate	= @startRun,
			@AgentId	= @AgentId,
			@Duration	= @Duration,
			@Data		= @logSPData,
			@OldData	= @logSPDataOld
		END	TRY
		BEGIN CATCH
			EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpAgent
			@UserId		= @ActorAgentId,
			@SPName		= 'Age_Agent_UpdateDiscount',
			@LogDate	= @startRun,
			@AgentId	= @AgentId,
			@Duration	= @Duration,
			@Data		= @logSPData,
			@OldData	= @logSPDataOld
		END CATCH 
END
