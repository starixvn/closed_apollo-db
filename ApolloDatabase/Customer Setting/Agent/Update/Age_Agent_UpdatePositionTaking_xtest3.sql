USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_Agent_UpdatePositionTaking_xtest3]    Script Date: 9/20/2013 4:52:40 PM ******/
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
							<PositionTaking SportType="1" BetType="1" IsLive="0" MaxUpper="122" MaxGiven="7761" MinGiven="0"></PositionTaking>
							<PositionTaking SportType="1" BetType="1" IsLive="1" MaxUpper="122" MaxGiven="7962" MinGiven="0"></PositionTaking>
						</ROOT>',
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT

SELECT	@ErrCode as N'@ErrCode',
		@ErrMsg as N'@ErrMsg'


SELECT	'Return Value' = @return_value

GO

*/
ALTER PROCEDURE [dbo].[Age_Agent_UpdatePositionTaking_xtest3]
	@ActorAgentId			INT				= NULL,
	@AdminId				INT				= NULL,
	@AgentId				INT,
	@PositionTaking			VARCHAR(MAX)	= '',	
	@MemberPositionTaking	VARCHAR(MAX)	= '',	
	@Language				VARCHAR(5)		= 'en-US',	
	@ErrCode				INT				= 0			OUTPUT,
	@ErrMsg					NVARCHAR(1000)	= ''		OUTPUT
AS

/**
 * Created by	: Edward
 * Date			: 20130410
 * Task			: Update agent position taking
 * DB			: SVRCUST.CustDB
 * Revisions	:
 *	• 20131707@Edward	: Add parameter @AdminId for write log
 *	•  20132808@Edward	: Add parameter @MemberPositionTaking for apply preset to all member
 * Parameters:
 *	@PositionTaking :
		<ROOT>
		<PositionTaking SportType="1" BetType="1" IsLive="0" MaxUpper="122" MaxGiven="7761" MinGiven="0"></PositionTaking>
		</ROOT>		
 *  
 */

BEGIN
	
	SET NOCOUNT ON
	
	-- Check update permission
	DECLARE @hasPermission BIT

	EXEC dbo.Age_Agent_CheckUpdatePermission 
		@ActorAgentId,
		@AgentId,
		1,				-- Is Agent
		@hasPermission OUTPUT 
	
	IF @hasPermission = 0
		BEGIN
			SELECT 
				@ErrCode = 1000,
				@ErrMsg	= 
					CASE @Language
						WHEN 'en-US' THEN 'You do not have permission to update setting'
						ELSE [dbo].f_Msg_GetContentById (1000, @Language)
					END

			RETURN
		END
		
	-- For write log
	DECLARE 
		@startRun		DATETIME,
		@endRun			DATETIME,
		@duration		INT,
		@logSPData		VARCHAR(5000),
		@logSPDataOld	VARCHAR(5000),
		@xml			XML

	SET @startRun = GETDATE()
	
	IF @PositionTaking <> ''
		BEGIN
			-- For read xml
			DECLARE @DocHandler INT

			-- Store new position taking of agent
			CREATE TABLE #TablePositionTaking (
				SportType	SMALLINT,
				BetType		SMALLINT,
				IsLive		BIT,
				MaxUpperPT	SMALLINT,
				MaxGivenPT	SMALLINT,
				MinGivenPT	SMALLINT,
				IsApply		BIT)

			-- write log before update
			SET @xml = (
				SELECT  
					SportType				AS '@s'
					,BetType				AS '@b'
					,IsLive					AS '@i'
					,MaxUpperPositionTaking	AS '@p'
					,MaxGivenPositionTaking	AS '@ma'
					,MinGivenPositionTaking	AS '@mi'
					,0						AS '@ia'
				FROM AgentPositionTaking WITH (NOLOCK)							
				WHERE AgentId = @AgentId	
				FOR XML PATH('z'), ROOT('r')
			)

			SET @logSPDataOld = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

			-- end write log before update

			-- Declare variable
			DECLARE 
				@agentHId			HIERARCHYID
				,@parentAgentId		INT
				,@agentLevel		SMALLINT
				,@sportType			SMALLINT
				,@betType			SMALLINT
				,@isLive			BIT
				,@tempAgentId		INT
				,@tempUsername		NVARCHAR(50)
				,@isLastAgent		BIT
				,@currentCustId		INT
				,@data				VARCHAR(MAX)
				,@tempLevel			INT

			---- Declare agentId
			DECLARE 
				@agentParentLevel		SMALLINT
				,@agentParentHId		HIERARCHYID
				,@parentOfParentAgentId	INT
				,@currentAgentId		INT
				,@childCurrentAgentId	INT
			---- End declare					

			-- Declare constant
			DECLARE	
				@MAINSHAREHOLDERLEVEL	SMALLINT	= 1
				,@SHAREHOLDERLEVEL		SMALLINT	= 2
				,@MAINAGENTLEVEL		SMALLINT	= 3
				,@MAXPT					SMALLINT	= 10000
				,@MAXSHAREHOLDERPT		SMALLINT	= 10000
				,@MINSHAREMUSTCOVER		SMALLINT	= 5000

			-- Select for current Agent
			SELECT 
				@agentLevel		= AgentLevel
				,@agentHId		= AgentHId
				,@parentAgentId = ParentId
			FROM AgentInfo WITH (NOLOCK)
			WHERE AgentId = @AgentId

			-- Select for parent
			SELECT 
				@agentParentLevel		= AgentLevel
				,@agentParentHId		= AgentHId
				,@parentOfParentAgentId = ParentId
			FROM AgentInfo WITH (NOLOCK)
			WHERE AgentId = @parentAgentId
			---- End set value

			-- begin update	
			IF @PositionTaking <> ''
			BEGIN					
				-- Check current agent is last agent ?
				IF EXISTS ( SELECT 1 FROM AgentInfo WITH (NOLOCK) WHERE ParentId = @AgentId )
					SET @isLastAgent = 0
				ELSE
					SET @isLastAgent = 1					
		
				DECLARE @TableUpdatePositionTaking TABLE (
					SportType	SMALLINT,
					BetType		SMALLINT,
					IsLive		BIT,
					MaxUpperPT	SMALLINT,
					MaxGivenPT	SMALLINT,
					MinGivenPT	SMALLINT)		
					
				DECLARE @TableChildAgent TABLE (AgentId INT)  																  						

				-- For read xml					
				EXEC sp_xml_preparedocument @DocHandler OUTPUT, @PositionTaking

				INSERT INTO #TablePositionTaking(
					SportType,
					BetType,
					IsLive,
					MaxUpperPT,
					MaxGivenPT,
					MinGivenPT,
					IsApply)
				SELECT
					Data.SportType,
					Data.BetType,
					Data.IsLive,
					Data.MaxUpper,
					Data.MaxGiven,
					Data.MinGiven,
					1
				FROM OPENXML (@DocHandler, '/ROOT/PositionTaking',1) 
				WITH (
					SportType	SMALLINT,
					BetType		SMALLINT,
					IsLive		BIT,
					MaxUpper	SMALLINT,
					MaxGiven	SMALLINT,
					MinGiven	SMALLINT
				) AS Data

				EXEC sp_xml_removedocument @DocHandler
				-- end read xml	

				-- Check validate max and min
				SELECT TOP(1) 
					@sportType	= SportType
					,@betType	= BetType
					,@isLive	= IsLive
				FROM #TablePositionTaking
				WHERE MinGivenPT	< 0
					OR MaxGivenPT	< 0
					OR MaxUpperPT	< 0 

				IF @sportType IS NOT NULL 
				BEGIN
					SELECT 
						@ErrCode = 4002,
						@ErrMsg	= 
							CASE @Language
								WHEN 'en-US' THEN '% Share must be equal or greater than zero' 
								ELSE [dbo].f_Msg_GetContentById (4002, @Language)
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

				-- Check validate max and min
				SELECT TOP(1) 
					@sportType	= SportType
					,@betType	= BetType
					,@isLive	= IsLive
				FROM #TablePositionTaking
				WHERE MinGivenPT > MaxGivenPT

				IF @sportType IS NOT NULL 
				BEGIN
					SELECT 
						@ErrCode = 4003,
						@ErrMsg	= 
							CASE @Language
								WHEN 'en-US' THEN '% Min Downline must be equal to or less than % Max Downline' 
								ELSE [dbo].f_Msg_GetContentById (4003, @Language)
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

				SELECT TOP(1) 
					@sportType		= tpt.SportType
					,@tempAgentId	= apt.AgentId
					,@betType		= tpt.BetType
					,@isLive		= tpt.IsLive
				FROM #TablePositionTaking AS tpt
					INNER JOIN AgentPositionTaking AS apt WITH (NOLOCK)
						ON apt.SportType	= tpt.SportType
						AND apt.BetType		= tpt.BetType
						AND apt.IsLive		= tpt.IsLive				
				WHERE tpt.MaxUpperPT + tpt.MaxGivenPT > apt.MaxGivenPositionTaking
					AND apt.AgentId = @parentAgentId

				SELECT @tempUsername = Username 
				FROM AgentInfo WITH (NOLOCK)
				WHERE AgentId = @tempAgentId

				IF @sportType IS NOT NULL 
				BEGIN
					SELECT 
						@ErrCode = 4001,
						@ErrMsg	= 
							CASE @Language
								WHEN 'en-US' THEN 'Sum % Preset and % Max Downline must be equal or less than % Max Downline of Parent Agent' 
								ELSE [dbo].f_Msg_GetContentById (4001, @Language)
							END + ' ('+ @tempUsername +')' 
								+ ' (' 
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
		
				SELECT TOP(1) 
					@sportType	= tpt.SportType
					,@betType	= tpt.BetType
					,@isLive	= tpt.IsLive
				FROM 
					#TablePositionTaking AS tpt
					INNER JOIN AgentPositionTaking AS papt WITH (NOLOCK)
						ON tpt.SportType	= papt.SportType
						AND tpt.BetType		= papt.BetType
						AND tpt.IsLive		= papt.IsLive
				WHERE 
					papt.AgentId = @parentAgentId
					AND tpt.MaxUpperPT NOT BETWEEN CASE WHEN papt.MinGivenPositionTaking - tpt.MaxGivenPT > 0 
														THEN papt.MinGivenPositionTaking - tpt.MaxGivenPT
														ELSE 0
													END AND papt.MaxGivenPositionTaking - tpt.MaxGivenPT

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

				SELECT TOP(1) 
					@sportType	= tpt.SportType
					,@betType	= tpt.BetType
					,@isLive	= tpt.IsLive
				FROM #TablePositionTaking AS tpt					
				WHERE (@agentLevel < @SHAREHOLDERLEVEL AND tpt.MaxGivenPT	< @MINSHAREMUSTCOVER)
						OR( @agentLevel			= @SHAREHOLDERLEVEL
							AND (tpt.MaxGivenPT	< @MINSHAREMUSTCOVER					   
							OR tpt.MinGivenPT	< @MINSHAREMUSTCOVER ))

				IF @sportType IS NOT NULL 
				BEGIN
					SELECT 
						@ErrCode	= 4010,
						@ErrMsg		= 
							CASE @Language
								WHEN 'en-US' THEN 'Invalid % share' 
								ELSE [dbo].f_Msg_GetContentById (4010, @Language)
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

				-- Update new position taking if had changed
				IF EXISTS (	SELECT 1
							FROM AgentPositionTaking AS apt WITH (NOLOCK)
								INNER JOIN #TablePositionTaking AS tpt
									ON tpt.SportType	= apt.SportType
									AND tpt.BetType		= apt.BetType
									AND tpt.IsLive		= apt.IsLive
							WHERE apt.AgentId = @AgentId
								AND (apt.MaxUpperPositionTaking		<> tpt.MaxUpperPT
										OR apt.MaxGivenPositionTaking	<> tpt.MaxGivenPT
										OR apt.MinGivenPositionTaking	<> tpt.MinGivenPT ) )
				BEGIN				

					INSERT INTO @TableChildAgent (AgentId)
					SELECT AgentId
					FROM AgentInfo WITH (NOLOCK)
					WHERE ParentId = @AgentId

					-- Get data for all line
					CREATE TABLE #TableAllLinePositionTaking (
						AgentId						INT
						,ParentAgentId				INT
						,ParentAgentLevel			SMALLINT
						,SportType					SMALLINT
						,BetType					SMALLINT
						,IsLive						BIT
						,MaxUpperPositionTaking		SMALLINT
						,MaxGivenPositionTaking		SMALLINT
						,MinGivenPositionTaking		SMALLINT
						,PositionTaking				SMALLINT
						,SumPresetDown				INT
						,DeltaMinSumDown			SMALLINT
						,MaxDeltaDown				SMALLINT
						,MemPositionTaking			SMALLINT
						,NewMaxUpperPositionTaking	SMALLINT
						,NewMaxGivenPositionTaking	SMALLINT
						,NewMinGivenPositionTaking	SMALLINT
						,NewPositionTaking			SMALLINT
						,NewSumPresetDown			INT
						,NewMemPositionTaking		SMALLINT
						,NewDeltaMinSumDown			SMALLINT
						,NewMaxDeltaDown			SMALLINT
					)

					CREATE CLUSTERED INDEX IX_C_#TableAllLinePositionTaking ON #TableAllLinePositionTaking (AgentId, ParentAgentId, ParentAgentLevel, SportType, BetType, IsLive) 

					INSERT INTO #TableAllLinePositionTaking(
						AgentId
						,ParentAgentId
						,ParentAgentLevel
						,SportType
						,BetType
						,IsLive
						,MaxUpperPositionTaking
						,MaxGivenPositionTaking
						,MinGivenPositionTaking
						,PositionTaking
						,SumPresetDown
						,MemPositionTaking
						,DeltaMinSumDown
						,MaxDeltaDown
						,NewMaxUpperPositionTaking
						,NewMaxGivenPositionTaking
						,NewMinGivenPositionTaking
						,NewPositionTaking
						,NewSumPresetDown
						,NewMemPositionTaking
						,NewDeltaMinSumDown
						,NewMaxDeltaDown
					)
					SELECT ai.AgentId
							,pai.AgentId
							,pai.AgentLevel
							,apt.SportType
							,apt.BetType
							,apt.IsLive
							,apt.MaxUpperPositionTaking
							,apt.MaxGivenPositionTaking
							,apt.MinGivenPositionTaking				
							,0
							,0
							,0
							,0
							,0
							,CASE WHEN pai.AgentId = @AgentId THEN tpt.MaxUpperPT ELSE apt.MaxUpperPositionTaking END
							,CASE WHEN pai.AgentId = @AgentId THEN tpt.MaxGivenPT ELSE apt.MaxGivenPositionTaking END
							,CASE WHEN pai.AgentId = @AgentId THEN tpt.MinGivenPT ELSE apt.MinGivenPositionTaking END
							,0
							,0
							,0
							,0
							,0
					FROM AgentInfo AS ai WITH (NOLOCK)
						INNER JOIN AgentInfo AS pai WITH (NOLOCK)
							ON ai.AgentHId.IsDescendantOf(pai.AgentHId) = 1	 	
							AND pai.AgentLevel	> 0
						INNER JOIN AgentPositionTaking AS apt WITH (NOLOCK)
							ON pai.AgentId	= apt.AgentId	
						INNER JOIN #TablePositionTaking AS tpt
							ON apt.SportType	= tpt.SportType
							AND apt.BetType		= tpt.BetType
							AND apt.IsLive		= tpt.IsLive
					WHERE ai.AgentHId.IsDescendantOf(@agentHId) = 1	 
						AND EXISTS (SELECT TOP(1) * FROM CustInfo AS ci WITH (NOLOCK) WHERE ci.AgentId = ai.AgentId)

					-- End get date for all line

					-- Edit Main Share Holder Position Taking
					IF @agentLevel = @MAINSHAREHOLDERLEVEL
					BEGIN
						-- If Max Given PT change
						IF EXISTS(	SELECT 1
									FROM AgentPositionTaking AS apt WITH (NOLOCK)
										INNER JOIN #TablePositionTaking AS tpt
											ON tpt.SportType	= apt.SportType
											AND tpt.BetType		= apt.BetType
											AND tpt.IsLive		= apt.IsLive
									WHERE apt.AgentId = @AgentId
										AND apt.MaxGivenPositionTaking	<> tpt.MaxGivenPT )
						BEGIN
							-- Check validate when update main share holder

							-- Max given position taking must be MinGivenPT < MaxGivenPT < @MAXSHAREHOLDERPT
							SELECT TOP(1) 
								@sportType	= SportType
								,@betType	= BetType
								,@isLive	= IsLive
							FROM #TablePositionTaking
							WHERE MaxGivenPT NOT BETWEEN MinGivenPT AND @MAXSHAREHOLDERPT

							IF @sportType IS NOT NULL 
							BEGIN
								SELECT 
									@ErrCode = 4004,
									@ErrMsg	= 
										CASE @Language
											WHEN 'en-US' THEN '% Max Downline must be equal to or less than 100%' 
											ELSE [dbo].f_Msg_GetContentById (4004, @Language)
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

							-- Max given position taking must be greater or equal Max[Sum(PreK+MaxK)]
							SELECT TOP(1) 
								@sportType	= tpt.SportType
								,@betType	= tpt.BetType
								,@isLive	= tpt.IsLive
							FROM #TablePositionTaking AS tpt
								INNER JOIN (
									SELECT 
										AgentId
										,SportType
										,BetType
										,IsLive												
										,MaxUpperPositionTaking + MaxGivenPositionTaking AS SumMaxUpperAndGiven
									FROM AgentPositionTaking WITH (NOLOCK)
									WHERE AgentId IN ( SELECT AgentId FROM @TableChildAgent)
								) AS shareHolderTemp
									ON tpt.SportType	= shareHolderTemp.SportType
									AND tpt.BetType		= shareHolderTemp.BetType
									AND tpt.IsLive		= shareHolderTemp.IsLive
							WHERE tpt.MaxGivenPT < shareHolderTemp.SumMaxUpperAndGiven
									  
							IF @sportType IS NOT NULL 
							BEGIN
								SELECT 
									@ErrCode	= 4006,
									@ErrMsg		= 
										CASE @Language
											WHEN 'en-US' THEN 'Invalid % Max Downline range' 
											ELSE [dbo].f_Msg_GetContentById (4006, @Language)
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
							-- End check validate when update main share holder

							-- Begin update
							UPDATE apt
							SET apt.MaxGivenPositionTaking		= tpt.MaxGivenPT
								,apt.MaxUpperPositionTaking		= @MAXPT - tpt.MaxGivenPT 
							FROM AgentPositionTaking AS apt WITH (ROWLOCK,UPDLOCK)
								INNER JOIN #TablePositionTaking AS tpt
									ON apt.SportType	= tpt.SportType
									AND apt.BetType		= tpt.BetType
									AND apt.IsLive		= tpt.IsLive
							WHERE apt.AgentId = @AgentId
							-- End update
						END
						-- End update Max Given PT

						-- If Min Given PT change
						IF EXISTS (	SELECT 1
								FROM AgentPositionTaking AS apt WITH (NOLOCK)
									INNER JOIN #TablePositionTaking AS tpt
										ON tpt.SportType	= apt.SportType
										AND tpt.BetType		= apt.BetType
										AND tpt.IsLive		= apt.IsLive
								WHERE apt.AgentId = @AgentId
									AND apt.MinGivenPositionTaking	<> tpt.MinGivenPT )
						BEGIN
																	
							UPDATE apt
							SET apt.MinGivenPositionTaking	= tpt.MinGivenPT
							FROM AgentPositionTaking AS apt WITH (ROWLOCK, UPDLOCK)
								INNER JOIN #TablePositionTaking AS tpt
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
						
						--(1)-- Edit Max Upper PT
						IF EXISTS (	SELECT 1
									FROM AgentPositionTaking AS apt WITH (NOLOCK)
										INNER JOIN #TablePositionTaking AS tpt
											ON tpt.SportType	= apt.SportType
											AND tpt.BetType		= apt.BetType
											AND tpt.IsLive		= apt.IsLive
									WHERE apt.AgentId = @AgentId
										AND apt.MaxUpperPositionTaking	<> tpt.MaxUpperPT )
						BEGIN											
											
							-- Update Max Upper PT
							UPDATE apt
							SET apt.MaxUpperPositionTaking	= tpt.MaxUpperPT
							FROM AgentPositionTaking AS apt WITH (ROWLOCK, UPDLOCK)
								INNER JOIN #TablePositionTaking AS tpt
									ON apt.SportType	= tpt.SportType
									AND apt.BetType		= tpt.BetType
									AND apt.IsLive		= tpt.IsLive
							WHERE apt.AgentId = @AgentId 
						END
						--(1)-- End edit Max Upper PT	

						--(3)-- Edit Min Given PT
						IF EXISTS (	SELECT 1
									FROM AgentPositionTaking AS apt WITH (NOLOCK)
										INNER JOIN #TablePositionTaking AS tpt
											ON tpt.SportType	= apt.SportType
											AND tpt.BetType		= apt.BetType
											AND tpt.IsLive		= apt.IsLive
									WHERE apt.AgentId = @AgentId
										AND apt.MinGivenPositionTaking <> tpt.MinGivenPT )
						BEGIN									

							-- Update Min Given PT
							UPDATE apt
							SET apt.MinGivenPositionTaking	= tpt.MinGivenPT
							FROM AgentPositionTaking AS apt WITH (ROWLOCK, UPDLOCK)
								INNER JOIN #TablePositionTaking AS tpt
									ON tpt.SportType	= apt.SportType
									AND tpt.BetType		= apt.BetType
									AND tpt.IsLive		= apt.IsLive
							WHERE apt.AgentId = @AgentId

							-- End update Min Given PT
						END
						--(3)-- End edit Min Given PT
						
						--(2)-- Edit Max Given PT
						IF EXISTS (	SELECT 1
									FROM AgentPositionTaking AS apt WITH (NOLOCK)
										INNER JOIN #TablePositionTaking AS tpt
											ON tpt.SportType	= apt.SportType
											AND tpt.BetType		= apt.BetType
											AND tpt.IsLive		= apt.IsLive
									WHERE apt.AgentId			= @AgentId
										AND apt.MaxGivenPositionTaking	<> tpt.MaxGivenPT )
						BEGIN								
											
							-- Update Max Given PT
							UPDATE apt
							SET apt.MaxGivenPositionTaking = tpt.MaxGivenPT
							FROM AgentPositionTaking AS apt WITH (ROWLOCK, UPDLOCK)
								INNER JOIN #TablePositionTaking AS tpt
									ON tpt.SportType	= apt.SportType
									AND tpt.BetType		= apt.BetType
									AND tpt.IsLive		= apt.IsLive
							WHERE apt.AgentId = @AgentId
							-- End update Max Given PT
											
							-- End update Max Given PT		
						END
						--(2)-- End edit Max Given PT																																
					END
					-- End edit Agent with level k ( k > 1)			
					
					-- Edit position taking on member				  					

					UPDATE pt
					SET pt.PositionTaking		= ISNULL(pt1.MaxUpperPositionTaking,pt.MaxGivenPositionTaking)	
						,pt.NewPositionTaking	= ISNULL(pt1.NewMaxUpperPositionTaking,pt.NewMaxGivenPositionTaking)	
					FROM #TableAllLinePositionTaking AS pt 
						LEFT JOIN #TableAllLinePositionTaking AS pt1 
							ON pt.AgentId			= pt1.AgentId
							AND pt.ParentAgentLevel	= pt1.ParentAgentLevel - 1
							AND pt.SportType		= pt1.SportType
							AND pt.BetType			= pt1.BetType
							AND pt.IsLive			= pt1.IsLive
		
					UPDATE pt
					SET pt.SumPresetDown			= temp.SumPresetDownLine	
						,pt.NewSumPresetDown		= temp.NewPresetSumDownLine	
					FROM #TableAllLinePositionTaking AS pt
						INNER JOIN (
							SELECT 	
									pt.AgentId
									,pt.ParentAgentId
									,pt.SportType
									,pt.BetType
									,pt.IsLive
									,SUM(ISNULL(pt1.PositionTaking,0))		AS SumPresetDownLine
									,SUM(ISNULL(pt1.NewPositionTaking,0))	AS NewPresetSumDownLine
							FROM #TableAllLinePositionTaking AS pt 
								LEFT JOIN #TableAllLinePositionTaking AS pt1 
									ON pt.AgentId			= pt1.AgentId
									AND pt.ParentAgentLevel	<= pt1.ParentAgentLevel
									AND pt.SportType		= pt1.SportType
									AND pt.BetType			= pt1.BetType
									AND pt.IsLive			= pt1.IsLive
							GROUP BY pt.AgentId	 
									,pt.ParentAgentId
									,pt.SportType
									,pt.BetType
									,pt.IsLive
						) AS temp
							ON pt.AgentId			= temp.AgentId
							AND pt.ParentAgentId	= temp.ParentAgentId
							AND pt.SportType		= temp.SportType
							AND pt.BetType			= temp.BetType
							AND pt.IsLive			= temp.IsLive

					UPDATE #TableAllLinePositionTaking 
					SET DeltaMinSumdown		= MinGivenPositionTaking	- SumPresetDown
						,NewDeltaMinSumDown = NewMinGivenPositionTaking	- NewSumPresetDown

					UPDATE pt
					SET pt.MaxDeltaDown			= CASE WHEN temp.MaxDeltaDownline < 0 THEN 0 ELSE temp.MaxDeltaDownline END	
						,pt.NewMaxDeltaDown		= CASE WHEN temp.NewMaxDeltaDownline < 0 THEN 0 ELSE temp.NewMaxDeltaDownline END							
					FROM #TableAllLinePositionTaking AS pt
						INNER JOIN (
							SELECT 	
									pt.AgentId
									,pt.ParentAgentId
									,pt.SportType
									,pt.BetType
									,pt.IsLive
									,MAX(ISNULL(pt1.DeltaMinSumDown,0))		AS MaxDeltaDownline
									,MAX(ISNULL(pt1.NewDeltaMinSumDown,0))	AS NewMaxDeltaDownline
							FROM #TableAllLinePositionTaking AS pt 
								LEFT JOIN #TableAllLinePositionTaking AS pt1 
									ON pt.AgentId			= pt1.AgentId
									AND pt.ParentAgentLevel	< pt1.ParentAgentLevel
									AND pt.SportType		= pt1.SportType
									AND pt.BetType			= pt1.BetType
									AND pt.IsLive			= pt1.IsLive
							GROUP BY pt.AgentId	 
									,pt.ParentAgentId
									,pt.SportType
									,pt.BetType
									,pt.IsLive
						) AS temp
							ON pt.AgentId			= temp.AgentId
							AND pt.ParentAgentId	= temp.ParentAgentId
							AND pt.SportType		= temp.SportType
							AND pt.BetType			= temp.BetType
							AND pt.IsLive			= temp.IsLive

					UPDATE pt
					SET pt.MemPositionTaking		= CASE WHEN pt.MinGivenPositionTaking - (pt.SumPresetDown + pt.MaxDeltaDown) + pt.PositionTaking > pt.PositionTaking 
															THEN pt.MinGivenPositionTaking - (pt.SumPresetDown + pt.MaxDeltaDown) + pt.PositionTaking
															ELSE pt.PositionTaking
														END	
						,pt.NewMemPositionTaking	= CASE WHEN pt.NewMinGivenPositionTaking - (pt.NewSumPresetDown + pt.NewMaxDeltaDown) + pt.NewPositionTaking > pt.NewPositionTaking 
															THEN pt.NewMinGivenPositionTaking - (pt.NewSumPresetDown + pt.NewMaxDeltaDown) + pt.NewPositionTaking 
															ELSE pt.NewPositionTaking
														END	
					FROM #TableAllLinePositionTaking AS pt 	

					--select * from #TableAllLinePositionTaking
					
					DELETE pt
					FROM #TableAllLinePositionTaking AS pt
					WHERE pt.MemPositionTaking = pt.NewMemPositionTaking
					
					--select * from #TableAllLinePositionTaking
					 
					UPDATE cpt 
					SET	cpt.PositionTaking = tapt.NewMemPositionTaking
					FROM CustPositionTaking AS cpt WITH (ROWLOCK, UPDLOCK)
						INNER JOIN CustInfo AS ci WITH (NOLOCK)
							ON cpt.CustId = ci.CustId
						INNER JOIN #TableAllLinePositionTaking AS tapt
							ON ci.AgentId		= tapt.AgentId
							AND cpt.SportType	= tapt.SportType
							AND cpt.BetType		= tapt.BetType
							AND cpt.IsLive		= tapt.IsLive
							AND cpt.AgentId		= tapt.ParentAgentId										

					DROP TABLE #TableAllLinePositionTaking
					-- End edit position taking on member 																	
				END
				-- End update new position taking if had changed 						
			END		

			-- Write log after update
			SET @xml = (
				SELECT SportType	AS '@s'
					,BetType		AS '@b'
					,IsLive			AS '@i'
					,MaxUpperPT		AS '@p'
					,MaxGivenPT		AS '@ma'
					,MinGivenPT		AS '@mi'
					,IsApply		AS '@ia'
				FROM #TablePositionTaking								
				FOR XML PATH('z'), ROOT('r')
			)

			DROP TABLE #TablePositionTaking

			SET @logSPData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

			-- end write log
			SET @endRun		= GETDATE()  
			SET @duration	= DATEDIFF(MILLISECOND, @startRun, @endRun) 
								
			IF @@ERROR = 0
				BEGIN TRY
					EXEC SVRLOG.LogDB.dbo.WriteLog_RunSpAgent
					@UserId		= @ActorAgentId,
					@AdminId	= @AdminId,
					@SPName		= 'Age_Agent_UpdatePositionTaking',
					@LogDate	= @startRun,
					@AgentId	= @AgentId,
					@Duration	= @Duration,
					@Data		= @logSPData,
					@OldData	= @logSPDataOld
				END	TRY
				BEGIN CATCH
					EXEC SVRTXN.LogDB.dbo.WriteLog_RunSpAgent
					@UserId		= @ActorAgentId,
					@AdminId	= @AdminId,
					@SPName		= 'Age_Agent_UpdatePositionTaking',
					@LogDate	= @startRun,
					@AgentId	= @AgentId,
					@Duration	= @Duration,
					@Data		= @logSPData,
					@OldData	= @logSPDataOld
				END CATCH 
		END	
END	   