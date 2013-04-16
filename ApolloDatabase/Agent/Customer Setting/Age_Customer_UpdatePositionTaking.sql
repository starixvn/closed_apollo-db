USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Customer_UpdatePositionTaking]    Script Date: 4/16/2013 9:59:44 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
USE [CustDB]
GO

DECLARE	@return_value int,
		@ErrCode int,
		@ErrMsg nvarchar(1000)

EXEC	@return_value = [dbo].[Age_Customer_UpdatePositionTaking]
		@ActorAgentId = 184,
		@AgentId = 184,
		@CustId = 128402,
		@PositionTaking = N'<ROOT><PositionTaking SportType="1" BetType="1" IsLive="1" PT="10" ></PositionTaking></ROOT>',
		@PositionTaking3rd = N'',
		@Language = NULL,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT

SELECT	@ErrCode as N'@ErrCode',
		@ErrMsg as N'@ErrMsg'

SELECT	'Return Value' = @return_value

GO

*/

ALTER PROCEDURE [dbo].[Age_Customer_UpdatePositionTaking]
	@ActorAgentId			INT				= NULL,
	@AgentId				INT,
	@CustId					INT,	
	@PositionTaking			VARCHAR(MAX)	= '',
	@PositionTaking3rd		VARCHAR(MAX)	= '',
	@Language				VARCHAR(2)		= 'E',
	@ErrCode				INT				= 0			OUTPUT,
	@ErrMsg					NVARCHAR(1000)	= ''		OUTPUT 			
AS

/**
 * Created by	: Edward
 * Date			: 20130412
 * Task			: Update customer position taking
 * DB			: APL.CustDB
 * Revisions	:
 *	
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
	
	IF @PositionTaking <> ''
		BEGIN
			DECLARE @TablePositionTaking TABLE(
								SportType	SMALLINT,
								BetType		SMALLINT,
								IsLive		BIT,
								PT			SMALLINT)
			
			DECLARE @TableStackPositionTaking TABLE(
								AgentId		INT,
								AgentLevel	INT,
								SportType	SMALLINT,
								BetType		SMALLINT,
								IsLive		BIT,
								PT			SMALLINT)
								
			DECLARE @TableUpdatePositionTaking TABLE(
								SportType	SMALLINT,
								BetType		SMALLINT,
								IsLive		BIT,
								PT			SMALLINT)			

			-- For read xml
			DECLARE @DocHandler int

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
			FROM OPENXML (@DocHandler, '/ROOT/PositionTaking',1) 
			WITH (			
				SportType		SMALLINT,
				BetType			SMALLINT,				
				IsLive			BIT,
				PT				SMALLINT				
			) AS Data

			EXEC sp_xml_removedocument @DocHandler
			-- end read xml	

			-- Validate data

			DELETE tpt
			FROM @TablePositionTaking AS tpt
				INNER JOIN CustPositionTaking AS cpt WITH (NOLOCK)
					ON 	cpt.SportType	= tpt.SportType
					AND cpt.BetType		= tpt.BetType
					AND cpt.IsLive		= tpt.IsLive
			WHERE cpt.PositionTaking	= tpt.PT
					AND cpt.CustId		= @CustId
					AND cpt.AgentId		= @AgentId

			IF EXISTS (
				SELECT TOP(1) *
				FROM @TablePositionTaking
			)
				BEGIN
					
					---- Declare agentId
					DECLARE @agentLevel				INT
							,@agentHId				HIERARCHYID
							,@parentAgentId			INT
							,@sportType				INT					
							,@childAgentId			INT
							,@index					INT
							,@currentAgentId		INT
							,@childCurrentAgentId	INT
					---- End declare					

					SELECT @agentLevel		= AgentLevel
							,@agentHId		= AgentHId
							,@parentAgentId = ParentId
					FROM AgentInfo WITH (NOLOCK)
					WHERE AgentId = @AgentId


					SET @index = @agentLevel - 1
					---- End set value

					-- Check for direct member or indirect member
					IF @AgentId = @ActorAgentId
						BEGIN
							
							SELECT TOP(1) @sportType = apt.SportType 
							FROM 
								AgentPositionTaking AS apt WITH (NOLOCK)
								INNER JOIN @TablePositionTaking AS ptt
								ON apt.SportType	= ptt.SportType
									AND apt.BetType	= ptt.BetType
									AND apt.IsLive	= ptt.IsLive
							WHERE 
								apt.AgentId = @ActorAgentId
								AND ptt.PT NOT BETWEEN apt.MinPositionTaking AND apt.MaxPositionTaking						
								
							IF @sportType IS NOT NULL
								BEGIN
									SELECT @ErrCode = 1

									SELECT @ErrMsg	= 'Invalid position taking range .'	+ ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'

									RETURN
								END
						END
					ELSE
						BEGIN														
							
							-- just use for correctly select statement
							DECLARE @tempLevel INT

							SELECT DISTINCT @childAgentId	= ai.AgentId ,
											@tempLevel		= ai.AgentLevel			
							FROM CustPositionTaking AS cpt WITH (NOLOCK)	
								INNER JOIN AgentInfo AS ai WITH (NOLOCK)
									ON cpt.AgentId = ai.AgentId		
							WHERE cpt.AgentId IN (
													SELECT dai.AgentId 
													FROM AgentInfo AS dai WITH (NOLOCK)
													WHERE dai.AgentHId.IsDescendantOf(@agentHId) = 1
														AND dai.AgentId <> @AgentId
													)
									AND ai.AgentLevel	= @agentLevel + 1
									AND cpt.CustId		= @CustId
							ORDER BY ai.AgentLevel
							
							SELECT TOP(1) @sportType = ptt.SportType	
								FROM @TablePositionTaking AS ptt
									INNER JOIN (
										SELECT 
											downCust.CustId	
											,downCust.SportType
											,downCust.BetType
											,downCust.IsLive
											,apt.MinPositionTaking - downCust.SumOfDownlinePT AS MinOfPositionTaking
											,CASE WHEN capt.PresetPositionTaking > apt.MinPositionTaking - downCust.SumOfDownlinePT
												THEN capt.PresetPositionTaking
												ELSE apt.MinPositionTaking - downCust.SumOfDownlinePT
											END AS MaxOfPositionTaking
										FROM 
											AgentPositionTaking AS apt WITH (NOLOCK)
											INNER JOIN (
												SELECT 
													cpt.CustId				
													,cpt.SportType
													,cpt.BetType
													,cpt.IsLive		
													,SUM(cpt.PositionTaking) AS SumOfDownlinePT
												FROM 
													CustPositionTaking AS cpt WITH (NOLOCK)
													INNER JOIN AgentInfo AS ai WITH (NOLOCK) 
														ON cpt.AgentId = ai.AgentId	
												WHERE 
													cpt.CustId = @custId
													AND ai.AgentLevel > @agentLevel 
												GROUP BY  
													cpt.CustId					
													,cpt.SportType
													,cpt.BetType
													,cpt.IsLive
											) AS downCust 
												ON 	apt.SportType		= downCust.SportType
													AND apt.BetType		= downCust.BetType
													AND apt.IsLive		= downCust.IsLive
											INNER JOIN AgentPositionTaking AS capt WITH (NOLOCK)
												ON 	apt.SportType	= capt.SportType
													AND apt.BetType = capt.BetType
													AND apt.IsLive	= capt.IsLive 	
										WHERE apt.AgentId = @AgentId
											AND capt.AgentId = @childAgentId
									) AS temp
										ON 	ptt.SportType = temp.SportType
											AND ptt.BetType = temp.BetType
											AND ptt.IsLive = temp.IsLive
								WHERE ptt.PT NOT BETWEEN temp.MinOfPositionTaking AND temp.MaxOfPositionTaking

							IF @sportType IS NOT NULL
								BEGIN
									SELECT @ErrCode = 1

									SELECT @ErrMsg	= 'Invalid position taking range .'	+ ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'

									RETURN
								END
						END	
					-- End check for direct member or indirect member
		
					INSERT INTO @TableStackPositionTaking (
							AgentId
							,AgentLevel
							,SportType
							,BetType
							,IsLive
							,PT)
					SELECT 
							cpt.AgentId
							,ai.AgentLevel
							,cpt.SportType
							,cpt.BetType
							,cpt.IsLive
							,cpt.PositionTaking
					FROM CustPositionTaking AS cpt WITH (NOLOCK)
						INNER JOIN @TablePositionTaking AS tpt
							ON cpt.SportType	= tpt.SportType
							AND cpt.BetType		= tpt.BetType
							AND cpt.IsLive		= tpt.IsLive
						INNER JOIN AgentInfo AS ai WITH (NOLOCK)
							ON cpt.AgentId = ai.AgentId
					WHERE cpt.CustId = @CustId
						AND ai.AgentLevel <= @agentLevel
					ORDER BY ai.AgentLevel

					-- If New Position Taking greater than Current Position Taking
					IF EXISTS (
						SELECT TOP(1) *
						FROM 
							CustPositionTaking AS cpt WITH (NOLOCK)
							INNER JOIN @TablePositionTaking AS tpt
							ON 
								cpt.SportType	= tpt.SportType
								AND cpt.BetType	= tpt.BetType
								AND cpt.IsLive	= tpt.IsLive
						WHERE tpt.PT > cpt.PositionTaking
							AND cpt.CustId	= @CustId
							AND cpt.AgentId = @AgentId
					)
						BEGIN  						

							DELETE @TableUpdatePositionTaking
							INSERT INTO @TableUpdatePositionTaking(
									SportType
									,BetType
									,IsLive
									,PT)
							SELECT 
									tpt.SportType
									,tpt.BetType
									,tpt.IsLive
									,tpt.PT - cpt.PositionTaking
							FROM @TablePositionTaking AS tpt
								INNER JOIN CustPositionTaking AS cpt WITH (NOLOCK)
									ON tpt.SportType	= cpt.SportType
									AND tpt.BetType		= cpt.BetType
									AND tpt.IsLive		= cpt.IsLive
							WHERE cpt.CustId	= @CustId
								AND cpt.AgentId	= @AgentId

							-- @index = k - 1
							WHILE @index > 0
								BEGIN
									SELECT TOP(1) @currentAgentId = AgentId
									FROM @TableStackPositionTaking 
									WHERE AgentLevel = @index

									SELECT TOP(1) @childCurrentAgentId = AgentId
									FROM @TableStackPositionTaking 
									WHERE AgentLevel = @index + 1

									UPDATE cpt
									SET cpt.PositionTaking	= CASE WHEN capt.PresetPositionTaking > cpt.PositionTaking - tupt.PT
																	THEN capt.PresetPositionTaking
																	ELSE cpt.PositionTaking - tupt.PT
																END
									FROM CustPositionTaking AS cpt WITH (ROWLOCK,UPDLOCK)
										INNER JOIN @TablePositionTaking AS tpt
											ON cpt.SportType	= tpt.SportType
											AND cpt.BetType		= tpt.BetType
											AND cpt.IsLive		= tpt.IsLive
										INNER JOIN AgentPositionTaking AS capt WITH (NOLOCK)
											ON cpt.SportType	= capt.SportType
											AND cpt.BetType		= capt.BetType	
											AND cpt.IsLive		= capt.IsLive
										INNER JOIN @TableUpdatePositionTaking AS tupt
											ON cpt.SportType	= tupt.SportType
											AND cpt.BetType		= tupt.BetType
											AND cpt.IsLive		= tupt.IsLive
									WHERE cpt.CustId		= @CustId
										AND cpt.AgentId		= @currentAgentId
										AND capt.AgentId	= @childCurrentAgentId
										AND capt.PresetPositionTaking < cpt.PositionTaking

									SET @index = 0

									UPDATE tupt
									SET tupt.PT = tupt.PT - (tspt.PT - cpt.PositionTaking)
									FROM @TableUpdatePositionTaking AS tupt
										INNER JOIN @TablePositionTaking AS tpt
											ON tupt.SportType	= tpt.SportType
											AND tupt.BetType	= tpt.BetType
											AND tupt.IsLive		= tpt.IsLive											
										INNER JOIN @TableStackPositionTaking AS tspt
											ON tupt.SportType	= tspt.SportType
											AND tupt.BetType	= tspt.BetType
											AND tupt.IsLive		= tspt.IsLive
										INNER JOIN CustPositionTaking AS cpt WITH (NOLOCK)
											ON tupt.SportType	= cpt.SportType
											AND tupt.BetType	= cpt.BetType
											AND tupt.IsLive		= cpt.IsLive
									WHERE tspt.AgentId	= @currentAgentId
										AND cpt.CustId	= @CustId
										AND cpt.AgentId	= @currentAgentId 

									IF EXISTS(
										SELECT TOP(1) * 
										FROM @TableUpdatePositionTaking 
										WHERE PT > 0
									)
										BEGIN
											
											-- Remove Sport Type and Bet Type if PT <=0 
											DELETE tpt
											FROM @TablePositionTaking AS tpt
												INNER JOIN @TableUpdatePositionTaking AS tupt
													ON tpt.SportType	= tupt.SportType
													AND tpt.BetType		= tupt.BetType
													AND tpt.IsLive		= tupt.IsLive
											WHERE tupt.PT <= 0

											SET @index = @index - 1
										END
									ELSE
										BEGIN
											SET @index = 0
										END
								END

							-- Update Position Taking
							UPDATE cpt
							SET	cpt.PositionTaking = tpt.PT
							FROM CustPositionTaking AS cpt WITH (ROWLOCK,UPDLOCK)
								INNER JOIN @TablePositionTaking	AS tpt
									ON tpt.SportType	= cpt.SportType
									AND tpt.BetType		= cpt.BetType
									AND tpt.IsLive		= cpt.IsLive
							WHERE cpt.CustId	= @CustId
								AND cpt.AgentId	= @AgentId
							-- End update Position Taking

						END
					-- End if New Position Taking greater than Current Position Taking

					-- If New Position Taking less than Current Position Taking
					IF EXISTS (
						SELECT TOP(1) *
						FROM 
							CustPositionTaking AS cpt WITH (NOLOCK)
							INNER JOIN @TablePositionTaking AS tpt
							ON 
								cpt.SportType	= tpt.SportType
								AND cpt.BetType	= tpt.BetType
								AND cpt.IsLive	= tpt.IsLive
						WHERE tpt.PT < cpt.PositionTaking
							AND cpt.CustId	= @CustId
							AND cpt.AgentId = @AgentId
					)
						BEGIN

							-- Update Position Taking
							UPDATE cpt
							SET	cpt.PositionTaking = tpt.PT
							FROM CustPositionTaking AS cpt WITH (ROWLOCK,UPDLOCK)
								INNER JOIN @TablePositionTaking	AS tpt
									ON tpt.SportType	= cpt.SportType
									AND tpt.BetType		= cpt.BetType
									AND tpt.IsLive		= cpt.IsLive
							WHERE cpt.CustId	= @CustId
								AND cpt.AgentId	= @AgentId
							-- End update Position Taking


							WHILE @index > 0
								BEGIN
									
									SELECT TOP(1) @currentAgentId = AgentId
									FROM @TableStackPositionTaking 
									WHERE AgentLevel = @index

									DELETE @TableUpdatePositionTaking
									INSERT INTO @TableUpdatePositionTaking(
											SportType
											,BetType
											,IsLive
											,PT)
									SELECT 
											cpt.SportType
											,cpt.BetType
											,cpt.IsLive
											,SUM(cpt.PositionTaking) 
									FROM CustPositionTaking AS cpt WITH (NOLOCK)
										INNER JOIN AgentInfo AS ai WITH (NOLOCK)
											ON cpt.AgentId	= ai.AgentId
										INNER JOIN @TablePositionTaking AS tpt 
											ON cpt.SportType	= tpt.SportType
											AND cpt.BetType		= tpt.BetType
											AND cpt.IsLive		= tpt.IsLive
									WHERE cpt.CustId = @CustId
										AND ai.AgentLevel >= @index
									GROUP BY cpt.SportType
											,cpt.BetType
											,cpt.IsLive

									IF EXISTS(
										SELECT TOP(1) *
										FROM @TableUpdatePositionTaking AS tupt
											INNER JOIN AgentPositionTaking AS apt WITH (NOLOCK)
												ON tupt.SportType	= apt.SportType
												AND tupt.BetType	= apt.BetType
												AND tupt.IsLive		= apt.IsLive
										WHERE apt.AgentId = @currentAgentId
											AND tupt.PT >= apt.MinPositionTaking
									)
										BEGIN
											SET @index = @index - 1
										END
									ELSE
										BEGIN
											UPDATE cpt
											SET cpt.PositionTaking = apt.MinPositionTaking - tupt.PT + cpt.PositionTaking
											FROM CustPositionTaking AS cpt WITH (ROWLOCK,UPDLOCK)
												INNER JOIN @TablePositionTaking AS tpt
													ON cpt.SportType	= tpt.SportType
													AND cpt.BetType		= tpt.BetType
													AND cpt.IsLive		= tpt.IsLive
												INNER JOIN @TableUpdatePositionTaking AS tupt
													ON cpt.SportType	= tupt.SportType
													AND cpt.BetType		= tupt.BetType
													AND cpt.IsLive		= tupt.IsLive
												INNER JOIN AgentPositionTaking AS apt WITH (NOLOCK)
													ON cpt.SportType	= apt.SportType
													AND cpt.BetType		= apt.BetType
													AND cpt.IsLive		= apt.IsLive													
											WHERE cpt.CustId = @CustId
												AND cpt.AgentId = @currentAgentId
												AND apt.AgentId	= @currentAgentId

											SET @index = 0
										END	 
								END
						END
					-- End if New Position Taking less than Current Position Taking	
					
				END	
		END	   
END
