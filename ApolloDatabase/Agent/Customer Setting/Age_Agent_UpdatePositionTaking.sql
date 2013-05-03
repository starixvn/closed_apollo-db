USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_UpdatePositionTaking]    Script Date: 4/22/2013 8:49:07 AM ******/
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

EXEC	@return_value = [dbo].Age_Agent_UpdatePositionTaking
		@ActorAgentId = 180,
		@AgentId = 185,
		@PositionTaking = N'<ROOT>
							<PositionTaking SportType="1" BetType="1" IsLive="0" Preset="122" Max="7761" Min="0"></PositionTaking>
							<PositionTaking SportType="1" BetType="1" IsLive="1" Preset="122" Max="7962" Min="0"></PositionTaking>
						</ROOT>',
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT

SELECT	@ErrCode as N'@ErrCode',
		@ErrMsg as N'@ErrMsg'


SELECT	'Return Value' = @return_value

GO

*/
ALTER PROCEDURE [dbo].[Age_Agent_UpdatePositionTaking]
	@ActorAgentId			INT				= NULL,
	@AgentId				INT,
	@PositionTaking			VARCHAR(MAX)	= '',	
	@Language				VARCHAR(2)		= 'E',
	@LogDate				DATETIME		= NULL,
	@ErrCode				INT				= 0			OUTPUT,
	@ErrMsg					NVARCHAR(1000)	= ''		OUTPUT	 	 		
AS

/**
 * Created by	: Edward
 * Date			: 20130410
 * Task			: Update agent discount
 * DB			: APL.CustDB
 * Revisions	:
 *	
 * Parameters:
 *	@PositionTaking :
		<ROOT><PositionTaking SportType="4" BetType="4" IsLive="1" Preset="10" Max="1" Min="1"></PositionTaking></ROOT>		
 *  
 */

BEGIN
	
	SET NOCOUNT ON
	
	-- Check update permission
	DECLARE @hasPermission BIT
	EXEC dbo.Age_Agent_CheckUpdatePermission 
				@ActorAgentId
				,@AgentId
				,1				-- Is Agent
				,@hasPermission OUTPUT 
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

	-- begin update	

	IF @PositionTaking <> ''
	BEGIN	
		
		-- Declare variable
		DECLARE @agentHId			HIERARCHYID
				,@parentAgentId		INT
				,@agentLevel		INT
				,@sportType			SMALLINT
				,@tempAgentId		INT
				,@isLastAgent		BIT
				,@currentCustId		INT				
				,@data				VARCHAR(MAX)


		---- Declare agentId
		DECLARE @agentParentLevel		INT
				,@agentParentHId		HIERARCHYID
				,@parentOfParentAgentId	INT				
				,@childAgentId			INT
				,@index					INT
				,@currentAgentId		INT
				,@childCurrentAgentId	INT
		---- End declare					

		-- Select for current Agent
		SELECT @agentLevel		= AgentLevel
				,@agentHId		= AgentHId
				,@parentAgentId = ParentId
		FROM AgentInfo WITH (NOLOCK)
		WHERE AgentId = @AgentId

		-- Select for parent
		SELECT @agentParentLevel		= AgentLevel
				,@agentParentHId		= AgentHId
				,@parentOfParentAgentId = ParentId
		FROM AgentInfo WITH (NOLOCK)
		WHERE AgentId = @parentAgentId

		SET @index = @agentParentLevel - 1
		---- End set value

		-- Declare constant
		DECLARE	@MAINSHAREHOLDERLEVEL	INT
				,@SHAREHOLDERLEVEL		INT
				,@MAINAGENTLEVEL		INT
				,@MAXPT					SMALLINT
				,@MAXSHAREHOLDERPT		SMALLINT
				

		-- Set value for constant
		SELECT	@MAXPT					= 10000
				,@MAXSHAREHOLDERPT		= 9000
				,@MAINSHAREHOLDERLEVEL	= 1
				,@SHAREHOLDERLEVEL		= 2	 		
				,@MAINAGENTLEVEL		= 3			

		-- Get agent Hierarchy ID, Parent ID and Agent Level
		SELECT 
			@agentHId		= AgentHId
			,@parentAgentId	= ParentId
			,@agentLevel	= AgentLevel
		FROM 
			AgentInfo WITH (NOLOCK)
		WHERE 
			AgentId = @AgentId

		-- Check current agent is last agent ?
		IF EXISTS (
			SELECT TOP(1) * 
			FROM AgentInfo WITH (NOLOCK)
			WHERE ParentId = @AgentId
		)
			SET @isLastAgent = 0
		ELSE
			SET @isLastAgent = 1

		-- Store new position taking of agent
		DECLARE @TablePositiongTaking TABLE(
					SportType	SMALLINT,
					BetType		SMALLINT,
					IsLive		BIT,
					MaxUpperPT	SMALLINT,
					MaxGivenPT	SMALLINT,
					MinGivenPT	SMALLINT)
		
		DECLARE @TableUpdatePositiongTaking TABLE(						
					SportType	SMALLINT,
					BetType		SMALLINT,
					IsLive		BIT,
					MaxUpperPT	SMALLINT,
					MaxGivenPT	SMALLINT,
					MinGivenPT	SMALLINT)		
	
		DECLARE @TableAgent	TABLE(AgentId INT)

		DECLARE @TableCust	TABLE(CustId INT)

		DECLARE @TableCustPositionTaking TABLE (
			CustId				INT,
			SportType			SMALLINT,
			BetType				SMALLINT,
			IsLive				BIT,
			PositionTaking		SMALLINT)

		-- For update Cust Position Taking
		
		DECLARE @TableStackPositionTaking TABLE(
								AgentId		INT,
								AgentLevel	INT,
								SportType	SMALLINT,
								BetType		SMALLINT,
								IsLive		BIT,
								PT			SMALLINT)
								
		DECLARE @TableUpdateCustPositionTaking TABLE(
							SportType	SMALLINT,
							BetType		SMALLINT,
							IsLive		BIT,
							PT			SMALLINT)
		
		-- End for update Cust Position Taking
		-- For read xml
		DECLARE @DocHandler int

		EXEC sp_xml_preparedocument @DocHandler OUTPUT, @PositionTaking

		INSERT INTO @TablePositiongTaking(
			SportType,
			BetType,
			IsLive,
			MaxUpperPT,			
			MaxGivenPT,
			MinGivenPT)					
		SELECT 			
			Data.SportType,
			Data.BetType,
			Data.IsLive,
			Data.Preset,			
			Data.Max,
			Data.Min
		FROM OPENXML (@DocHandler, '/ROOT/PositionTaking',1) 
		WITH (			
			SportType		SMALLINT,
			BetType			SMALLINT,
			IsLive			BIT,
			Preset			SMALLINT,			
			Max				SMALLINT,
			Min				SMALLINT
		) AS Data

		EXEC sp_xml_removedocument @DocHandler
		-- end read xml	

		-- Check validate max and min
		SELECT TOP(1) @sportType = tpt.SportType
		FROM @TablePositiongTaking AS tpt					
		WHERE tpt.MinGivenPT	< 0
			OR tpt.MaxGivenPT	< 0
			OR tpt.MaxUpperPT	< 0 

		IF @sportType IS NOT NULL 
			BEGIN
				SELECT @ErrCode = 1

				----Message for each sport type	WITH CASE @sportType
				SELECT @ErrMsg	= 'Positiont king must be greater than zero .' + ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'

				RETURN			
			END	

		-- Check validate max and min
		SELECT TOP(1) @sportType = tpt.SportType
		FROM @TablePositiongTaking AS tpt					
		WHERE tpt.MinGivenPT > tpt.MaxGivenPT

		IF @sportType IS NOT NULL 
			BEGIN
				SELECT @ErrCode = 1

				----Message for each sport type	WITH CASE @sportType
				SELECT @ErrMsg	= 'Min Given Position taking must be equal to or less than Max Given Position Taking.' + ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'

				RETURN			
			END	

		SELECT TOP(1) @sportType		= tpt.SportType
						,@tempAgentId	= apt.AgentId
		FROM @TablePositiongTaking AS tpt
			INNER JOIN AgentPositionTaking AS apt WITH (NOLOCK)
				ON apt.SportType	= tpt.SportType
				AND apt.BetType		= tpt.BetType
				AND apt.IsLive		= tpt.IsLive				
		WHERE tpt.MaxUpperPT + tpt.MaxGivenPT > apt.MaxPositionTaking
			AND apt.AgentId = @parentAgentId

		IF @sportType IS NOT NULL 
			BEGIN
				SELECT @ErrCode = 1

				----Message for each sport type	WITH CASE @sportType
				SELECT @ErrMsg	= 'Sum Max Upper and Max Given Position Taking must be equal or less than Max Given Position Taking of Parent Agent.' 
									+ 'AgentID = '+ CONVERT(VARCHAR(10), @tempAgentId) 
									+ ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'

				RETURN			
			END	

		-- Update new position taking if had changed
		IF EXISTS(
			SELECT TOP(1) * 
			FROM AgentPositionTaking AS apt WITH (NOLOCK)
				INNER JOIN @TablePositiongTaking AS tpt
					ON tpt.SportType	= apt.SportType
					AND tpt.BetType		= apt.BetType
					AND tpt.IsLive		= apt.IsLive
			WHERE apt.AgentId = @AgentId
				AND (apt.PresetPositionTaking	<> tpt.MaxUpperPT
					 OR apt.MaxPositionTaking	<> tpt.MaxGivenPT
					 OR apt.MinPositionTaking	<> tpt.MinGivenPT)
		)
			BEGIN
				
				-- write log before update
				
				SET @xml = (
					SELECT  
						apt.SportType				AS '@s'
						,apt.BetType				AS '@b'
						,apt.IsLive					AS '@i'
						,apt.PresetPositionTaking	AS '@p'
						,apt.MaxPositionTaking		AS '@ma'
						,apt.MinPositionTaking		AS '@mi'
					FROM 
						AgentPositionTaking AS apt WITH (NOLOCK)
						INNER JOIN @TablePositiongTaking AS tpt
							ON apt.SportType	= tpt.SportType
							AND apt.BetType		= tpt.BetType
							AND apt.IsLive		= tpt.IsLive
					WHERE apt.AgentId = @AgentId				
					FOR XML PATH('z'), ROOT('r')
				)

				SET @logSPDataOld = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

				-- end write log

				-- Edit Main Share Holder Position Taking
				IF @agentLevel = @MAINSHAREHOLDERLEVEL
					BEGIN
						-- If Max Given PT change
						IF EXISTS(
							SELECT TOP(1) * 
							FROM AgentPositionTaking AS apt WITH (NOLOCK)
								INNER JOIN @TablePositiongTaking AS tpt
									ON tpt.SportType	= apt.SportType
									AND tpt.BetType		= apt.BetType
									AND tpt.IsLive		= apt.IsLive
							WHERE apt.AgentId = @AgentId
								AND apt.MaxPositionTaking	<> tpt.MaxGivenPT
						)
							BEGIN
								-- Check validate when update main share holder

								-- Max given position taking must be MinGivenPT < MaxGivenPT < @MAXSHAREHOLDERPT
								SELECT TOP(1) @sportType = tpt.SportType
								FROM @TablePositiongTaking AS tpt					
								WHERE tpt.MaxGivenPT NOT BETWEEN tpt.MinGivenPT AND @MAXSHAREHOLDERPT

								IF @sportType IS NOT NULL 
									BEGIN
										SELECT @ErrCode = 1

										----Message for each sport type	WITH CASE @sportType
										SELECT @ErrMsg	= 'Max Given Position taking must be equal to or less than ' + @MAXSHAREHOLDERPT + '.' + ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'

										RETURN			
									END

								-- Max given position taking must be greater or equal Max[Sum(PreK+MaxK)]
								SELECT TOP(1) @sportType		= tpt.SportType
												,@tempAgentId	= shareHolderTemp.AgentId
								FROM @TablePositiongTaking AS tpt
									INNER JOIN (
										SELECT apt.AgentId
												,apt.SportType
												,apt.BetType
												,apt.IsLive												
												,apt.PresetPositionTaking + apt.MaxPositionTaking AS SumMaxUpperAndGiven
										FROM AgentPositionTaking AS apt WITH (NOLOCK)
											INNER JOIN AgentInfo AS ai WITH (NOLOCK)
												ON apt.AgentId = ai.AgentId
										WHERE ai.ParentId = @AgentId
									) AS shareHolderTemp
										ON tpt.SportType	= shareHolderTemp.SportType
										AND tpt.BetType		= shareHolderTemp.BetType
										AND tpt.IsLive		= shareHolderTemp.IsLive
								WHERE tpt.MaxGivenPT < shareHolderTemp.SumMaxUpperAndGiven

								IF @sportType IS NOT NULL 
									BEGIN
										SELECT @ErrCode = 1

										----Message for each sport type	WITH CASE @sportType
										SELECT @ErrMsg	= 'Max Given Position taking must be equal to or 
															less than sum Max Upper and Max Given Position Taking of Share Holder.'
															+ 'AgentID = '+ CONVERT(VARCHAR(10), @tempAgentId) 
															+ ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'

										RETURN			
									END
								-- End check validate when update main share holder

								-- Begin update
								UPDATE apt
								SET apt.MaxPositionTaking		= tpt.MaxGivenPT
									,apt.PresetPositionTaking	= @MAXPT - tpt.MaxGivenPT 
								FROM AgentPositionTaking AS apt WITH (ROWLOCK,UPDLOCK)
									INNER JOIN @TablePositiongTaking AS tpt
										ON apt.SportType	= tpt.SportType
										AND apt.BetType		= tpt.BetType
										AND apt.IsLive		= tpt.IsLive
								WHERE apt.AgentId = @AgentId
								-- End update
							END
						-- End update Max Given PT

						-- If Min Given PT change
						IF EXISTS(
							SELECT TOP(1) * 
							FROM AgentPositionTaking AS apt WITH (NOLOCK)
								INNER JOIN @TablePositiongTaking AS tpt
									ON tpt.SportType	= apt.SportType
									AND tpt.BetType		= apt.BetType
									AND tpt.IsLive		= apt.IsLive
							WHERE apt.AgentId = @AgentId
								AND apt.MinPositionTaking	<> tpt.MinGivenPT
						)
							BEGIN
								
								-- If New Min Given PT greater than Current Min Givent PT
								IF EXISTS(
									SELECT TOP(1) * 
									FROM AgentPositionTaking AS apt WITH (NOLOCK)
										INNER JOIN @TablePositiongTaking AS tpt
											ON tpt.SportType	= apt.SportType
											AND tpt.BetType		= apt.BetType
											AND tpt.IsLive		= apt.IsLive
									WHERE apt.AgentId		= @AgentId
										AND tpt.MinGivenPT	> apt.MinPositionTaking
								)
									BEGIN								
										
										-- Don't need update direct member here because agent is main shareholder
																				
										-- Get all member in downline of agent
										DELETE @TableCust
										INSERT INTO @TableCust(CustId)
										SELECT ci.CustId 
										FROM CustInfo AS ci WITH (NOLOCK)
											INNER JOIN AgentInfo AS ai WITH (NOLOCK)
												ON ci.AgentId = ai.AgentId
										WHERE ai.AgentHId.IsDescendantOf(@agentHId) = 1
											AND ai.AgentId <> @AgentId												
										
										WHILE EXISTS (
											SELECT TOP(1) * FROM @TableCust
										)
											BEGIN
												
												-- Select current Cust Id												
												SELECT TOP(1) @currentCustId = CustId
												FROM @TableCust 

												UPDATE cpt
												SET	cpt.PositionTaking = tpt.MinGivenPT - dcpt.SumOfPositionTaking + cpt.PositionTaking
												FROM CustPositionTaking AS cpt WITH (ROWLOCK,UPDLOCK)																					
													INNER JOIN @TablePositiongTaking AS tpt
														ON cpt.SportType	= tpt.SportType
														AND cpt.BetType		= tpt.BetType
														AND cpt.IsLive		= tpt.IsLive
													INNER JOIN (
														SELECT 
															CustId
															,SportType
															,BetType
															,IsLive
															,SUM(PositionTaking) AS SumOfPositionTaking
														FROM 
															CustPositionTaking AS cpt WITH (NOLOCK)															
														WHERE cpt.CustId = @currentCustId
														GROUP BY CustId, SportType, BetType, IsLive	
													) AS dcpt 
														ON 	cpt.SportType	= dcpt.SportType
															AND cpt.BetType = dcpt.BetType
															AND cpt.IsLive	= dcpt.IsLive																
												WHERE dcpt.SumOfPositionTaking < tpt.MinGivenPT
													AND cpt.AgentId = @AgentId
													AND cpt.CustId	= @currentCustId	

												-- Remove Cust Id for loop
												DELETE @TableCust WHERE CustId = @currentCustId
											END																			
									END
								-- End update Min Given PT greater than Current Min Given PT

								-- Begin update
								UPDATE apt
								SET apt.MinPositionTaking	= tpt.MinGivenPT
								FROM AgentPositionTaking AS apt WITH (ROWLOCK,UPDLOCK)
									INNER JOIN @TablePositiongTaking AS tpt
										ON apt.SportType	= tpt.SportType
										AND apt.BetType		= tpt.BetType
										AND apt.IsLive		= tpt.IsLive
								WHERE apt.AgentId = @AgentId								
								-- End update									
							END
						-- End update Min Given PT
					END
				-- End edit Main Share Holder Position Taking
				ELSE
				-- Begin edit Agent with level k ( k > 1)
					BEGIN
						-- Edit Max Upper PT
						IF EXISTS(
							SELECT TOP(1) * 
							FROM AgentPositionTaking AS apt WITH (NOLOCK)
								INNER JOIN @TablePositiongTaking AS tpt
									ON tpt.SportType	= apt.SportType
									AND tpt.BetType		= apt.BetType
									AND tpt.IsLive		= apt.IsLive
							WHERE apt.AgentId = @AgentId
								AND apt.PresetPositionTaking	<> tpt.MaxUpperPT
						)
							BEGIN
								-- Check validate when update main share holder
								SELECT TOP(1) @sportType = tpt.SportType
								FROM @TablePositiongTaking AS tpt					
									INNER JOIN AgentPositionTaking AS papt WITH (NOLOCK)
										ON tpt.SportType	= papt.SportType
										AND tpt.BetType		= papt.BetType
										AND tpt.IsLive		= papt.IsLive
								WHERE papt.AgentId = @parentAgentId
									AND tpt.MaxUpperPT NOT BETWEEN 0 AND papt.MaxPositionTaking - tpt.MaxGivenPT

								IF @sportType IS NOT NULL 
									BEGIN
										SELECT @ErrCode = 1

										----Message for each sport type	WITH CASE @sportType
										SELECT @ErrMsg	= 'Max Upper Position taking invalid range .' + ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'

										RETURN			
									END

								-- Update New Max Upper PT less than Current Max Upper PT of agent
								IF EXISTS(
									SELECT TOP(1) * 
									FROM AgentPositionTaking AS apt WITH (NOLOCK)
										INNER JOIN @TablePositiongTaking AS tpt
											ON tpt.SportType	= apt.SportType
											AND tpt.BetType		= apt.BetType
											AND tpt.IsLive		= apt.IsLive
									WHERE apt.AgentId		= @AgentId
										AND tpt.MaxUpperPT	< apt.PresetPositionTaking
								)
									BEGIN

										-- Insert direct member of agent
										-- Reset @TableCust
										DELETE @TableCust																				
										INSERT INTO @TableCust(CustId)
										SELECT CustId
										FROM CustInfo WITH (NOLOCK)
										WHERE AgentId = @AgentId

										-- Reset @TableCustPosistionTaking
										DELETE @TableCustPositionTaking

										-- Get member break rule of agent level n
										IF @isLastAgent = 1
											BEGIN
												INSERT INTO @TableCustPositionTaking(
													CustId
													,SportType
													,BetType
													,IsLive
													,PositionTaking)
												SELECT
													cpt.CustId
													,cpt.SportType
													,cpt.BetType
													,cpt.IsLive
													,cpt.PositionTaking 
												FROM CustPositionTaking AS cpt WITH (NOLOCK)	
													INNER JOIN @TablePositiongTaking AS tpt
														ON tpt.SportType	= cpt.SportType
														AND tpt.BetType		= cpt.BetType
														AND tpt.IsLive		= cpt.IsLive
													INNER JOIN @TableCust AS tc
														ON cpt.CustId = tc.CustId
												WHERE cpt.AgentId = @parentAgentId
													AND cpt.PositionTaking > tpt.MaxUpperPT
											END -- Get member break rule of agent level n										
										ELSE
										-- Get member break rule of agent level k
											BEGIN										
												INSERT INTO @TableCustPositionTaking(
													CustId
													,SportType
													,BetType
													,IsLive
													,PositionTaking)
												SELECT
													cpt.CustId
													,cpt.SportType
													,cpt.BetType
													,cpt.IsLive
													,cpt.PositionTaking 
												FROM CustPositionTaking AS cpt WITH (NOLOCK)	
													INNER JOIN @TablePositiongTaking AS tpt
														ON tpt.SportType	= cpt.SportType
														AND tpt.BetType		= cpt.BetType
														AND tpt.IsLive		= cpt.IsLive
													INNER JOIN @TableCust AS tc
														ON cpt.CustId		= tc.CustId
													INNER JOIN AgentPositionTaking AS apt WITH (NOLOCK)
														ON apt.SportType	= cpt.SportType
														AND apt.BetType		= cpt.BetType
														AND apt.IsLive		= cpt.IsLive
												WHERE cpt.AgentId	= @parentAgentId
													AND apt.AgentId = @AgentId
													AND cpt.PositionTaking	> tpt.MaxUpperPT 
													AND cpt.PositionTaking	<= apt.PresetPositionTaking
											END	-- Get member break rule of agent level k	
											
										WHILE EXISTS(
											SELECT TOP(1) * FROM @TableCustPositionTaking
										)
											BEGIN
												-- Select current Cust Id
												SELECT TOP(1) @currentCustId = CustId
												FROM @TableCustPositionTaking
												
												-- Begin update	
												UPDATE cpt
												SET cpt.PositionTaking = CASE WHEN tpt.MaxUpperPT > papt.MinPositionTaking - downCust.SumOfPositionTaking
																			THEN tpt.MaxUpperPT
																			ELSE papt.MinPositionTaking - downCust.SumOfPositionTaking
																		END
												FROM CustPositionTaking AS cpt WITH (ROWLOCK,UPDLOCK)
													INNER JOIN @TablePositiongTaking AS tpt
														ON cpt.SportType	= tpt.SportType
														AND cpt.BetType		= tpt.BetType
														AND cpt.IsLive		= tpt.IsLive
													INNER JOIN @TableCustPositionTaking AS tcpt
														ON tcpt.SportType	= cpt.SportType
														AND tcpt.BetType	= cpt.BetType
														AND tcpt.IsLive		= cpt.IsLive 
													INNER JOIN (
														SELECT 
															CustId
															,SportType
															,BetType
															,IsLive
															,SUM(PositionTaking) AS SumOfPositionTaking
														FROM 
															CustPositionTaking AS cpt WITH (NOLOCK)															
															INNER JOIN AgentInfo AS ai WITH (NOLOCK)
																ON cpt.AgentId = ai.AgentId
														WHERE cpt.CustId	= @currentCustId
															AND ai.AgentHId.IsDescendantOf(@agentHId) = 1
														GROUP BY CustId, SportType, BetType, IsLive												
													) AS downCust	
														ON cpt.SportType	= downCust.SportType
														AND cpt.BetType		= downCust.BetType
														AND cpt.IsLive		= downCust.IsLive		
														AND cpt.CustId		= downCust.CustId	
													INNER JOIN AgentPositionTaking AS papt WITH (NOLOCK)
														ON cpt.SportType	= papt.SportType
														AND cpt.BetType		= papt.BetType
														AND cpt.IsLive		= papt.IsLive
												WHERE papt.AgentId	= @parentAgentId	
													AND cpt.AgentId	= @parentAgentId																									
												-- End update

												-- Edit Position Taking of member for mem less than current mem pt
												DELETE @TableStackPositionTaking
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
													INNER JOIN @TableCustPositionTaking AS tcpt
														ON cpt.SportType	= tcpt.SportType
														AND cpt.BetType		= tcpt.BetType
														AND cpt.IsLive		= tcpt.IsLive
														AND cpt.CustId		= tcpt.CustId
													INNER JOIN AgentInfo AS ai WITH (NOLOCK)
														ON cpt.AgentId		= ai.AgentId
												WHERE cpt.CustId		= @currentCustId
													AND tcpt.CustId		= @currentCustId			-- The same above condition
													AND ai.AgentLevel	<= @agentParentLevel
												ORDER BY ai.AgentLevel
														
												-- @index = Level of parent agent - 1
												SET @index = @agentParentLevel - 1	
												WHILE @index > 0
													BEGIN
									
														SELECT TOP(1) @currentAgentId = AgentId
														FROM @TableStackPositionTaking 
														WHERE AgentLevel = @index

														DELETE @TableUpdateCustPositionTaking
														INSERT INTO @TableUpdateCustPositionTaking(
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
															INNER JOIN @TableCustPositionTaking AS tcpt 
																ON cpt.SportType	= tcpt.SportType
																AND cpt.BetType		= tcpt.BetType
																AND cpt.IsLive		= tcpt.IsLive
																AND cpt.CustId		= tcpt.CustId
														WHERE cpt.CustId		= @currentCustId
															AND ai.AgentLevel	>= @index
														GROUP BY cpt.SportType
																,cpt.BetType
																,cpt.IsLive

														IF EXISTS(
															SELECT TOP(1) *
															FROM @TableUpdateCustPositionTaking AS tucpt
																INNER JOIN AgentPositionTaking AS apt WITH (NOLOCK)
																	ON tucpt.SportType	= apt.SportType
																	AND tucpt.BetType	= apt.BetType
																	AND tucpt.IsLive	= apt.IsLive
															WHERE apt.AgentId = @currentAgentId
																AND tucpt.PT >= apt.MinPositionTaking
														)
															BEGIN
																SET @index = @index - 1
															END
														ELSE
															BEGIN
																UPDATE cpt
																SET cpt.PositionTaking = apt.MinPositionTaking - tucpt.PT + cpt.PositionTaking
																FROM CustPositionTaking AS cpt WITH (ROWLOCK,UPDLOCK)
																	INNER JOIN @TableCustPositionTaking AS tcpt
																		ON cpt.SportType	= tcpt.SportType
																		AND cpt.BetType		= tcpt.BetType
																		AND cpt.IsLive		= tcpt.IsLive
																		AND cpt.CustId		= tcpt.CustId
																	INNER JOIN @TableUpdateCustPositionTaking AS tucpt
																		ON cpt.SportType	= tucpt.SportType
																		AND cpt.BetType		= tucpt.BetType
																		AND cpt.IsLive		= tucpt.IsLive
																	INNER JOIN AgentPositionTaking AS apt WITH (NOLOCK)
																		ON cpt.SportType	= apt.SportType
																		AND cpt.BetType		= apt.BetType
																		AND cpt.IsLive		= apt.IsLive													
																WHERE cpt.CustId = @currentCustId
																	AND cpt.AgentId = @currentAgentId
																	AND apt.AgentId	= @currentAgentId

																SET @index = 0
															END	 
													END
												-- End edit positin taking of member

												-- Remove cust
												DELETE @TableCustPositionTaking WHERE CustId = @currentCustId
											END
																											
									END
								-- End update New Max Upper PT less than Current Max Upper PT of agent

								-- Update Max Upper PT
								UPDATE apt
								SET apt.PresetPositionTaking	= tpt.MaxUpperPT
								FROM AgentPositionTaking AS apt WITH (ROWLOCK,UPDLOCK)
									INNER JOIN @TablePositiongTaking AS tpt
										ON apt.SportType	= tpt.SportType
										AND apt.BetType		= tpt.BetType
										AND apt.IsLive		= tpt.IsLive
								WHERE apt.AgentId = @AgentId

							END
						-- End edit Max Upper PT
						
						-- Edit Max Given PT
						 IF EXISTS(
							SELECT TOP(1) * 
							FROM AgentPositionTaking AS apt WITH (NOLOCK)
								INNER JOIN @TablePositiongTaking AS tpt
									ON tpt.SportType	= apt.SportType
									AND tpt.BetType		= apt.BetType
									AND tpt.IsLive		= apt.IsLive
							WHERE apt.AgentId				= @AgentId
								AND apt.MaxPositionTaking	<> tpt.MaxGivenPT
						)
							BEGIN								
								IF @isLastAgent = 1
									BEGIN
										SELECT TOP(1) @sportType = tpt.SportType
										FROM @TablePositiongTaking AS tpt
											INNER JOIN AgentPositionTaking AS papt WITH (NOLOCK)
												ON tpt.SportType	= papt.SportType
												AND tpt.BetType		= papt.BetType
												AND tpt.IsLive		= papt.IsLive
										WHERE papt.AgentId	= @parentAgentId
											AND tpt.MaxGivenPT NOT BETWEEN tpt.MinGivenPT AND papt.MaxPositionTaking

										 IF @sportType IS NOT NULL 
											BEGIN
												SELECT @ErrCode = 1

												----Message for each sport type	WITH CASE @sportType
												SELECT @ErrMsg	= 'Max Given Position taking invalid range .' + ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'

												RETURN			
											END
									END
								ELSE
									BEGIN
									
										SELECT TOP(1) @sportType = tpt.SportType
										FROM @TablePositiongTaking AS tpt
											INNER JOIN (
												SELECT	
													downAgent.SportType
													,downAgent.BetType
													,downAgent.IsLive
													,MAX(downAgent.SumOfMaxUpperAndGiven) AS MaxOfMaxUpperAndGiven
												FROM (
														SELECT ai.AgentId
																,apt.PresetPositionTaking + apt.MaxPositionTaking AS SumOfMaxUpperAndGiven
																,apt.SportType
																,apt.BetType
																,apt.IsLive
														FROM AgentPositionTaking AS apt WITH (NOLOCK)
															INNER JOIN AgentInfo AS ai WITH (NOLOCK)
																ON apt.AgentId = ai.AgentId
														WHERE ai.AgentHId.IsDescendantOf(@agentHId) = 1
															AND ai.AgentId <> @AgentId
													) AS downAgent	
												GROUP BY downAgent.SportType
														,downAgent.BetType
														,downAgent.IsLive
											) AS maxDownAgent
												ON tpt.SportType	= maxDownAgent.SportType
												AND tpt.BetType		= maxDownAgent.BetType
												AND tpt.IsLive		= maxDownAgent.IsLive
											INNER JOIN AgentPositionTaking AS papt WITH (NOLOCK)
												ON tpt.SportType	= papt.SportType
												AND tpt.BetType		= papt.BetType
												AND tpt.IsLive		= papt.IsLive
										WHERE papt.AgentId = @parentAgentId
											AND tpt.MaxGivenPT NOT BETWEEN CASE WHEN maxDownAgent.MaxOfMaxUpperAndGiven > tpt.MinGivenPT
																				THEN maxDownAgent.MaxOfMaxUpperAndGiven
																				ELSE tpt.MinGivenPT
																			END	 AND papt.MaxPositionTaking 
										IF @sportType IS NOT NULL 
											BEGIN
												SELECT @ErrCode = 1

												----Message for each sport type	WITH CASE @sportType
												SELECT @ErrMsg	= 'Max Given Position taking invalid range .' + ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'

												RETURN			
											END
										
									END		
									
								-- Update Max Given PT
								UPDATE apt
								SET	
									apt.MaxPositionTaking		= tpt.MaxGivenPT									
								FROM AgentPositionTaking AS apt WITH (ROWLOCK,UPDLOCK)
									INNER JOIN @TablePositiongTaking AS tpt
										ON tpt.SportType	= apt.SportType
										AND tpt.BetType		= apt.BetType
										AND tpt.IsLive		= apt.IsLive									
								WHERE apt.AgentId		= @AgentId									

								-- Update Max Upper PT when greater than Max Given PT of Agent Parent - Max Given of current Agent
								DELETE @TableUpdatePositiongTaking
								INSERT INTO @TableUpdatePositiongTaking(
													SportType
													,BetType
													,IsLive
													,MaxUpperPT
													,MaxGivenPT)
								SELECT apt.SportType
										,apt.BetType
										,apt.IsLive
										,apt.PresetPositionTaking
										,apt.MaxPositionTaking									-- Already updated with new value
								FROM AgentPositionTaking AS apt WITH (NOLOCK)
									INNER JOIN AgentPositionTaking AS papt WITH (NOLOCK)
										ON apt.SportType	= papt.SportType
										AND apt.BetType		= papt.BetType
										AND apt.IsLive		= papt.IsLive
									INNER JOIN @TablePositiongTaking AS tpt
										ON apt.SportType	= tpt.SportType
										AND apt.BetType		= tpt.BetType
										AND apt.IsLive		= tpt.IsLive
								WHERE apt.AgentId		= @AgentId
									AND papt.AgentId	= @parentAgentId
									AND apt.PresetPositionTaking > papt.MaxPositionTaking - apt.MaxPositionTaking

								IF EXISTS (
									SELECT TOP(1) * 
									FROM @TableUpdatePositiongTaking
								)
									BEGIN
										
										-- Update new Max Upper PT
										UPDATE apt 
										SET apt.PresetPositionTaking = papt.MaxPositionTaking - tupt.MaxGivenPT	
										FROM AgentPositionTaking AS apt WITH (ROWLOCK,UPDLOCK)
											INNER JOIN AgentPositionTaking AS papt WITH (NOLOCK)
												ON apt.SportType	= papt.SportType
												AND apt.BetType		= papt.BetType
												AND apt.IsLive		= papt.IsLive
											INNER JOIN @TableUpdatePositiongTaking AS tupt
												ON apt.SportType	= tupt.SportType
												AND apt.BetType		= tupt.BetType
												AND apt.IsLive		= tupt.IsLive
										WHERE apt.AgentId		= @AgentId
											AND papt.AgentId	= @parentAgentId											
										-- End update new Max Upper PT										

										-- Reset @TableCustPosistionTaking
										DELETE @TableCustPositionTaking

										-- Get member break rule of agent level n
										IF @isLastAgent = 1
											BEGIN
												-- Insert direct member of agent
												-- Reset @TableCust
												DELETE @TableCust																				
												INSERT INTO @TableCust(CustId)
												SELECT CustId
												FROM CustInfo WITH (NOLOCK)
												WHERE AgentId = @AgentId

												INSERT INTO @TableCustPositionTaking(
													CustId
													,SportType
													,BetType
													,IsLive
													,PositionTaking)
												SELECT
													cpt.CustId
													,cpt.SportType
													,cpt.BetType
													,cpt.IsLive
													,cpt.PositionTaking 
												FROM CustPositionTaking AS cpt WITH (NOLOCK)	
													INNER JOIN @TableUpdatePositiongTaking AS tupt
														ON tupt.SportType	= cpt.SportType
														AND tupt.BetType	= cpt.BetType
														AND tupt.IsLive		= cpt.IsLive
													INNER JOIN AgentPositionTaking AS apt WITH (NOLOCK)
														ON cpt.SportType	= apt.SportType
														AND cpt.BetType		= apt.BetType
														AND cpt.IsLive		= apt.IsLive
													INNER JOIN @TableCust AS tc
														ON cpt.CustId = tc.CustId
												WHERE cpt.AgentId			= @parentAgentId	
													AND apt.AgentId			= @AgentId												
													AND cpt.PositionTaking	> apt.PresetPositionTaking
											END
										ELSE
										-- Get member break rule of agent level k
											BEGIN
												INSERT INTO @TableCustPositionTaking(
													CustId
													,SportType
													,BetType
													,IsLive
													,PositionTaking)
												SELECT
													cpt.CustId
													,cpt.SportType
													,cpt.BetType
													,cpt.IsLive
													,cpt.PositionTaking 
												FROM CustPositionTaking AS cpt WITH (NOLOCK)	
													INNER JOIN @TableUpdatePositiongTaking AS tupt
														ON tupt.SportType	= cpt.SportType
														AND tupt.BetType	= cpt.BetType
														AND tupt.IsLive		= cpt.IsLive
													INNER JOIN @TableCust AS tc
														ON cpt.CustId = tc.CustId
													INNER JOIN AgentPositionTaking AS apt WITH (NOLOCK)
														ON apt.SportType	= cpt.SportType
														AND apt.BetType		= cpt.BetType
														AND apt.IsLive		= cpt.IsLive
												WHERE cpt.AgentId			= @parentAgentId
													AND apt.AgentId			= @AgentId
													AND cpt.PositionTaking	> apt.PresetPositionTaking
													AND cpt.PositionTaking	<= tupt.MaxUpperPT
											END		
											
											WHILE EXISTS(
												SELECT TOP(1) * FROM @TableCustPositionTaking
											)
												BEGIN
													-- Select current Cust Id
													SELECT TOP(1) @currentCustId = CustId
													FROM @TableCustPositionTaking
													
													UPDATE cpt
													SET cpt.PositionTaking = CASE WHEN tupt.MaxUpperPT > papt.MinPositionTaking - downCust.SumOfPositionTaking
																				THEN tupt.MaxUpperPT
																				ELSE papt.MinPositionTaking - downCust.SumOfPositionTaking
																			END
													FROM CustPositionTaking AS cpt WITH (ROWLOCK,UPDLOCK)
														INNER JOIN @TableUpdatePositiongTaking AS tupt
															ON cpt.SportType	= tupt.SportType
															AND cpt.BetType		= tupt.BetType
															AND cpt.IsLive		= tupt.IsLive
														INNER JOIN @TableCustPositionTaking AS tcpt
															ON tcpt.SportType	= cpt.SportType
															AND tcpt.BetType	= cpt.BetType
															AND tcpt.IsLive		= cpt.IsLive 
														INNER JOIN (
															SELECT 
																CustId
																,SportType
																,BetType
																,IsLive
																,SUM(PositionTaking) AS SumOfPositionTaking
															FROM 
																CustPositionTaking AS cpt WITH (NOLOCK)															
																INNER JOIN AgentInfo AS ai WITH (NOLOCK)
																	ON cpt.AgentId = ai.AgentId
															WHERE cpt.CustId	= @currentCustId
																AND ai.AgentHId.IsDescendantOf(@agentHId) = 1
															GROUP BY CustId, SportType, BetType, IsLive												
														) AS downCust	
															ON cpt.SportType	= downCust.SportType
															AND cpt.BetType		= downCust.BetType
															AND cpt.IsLive		= downCust.IsLive		
															AND cpt.CustId		= downCust.CustId	
														INNER JOIN AgentPositionTaking AS papt WITH (NOLOCK)
															ON cpt.SportType	= papt.SportType
															AND cpt.BetType		= papt.BetType
															AND cpt.IsLive		= papt.IsLive
													WHERE papt.AgentId	= @parentAgentId	
														AND cpt.AgentId	= @parentAgentId												
													
													-- Edit Position Taking of member when new mem pt less than current mem pt
													DELETE @TableStackPositionTaking
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
														INNER JOIN @TableCustPositionTaking AS tcpt
															ON cpt.SportType	= tcpt.SportType
															AND cpt.BetType		= tcpt.BetType
															AND cpt.IsLive		= tcpt.IsLive
															AND cpt.CustId		= tcpt.CustId
														INNER JOIN AgentInfo AS ai WITH (NOLOCK)
															ON cpt.AgentId = ai.AgentId
													WHERE cpt.CustId = @currentCustId
														AND ai.AgentLevel <= @agentParentLevel
													ORDER BY ai.AgentLevel
														
													SET @index = @agentParentLevel - 1		
													WHILE @index > 0
														BEGIN
									
															SELECT TOP(1) @currentAgentId = AgentId
															FROM @TableStackPositionTaking 
															WHERE AgentLevel = @index

															DELETE @TableUpdateCustPositionTaking
															INSERT INTO @TableUpdateCustPositionTaking(
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
																INNER JOIN @TableCustPositionTaking AS tcpt 
																	ON cpt.SportType	= tcpt.SportType
																	AND cpt.BetType		= tcpt.BetType
																	AND cpt.IsLive		= tcpt.IsLive
																	AND cpt.CustId		= tcpt.CustId
															WHERE cpt.CustId = @currentCustId
																AND ai.AgentLevel >= @index
															GROUP BY cpt.SportType
																	,cpt.BetType
																	,cpt.IsLive

															IF EXISTS(
																SELECT TOP(1) *
																FROM @TableUpdateCustPositionTaking AS tucpt
																	INNER JOIN AgentPositionTaking AS apt WITH (NOLOCK)
																		ON tucpt.SportType	= apt.SportType
																		AND tucpt.BetType	= apt.BetType
																		AND tucpt.IsLive	= apt.IsLive
																WHERE apt.AgentId = @currentAgentId
																	AND tucpt.PT >= apt.MinPositionTaking
															)
																BEGIN
																	SET @index = @index - 1
																END
															ELSE
																BEGIN
																	UPDATE cpt
																	SET cpt.PositionTaking = apt.MinPositionTaking - tucpt.PT + cpt.PositionTaking
																	FROM CustPositionTaking AS cpt WITH (ROWLOCK,UPDLOCK)
																		INNER JOIN @TableCustPositionTaking AS tcpt
																			ON cpt.SportType	= tcpt.SportType
																			AND cpt.BetType		= tcpt.BetType
																			AND cpt.IsLive		= tcpt.IsLive
																			AND cpt.CustId		= tcpt.CustId
																		INNER JOIN @TableUpdateCustPositionTaking AS tucpt
																			ON cpt.SportType	= tucpt.SportType
																			AND cpt.BetType		= tucpt.BetType
																			AND cpt.IsLive		= tucpt.IsLive
																		INNER JOIN AgentPositionTaking AS apt WITH (NOLOCK)
																			ON cpt.SportType	= apt.SportType
																			AND cpt.BetType		= apt.BetType
																			AND cpt.IsLive		= apt.IsLive													
																	WHERE cpt.CustId = @currentCustId
																		AND cpt.AgentId = @currentAgentId
																		AND apt.AgentId	= @currentAgentId

																	SET @index = 0
																END	 
														END
													-- End edit positin taking of member

													-- Remove cust
													DELETE @TableCustPositionTaking WHERE CustId = @currentCustId
												END											

									END
								-- End update Max Upper PT when greater than Max Given PT of Agent Parent and current Agent

								-- End update Max Given PT		
							END
						-- End edit Max Given PT	

						-- Edit Min Given PT
						IF EXISTS(
							SELECT TOP(1) * 
							FROM AgentPositionTaking AS apt WITH (NOLOCK)
								INNER JOIN @TablePositiongTaking AS tpt
									ON tpt.SportType	= apt.SportType
									AND tpt.BetType		= apt.BetType
									AND tpt.IsLive		= apt.IsLive
							WHERE apt.AgentId = @AgentId
								AND apt.MinPositionTaking <> tpt.MinGivenPT
						)
							BEGIN
								-- Check validate when update main share holder
								SELECT TOP(1) @sportType = tpt.SportType
								FROM @TablePositiongTaking AS tpt														
								WHERE tpt.MinGivenPT NOT BETWEEN 0 AND tpt.MaxGivenPT

								IF @sportType IS NOT NULL 
									BEGIN
										SELECT @ErrCode = 1

										----Message for each sport type	WITH CASE @sportType
										SELECT @ErrMsg	= 'Min Given Position taking invalid range .' + ' (' + dbo.f_Get_SportNameBySporttype(@sportType,@Language) + ')'

										RETURN			
									END
								
								IF EXISTS(
									SELECT TOP(1) *
									FROM AgentPositionTaking AS apt WITH (NOLOCK)
										INNER JOIN @TablePositiongTaking AS tpt 
											ON apt.SportType	= tpt.SportType
											AND apt.BetType		= tpt.BetType
											AND apt.IsLive		= tpt.IsLive
									WHERE apt.AgentId = @AgentId
										AND tpt.MinGivenPT < apt.MinPositionTaking
								)
									BEGIN

										-- Update PT of all direct member of agent
										DELETE @TableCust
										INSERT INTO @TableCust(CustId)
										SELECT ci.CustId
										FROM CustInfo AS ci WITH (NOLOCK)
										WHERE ci.AgentId = @AgentId										
												
										WHILE EXISTS (
											SELECT TOP(1) * FROM @TableCust
										) 
											BEGIN

												SELECT TOP(1) @currentCustId = CustId
												FROM @TableCust
														
												DELETE @TableCustPositionTaking
												INSERT INTO @TableCustPositionTaking(
													SportType
													,BetType
													,IsLive
													,PositionTaking)
												SELECT 
													cpt.SportType
													,cpt.BetType
													,cpt.IsLive
													,tpt.MinGivenPT
												FROM CustPositionTaking AS cpt WITH (ROWLOCK,UPDLOCK)																																
													INNER JOIN @TablePositiongTaking AS tpt
														ON cpt.SportType	= tpt.SportType
														AND cpt.BetType		= tpt.BetType
														AND cpt.IsLive		= tpt.IsLive
												WHERE cpt.AgentId			= @AgentId
													AND cpt.CustId			= @currentCustId
													AND cpt.PositionTaking	< tpt.MinGivenPT																											
												
												-- Update member position taking when member position taking greater
												DELETE @TableStackPositionTaking
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
													INNER JOIN @TableCustPositionTaking AS tcpt
														ON cpt.SportType	= tcpt.SportType
														AND cpt.BetType		= tcpt.BetType
														AND cpt.IsLive		= tcpt.IsLive														
													INNER JOIN AgentInfo AS ai WITH (NOLOCK)
														ON cpt.AgentId = ai.AgentId
												WHERE cpt.CustId = @currentCustId
													AND ai.AgentLevel <= @agentLevel
												ORDER BY ai.AgentLevel

												--SET @index = @agentLevel - 1

												DELETE @TableUpdateCustPositionTaking
												INSERT INTO @TableUpdateCustPositionTaking(
														SportType
														,BetType
														,IsLive
														,PT)
												SELECT 
														tpt.SportType
														,tpt.BetType
														,tpt.IsLive
														,tpt.PositionTaking - cpt.PositionTaking
												FROM @TableCustPositionTaking AS tpt
													INNER JOIN CustPositionTaking AS cpt WITH (NOLOCK)
														ON tpt.SportType	= cpt.SportType
														AND tpt.BetType		= cpt.BetType
														AND tpt.IsLive		= cpt.IsLive														
												WHERE cpt.CustId	= @currentCustId
													AND cpt.AgentId	= @AgentId

												SET @index = @agentLevel - 1
												WHILE @index > 0
													BEGIN
														SELECT TOP(1) @currentAgentId = AgentId
														FROM @TableStackPositionTaking 
														WHERE AgentLevel = @index

														SELECT TOP(1) @childCurrentAgentId = AgentId
														FROM @TableStackPositionTaking 
														WHERE AgentLevel = @index + 1

														UPDATE cpt
														SET cpt.PositionTaking	= CASE WHEN capt.PresetPositionTaking > cpt.PositionTaking - tucpt.PT
																						THEN capt.PresetPositionTaking
																						ELSE cpt.PositionTaking - tucpt.PT
																					END
														FROM CustPositionTaking AS cpt WITH (ROWLOCK,UPDLOCK)
															INNER JOIN @TableCustPositionTaking AS tpt
																ON cpt.SportType	= tpt.SportType
																AND cpt.BetType		= tpt.BetType
																AND cpt.IsLive		= tpt.IsLive																
															INNER JOIN AgentPositionTaking AS capt WITH (NOLOCK)
																ON cpt.SportType	= capt.SportType
																AND cpt.BetType		= capt.BetType	
																AND cpt.IsLive		= capt.IsLive
															INNER JOIN @TableUpdateCustPositionTaking AS tucpt
																ON cpt.SportType	= tucpt.SportType
																AND cpt.BetType		= tucpt.BetType
																AND cpt.IsLive		= tucpt.IsLive
														WHERE cpt.CustId		= @currentCustId
															AND cpt.AgentId		= @currentAgentId
															AND capt.AgentId	= @childCurrentAgentId
															AND capt.PresetPositionTaking < cpt.PositionTaking

														SET @index = 0

														UPDATE tupt
														SET tupt.PT = tupt.PT - (tspt.PT - cpt.PositionTaking)
														FROM @TableUpdateCustPositionTaking AS tupt
															INNER JOIN @TableCustPositionTaking AS tpt
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
															AND cpt.CustId	= @currentCustId
															AND cpt.AgentId	= @currentAgentId
															

														IF EXISTS(
															SELECT TOP(1) * 
															FROM @TableUpdateCustPositionTaking 
															WHERE PT > 0
														)
															BEGIN
											
																-- Remove Sport Type and Bet Type if PT <=0 
																DELETE tpt
																FROM @TableCustPositionTaking AS tpt
																	INNER JOIN @TableUpdateCustPositionTaking AS tupt
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
												-- End update member position taking when member position taking greater					

												-- update direct member

												UPDATE cpt
												SET	cpt.PositionTaking = tcpt.PositionTaking
												FROM CustPositionTaking AS cpt WITH (ROWLOCK,UPDLOCK)																																
													INNER JOIN @TableCustPositionTaking AS tcpt
														ON cpt.SportType	= tcpt.SportType
														AND cpt.BetType		= tcpt.BetType
														AND cpt.IsLive		= tcpt.IsLive
												WHERE cpt.AgentId	= @AgentId
													AND cpt.CustId	= @currentCustId
												
												-- End update direct member

												DELETE @TableCust WHERE CustId = @currentCustId
											END													
									END															 

								-- End update Position Taking of direct member								

								-- Check for update Min Given PT of agent level k
								IF @isLastAgent = 0
									BEGIN																			
										-- If New Min Given PT greater than current Min Position Taking of agent
										IF EXISTS(
											SELECT TOP(1) *
											FROM AgentPositionTaking AS apt WITH (NOLOCK)
												INNER JOIN @TablePositiongTaking AS tpt 
													ON apt.SportType	= tpt.SportType
													AND apt.BetType		= tpt.BetType
													AND apt.IsLive		= tpt.IsLive
											WHERE apt.AgentId = @AgentId
												AND tpt.MinGivenPT > apt.MinPositionTaking
										)
											BEGIN												
												
												-- The same with update Min Given PT of Main ShareHolder
												-- Get all member in downline of agent
												DELETE @TableCust
												INSERT INTO @TableCust(CustId)
												SELECT ci.CustId 
												FROM CustInfo AS ci WITH (NOLOCK)
													INNER JOIN AgentInfo AS ai WITH (NOLOCK)
														ON ci.AgentId = ai.AgentId
												WHERE ai.AgentHId.IsDescendantOf(@agentHId) = 1
													AND ai.AgentId <> @AgentId												
										
												WHILE EXISTS(
													SELECT TOP(1) * FROM @TableCust
												)
													BEGIN
														-- Select current Cust Id
														SELECT TOP(1) @currentCustId = CustId
														FROM @TableCust

														DELETE @TableCustPositionTaking

														INSERT INTO @TableCustPositionTaking(																														
															SportType
															,BetType
															,IsLive
															,PositionTaking)
														SELECT
															cpt.SportType
															,cpt.BetType
															,cpt.IsLive
															,tpt.MinGivenPT - dcpt.SumOfPositionTaking + cpt.PositionTaking
														FROM CustPositionTaking AS cpt WITH (ROWLOCK,UPDLOCK)																					
															INNER JOIN @TablePositiongTaking AS tpt
																ON cpt.SportType	= tpt.SportType
																AND cpt.BetType		= tpt.BetType
																AND cpt.IsLive		= tpt.IsLive
															INNER JOIN (
																SELECT 
																	CustId
																	,SportType
																	,BetType
																	,IsLive
																	,SUM(PositionTaking) AS SumOfPositionTaking
																FROM 
																	CustPositionTaking AS cpt WITH (NOLOCK)	
																	INNER JOIN AgentInfo AS ai WITH (NOLOCK)
																		ON cpt.AgentId	= ai.AgentId															
																WHERE cpt.CustId		= @currentCustId
																	AND ai.AgentLevel	>= @agentLevel		
																GROUP BY CustId, SportType, BetType, IsLive	
															) AS dcpt 
																ON 	cpt.SportType	= dcpt.SportType
																	AND cpt.BetType = dcpt.BetType
																	AND cpt.IsLive	= dcpt.IsLive	
																	AND cpt.CustId	= dcpt.CustId
														WHERE dcpt.SumOfPositionTaking < tpt.MinGivenPT
															AND cpt.AgentId				= @AgentId
															AND cpt.CustId				= @currentCustId
														-- Update member position taking when member position taking greater
														DELETE @TableStackPositionTaking
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
															INNER JOIN @TableCustPositionTaking AS tcpt
																ON cpt.SportType	= tcpt.SportType
																AND cpt.BetType		= tcpt.BetType
																AND cpt.IsLive		= tcpt.IsLive														
															INNER JOIN AgentInfo AS ai WITH (NOLOCK)
																ON cpt.AgentId = ai.AgentId
														WHERE cpt.CustId = @currentCustId
															AND ai.AgentLevel <= @agentLevel
														ORDER BY ai.AgentLevel

														--SET @index = @agentLevel - 1

														DELETE @TableUpdateCustPositionTaking
														INSERT INTO @TableUpdateCustPositionTaking(
																SportType
																,BetType
																,IsLive
																,PT)
														SELECT 
																tpt.SportType
																,tpt.BetType
																,tpt.IsLive
																,tpt.PositionTaking - cpt.PositionTaking
														FROM @TableCustPositionTaking AS tpt
															INNER JOIN CustPositionTaking AS cpt WITH (NOLOCK)
																ON tpt.SportType	= cpt.SportType
																AND tpt.BetType		= cpt.BetType
																AND tpt.IsLive		= cpt.IsLive														
														WHERE cpt.CustId	= @currentCustId
															AND cpt.AgentId	= @AgentId

														SET @index = @agentLevel - 1
														WHILE @index > 0
															BEGIN
																SELECT TOP(1) @currentAgentId = AgentId
																FROM @TableStackPositionTaking 
																WHERE AgentLevel = @index

																SELECT TOP(1) @childCurrentAgentId = AgentId
																FROM @TableStackPositionTaking 
																WHERE AgentLevel = @index + 1

																UPDATE cpt
																SET cpt.PositionTaking	= CASE WHEN capt.PresetPositionTaking > cpt.PositionTaking - tucpt.PT
																								THEN capt.PresetPositionTaking
																								ELSE cpt.PositionTaking - tucpt.PT
																							END
																FROM CustPositionTaking AS cpt WITH (ROWLOCK,UPDLOCK)
																	INNER JOIN @TableCustPositionTaking AS tpt
																		ON cpt.SportType	= tpt.SportType
																		AND cpt.BetType		= tpt.BetType
																		AND cpt.IsLive		= tpt.IsLive																
																	INNER JOIN AgentPositionTaking AS capt WITH (NOLOCK)
																		ON cpt.SportType	= capt.SportType
																		AND cpt.BetType		= capt.BetType	
																		AND cpt.IsLive		= capt.IsLive
																	INNER JOIN @TableUpdateCustPositionTaking AS tucpt
																		ON cpt.SportType	= tucpt.SportType
																		AND cpt.BetType		= tucpt.BetType
																		AND cpt.IsLive		= tucpt.IsLive
																WHERE cpt.CustId		= @currentCustId
																	AND cpt.AgentId		= @currentAgentId
																	AND capt.AgentId	= @childCurrentAgentId
																	AND capt.PresetPositionTaking < cpt.PositionTaking

																SET @index = 0

																UPDATE tupt
																SET tupt.PT = tupt.PT - (tspt.PT - cpt.PositionTaking)
																FROM @TableUpdateCustPositionTaking AS tupt
																	INNER JOIN @TableCustPositionTaking AS tpt
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
																	AND cpt.CustId	= @currentCustId
																	AND cpt.AgentId	= @currentAgentId
															

																IF EXISTS(
																	SELECT TOP(1) * 
																	FROM @TableUpdateCustPositionTaking 
																	WHERE PT > 0
																)
																	BEGIN
											
																		-- Remove Sport Type and Bet Type if PT <=0 
																		DELETE tpt
																		FROM @TableCustPositionTaking AS tpt
																			INNER JOIN @TableUpdateCustPositionTaking AS tupt
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
														-- End update member position taking when member position taking greater

														UPDATE cpt
														SET	cpt.PositionTaking = tcpt.PositionTaking
														FROM CustPositionTaking AS cpt WITH (ROWLOCK,UPDLOCK)																					
															INNER JOIN @TableCustPositionTaking AS tcpt
																ON cpt.SportType	= tcpt.SportType
																AND cpt.BetType		= tcpt.BetType
																AND cpt.IsLive		= tcpt.IsLive
														WHERE cpt.CustId		= @currentCustId
															AND cpt.AgentId		= @AgentId																							
								
														-- Remove cust id
														DELETE @TableCust WHERE CustId = @currentCustId
													END
												 -- End the same with update Min Given PT of Main ShareHolder
											END
										-- End if New Min Given PT greater than current Min Position Taking of agent
										
										-- If New Min Given PT less than current Min Position Taking of agent
										IF EXISTS(
											SELECT TOP(1) *
											FROM AgentPositionTaking AS apt WITH (NOLOCK)
												INNER JOIN @TablePositiongTaking AS tpt 
													ON apt.SportType	= tpt.SportType
													AND apt.BetType		= tpt.BetType
													AND apt.IsLive		= tpt.IsLive
											WHERE apt.AgentId = @AgentId
												AND tpt.MinGivenPT < apt.MinPositionTaking
										)
											BEGIN												

												-- Get all member in downline of agent
												DELETE @TableCust
												INSERT INTO @TableCust(CustId)
												SELECT ci.CustId 
												FROM CustInfo AS ci WITH (NOLOCK)
													INNER JOIN AgentInfo AS ai WITH (NOLOCK)
														ON ci.AgentId = ai.AgentId
												WHERE ai.AgentHId.IsDescendantOf(@agentHId) = 1
													AND ai.AgentId <> @AgentId	

												WHILE EXISTS(
													SELECT TOP(1) * FROM @TableCust
												)
													BEGIN
														-- Select current Cust Id
														SELECT TOP(1) @currentCustId = CustId
														FROM @TableCust																										

														DECLARE @TableCustAgent TABLE(CustId INT, AgentId INT,AgentLevel INT)																												
														
														
														INSERT INTO @TableCustAgent(CustId, AgentId,AgentLevel)
														SELECT DISTINCT 
																	cpt.CustId
																	,ai.AgentId 
																	,ai.AgentLevel			
														FROM CustPositionTaking AS cpt WITH (NOLOCK)	
															INNER JOIN AgentInfo AS ai WITH (NOLOCK)
																ON cpt.AgentId = ai.AgentId																		
														WHERE cpt.AgentId IN (	SELECT dai.AgentId 
																				FROM AgentInfo AS dai WITH (NOLOCK)
																				WHERE dai.ParentId = @AgentId
																				)																
																AND cpt.CustId = @currentCustId
														ORDER BY ai.AgentLevel


														SELECT TOP(1) @tempAgentId = AgentId FROM @TableCustAgent

														DELETE @TableCustPositionTaking
														INSERT INTO @TableCustPositionTaking(
															CustId																														
															,SportType
															,BetType
															,IsLive
															,PositionTaking)
														SELECT 
															cpt.CustId
															,cpt.SportType
															,cpt.BetType
															,cpt.IsLive
															,CASE WHEN capt.PresetPositionTaking > tpt.MinGivenPT - dcpt.SumOfPositionTaking
																THEN capt.PresetPositionTaking
																ELSE tpt.MinGivenPT - dcpt.SumOfPositionTaking																			
															END
														FROM CustPositionTaking AS cpt WITH (NOLOCK)
															INNER JOIN @TablePositiongTaking AS tpt
																 ON cpt.SportType	= tpt.SportType
																 AND cpt.BetType	= tpt.BetType
																 AND cpt.IsLive		= tpt.IsLive															
															INNER JOIN AgentPositionTaking AS capt WITH (NOLOCK)
																ON cpt.SportType	= capt.SportType
																 AND cpt.BetType	= capt.BetType
																 AND cpt.IsLive		= capt.IsLive
															INNER JOIN (
																SELECT 
																	CustId
																	,SportType
																	,BetType
																	,IsLive
																	,SUM(PositionTaking) AS SumOfPositionTaking
																FROM 
																	CustPositionTaking AS cpt WITH (NOLOCK)															
																	INNER JOIN AgentInfo AS ai WITH (NOLOCK)
																		ON cpt.AgentId	= ai.AgentId
																	WHERE cpt.CustId		= @currentCustId
																		AND ai.AgentLevel	> @agentLevel
																GROUP BY CustId, SportType, BetType, IsLive	
															) AS dcpt 
																ON 	cpt.SportType	= dcpt.SportType
																	AND cpt.BetType = dcpt.BetType
																	AND cpt.IsLive	= dcpt.IsLive
																	AND cpt.CustId  = dcpt.CustId
														WHERE cpt.AgentId			= @AgentId
															AND cpt.CustId			= @currentCustId
															AND capt.AgentId		= @tempAgentId
															AND cpt.PositionTaking	> capt.PresetPositionTaking


														UPDATE cpt	
														SET cpt.PositionTaking = tcpt.PositionTaking	
														FROM CustPositionTaking AS cpt WITH (NOLOCK)
															INNER JOIN @TableCustPositionTaking AS tcpt
																 ON cpt.SportType	= tcpt.SportType
																 AND cpt.BetType	= tcpt.BetType
																 AND cpt.IsLive		= tcpt.IsLive															
														WHERE cpt.AgentId	= @AgentId
															AND cpt.CustId	= @currentCustId														

														IF EXISTS(
															SELECT TOP(1) * FROM @TableCustPositionTaking
														)
															BEGIN														
																-- Edit Position Taking of member
																DELETE @TableStackPositionTaking
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
															INNER JOIN @TableCustPositionTaking AS tcpt
																ON cpt.SportType	= tcpt.SportType
																AND cpt.BetType		= tcpt.BetType
																AND cpt.IsLive		= tcpt.IsLive
																AND cpt.CustId		= tcpt.CustId
															INNER JOIN AgentInfo AS ai WITH (NOLOCK)
																ON cpt.AgentId = ai.AgentId
														WHERE cpt.CustId	= @currentCustId
															AND ai.AgentLevel <= @agentLevel
														ORDER BY ai.AgentLevel
															
																SET @index = @agentLevel - 1
																WHILE @index > 0
																																																																																																																																																			BEGIN
									
																SELECT TOP(1) @currentAgentId = AgentId
																FROM @TableStackPositionTaking 
																WHERE AgentLevel = @index

																DELETE @TableUpdateCustPositionTaking
																INSERT INTO @TableUpdateCustPositionTaking(
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
																	INNER JOIN @TableCustPositionTaking AS tcpt 
																		ON cpt.SportType	= tcpt.SportType
																		AND cpt.BetType		= tcpt.BetType
																		AND cpt.IsLive		= tcpt.IsLive
																		AND cpt.CustId		= tcpt.CustId
																WHERE cpt.CustId = @currentCustId
																	AND ai.AgentLevel >= @index
																GROUP BY cpt.SportType
																		,cpt.BetType
																		,cpt.IsLive																

																IF EXISTS(
																	SELECT TOP(1) *
																	FROM @TableUpdateCustPositionTaking AS tucpt
																		INNER JOIN AgentPositionTaking AS apt WITH (NOLOCK)
																			ON tucpt.SportType	= apt.SportType
																			AND tucpt.BetType	= apt.BetType
																			AND tucpt.IsLive	= apt.IsLive
																	WHERE apt.AgentId = @currentAgentId
																		AND tucpt.PT >= apt.MinPositionTaking
																)
																	BEGIN
																		SET @index = @index - 1
																	END
																ELSE
																	BEGIN
																		UPDATE cpt
																		SET cpt.PositionTaking = apt.MinPositionTaking - tucpt.PT + cpt.PositionTaking
																		FROM CustPositionTaking AS cpt WITH (ROWLOCK,UPDLOCK)
																			INNER JOIN @TableCustPositionTaking AS tcpt
																				ON cpt.SportType	= tcpt.SportType
																				AND cpt.BetType		= tcpt.BetType
																				AND cpt.IsLive		= tcpt.IsLive
																				AND cpt.CustId		= tcpt.CustId
																			INNER JOIN @TableUpdateCustPositionTaking AS tucpt
																				ON cpt.SportType	= tucpt.SportType
																				AND cpt.BetType		= tucpt.BetType
																				AND cpt.IsLive		= tucpt.IsLive
																			INNER JOIN AgentPositionTaking AS apt WITH (NOLOCK)
																				ON cpt.SportType	= apt.SportType
																				AND cpt.BetType		= apt.BetType
																				AND cpt.IsLive		= apt.IsLive													
																		WHERE cpt.CustId = @currentCustId
																			AND cpt.AgentId = @currentAgentId
																			AND apt.AgentId	= @currentAgentId

																		SET @index = 0 
																	END	 
															END
																-- End edit positin taking of member
															END
														
														-- Remove cust id
														DELETE @TableCust WHERE CustId = @currentCustId
													END												
											END
										-- End if New Min Given PT less than current Min Position Taking of agent 

									END
								-- End check for update Min Given PT of agent level k

								-- Update Min Given PT
								UPDATE apt
								SET apt.MinPositionTaking	= tpt.MinGivenPT
								FROM AgentPositionTaking AS apt WITH (ROWLOCK,UPDLOCK)
									INNER JOIN @TablePositiongTaking AS tpt
										ON tpt.SportType	= apt.SportType
										AND tpt.BetType		= apt.BetType
										AND tpt.IsLive		= apt.IsLive
								WHERE apt.AgentId = @AgentId

								-- End update Min Given PT
							END
						-- End edit Min Given PT
					END
				-- End edit Agent with level k ( k > 1)

				-- write log before update
				
				SET @xml = (
					SELECT  
						tpt.SportType				AS '@s'
						,tpt.BetType				AS '@b'
						,tpt.IsLive					AS '@i'
						,tpt.MaxUpperPT				AS '@p'
						,tpt.MaxGivenPT				AS '@ma'
						,tpt.MinGivenPT				AS '@mi'
					FROM @TablePositiongTaking AS tpt							
					FOR XML PATH('z'), ROOT('r')
				)

				SET @logSPData = REPLACE(CONVERT(varchar(max), @xml), '" />', '"/"')

				-- end write log

				
				SET @endRun		= GETDATE()  
				SET @duration	= DATEDIFF(millisecond, @startRun, @endRun) 

				IF @LogDate IS NULL
					SET @LogDate = GETDATE()				

				EXEC LogDB.dbo.Age_LogRunSp_Insert
					@UserId			= @ActorAgentId,
					@SPName			= 'Age_Agent_UpdatePositionTaking',
					@LogDate		= @LogDate,
					@ObjectId		= @AgentId,
					@ObjectTypeId	= 1,			--Object type : Agent						
					@Duration		= @Duration,
					@Data			= @logSPData,
					@OldData		= @logSPDataOld
			END
					-- End update new position taking if had changed
	END
	-- end update
END	