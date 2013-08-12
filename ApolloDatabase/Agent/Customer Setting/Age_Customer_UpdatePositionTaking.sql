USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_UpdatePositionTaking]    Script Date: 8/7/2013 4:01:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
DECLARE	@return_value int,
		@ErrCode int,
		@ErrMsg nvarchar(1000)

EXEC	@return_value = [dbo].[Age_Customer_UpdatePositionTaking]
		@ActorAgentId = 206,
		@AgentId = 226,
		@CustId = 128465,
		@PositionTaking = N'<ROOT><PositionTaking SportType="1" BetType="1" IsLive="0" PT="5000" ></PositionTaking></ROOT>',		
		@Language = NULL,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT

SELECT	@ErrCode as N'@ErrCode',
		@ErrMsg as N'@ErrMsg'

SELECT	'Return Value' = @return_value

GO

*/

ALTER PROCEDURE [dbo].[Age_Customer_UpdatePositionTaking]
	@ActorAgentId		INT				= NULL,
	@AdminId			INT				= NULL,
	@AgentId			INT,
	@CustId				INT,
	@PositionTaking		VARCHAR(MAX)	= '',
	@Language			VARCHAR(5)		= 'en-US',
	@ErrCode			INT				= 0			OUTPUT,
	@ErrMsg				NVARCHAR(1000)	= ''		OUTPUT
AS

/**
 * Created by	: Edward
 * Date			: 20130412
 * Task			: Update customer position taking
 * DB			: SVRCUST.CustDB
 * Revisions	:
 *	• 20131707@Edward	: Add parameter @AdminId for write log
 * Parameters:
 * • @AgentID			: Parent agent ID
 * • @PositionTaking	: 
 *		<ROOT>
 *			<PositionTaking SportType="4" BetType="4" IsLive="1" PT="10" ></PositionTaking>
 *		</ROOT>
 *	•
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

	IF @PositionTaking <> ''
		BEGIN
			-- For write log
			DECLARE 
				@startRun		DATETIME,
				@endRun			DATETIME,
				@duration		INT,
				@logSPData		NVARCHAR(MAX),
				@logSPDataOld	NVARCHAR(MAX),
				@xml			XML

			SET @startRun = GETDATE()

			DECLARE @TablePositionTaking TABLE (
				SportType	SMALLINT,
				BetType		SMALLINT,
				IsLive		BIT,
				PT			SMALLINT)
			
			DECLARE @TableStackPositionTaking TABLE (
				AgentId		INT,
				AgentLevel	SMALLINT,
				SportType	SMALLINT,
				BetType		SMALLINT,
				IsLive		BIT,
				PT			SMALLINT,
				MinPT		SMALLINT,
				SumDownPT	SMALLINT)

			DECLARE @TableUpdatePositionTaking TABLE (
				AgentId		INT,
				SportType	SMALLINT,
				BetType		SMALLINT,
				IsLive		BIT,
				PT			SMALLINT,
				Preset		SMALLINT,
				Result		SMALLINT,
				IsDeleted	BIT)
						
			DECLARE @TableTempPositionTaking TABLE (
				AgentId		INT,
				AgentLevel	SMALLINT,
				SportType	SMALLINT,
				BetType		SMALLINT,
				IsLive		BIT,
				PT			SMALLINT,
				Preset		SMALLINT)

			DECLARE @UplineAgentInfo TABLE (
				AgentId		INT,
				AgentLevel	SMALLINT,
				ParentId	INT)

			DECLARE @DownlineAgentInfo TABLE (
				AgentId		INT,
				AgentLevel	SMALLINT,
				ParentId	INT)

			-- For read xml
			DECLARE @DocHandler INT

			EXEC sp_xml_preparedocument @DocHandler OUTPUT, @PositionTaking

			INSERT INTO @TablePositionTaking (
				SportType,
				BetType,
				IsLive,
				PT)
			SELECT
				Data.SportType,
				Data.BetType,
				Data.IsLive,
				Data.PT
			FROM OPENXML (@DocHandler, '/ROOT/PositionTaking', 1) 
			WITH (
				SportType	SMALLINT,
				BetType		SMALLINT,
				IsLive		BIT,
				PT			SMALLINT
			) AS Data

			EXEC sp_xml_removedocument @DocHandler
			-- end read xml

			-- Validate data

			DELETE tpt
			FROM 
				@TablePositionTaking AS tpt
				INNER JOIN dbo.CustPositionTaking AS cpt WITH (NOLOCK)
				ON 	cpt.SportType	= tpt.SportType
					AND cpt.BetType	= tpt.BetType
					AND cpt.IsLive	= tpt.IsLive
			WHERE 
				cpt.PositionTaking	= tpt.PT
				AND cpt.CustId		= @CustId
				AND cpt.AgentId		= @AgentId

			IF EXISTS (	SELECT 1 FROM @TablePositionTaking )
				BEGIN
					-- write log before update
					SET @xml = (
						SELECT  
							cpt.SportType		AS '@s'
							,cpt.BetType		AS '@b'
							,cpt.IsLive			AS '@i'
							,cpt.PositionTaking	AS '@p'
						FROM 
							dbo.CustPositionTaking AS cpt WITH (NOLOCK)
							--INNER JOIN @TablePositionTaking AS tpt
							--	ON cpt.SportType	= tpt.SportType
							--	AND cpt.BetType		= tpt.BetType
							--	AND cpt.IsLive		= tpt.IsLive
						WHERE 
							cpt.AgentId	= @AgentId
							AND cpt.CustId	= @CustId
						ORDER BY
							cpt.SportType
							--,cpt.BetType
							,cpt.IsLive
						FOR XML PATH('z'), ROOT('r')
					)

					SET @logSPDataOld = REPLACE(CONVERT(NVARCHAR(MAX), @xml), '" />', '"/"')

					-- end write log

					---- Declare agentId
					DECLARE 
						@agentLevel		SMALLINT,
						@agentHId		HIERARCHYID,
						@sportType		INT,
						@betType		INT,
						@isLive			BIT,
						@childAgentId	INT
					---- End declare

					SELECT 
						@agentLevel = AgentLevel,
						@agentHId = AgentHId
					FROM dbo.AgentInfo WITH (NOLOCK)
					WHERE AgentId = @AgentId

					INSERT INTO @UplineAgentInfo (
						AgentId,
						AgentLevel,
						ParentId)
					SELECT	
						AgentId,
						AgentLevel,
						ParentId
					FROM dbo.AgentInfo WITH (NOLOCK)
					WHERE
						@agentHId.IsDescendantOf(AgentHId) = 1
						AND AgentId <> @AgentId
						AND AgentId IN (	SELECT DISTINCT AgentId
											FROM dbo.CustPositionTaking WITH (NOLOCK)
											WHERE CustId = @CustId )

					INSERT INTO @DownlineAgentInfo (
						AgentId,
						AgentLevel,
						ParentId)
					SELECT	
						AgentId,
						AgentLevel,
						ParentId
					FROM dbo.AgentInfo WITH (NOLOCK)
					WHERE
						AgentHId.IsDescendantOf(@agentHId) = 1
						AND AgentId <> @AgentId
						AND AgentId IN (	SELECT DISTINCT AgentId
											FROM dbo.CustPositionTaking WITH (NOLOCK)
											WHERE CustId = @CustId )
					---- End set value

					-- Check for direct member or indirect member
					IF EXISTS (	SELECT 1 FROM dbo.CustInfo WITH (NOLOCK) WHERE CustId = @CustId AND AgentId = @AgentId )		-- direct member
						BEGIN
							SELECT TOP(1) 
								@sportType	= apt.SportType 
								,@betType	= apt.BetType
								,@isLive	= apt.IsLive
							FROM 
								dbo.AgentPositionTaking AS apt WITH (NOLOCK)
								INNER JOIN @TablePositionTaking AS ptt
								ON apt.SportType	= ptt.SportType
									AND apt.BetType	= ptt.BetType
									AND apt.IsLive	= ptt.IsLive
							WHERE 
								apt.AgentId = @AgentId
								AND ptt.PT NOT BETWEEN apt.MinGivenPositionTaking AND apt.MaxGivenPositionTaking
								
							IF @sportType IS NOT NULL
								BEGIN
									SELECT 
										@ErrCode	= 4000,
										@ErrMsg		= 
											CASE @Language
												WHEN 'en-US' THEN 'Invalid % range' 
												ELSE [dbo].f_Msg_GetContentById (4000, @Language)
											END + ' (' 
												+ CASE WHEN @sportType = 99 AND @betType = 9
														THEN [dbo].f_Msg_GetContentById (4009, @Language)
														ELSE dbo.f_Sport_GetNameByType(@sportType, @Language) 
													END
												+ CASE WHEN @isLive = 1 THEN + ' ' + [dbo].f_Msg_GetContentById (4008, @Language) 
														ELSE '' 
													END
												+ ' - ' + dbo.f_Bet_GetNameByType(@betType, @Language) 
												+')'
									RETURN
								END
						END
					ELSE	-- indirect member
						BEGIN
							
							SELECT DISTINCT @childAgentId = AgentId
							FROM @DownlineAgentInfo
							WHERE ParentId = @AgentId
							
							SELECT TOP(1) 
								@sportType	= ptt.SportType
								,@betType	= ptt.BetType
								,@isLive	= ptt.IsLive
							FROM 
								@TablePositionTaking AS ptt
								INNER JOIN (
									SELECT 
										downCust.SportType
										,downCust.BetType
										,downCust.IsLive
										,apt.MinGivenPositionTaking - downCust.SumOfDownlinePT AS MinOfPositionTaking
										,CASE 
											WHEN capt.MaxUpperPositionTaking > apt.MinGivenPositionTaking - downCust.SumOfDownlinePT
												THEN capt.MaxUpperPositionTaking
											ELSE apt.MinGivenPositionTaking - downCust.SumOfDownlinePT
										END AS MaxOfPositionTaking
									FROM 
										dbo.AgentPositionTaking AS apt WITH (NOLOCK)
										INNER JOIN dbo.AgentPositionTaking AS capt WITH (NOLOCK)
											ON 	apt.SportType	= capt.SportType
												AND apt.BetType = capt.BetType
												AND apt.IsLive	= capt.IsLive
										INNER JOIN (
											SELECT 
												SportType,
												BetType,
												IsLive,
												SUM(PositionTaking) AS SumOfDownlinePT
											FROM dbo.CustPositionTaking WITH (NOLOCK)
											WHERE 
												CustId = @custId
												AND AgentId IN ( SELECT AgentId FROM @DownlineAgentInfo )
											GROUP BY  
												SportType,
												BetType,
												IsLive
										) AS downCust 
											ON 	apt.SportType	= downCust.SportType
												AND apt.BetType	= downCust.BetType
												AND apt.IsLive	= downCust.IsLive
									WHERE 
										apt.AgentId = @AgentId
										AND capt.AgentId = @childAgentId
								) AS temp
									ON 	ptt.SportType = temp.SportType
										AND ptt.BetType = temp.BetType
										AND ptt.IsLive = temp.IsLive
							WHERE ptt.PT NOT BETWEEN temp.MinOfPositionTaking AND temp.MaxOfPositionTaking

							IF @sportType IS NOT NULL
								BEGIN
									SELECT 
										@ErrCode	= 4000,
										@ErrMsg		= 
											CASE @Language
												WHEN 'en-US' THEN 'Invalid % range' 
												ELSE [dbo].f_Msg_GetContentById (4000, @Language)
											END + ' (' 
												+ CASE WHEN @sportType = 99 AND @betType = 9
														THEN [dbo].f_Msg_GetContentById (4009, @Language)
														ELSE dbo.f_Sport_GetNameByType(@sportType, @Language) 
													END
												+ CASE WHEN @isLive = 1 THEN + ' ' + [dbo].f_Msg_GetContentById (4008, @Language) 
														ELSE '' 
													END
												+ ' - ' + dbo.f_Bet_GetNameByType(@betType, @Language) 
												+')'

									RETURN
								END
						END	
					-- End check for direct member or indirect member
					
					-- If New Position Taking greater than Current Position Taking
					IF EXISTS (	SELECT 1
								FROM 
									dbo.CustPositionTaking AS cpt WITH (NOLOCK)
									INNER JOIN @TablePositionTaking AS tpt
									ON 
										cpt.SportType	= tpt.SportType
										AND cpt.BetType	= tpt.BetType
										AND cpt.IsLive	= tpt.IsLive
								WHERE 
									tpt.PT > cpt.PositionTaking
									AND cpt.CustId	= @CustId
									AND cpt.AgentId = @AgentId )
						BEGIN

							-- Get all Pre(k+1) < Mem(k)
							DELETE @TableTempPositionTaking

							INSERT INTO @TableTempPositionTaking (
								AgentId
								,AgentLevel
								,SportType
								,BetType
								,IsLive
								,PT
								,Preset)
							SELECT	
								cpt.AgentId
								,uai.AgentLevel
								,cpt.SportType
								,cpt.BetType
								,cpt.IsLive	
								,cpt.PositionTaking
								,apt.MaxUpperPositionTaking
							FROM 
								dbo.CustPositionTaking AS cpt WITH (NOLOCK)	
								INNER JOIN @UplineAgentInfo AS uai ON cpt.AgentId = uai.AgentId
								INNER JOIN @TablePositionTaking AS tpt 
									ON cpt.SportType	= tpt.SportType
									AND cpt.BetType		= tpt.BetType
									AND cpt.IsLive		= tpt.IsLive
								INNER JOIN dbo.AgentPositionTaking AS apt WITH (NOLOCK)
									ON cpt.SportType	= apt.SportType
									AND cpt.BetType		= apt.BetType
									AND cpt.IsLive		= apt.IsLive
								INNER JOIN dbo.AgentInfo AS ai WITH (NOLOCK)
									ON ai.AgentId		= apt.AgentId
									AND ai.ParentId		= cpt.AgentId
									AND ai.AgentId IN (	SELECT DISTINCT AgentId 
														FROM dbo.CustPositionTaking WITH (NOLOCK)
														WHERE CustId = @CustId) 		 	
							WHERE 
								cpt.CustId = @CustId
								AND apt.MaxUpperPositionTaking < cpt.PositionTaking

							DELETE @TableUpdatePositionTaking

							INSERT INTO @TableUpdatePositionTaking (
								AgentId
								,SportType
								,BetType
								,IsLive
								,PT
								,Preset
								,IsDeleted)
							SELECT DISTINCT
								ttpt.AgentId
								,ttpt.SportType
								,ttpt.BetType
								,ttpt.IsLive
								,ISNULL(ttpt.PT, 0)
								,ISNULL(ttpt.Preset, 0)
								,0
							FROM 
								@TableTempPositionTaking AS ttpt
								INNER JOIN (
									SELECT 
										MAX(AgentLevel) AS AgentLevel,
										SportType,
										BetType,
										IsLive
									FROM @TableTempPositionTaking 
									GROUP BY 
										SportType,
										BetType,
										IsLive
								) AS temp
									ON ttpt.SportType		= temp.SportType
										AND ttpt.BetType	= temp.BetType
										AND ttpt.IsLive		= temp.IsLive
										AND ttpt.AgentLevel	= temp.AgentLevel

							UPDATE tupt 
							SET tupt.Result = tpt.PT - cpt.PositionTaking
							FROM 
								@TableUpdatePositionTaking AS tupt
								INNER JOIN @TablePositionTaking AS tpt
									ON tupt.SportType	= tpt.SportType
									AND tupt.BetType	= tpt.BetType
									AND tupt.IsLive		= tpt.IsLive
								INNER JOIN dbo.CustPositionTaking AS cpt WITH (NOLOCK)
									ON tupt.SportType	= cpt.SportType
									AND tupt.BetType	= cpt.BetType
									AND tupt.IsLive		= cpt.IsLive
							WHERE 
								tpt.PT > cpt.PositionTaking
								AND cpt.CustId	= @CustId
								AND cpt.AgentId	= @AgentId
							
							WHILE EXISTS (	SELECT 1 FROM @TableUpdatePositionTaking WHERE Result > 0 )
								BEGIN
									
									UPDATE cpt
									SET cpt.PositionTaking =	
										CASE 
											WHEN tupt.Preset > tupt.PT - tupt.Result THEN tupt.Preset
											ELSE tupt.PT - tupt.Result
										END
									FROM 
										dbo.CustPositionTaking AS cpt WITH (ROWLOCK, UPDLOCK)
										INNER JOIN @TableUpdatePositionTaking AS tupt
											ON cpt.SportType	= tupt.SportType
											AND cpt.BetType		= tupt.BetType
											AND cpt.IsLive		= tupt.IsLive
											AND cpt.AgentId		= tupt.AgentId
									WHERE cpt.CustId = @CustId
									
									UPDATE tupt
									SET 
										tupt.Result	= tupt.Result - (tupt.PT - cpt.PositionTaking),
										tupt.IsDeleted = 1
									FROM 
										@TableUpdatePositionTaking AS tupt
										INNER JOIN dbo.CustPositionTaking AS cpt WITH (NOLOCK)
											ON tupt.SportType	= cpt.SportType
											AND tupt.BetType	= cpt.BetType
											AND tupt.IsLive		= cpt.IsLive
											AND tupt.AgentId	= cpt.AgentId
									WHERE cpt.CustId = @CustId

									IF EXISTS (	SELECT 1 FROM @TableUpdatePositionTaking WHERE Result > 0 )
										BEGIN
											DELETE @TableTempPositionTaking

											INSERT INTO @TableTempPositionTaking(
												AgentId
												,AgentLevel
												,SportType
												,BetType
												,IsLive
												,PT
												,Preset)
											SELECT
												cpt.AgentId
												,uai.AgentLevel
												,cpt.SportType
												,cpt.BetType
												,cpt.IsLive	
												,cpt.PositionTaking
												,apt.MaxUpperPositionTaking
											FROM 
												dbo.CustPositionTaking AS cpt WITH (NOLOCK)	
												INNER JOIN @UplineAgentInfo AS uai ON cpt.AgentId = uai.AgentId
												INNER JOIN @TablePositionTaking AS tpt 
													ON cpt.SportType	= tpt.SportType
													AND cpt.BetType		= tpt.BetType
													AND cpt.IsLive		= tpt.IsLive
												INNER JOIN dbo.AgentPositionTaking AS apt WITH (NOLOCK)
													ON cpt.SportType	= apt.SportType
													AND cpt.BetType		= apt.BetType
													AND cpt.IsLive		= apt.IsLive
												INNER JOIN dbo.AgentInfo AS ai WITH (NOLOCK)
													ON ai.AgentId		= apt.AgentId
													AND ai.ParentId		= cpt.AgentId
													AND ai.AgentId IN (SELECT DISTINCT AgentId FROM dbo.CustPositionTaking WHERE CustId = @CustId)
											WHERE 
												cpt.CustId = @CustId
												AND apt.MaxUpperPositionTaking < cpt.PositionTaking

											INSERT INTO @TableUpdatePositionTaking (
												AgentId
												,SportType
												,BetType
												,IsLive
												,PT
												,Preset
												,IsDeleted)
											SELECT DISTINCT
												ttpt.AgentId
												,ttpt.SportType
												,ttpt.BetType
												,ttpt.IsLive
												,ISNULL(ttpt.PT, 0)
												,ISNULL(ttpt.Preset, 0)
												,0
											FROM 
												@TableTempPositionTaking AS ttpt
												INNER JOIN (
													SELECT 
														MAX(AgentLevel) AS AgentLevel,
														SportType,
														BetType,
														IsLive
													FROM @TableTempPositionTaking 
													GROUP BY 
														SportType,
														BetType,
														IsLive
												) AS temp
													ON ttpt.SportType	= temp.SportType
													AND ttpt.BetType	= temp.BetType
													AND ttpt.IsLive		= temp.IsLive
													AND ttpt.AgentLevel	= temp.AgentLevel

											UPDATE tupt
											SET tupt.Result	= dtupt.Result
											FROM 
												@TableUpdatePositionTaking AS tupt
												INNER JOIN @TableUpdatePositionTaking AS dtupt
													ON tupt.SportType	= dtupt.SportType
													AND tupt.BetType	= dtupt.BetType
													AND tupt.IsLive		= dtupt.IsLive
											WHERE 
												dtupt.IsDeleted	= 1
												AND tupt.IsDeleted	= 0

											DELETE @TableUpdatePositionTaking WHERE IsDeleted = 1
										END
									ELSE
										BEGIN
											DELETE @TableUpdatePositionTaking
										END
								END

							-- Update Position Taking
							UPDATE cpt
							SET	cpt.PositionTaking = tpt.PT
							FROM 
								dbo.CustPositionTaking AS cpt WITH (ROWLOCK,UPDLOCK)
								INNER JOIN @TablePositionTaking	AS tpt
									ON tpt.SportType	= cpt.SportType
									AND tpt.BetType		= cpt.BetType
									AND tpt.IsLive		= cpt.IsLive
							WHERE 
								cpt.CustId = @CustId
								AND cpt.AgentId	= @AgentId
								AND tpt.PT > cpt.PositionTaking
							-- End update Position Taking

						END
					-- End if New Position Taking greater than Current Position Taking

					-- If New Position Taking less than Current Position Taking
					IF EXISTS (	SELECT 1
								FROM 
									dbo.CustPositionTaking AS cpt WITH (NOLOCK)
									INNER JOIN @TablePositionTaking AS tpt
									ON 
										cpt.SportType	= tpt.SportType
										AND cpt.BetType	= tpt.BetType
										AND cpt.IsLive	= tpt.IsLive
								WHERE 
									tpt.PT < cpt.PositionTaking
									AND cpt.CustId	= @CustId
									AND cpt.AgentId = @AgentId )
						BEGIN

							-- Update Position Taking
							UPDATE cpt
							SET	cpt.PositionTaking = tpt.PT
							FROM 
								CustPositionTaking AS cpt WITH (ROWLOCK,UPDLOCK)
								INNER JOIN @TablePositionTaking	AS tpt
								ON tpt.SportType	= cpt.SportType
									AND tpt.BetType	= cpt.BetType
									AND tpt.IsLive	= cpt.IsLive
							WHERE 
								cpt.CustId	= @CustId
								AND cpt.AgentId	= @AgentId
								AND tpt.PT < cpt.PositionTaking

							-- End update Position Taking
							DECLARE @currentAgentId	INT

							SET @currentAgentId = @AgentId

							WHILE @currentAgentId IS NOT NULL
								BEGIN
									INSERT INTO @TableStackPositionTaking (
										AgentId
										,AgentLevel
										,SportType
										,BetType
										,IsLive
										,PT
										,MinPT)
									SELECT 
										apt.AgentId
										,uai.AgentLevel
										,apt.SportType
										,apt.BetType
										,apt.IsLive
										,cpt.PositionTaking
										,apt.MinGivenPositionTaking
									FROM 
										dbo.AgentPositionTaking AS apt WITH (NOLOCK)
										INNER JOIN @UplineAgentInfo AS uai ON apt.AgentId = uai.AgentId
										INNER JOIN dbo.CustPositionTaking AS cpt WITH (NOLOCK)
											ON apt.SportType	= cpt.SportType
											AND apt.BetType		= cpt.BetType
											AND apt.IsLive		= cpt.IsLive
											AND apt.AgentId		= cpt.AgentId
									WHERE 
										cpt.CustId = @CustId
										AND apt.MinGivenPositionTaking > 0

									WHILE EXISTS( SELECT 1 FROM @UplineAgentInfo )
										BEGIN
		
											DECLARE 
												@tempLevel		INT,
												@tempAgentId	INT

											SELECT TOP 1
												@tempAgentId = AgentId,
												@tempLevel = AgentLevel
											FROM @UplineAgentInfo

											UPDATE tspt
											SET	tspt.SumDownPT = temp.Sum
											FROM 
												@TableStackPositionTaking AS tspt
												INNER JOIN (		
													SELECT 
														tcpt.SportType,
														tcpt.BetType,
														tcpt.IsLive,
														SUM(tcpt.PositionTaking) AS Sum
													FROM 
														dbo.CustPositionTaking AS tcpt WITH (NOLOCK)
														INNER JOIN dbo.AgentInfo AS tai WITH (NOLOCK) ON tcpt.AgentId = tai.AgentId
													WHERE 
														tcpt.CustId = @CustId
														AND tai.AgentLevel >= @tempLevel
													GROUP BY 
														tcpt.SportType,
														tcpt.BetType,
														tcpt.IsLive
												) AS temp
													ON tspt.SportType	= temp.SportType
													AND tspt.BetType	= temp.BetType
													AND tspt.IsLive		= temp.IsLive
											WHERE tspt.AgentLevel		= @tempLevel

											DELETE @UplineAgentInfo 
											WHERE AgentId = @tempAgentId
										END	

										SET @currentAgentId = NULL
										SELECT @currentAgentId = tspt.AgentId
										FROM 
											@TableStackPositionTaking AS tspt
											INNER JOIN (
												SELECT	
													MAX(AgentLevel) AS AgentLevel,
													SportType,
													BetType,
													IsLive 
												FROM @TableStackPositionTaking
												WHERE SumDownPT < MinPT
												GROUP BY 
													SportType,
													BetType,
													IsLive
											) AS temp
												ON 
													tspt.SportType	= temp.SportType
													AND tspt.BetType	= temp.BetType
													AND tspt.IsLive		= temp.IsLive
													AND tspt.AgentLevel	= temp.AgentLevel

										IF @currentAgentId IS NOT NULL
											BEGIN
												DELETE @UplineAgentInfo
												INSERT INTO @UplineAgentInfo (
													AgentId,
													AgentLevel,
													ParentId)
												SELECT	
													AgentId,
													AgentLevel,
													ParentId
												FROM dbo.AgentInfo WITH (NOLOCK)
												WHERE
													@agentHId.IsDescendantOf(AgentHId) = 1
													AND AgentId <> @AgentId
													AND AgentId IN (	SELECT DISTINCT AgentId
																		FROM dbo.CustPositionTaking WITH (NOLOCK)
																		WHERE CustId = @CustId )
											END
										
										UPDATE cpt
										SET cpt.PositionTaking = tempUpdate.MinPT - tempUpdate.SumDownPT + tempUpdate.PT
										FROM 
											dbo.CustPositionTaking AS cpt WITH (ROWLOCK, UPDLOCK)
											INNER JOIN (
												SELECT 
													tspt.AgentId
													,tspt.AgentLevel
													,tspt.SportType
													,tspt.BetType
													,tspt.IsLive
													,tspt.PT
													,tspt.MinPT
													,tspt.SumDownPT
												FROM 
													@TableStackPositionTaking AS tspt
													INNER JOIN (
														SELECT	
															MAX(AgentLevel) AS AgentLevel,
															SportType,
															BetType,
															IsLive 
														FROM @TableStackPositionTaking
														WHERE SumDownPT < MinPT
														GROUP BY 
															SportType,
															BetType,
															IsLive
													) AS temp
												ON 
													tspt.SportType	= temp.SportType
													AND tspt.BetType	= temp.BetType
													AND tspt.IsLive		= temp.IsLive
													AND tspt.AgentLevel	= temp.AgentLevel
											) AS tempUpdate
												ON cpt.SportType	= tempUpdate.SportType
												AND cpt.BetType		= tempUpdate.BetType
												AND cpt.IsLive		= tempUpdate.IsLive
												AND cpt.AgentId		= tempUpdate.AgentId
										WHERE cpt.CustId = @CustId
								END
						END
					-- End if New Position Taking less than Current Position Taking	
					
					SET @xml = (
						SELECT 
							SportType	AS '@s',
							BetType		AS '@b',
							IsLive		AS '@i',
							PT			AS '@p'
						FROM @TablePositionTaking
						ORDER BY SportType
								--,BetType
								,IsLive
						FOR XML PATH('z')
					)

					SET @logSPData = '<r a="'+(SELECT Username FROM AgentInfo WITH (NOLOCK) WHERE AgentId = @AgentId)+'">'+REPLACE(CONVERT(NVARCHAR(MAX), @xml), '" />', '"/"')+'</r>'

					SET @endRun	= GETDATE()  
					SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun) 

					IF @@ERROR = 0
						BEGIN TRY
							EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpCust
								@UserId		= @ActorAgentId,
								@AdminId	= @AdminId,
								@SPName		= 'Age_Customer_UpdatePositionTaking',
								@LogDate	= @startRun,
								@CustId		= @CustId,
								@Duration	= @Duration,
								@Data		= @logSPData,
								@OldData	= @logSPDataOld
						END TRY
						BEGIN CATCH
							EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpCust
								@UserId		= @ActorAgentId,
								@AdminId	= @AdminId,
								@SPName		= 'Age_Customer_UpdatePositionTaking',
								@LogDate	= @startRun,
								@CustId		= @CustId,
								@Duration	= @Duration,
								@Data		= @logSPData,
								@OldData	= @logSPDataOld
						END CATCH
				END
		END
END

